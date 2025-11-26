> **ARCHIVED DOCUMENT NOTE** : Les fichiers de migration mentionnés dans ce document ont été supprimés. Pour les nouvelles installations, utilisez `database.sql` (ou `structure_ok_dns3_db.sql`).

# Zone Validation Worker Fix - Documentation

## Problem Summary

The zone validation system had issues when validating zone files that use `$INCLUDE` directives:

1. **Schema Mismatch**: The code tried to insert `command` and `return_code` columns into `zone_file_validation` table, but these columns don't exist in the actual schema (`structure_ok_dns3_db.sql`)
2. **$INCLUDE Handling**: Zone files with `$INCLUDE` directives would fail validation because `named-checkzone` received files with `$INCLUDE` references pointing to files not present on disk

## Solution Implemented

### 1. Database Schema Fix

**Changed**: `storeValidationResult()` method in `includes/models/ZoneFile.php`

- **Before**: Attempted to insert into non-existent `command` and `return_code` columns
- **After**: Embeds command and exit code into the `output` TEXT field

**Format of output field**:
```
Command: named-checkzone -q example.com /tmp/dns3_validate_xxx/zone_1_flat.db 2>&1
Exit Code: 0

<stdout/stderr from named-checkzone>
```

**Benefits**:
- Matches the actual database schema in `structure_ok_dns3_db.sql`
- All validation information in a single field
- Proper truncation of large outputs (10000 chars max)
- Backward compatible with existing records

### 2. Flattened Zone Generation

The system already had a working `generateFlatZone()` method that:
- Recursively traverses the include tree
- Removes `$INCLUDE` directives from content
- Inlines all include content in the correct order (respecting `position` field)
- Protects against circular dependencies using a `visited` array
- Generates a single "flat" zone file for validation

### 3. Include File Validation

When validating an include file:
1. `findTopMaster()` traverses the parent chain to find the top-level master zone
2. Validation is performed on the entire flattened master zone
3. Results are propagated back to all includes in the tree

**Cycle Protection**:
- Both `findTopMaster()` and `generateFlatZone()` track visited zone IDs
- Circular dependencies are detected and reported as errors

### 4. Enhanced Logging

**Improvements in `runNamedCheckzone()`**:
- Logs temporary directory path for each validation
- Logs command being executed
- Logs exit code and status
- Logs first 500 chars of error output for failed validations
- All logs go to `jobs/worker.log` with timestamps

**Example log entries**:
```
[2025-10-23 15:30:45] [ZoneFile] Created temporary directory for zone ID 5: /tmp/dns3_validate_abc123
[2025-10-23 15:30:45] [ZoneFile] Generated flattened zone content for zone ID 5 (4256 bytes)
[2025-10-23 15:30:45] [ZoneFile] Executing command for zone ID 5: named-checkzone -q example.com /tmp/...
[2025-10-23 15:30:45] [ZoneFile] Command exit code for zone ID 5: 0
[2025-10-23 15:30:45] [ZoneFile] Validation PASSED for zone ID 5
```

### 5. Debug Mode

Set `JOBS_KEEP_TMP=1` environment variable to preserve temporary directories:

```bash
export JOBS_KEEP_TMP=1
./jobs/worker.sh
```

When enabled:
- Temporary directories are NOT deleted after validation
- Allows inspection of flattened zone files
- Logged message shows the preserved directory path

### 6. Migration 012 Handling

**File**: `migrations/012_add_validation_command_fields.sql`

- **Renamed to**: `012_add_validation_command_fields.sql.disabled`
- **Reason**: These columns are not in the actual schema
- **Documentation**: Added `README_012_DISABLED.md` explaining the decision

**If migration was already applied**:
- System will continue to work
- Command and exit code will be in the `output` field
- The extra columns will remain unused but won't cause issues

## Testing

### Manual Test Script

Run the included test script to verify the setup:

```bash
php test_validation_manual.php
```

This checks:
- Database schema (confirms no command/return_code columns)
- named-checkzone availability
- Existing zones in the database

### End-to-End Testing

1. **Create a test master zone** with $INCLUDE directives:
```
$TTL 3600
@   IN  SOA ns1.example.com. admin.example.com. (
        2024010101 ; Serial
        3600       ; Refresh
        1800       ; Retry
        604800     ; Expire
        86400 )    ; Minimum

@   IN  NS  ns1.example.com.

$INCLUDE "hosts.db"
```

2. **Create an include file** (hosts.db):
```
www     IN  A   192.168.1.100
mail    IN  A   192.168.1.101
```

3. **Assign the include** to the master zone via the UI

4. **Trigger validation** on either the master or include

5. **Check results**:
   - `jobs/worker.log` - detailed execution logs
   - Database query: `SELECT * FROM zone_file_validation WHERE zone_file_id = ?`
   - Output field should contain command, exit code, and validation results

### Validation Scenarios

✅ **Master zone without includes** - validates directly
✅ **Master zone with includes** - generates flat zone, validates, propagates results
✅ **Include zone** - finds top master, validates entire tree, propagates results
✅ **Circular dependencies** - detected and reported as error
✅ **Missing parent** - detected and reported as error
✅ **Large output** - truncated to 10000 chars with note

## Files Changed

1. `includes/models/ZoneFile.php`
   - Modified `storeValidationResult()` - embed command/exit code in output field
   - Enhanced `runNamedCheckzone()` - improved logging and error messages

2. `migrations/012_add_validation_command_fields.sql`
   - Renamed to `.disabled` suffix
   - Not compatible with actual schema

3. `migrations/README_012_DISABLED.md` (NEW)
   - Documentation explaining why migration was disabled

4. `test_validation_manual.php` (NEW)
   - Manual test script for verification

## API Compatibility

The validation API remains unchanged:
- `/api/zone_api.php?action=zone_validate&id=<zone_id>`
- Returns: `{status, output, return_code}`

The `return_code` is from the validation result array, not from the database.

## Configuration

In `config.php`:
```php
// Run validation synchronously (true) or queue for background (false)
define('ZONE_VALIDATE_SYNC', false);

// Path to named-checkzone binary
define('NAMED_CHECKZONE_PATH', 'named-checkzone');
```

## Troubleshooting

**Issue**: Validation fails with "command not found"
- **Fix**: Install bind-utils (RHEL/CentOS) or bind9-utils (Debian/Ubuntu)
- Or set full path: `define('NAMED_CHECKZONE_PATH', '/usr/sbin/named-checkzone');`

**Issue**: "Failed to create temporary directory"
- **Fix**: Check permissions on `/tmp` or system temp directory
- Verify PHP has write access

**Issue**: "Circular dependency detected"
- **Fix**: Check zone_file_includes table for cycles
- Remove the circular include relationship

**Issue**: Old validation records have different format
- **Note**: This is expected - old records may have separate command/return_code columns
- New records will have everything in output field
- Both formats work with the API

## Security Considerations

✅ Temporary directories are created with mode 0700 (owner-only access)
✅ Command arguments are properly escaped with `escapeshellcmd()` and `escapeshellarg()`
✅ Temporary files are cleaned up after validation (unless debug mode is on)
✅ Output is truncated to prevent database bloat
✅ Cycle detection prevents infinite loops

## Future Improvements

Potential enhancements (not implemented in this fix):
- Add validation caching to avoid redundant checks
- Support for zone file signing (DNSSEC)
- Parallel validation of multiple zones
- Validation result notifications (email/webhook)
- Web UI for viewing flattened zone content
