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

$zoneFile = new ZoneFile();

// Load queue
$queue = json_decode(file_get_contents($queueFile), true);
if (!is_array($queue)) {
    echo "Invalid queue file format\n";
    exit(1);
}

echo "Processing " . count($queue) . " validation job(s)\n";

foreach ($queue as $job) {
    $zoneId = $job['zone_id'];
    $userId = $job['user_id'];
    
    echo "Validating zone ID: $zoneId\n";
    
    try {
        // Run validation synchronously (we're in background)
        $result = $zoneFile->validateZoneFile($zoneId, $userId, true);
        
        if (is_array($result)) {
            echo "Validation completed: " . $result['status'] . "\n";
        } else {
            echo "Validation failed\n";
        }
    } catch (Exception $e) {
        echo "Error validating zone $zoneId: " . $e->getMessage() . "\n";
    }
}

echo "All jobs processed\n";
exit(0);
?>
