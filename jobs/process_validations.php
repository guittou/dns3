<?php
/**
 * Process validation jobs: inline $INCLUDE contents into a flattened zone file,
 * run named-checkzone against the flattened file, store output in zone_file_validation,
 * and log results.
 *
 * Behaviour:
 * - For each job (zone_id) read master zone content from zone_files
 * - Replace each $INCLUDE <filename> by the content of the corresponding include zone (recursive, cycle-safe)
 * - Write flattened file to tmpdir and run: named-checkzone -q <origin> <flattened-file>
 * - Save output and set status passed|failed in zone_file_validation
 * - Remove tmpdir unless JOBS_KEEP_TMP=1
 *
 * Note: this script assumes includes are stored in zone_files.filename and
 * include contents are in zone_files.content. Lookup tries exact filename then basename.
 */

require_once __DIR__ . '/../includes/db.php';

$pdo = Database::getInstance()->getConnection();
$pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

$LOG_FILE = __DIR__ . '/worker.log';
function log_msg($msg) {
    global $LOG_FILE;
    $line = '[' . date('Y-m-d H:i:s') . '] ' . $msg . PHP_EOL;
    file_put_contents($LOG_FILE, $line, FILE_APPEND);
}

// Utility: find include by filename (exact or basename)
function find_include_by_filename(PDO $pdo, $filename) {
    // Try exact match first
    $stmt = $pdo->prepare("SELECT id, filename, content FROM zone_files WHERE filename = :fn LIMIT 1");
    $stmt->execute([':fn' => $filename]);
    $row = $stmt->fetch(PDO::FETCH_ASSOC);
    if ($row) return $row;

    // Try basename match
    $basename = basename($filename);
    $stmt = $pdo->prepare("SELECT id, filename, content FROM zone_files WHERE filename LIKE :bfn OR filename = :bfn_exact LIMIT 1");
    $stmt->execute([':bfn' => "%{$basename}", ':bfn_exact' => $basename]);
    $row = $stmt->fetch(PDO::FETCH_ASSOC);
    if ($row) return $row;

    // Not found
    return null;
}

// Inline includes recursively. $visited tracks included filenames/ids to avoid cycles.
function inline_includes(PDO $pdo, $content, &$visited) {
    // Regex to match $INCLUDE lines and capture filename (supports quoted and unquoted)
    $regex = '/^(\s*\$INCLUDE\s+)(?:"([^"]+)"|\'([^\']+)\'|(\S+))(.*)$/im';
    $offset = 0;
    $result = $content;

    // Use preg_match_all to find all include occurrences
    if (preg_match_all($regex, $content, $matches, PREG_SET_ORDER)) {
        foreach ($matches as $m) {
            // Determine the filename token
            $includeFilename = $m[2] ?: ($m[3] ?: $m[4]);
            $fullLine = $m[0];

            // Prevent including same file twice (cycle protection)
            if (in_array($includeFilename, $visited, true)) {
                $replacement = "; CYCLE DETECTED: include {$includeFilename} skipped to avoid infinite loop\n";
                $result = str_replace($fullLine, $replacement, $result);
                continue;
            }

            // Lookup include content in DB
            $incRow = find_include_by_filename($pdo, $includeFilename);
            if (!$incRow) {
                // Not found ? keep a descriptive message but mark as failure later
                $replacement = "; INCLUDE MISSING: {$includeFilename} (not found in DB)\n";
                $result = str_replace($fullLine, $replacement, $result);
                // record a special token in visited to indicate missing include
                $visited[] = "MISSING:{$includeFilename}";
                continue;
            }

            // Mark visited to prevent cycles
            $visited[] = $includeFilename;

            // Inline included content as-is (no wrapping). Preserve original indentation if any.
            $includeContent = $incRow['content'] ?? '';
            // Recursively inline includes inside this include
            $includeContentInlined = inline_includes($pdo, $includeContent, $visited);

            // Replace the $INCLUDE line with the include content
            // Keep a clear marker around the inlined content for debugging
            $replacement = "; BEGIN INLINE INCLUDE: {$incRow['filename']}\n"
                         . $includeContentInlined
                         . "\n; END INLINE INCLUDE: {$incRow['filename']}\n";

            $result = str_replace($fullLine, $replacement, $result);
            // Note: do not remove from visited here ï¿½ keep it to avoid re-including later
        }
    }

    return $result;
}

// Update or insert validation result
function save_validation_result(PDO $pdo, $zone_file_id, $status, $output) {
    // check if a validation row exists for this zone_file_id (we keep history but update a recent row)
    $stmt = $pdo->prepare("INSERT INTO zone_file_validation (zone_file_id, status, output, checked_at) VALUES (:zf, :status, :output, NOW())");
    $stmt->execute([
        ':zf' => $zone_file_id,
        ':status' => $status,
        ':output' => $output
    ]);
}

