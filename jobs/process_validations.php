#!/usr/bin/env php
<?php
/**
 * Process queued zone validation jobs
 * This script is called by worker.sh to process validation jobs
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

// Setup logging
$logFile = __DIR__ . '/worker.log';
function logMessage($message) {
    global $logFile;
    $timestamp = date('Y-m-d H:i:s');
    $logLine = "[$timestamp] [process_validations] $message\n";
    file_put_contents($logFile, $logLine, FILE_APPEND);
    echo $logLine;
}

// Check for JOBS_KEEP_TMP environment variable
$keepTmp = getenv('JOBS_KEEP_TMP') === '1';
if ($keepTmp) {
    define('DEBUG_KEEP_TMPDIR', true);
    logMessage("JOBS_KEEP_TMP is set - temporary directories will be preserved for debugging");
}

$zoneFile = new ZoneFile();

// Load queue
$queue = json_decode(file_get_contents($queueFile), true);
if (!is_array($queue)) {
    logMessage("ERROR: Invalid queue file format");
    exit(1);
}

logMessage("Processing " . count($queue) . " validation job(s)");

foreach ($queue as $job) {
    $zoneId = $job['zone_id'];
    $userId = $job['user_id'];
    
    logMessage("Starting validation for zone ID: $zoneId (user: $userId)");
    
    try {
        // Get zone info for logging
        $zone = $zoneFile->getById($zoneId);
        if ($zone) {
            logMessage("Zone details: name='{$zone['name']}', type='{$zone['file_type']}', status='{$zone['status']}'");
        }
        
        // Run validation synchronously (we're in background)
        $result = $zoneFile->validateZoneFile($zoneId, $userId, true);
        
        if (is_array($result)) {
            logMessage("Validation completed for zone ID $zoneId: status={$result['status']}, return_code={$result['return_code']}");
            
            // Log output if validation failed
            if ($result['status'] === 'failed') {
                logMessage("Validation output for zone ID $zoneId:\n" . $result['output']);
            }
        } else {
            logMessage("WARNING: Validation returned non-array result for zone ID $zoneId");
        }
    } catch (Exception $e) {
        logMessage("ERROR: Exception while validating zone $zoneId: " . $e->getMessage());
        logMessage("Stack trace: " . $e->getTraceAsString());
    }
}

logMessage("All jobs processed successfully");
exit(0);
?>
