# Testing Guide for Validation Include Master Generate

## Overview
This guide explains how to test the enhanced zone file validation system with include file support and comprehensive logging.

## Prerequisites
- PHP 7.4 or higher
- `named-checkzone` binary (from BIND package) - optional for full validation testing
- Access to the DNS3 database
- Shell access to run background workers

## Manual Testing

### Test 1: Basic Logging Verification

#### Setup
1. Navigate to the jobs directory:
   ```bash
   cd /path/to/dns3/jobs
   ```

2. Create a test validation queue:
   ```bash
   cat > validation_queue.json << 'EOF'
   [
       {
           "zone_id": 1,
           "user_id": 1,
           "queued_at": "2025-10-23 12:00:00"
       }
   ]
   EOF
   ```

#### Execute
```bash
php process_validations.php validation_queue.json
```

#### Expected Output
- Console output with timestamp-prefixed log messages
- Log entries written to `worker.log`
- Each validation job logs:
  - Start message with zone ID and user ID
  - Zone details (name, type, status)
  - Validation result with status and return code

#### Verification
```bash
cat worker.log
```

Look for entries like:
```
[YYYY-MM-DD HH:MM:SS] [process_validations] Processing 1 validation job(s)
[YYYY-MM-DD HH:MM:SS] [process_validations] Starting validation for zone ID: 1 (user: 1)
```

---

### Test 2: JOBS_KEEP_TMP Environment Variable

#### Setup
Set the environment variable:
```bash
export JOBS_KEEP_TMP=1
```

#### Execute
```bash
php process_validations.php validation_queue.json
```

#### Expected Output
- Log message confirming JOBS_KEEP_TMP is set
- Temporary directory path logged
- Temporary directory NOT deleted after validation

#### Verification
1. Check the log for the message:
   ```
   [YYYY-MM-DD HH:MM:SS] [process_validations] JOBS_KEEP_TMP is set - temporary directories will be preserved for debugging
   ```

2. Look for the temp directory path:
   ```
   [YYYY-MM-DD HH:MM:SS] [ZoneFile] DEBUG: Temporary directory kept at: /tmp/dns3_validate_XXXXX
   ```

3. Verify the directory exists:
   ```bash
   ls -la /tmp/dns3_validate_*
   ```

4. Clean up manually:
   ```bash
   rm -rf /tmp/dns3_validate_*
   ```

---

### Test 3: Include Zone Validation

#### Setup
Requires database with:
- At least one master zone
- At least one include zone assigned to the master
- Proper zone_file_includes relationship

#### Test Scenario 1: Include with Valid Master Parent
1. Create/identify an include zone in the database
2. Ensure it has a parent_id pointing to a master zone
3. Queue validation for the include zone

#### Execute
```bash
# Create queue file for include zone (e.g., zone_id 5)
cat > validation_queue.json << 'EOF'
[
    {
        "zone_id": 5,
        "user_id": 1,
        "queued_at": "2025-10-23 12:00:00"
    }
]
EOF

php process_validations.php validation_queue.json
```

#### Expected Output
Log entries showing:
1. Detection of include type
2. Parent chain traversal
3. Top master found
4. Validation performed on master

#### Verification
Check `worker.log` for:
```
[YYYY-MM-DD HH:MM:SS] [ZoneFile] Zone ID 5 is an include file - finding top master for validation
[YYYY-MM-DD HH:MM:SS] [ZoneFile] Traversing parent chain: zone ID 5, type='include', name='...'
[YYYY-MM-DD HH:MM:SS] [ZoneFile] Found master zone: ID X, name '...'
```

#### Test Scenario 2: Orphaned Include (No Master Parent)
1. Create an include zone with no parent
2. Queue validation for this include

#### Expected Output
```
[YYYY-MM-DD HH:MM:SS] [ZoneFile] ERROR: Include file has no master parent; cannot validate standalone
```

#### Test Scenario 3: Circular Dependency
1. Create a circular reference in include chain (Zone A includes Zone B, Zone B includes Zone A)
2. Queue validation

#### Expected Output
```
[YYYY-MM-DD HH:MM:SS] [ZoneFile] ERROR: Circular dependency detected in include chain at zone ID X
```

---

### Test 4: Worker Script

#### Execute
```bash
./worker.sh
```

#### Expected Output in worker.log
```
[YYYY-MM-DD HH:MM:SS] Worker started
[YYYY-MM-DD HH:MM:SS] Processing queue file: /path/to/validation_processing.json
[YYYY-MM-DD HH:MM:SS] Number of jobs in queue: X
[YYYY-MM-DD HH:MM:SS] Executing: php /path/to/process_validations.php /path/to/validation_processing.json
[YYYY-MM-DD HH:MM:SS] process_validations.php completed with exit code: 0
[YYYY-MM-DD HH:MM:SS] Worker completed
```

