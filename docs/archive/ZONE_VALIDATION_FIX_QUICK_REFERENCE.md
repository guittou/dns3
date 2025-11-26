> **ARCHIVED DOCUMENT NOTE** : Les fichiers de migration mentionnés dans ce document ont été supprimés. Pour les nouvelles installations, utilisez `database.sql` (ou `structure_ok_dns3_db.sql`).

# Zone Validation Fix - Quick Reference

## What Was Fixed

1. ✅ **Database Schema Alignment**: Removed references to non-existent `command` and `return_code` columns
2. ✅ **Output Field Format**: Command and exit code now embedded in `output` TEXT field
3. ✅ **Flattened Zone Generation**: Already working - generates single file without $INCLUDE directives
4. ✅ **Cycle Detection**: Protected against circular includes in both parent traversal and flattening
5. ✅ **Enhanced Logging**: Detailed logs in `jobs/worker.log` with tmpdir, command, exit code
6. ✅ **Debug Mode**: `JOBS_KEEP_TMP=1` preserves temp directories for inspection

## Key Changes

### File: `includes/models/ZoneFile.php`

**Method: `storeValidationResult()`**
```php
// OLD: Tried to insert into non-existent columns
INSERT INTO zone_file_validation (zone_file_id, status, output, command, return_code, run_by, checked_at)

// NEW: Embeds everything in output field
INSERT INTO zone_file_validation (zone_file_id, status, output, run_by, checked_at)
```

**Method: `runNamedCheckzone()`**
- Added detailed logging for tmpdir, command, exit code
- Improved error messages with zone ID context
- Uses `-q` flag for quieter named-checkzone output

### File: `migrations/012_add_validation_command_fields.sql.disabled`
- Disabled (renamed with .disabled suffix)
- Not compatible with actual schema in `structure_ok_dns3_db.sql`

## Output Field Format

```
Command: named-checkzone -q example.com /tmp/dns3_validate_xxx/zone_1_flat.db 2>&1
Exit Code: 0

zone example.com/IN: loaded serial 2024010101
OK
```

## Testing

**Quick test**:
```bash
php test_validation_manual.php
```

**Enable debug mode**:
```bash
export JOBS_KEEP_TMP=1
./jobs/worker.sh
```

**Check logs**:
```bash
tail -f jobs/worker.log
```

**Query validation results**:
```sql
SELECT 
    zf.name,
    zfv.status,
    zfv.output,
    zfv.checked_at
FROM zone_file_validation zfv
JOIN zone_files zf ON zf.id = zfv.zone_file_id
ORDER BY zfv.checked_at DESC
LIMIT 10;
```

## Validation Flow

1. **Master Zone**:
   - Generate flattened content (inline all includes)
   - Write to temp file
   - Run `named-checkzone -q <zone> <file>`
   - Store result
   - Propagate to all includes

2. **Include Zone**:
   - Find top master (traverse parent chain)
   - Validate entire master tree
   - Store result for include
   - Propagate to sibling includes

## Common Issues

**Schema already has command/return_code columns** (migration 012 was run):
- ✅ System still works - new code ignores those columns
- Data goes into `output` field as documented

**named-checkzone not found**:
```bash
# Debian/Ubuntu
sudo apt-get install bind9-utils

# RHEL/CentOS/Rocky
sudo yum install bind-utils

# Or set full path in config.php
define('NAMED_CHECKZONE_PATH', '/usr/sbin/named-checkzone');
```

## Files Modified

- ✏️ `includes/models/ZoneFile.php` - storeValidationResult, runNamedCheckzone
- 🚫 `migrations/012_add_validation_command_fields.sql` → `.disabled`
- 📄 `migrations/README_012_DISABLED.md` - NEW
- 📄 `ZONE_VALIDATION_FIX_DOCUMENTATION.md` - NEW
- 📄 `test_validation_manual.php` - NEW

## Validation Status Values

- `pending` - Queued for validation
- `passed` - Zone file is valid (exit code 0)
- `failed` - Zone file has errors (exit code != 0)
- `error` - System error during validation

## Log Messages

**Success**:
```
[2025-10-23 15:30:45] [ZoneFile] Validation PASSED for zone ID 5
[2025-10-23 15:30:45] [ZoneFile] Temporary directory cleaned up: /tmp/dns3_validate_abc123
```

**Failure**:
```
[2025-10-23 15:30:45] [ZoneFile] Command exit code for zone ID 5: 1
[2025-10-23 15:30:45] [ZoneFile] Validation FAILED for zone ID 5. Output: zone example.com/IN: NS 'ns1.example.com' has no address records (A or AAAA)
```

**Cycle detected**:
```
[2025-10-23 15:30:45] [ZoneFile] ERROR: Circular reference detected in generateFlatZone for zone ID 7
```

## No Breaking Changes

- ✅ API endpoints unchanged
- ✅ Return values unchanged (status, output, return_code still in result array)
- ✅ Existing validation records remain readable
- ✅ Background worker (process_validations.php) works as-is
- ✅ Config settings unchanged
