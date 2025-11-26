> **ARCHIVED DOCUMENT NOTE** : Les fichiers de migration mentionnés dans ce document ont été supprimés. Pour les nouvelles installations, utilisez `database.sql` (ou `structure_ok_dns3_db.sql`).

# Testing Guide for Validation Flattening

## Prerequisites

1. MySQL/MariaDB running with dns3_db database
2. Run migration: `mysql dns3_db < migrations/012_add_validation_command_fields.sql`
3. `named-checkzone` binary installed (usually part of BIND package)
4. Web server configured (Apache/Nginx with PHP)

## Manual Testing Steps

### Test 1: Master Zone Validation

1. Create a master zone through the web UI or API:
```sql
INSERT INTO zone_files (name, filename, content, file_type, status, created_by)
VALUES (
    'example.com',
    'example.com.db',
    '$ORIGIN example.com.
$TTL 3600
@   IN  SOA ns1.example.com. admin.example.com. (
    2024010101  ; Serial
    3600        ; Refresh
    1800        ; Retry
    604800      ; Expire
    86400       ; Minimum TTL
)
@   IN  NS  ns1.example.com.
ns1 IN  A   192.168.1.1
',
    'master',
    'active',
    1
);
```

2. Trigger validation (via API or create a queue file):
```bash
# Create queue file
echo '[{"zone_id": 1, "user_id": 1, "queued_at": "2024-01-01 12:00:00"}]' > jobs/validation_queue.json

# Run worker
./jobs/worker.sh
```

3. Check validation results:
```sql
SELECT * FROM zone_file_validation WHERE zone_file_id = 1 ORDER BY checked_at DESC LIMIT 1;
```

Expected result:
- `status`: 'passed' or 'failed'
- `command`: Full named-checkzone command
- `return_code`: 0 for success, non-zero for failure
- `output`: Output from named-checkzone

### Test 2: Include Zone Validation

1. Create an include zone:
```sql
INSERT INTO zone_files (name, filename, content, file_type, status, created_by)
VALUES (
    'hosts-include',
    'hosts.inc',
    'host1   IN  A   192.168.1.10
host2   IN  A   192.168.1.11
host3   IN  A   192.168.1.12
',
    'include',
    'active',
    1
);
```

2. Assign include to master:
```sql
INSERT INTO zone_file_includes (parent_id, include_id, position)
VALUES (1, 2, 1);
```

3. Update master zone to include the $INCLUDE directive:
```sql
UPDATE zone_files 
SET content = '$ORIGIN example.com.
$TTL 3600
@   IN  SOA ns1.example.com. admin.example.com. (
    2024010102  ; Serial
    3600        ; Refresh
    1800        ; Retry
    604800      ; Expire
    86400       ; Minimum TTL
)
@   IN  NS  ns1.example.com.
ns1 IN  A   192.168.1.1
$INCLUDE "hosts.inc"
'
WHERE id = 1;
```

4. Trigger validation on the include:
```bash
echo '[{"zone_id": 2, "user_id": 1, "queued_at": "2024-01-01 12:00:00"}]' > jobs/validation_queue.json
./jobs/worker.sh
```

5. Verify both zones have validation results:
```sql
-- Master validation
SELECT * FROM zone_file_validation WHERE zone_file_id = 1 ORDER BY checked_at DESC LIMIT 1;

-- Include validation (should reference parent master)
SELECT * FROM zone_file_validation WHERE zone_file_id = 2 ORDER BY checked_at DESC LIMIT 1;
```

### Test 3: Debug Mode with Temporary Files

1. Set environment variable and run worker:
```bash
JOBS_KEEP_TMP=1 ./jobs/worker.sh
```

2. Check worker log for tmpdir path:
```bash
tail -50 jobs/worker.log
```

3. Inspect the temporary directory:
```bash
# The log will show path like: /tmp/dns3_validate_abc123
ls -la /tmp/dns3_validate_*
cat /tmp/dns3_validate_*/zone_*_flat.db
```