---

### Test 5: Full Validation with named-checkzone

#### Prerequisites
- `named-checkzone` installed and in PATH
- Valid zone file content in database

#### Setup
Create a master zone with proper DNS content:
```sql
INSERT INTO zone_files (name, filename, content, file_type, status, created_by, created_at)
VALUES (
    'example.com',
    'example.com.db',
    '$TTL 3600
@   IN  SOA ns1.example.com. admin.example.com. (
        2024010101 ; Serial
        3600       ; Refresh
        1800       ; Retry
        604800     ; Expire
        86400 )    ; Minimum TTL
@   IN  NS  ns1.example.com.
ns1 IN  A   192.0.2.1',
    'master',
    'active',
    1,
    NOW()
);
```

#### Execute
Queue validation for the zone and process it.

#### Expected Output
- Exit code 0 for valid zone
- Exit code non-zero for invalid zone
- Detailed validation output from named-checkzone
- Line context extraction for any errors

#### Verification
1. Check validation status in database:
   ```sql
   SELECT * FROM zone_file_validation WHERE zone_file_id = X ORDER BY checked_at DESC LIMIT 1;
   ```

2. Verify status is 'passed' or 'failed'
3. Check output field for named-checkzone messages

---

## Automated Testing

### Unit Tests
Run existing unit tests:
```bash
cd /path/to/dns3
composer install
vendor/bin/phpunit tests/unit/
```

### Integration Test Script
Run the integration test:
```bash
bash /tmp/test_integration.sh
```

Expected output:
```
=== Zone File Validation Integration Test ===
✓ Created master zone file
✓ Created include zone file
✓ Created master zone file with include
✓ All tests passed successfully
```

---

## Troubleshooting

### Issue: Logs not appearing in worker.log
**Solution**: Check file permissions on the jobs directory:
```bash
chmod 755 /path/to/dns3/jobs
touch /path/to/dns3/jobs/worker.log
chmod 664 /path/to/dns3/jobs/worker.log
```

### Issue: Temporary directories not being cleaned up
**Solution**: 
1. Check if JOBS_KEEP_TMP is set:
   ```bash
   echo $JOBS_KEEP_TMP
   ```
2. Manually clean up:
   ```bash
   rm -rf /tmp/dns3_validate_*
   ```

### Issue: named-checkzone not found
**Solution**: 
1. Install BIND utilities:
   ```bash
   # Ubuntu/Debian
   sudo apt-get install bind9-utils
   
   # CentOS/RHEL
   sudo yum install bind-utils
   ```
2. Or set the path in config.php:
   ```php
   define('NAMED_CHECKZONE_PATH', '/usr/sbin/named-checkzone');
   ```

### Issue: Include validation not working
**Solution**:
1. Verify zone_file_includes table has correct relationships
2. Check that include zone has a parent_id
3. Verify parent chain leads to a master zone
4. Check worker.log for detailed error messages

---

## Performance Testing

### Test with Large Queue
Create a queue with 100 validation jobs:
```bash
php -r '
$queue = [];
for ($i = 1; $i <= 100; $i++) {
    $queue[] = [
        "zone_id" => $i,
        "user_id" => 1,
        "queued_at" => date("Y-m-d H:i:s")
    ];
}
file_put_contents("validation_queue.json", json_encode($queue, JSON_PRETTY_PRINT));
'
```

Execute and measure time:
```bash
time php process_validations.php validation_queue.json
```

---

## Regression Testing Checklist

- [ ] Master zone validation still works as before
- [ ] Include zone validation finds correct parent
- [ ] Circular dependency detection works
- [ ] Orphaned include detection works
- [ ] JOBS_KEEP_TMP preserves temp directories
- [ ] Logs are written to worker.log
- [ ] Validation results stored in database
- [ ] Worker script processes queue correctly
- [ ] Exit codes are correctly captured
- [ ] Shell commands are properly escaped

---

## Success Criteria

✅ All log messages appear in worker.log with correct timestamps  
✅ JOBS_KEEP_TMP=1 preserves temporary directories  
✅ Include zones are validated through their master  
✅ Parent chain traversal logs each step  
✅ Error conditions produce clear error messages  
✅ Exit codes are captured and logged  
✅ Shell commands use escapeshellarg  
✅ Database content remains unchanged  
✅ No PHP or bash syntax errors  
✅ All existing functionality continues to work
