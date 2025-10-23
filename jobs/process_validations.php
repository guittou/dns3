#!/usr/bin/env php
<?php
/**
 * Process queued zone validation jobs
 * This script is called by worker.sh to process validation jobs
 * 
 * For master zones referencing includes, this worker:
 * - Builds a flattened zone file by inlining all referenced include files recursively
 * - Writes the flattened zone to a temporary directory
 * - Runs named-checkzone against the flattened file
 * - Stores validation results in the database
 */

// Get queue file path from command line
if ($argc < 2) {
    echo "Usage: php process_validations.php <queue_file>\n";
    exit(1);
}

$queueFile = $argv[1];

if (!file_exists($queueFile)) {
    echo "Queue file not found: $queueFile\n";
    exit(1);
}

// Load configuration and models
require_once __DIR__ . '/../config.php';
require_once __DIR__ . '/../includes/db.php';
require_once __DIR__ . '/../includes/models/ZoneFile.php';

// Check if we should keep temporary files for debugging
$keepTmpFiles = getenv('JOBS_KEEP_TMP') === '1';

/**
 * Build flattened zone content by inlining all include files recursively
 * 
 * @param PDO $db Database connection
 * @param string $content Master zone content with $INCLUDE directives
 * @param array &$visited Array of visited filenames to prevent cycles
 * @return string Flattened zone content with includes inlined
 * @throws Exception if include not found or circular dependency detected
 */
function flattenZoneContent($db, $content, &$visited = []) {
    // Find all $INCLUDE directives
    // Pattern: $INCLUDE "path/to/file" or $INCLUDE path/to/file
    $pattern = '/^\s*\$INCLUDE\s+["\']?([^\s"\']+)["\']?\s*$/m';
    
    $result = preg_replace_callback($pattern, function($matches) use ($db, &$visited) {
        $includePath = $matches[1];
        $includeFilename = basename($includePath);
        
        // Check for circular dependency
        if (in_array($includeFilename, $visited)) {
            throw new Exception("Circular include detected: $includeFilename");
        }
        $visited[] = $includeFilename;
        
        // Try to find the include by filename (exact match first, then basename)
        $sql = "SELECT id, filename, content FROM zone_files 
                WHERE (filename = ? OR filename = ?) 
                AND file_type = 'include' 
                AND status = 'active' 
                LIMIT 1";
        $stmt = $db->prepare($sql);
        $stmt->execute([$includePath, $includeFilename]);
        $includeZone = $stmt->fetch(PDO::FETCH_ASSOC);
        
        if (!$includeZone) {
            throw new Exception("Include file not found: $includeFilename (path: $includePath)");
        }
        
        // Get the include content
        $includeContent = $includeZone['content'] ?? '';
        
        // Recursively flatten any nested includes
        $includeContent = flattenZoneContent($db, $includeContent, $visited);
        
        // Return the inlined content (no extra wrapping, preserve as-is)
        return $includeContent;
    }, $content);
    
    if ($result === null) {
        throw new Exception("Error processing includes: " . preg_last_error_msg());
    }
    
    return $result;
}

/**
 * Store validation result in database
 * 
 * @param PDO $db Database connection
 * @param int $zoneId Zone file ID
 * @param string $status Validation status (pending, passed, failed)
 * @param string $output Command output
 * @param int|null $userId User ID
 * @return bool Success status
 */
function storeValidationResult($db, $zoneId, $status, $output, $userId) {
    try {
        $sql = "INSERT INTO zone_file_validation (zone_file_id, status, output, run_by, checked_at)
                VALUES (?, ?, ?, ?, NOW())";
        
        $stmt = $db->prepare($sql);
        $stmt->execute([$zoneId, $status, $output, $userId]);
        
        return true;
    } catch (Exception $e) {
        error_log("Failed to store validation result: " . $e->getMessage());
        return false;
    }
}

$db = Database::getInstance()->getConnection();

// Load queue
$queue = json_decode(file_get_contents($queueFile), true);
if (!is_array($queue)) {
    echo "Invalid queue file format\n";
    exit(1);
}

