#!/usr/bin/env php
<?php
/**
 * Manual test script to verify zone validation functionality
 * Tests the changes made to fix zone validation with $INCLUDE directives
 */

require_once __DIR__ . '/config.php';
require_once __DIR__ . '/includes/db.php';
require_once __DIR__ . '/includes/models/ZoneFile.php';

echo "=== Zone Validation Test ===\n\n";

// Check if named-checkzone is available
$namedCheckzone = defined('NAMED_CHECKZONE_PATH') ? NAMED_CHECKZONE_PATH : 'named-checkzone';
$checkCmd = "which $namedCheckzone 2>&1";
exec($checkCmd, $checkOutput, $checkReturnCode);

if ($checkReturnCode !== 0) {
    echo "WARNING: named-checkzone not found in PATH. Validation will fail.\n";
    echo "Please install bind-utils or bind9-utils package.\n\n";
} else {
    echo "✓ named-checkzone found at: " . implode("\n", $checkOutput) . "\n\n";
}

$zoneFile = new ZoneFile();

// Test 1: Check database schema
echo "Test 1: Verify database schema\n";
echo "-------------------------------\n";
try {
    $db = Database::getInstance()->getConnection();
    $stmt = $db->query("DESCRIBE zone_file_validation");
    $columns = $stmt->fetchAll(PDO::FETCH_COLUMN);
    
    echo "Columns in zone_file_validation table:\n";
    foreach ($columns as $col) {
        echo "  - $col\n";
    }
    
    // Check that command and return_code columns are NOT present
    if (in_array('command', $columns)) {
        echo "\n⚠ WARNING: 'command' column exists in database (migration 012 was applied)\n";
        echo "  The code will still work by embedding command in output field.\n";
    } else {
        echo "\n✓ Schema is correct - no 'command' column (using output field)\n";
    }
    
    if (in_array('return_code', $columns)) {
        echo "⚠ WARNING: 'return_code' column exists in database (migration 012 was applied)\n";
        echo "  The code will still work by embedding exit code in output field.\n";
    } else {
        echo "✓ Schema is correct - no 'return_code' column (using output field)\n";
    }
} catch (Exception $e) {
    echo "ERROR: " . $e->getMessage() . "\n";
}

echo "\n\nTest 2: Check zone files in database\n";
echo "-------------------------------------\n";
try {
    $zones = $zoneFile->search(['status' => 'active'], 10, 0);
    echo "Found " . count($zones) . " active zone(s):\n";
    foreach ($zones as $zone) {
        echo "  - ID: {$zone['id']}, Name: {$zone['name']}, Type: {$zone['file_type']}\n";
    }
    
    if (count($zones) === 0) {
        echo "\nNOTE: No zones found in database. Cannot test validation.\n";
        echo "Please create a test zone file in the web interface first.\n";
    }
} catch (Exception $e) {
    echo "ERROR: " . $e->getMessage() . "\n";
}

echo "\n\n=== Test Complete ===\n";
echo "\nTo test actual validation:\n";
echo "1. Create a zone file in the web interface\n";
echo "2. Trigger validation via API or UI\n";
echo "3. Check jobs/worker.log for detailed logs\n";
echo "4. Verify validation result in zone_file_validation table\n";
echo "\nTo enable debug mode (keep temp directories):\n";
echo "  export JOBS_KEEP_TMP=1\n";
?>