function run_named_checkzone($origin, $filePath) {
    // Use -q for quiet output on success
    $cmd = sprintf('named-checkzone -q %s %s 2>&1', escapeshellarg($origin), escapeshellarg($filePath));
    $output = [];
    $exitCode = 0;
    exec($cmd, $output, $exitCode);
    return ['cmd' => $cmd, 'exit' => $exitCode, 'output' => implode("\n", $output)];
}

// Main: read processing JSON job list passed as first arg
if ($argc < 2) {
    fwrite(STDERR, "Usage: php process_validations.php <processing_json>\n");
    exit(1);
}

$processingJson = $argv[1];
if (!file_exists($processingJson)) {
    fwrite(STDERR, "Processing file not found: {$processingJson}\n");
    exit(1);
}

$jobs = json_decode(file_get_contents($processingJson), true);
if (!is_array($jobs)) {
    fwrite(STDERR, "Invalid processing file format\n");
    exit(1);
}

log_msg("process_validations.php started: " . count($jobs) . " job(s)");

foreach ($jobs as $job) {
    $zone_id = isset($job['zone_id']) ? (int)$job['zone_id'] : (isset($job['id']) ? (int)$job['id'] : null);
    if (!$zone_id) {
        log_msg("Skipping invalid job entry: " . json_encode($job));
        continue;
    }

    log_msg("Validating zone ID: {$zone_id}");

    // Load master zone
    $stmt = $pdo->prepare("SELECT id, name, filename, content FROM zone_files WHERE id = :id LIMIT 1");
    $stmt->execute([':id' => $zone_id]);
    $zone = $stmt->fetch(PDO::FETCH_ASSOC);
    if (!$zone) {
        $msg = "Zone file id {$zone_id} not found in DB";
        log_msg($msg);
        save_validation_result($pdo, $zone_id, 'error', $msg);
        continue;
    }

    $origin = $zone['name'];
    $masterFilename = $zone['filename'] ?: ("zone_{$zone_id}.db");
    $masterContent = $zone['content'] ?? '';

    // Build flattened content by inlining includes
    $visited = [];
    $flattened = inline_includes($pdo, $masterContent, $visited);

    // If any visited entry indicates missing include, mark as failed with message
    $missingIncludes = array_filter($visited, function($v){ return strpos($v, 'MISSING:') === 0; });
    $tmpBase = sys_get_temp_dir() . '/dns3_validate_' . $zone_id . '_' . time();
    if (!mkdir($tmpBase, 0775, true) && !is_dir($tmpBase)) {
        $msg = "Failed to create tmpdir {$tmpBase}";
        log_msg($msg);
        save_validation_result($pdo, $zone_id, 'error', $msg);
        continue;
    }

    // Write flattened file
    $flatPath = rtrim($tmpBase, '/') . '/' . basename($masterFilename) . '.flat';
    file_put_contents($flatPath, $flattened);

    log_msg("Flattened zone written to {$flatPath} (tmpdir: {$tmpBase})");

    // If missing includes encountered, include a descriptive message before running named-checkzone
    if (!empty($missingIncludes)) {
        $msg = "Missing includes detected: " . implode(', ', $missingIncludes);
        log_msg($msg);
        // still run named-checkzone to capture errors, but we'll record that includes were missing
    }

    // Run named-checkzone against flattened file
    $res = run_named_checkzone($origin, $flatPath);

    $shortOutput = substr($res['output'], 0, 8000);
    $status = ($res['exit'] === 0) ? 'passed' : 'failed';

    // Prepend some metadata into the output stored
    $storeOutput = "Command: {$res['cmd']}\nExitCode: {$res['exit']}\n---\n{$shortOutput}\n";
    if (!empty($missingIncludes)) {
        $storeOutput .= "\nNOTE: Missing includes were detected and inlined as comments. Missing list: " . implode(', ', $missingIncludes) . "\n";
        $status = 'failed';
    }

    // Save validation result
    save_validation_result($pdo, $zone_id, $status, $storeOutput);
    log_msg("Validation completed for zone {$zone_id}: status={$status}, exit={$res['exit']}");

    // Keep tmpdir if JOBS_KEEP_TMP=1
    if (getenv('JOBS_KEEP_TMP') === '1') {
        log_msg("JOBS_KEEP_TMP=1, leaving tmpdir {$tmpBase} for inspection");
    } else {
        // remove tmpdir recursively
        $cmdRm = 'rm -rf ' . escapeshellarg($tmpBase);
        exec($cmdRm);
        log_msg("Tmpdir {$tmpBase} removed");
    }
}

log_msg("process_validations.php completed");