4. Verify the flattened file contains:
   - Master zone content (without $INCLUDE directives)
   - All include content inlined with BEGIN/END markers
   - No $INCLUDE directives remaining

### Test 4: Circular Dependency Detection

1. Create a circular dependency (this should fail):
```sql
-- Create two includes
INSERT INTO zone_files (name, filename, content, file_type, status, created_by)
VALUES 
    ('include-a', 'a.inc', 'hosta IN A 192.168.1.20', 'include', 'active', 1),
    ('include-b', 'b.inc', 'hostb IN A 192.168.1.21', 'include', 'active', 1);

-- Create circular reference (include-a includes include-b, and vice versa)
INSERT INTO zone_file_includes (parent_id, include_id, position)
VALUES 
    (3, 4, 1),  -- include-a includes include-b
    (4, 3, 1);  -- include-b includes include-a
```

2. Try to validate include-a:
```bash
echo '[{"zone_id": 3, "user_id": 1, "queued_at": "2024-01-01 12:00:00"}]' > jobs/validation_queue.json
JOBS_KEEP_TMP=1 ./jobs/worker.sh
```

3. Check validation result:
```sql
SELECT * FROM zone_file_validation WHERE zone_file_id = 3 ORDER BY checked_at DESC LIMIT 1;
```

Expected: Error message about circular dependency.

## Verification Checklist

- [ ] Master zones validate successfully with flattened content
- [ ] Include zones trigger validation of their top master
- [ ] `command` field is populated in zone_file_validation
- [ ] `return_code` field is populated in zone_file_validation
- [ ] Validation results propagate to all child includes
- [ ] JOBS_KEEP_TMP=1 preserves temporary directories
- [ ] Worker log shows tmpdir path, command, and exit code
- [ ] Flattened files contain no $INCLUDE directives
- [ ] Circular dependencies are detected and handled gracefully
- [ ] Database content (zone_files.content) remains unchanged

## Expected Worker Log Output

```
[2024-01-01 12:00:00] [worker] Worker started
[2024-01-01 12:00:00] [worker] Processing queue file: /path/to/jobs/validation_processing.json
[2024-01-01 12:00:00] [process_validations] Processing 1 validation job(s)
[2024-01-01 12:00:00] [process_validations] Starting validation for zone ID: 1 (user: 1)
[2024-01-01 12:00:00] [process_validations] Zone details: name='example.com', type='master', status='active'
[2024-01-01 12:00:00] [ZoneFile] Zone ID 1 is a master zone - validating directly
[2024-01-01 12:00:00] [ZoneFile] Created temporary directory: /tmp/dns3_validate_abc123
[2024-01-01 12:00:00] [ZoneFile] Generated flattened zone content (1234 bytes)
[2024-01-01 12:00:00] [ZoneFile] Flattened zone file written to: /tmp/dns3_validate_abc123/zone_1_flat.db
[2024-01-01 12:00:00] [ZoneFile] Executing command: named-checkzone 'example.com' '/tmp/dns3_validate_abc123/zone_1_flat.db' 2>&1
[2024-01-01 12:00:00] [ZoneFile] Temporary directory: /tmp/dns3_validate_abc123
[2024-01-01 12:00:00] [ZoneFile] Command exit code: 0
[2024-01-01 12:00:00] [ZoneFile] Validation result for zone ID 1: passed
[2024-01-01 12:00:00] [ZoneFile] Temporary directory cleaned up: /tmp/dns3_validate_abc123
[2024-01-01 12:00:00] [process_validations] Validation completed for zone ID 1: status=passed, return_code=0
[2024-01-01 12:00:00] [process_validations] All jobs processed successfully
[2024-01-01 12:00:00] [worker] process_validations.php completed with exit code: 0
[2024-01-01 12:00:00] [worker] Worker completed
```