echo "Processing " . count($queue) . " validation job(s)\n";

$namedCheckzone = defined('NAMED_CHECKZONE_PATH') ? NAMED_CHECKZONE_PATH : 'named-checkzone';

foreach ($queue as $job) {
    $zoneId = $job['zone_id'];
    $userId = $job['user_id'];
    
    echo "Validating zone ID: $zoneId\n";
    
    try {
        // Get zone file from database
        $sql = "SELECT id, name, filename, content, file_type FROM zone_files WHERE id = ? AND status != 'deleted'";
        $stmt = $db->prepare($sql);
        $stmt->execute([$zoneId]);
        $zone = $stmt->fetch(PDO::FETCH_ASSOC);
        
        if (!$zone) {
            echo "Zone file not found: $zoneId\n";
            storeValidationResult($db, $zoneId, 'failed', 'Zone file not found', $userId);
            continue;
        }
        
        // Create temporary directory
        $tmpDir = sys_get_temp_dir() . '/dns3_validate_' . uniqid();
        if (!mkdir($tmpDir, 0700, true)) {
            $errorMsg = "Failed to create temporary directory for validation";
            echo "$errorMsg\n";
            storeValidationResult($db, $zoneId, 'failed', $errorMsg, $userId);
            continue;
        }
        
        echo "Created temp directory: $tmpDir\n";
        
        try {
            // Build flattened zone content by inlining includes
            $zoneContent = $zone['content'] ?? '';
            $visited = [];
            
            try {
                $flattenedContent = flattenZoneContent($db, $zoneContent, $visited);
            } catch (Exception $e) {
                $errorMsg = "Failed to flatten zone content: " . $e->getMessage();
                echo "$errorMsg\n";
                storeValidationResult($db, $zoneId, 'failed', $errorMsg, $userId);
                
                if (!$keepTmpFiles) {
                    rmdir($tmpDir);
                }
                continue;
            }
            
            // Write flattened zone to temporary file
            $tempFileName = 'zone_' . $zoneId . '.db';
            $tempFilePath = $tmpDir . '/' . $tempFileName;
            
            if (file_put_contents($tempFilePath, $flattenedContent) === false) {
                $errorMsg = "Failed to write flattened zone file";
                echo "$errorMsg\n";
                storeValidationResult($db, $zoneId, 'failed', $errorMsg, $userId);
                
                if (!$keepTmpFiles) {
                    rmdir($tmpDir);
                }
                continue;
            }
            
            // Run named-checkzone against the flattened file
            $zoneName = $zone['name'];
            $command = escapeshellcmd($namedCheckzone) . ' ' . 
                       escapeshellarg($zoneName) . ' ' . 
                       escapeshellarg($tempFilePath) . ' 2>&1';
            
            exec($command, $output, $returnCode);
            $outputText = implode("\n", $output);
            
            // Determine status
            $status = ($returnCode === 0) ? 'passed' : 'failed';
            
            echo "named-checkzone exit code: $returnCode\n";
            echo "Output snippet: " . substr($outputText, 0, 200) . (strlen($outputText) > 200 ? '...' : '') . "\n";
            
            // Store validation result
            storeValidationResult($db, $zoneId, $status, $outputText, $userId);
            
            echo "Validation completed: $status\n";
            
        } finally {
            // Clean up temporary directory
            if ($keepTmpFiles) {
                echo "Keeping temporary files at: $tmpDir (JOBS_KEEP_TMP=1)\n";
            } else {
                // Remove files and directory
                if (file_exists($tempFilePath)) {
                    unlink($tempFilePath);
                }
                rmdir($tmpDir);
            }
        }
        
    } catch (Exception $e) {
        echo "Error validating zone $zoneId: " . $e->getMessage() . "\n";
        storeValidationResult($db, $zoneId, 'failed', 'Validation error: ' . $e->getMessage(), $userId);
    }
}

echo "All jobs processed\n";
exit(0);
?>
