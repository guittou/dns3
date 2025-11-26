> **ARCHIVED DOCUMENT NOTE** : Les fichiers de migration mentionnés dans ce document ont été supprimés. Pour les nouvelles installations, utilisez `database.sql` (ou `structure_ok_dns3_db.sql`).

# Pull Request Summary: Fix Zone Validation Worker

## Overview

This PR fixes critical issues in the zone validation system that prevented proper validation of zone files using `$INCLUDE` directives and caused database errors due to schema mismatches.

## Issues Fixed

### 1. Database Schema Mismatch
**Problem**: Code tried to insert into `command` and `return_code` columns that don't exist in the actual `zone_file_validation` table schema.

**Solution**: Modified `storeValidationResult()` to embed command and exit code into the existing `output` TEXT field, matching the real schema in `structure_ok_dns3_db.sql`.

### 2. Zone Validation with $INCLUDE Directives
**Problem**: Already working! The existing `generateFlatZone()` method correctly:
- Generates flattened zone content (master + all includes inlined)
- Removes $INCLUDE directives before validation
- Respects `position` field for include ordering
- Protects against circular dependencies

**Verification**: Confirmed cycle detection and proper flattening logic.

### 3. Include File Validation
**Problem**: Already working! The `findTopMaster()` method correctly:
- Traverses parent chain to find top-level master
- Validates entire flattened master tree
- Propagates results to all includes

**Verification**: Confirmed cycle detection and parent chain traversal.

## Changes Made

### Code Changes

**File: `includes/models/ZoneFile.php`**

1. **`storeValidationResult()` method**:
   - Changed SQL from: `INSERT INTO zone_file_validation (zone_file_id, status, output, command, return_code, run_by, checked_at)`
   - To: `INSERT INTO zone_file_validation (zone_file_id, status, output, run_by, checked_at)`
   - Command and exit code now embedded in `output` field with format:
     ```
     Command: <command>
     Exit Code: <code>
     
     <stdout/stderr>
     ```
   - Added truncation at 10,000 chars (increased from 5,000)

2. **`runNamedCheckzone()` method**:
   - Enhanced logging with zone ID context in all messages
   - Added `-q` flag to named-checkzone for quieter output
   - Logs first 500 chars of error output for failed validations
   - Moved truncation logic to `storeValidationResult()`
   - Improved debug mode log message

### Migration Changes

**File: `migrations/012_add_validation_command_fields.sql`**
- Renamed to `012_add_validation_command_fields.sql.disabled`
- Not compatible with actual schema - columns should not exist
- Added `README_012_DISABLED.md` explaining the decision

**Note**: If migration was already applied, system continues to work. New code ignores those columns.

### Documentation Added

1. **`ZONE_VALIDATION_FIX_DOCUMENTATION.md`**
   - Comprehensive documentation of the problem and solution
   - Testing procedures
   - Troubleshooting guide
   - API compatibility notes

2. **`ZONE_VALIDATION_FIX_QUICK_REFERENCE.md`**
   - Quick reference for developers
   - Key changes summary
   - Common issues and solutions
   - Testing commands

3. **`test_validation_manual.php`**
   - Manual test script to verify:
     - Database schema correctness
     - named-checkzone availability
     - Existing zones in database

4. **`migrations/README_012_DISABLED.md`**
   - Explains why migration 012 was disabled
   - Documents the new approach

## Verification

### Schema Compliance
✅ Code now matches `structure_ok_dns3_db.sql` exactly
✅ No references to non-existent columns
✅ Proper truncation of output field

### Functionality Preserved
✅ Flattened zone generation working (already implemented)
✅ Cycle detection working (already implemented)
✅ Parent chain traversal working (already implemented)
✅ Result propagation working (already implemented)
✅ Debug mode working (JOBS_KEEP_TMP=1)

### Logging Improvements
✅ All log messages include zone ID for context
✅ Temporary directory path logged
✅ Command executed logged
✅ Exit code logged
✅ Error output preview logged for failures

### API Compatibility
✅ No breaking changes to API endpoints
✅ Return value structure unchanged (status, output, return_code)
✅ Background worker unchanged (`process_validations.php`)
✅ Configuration unchanged

## Testing

### Manual Testing
Run the included test script:
```bash
php test_validation_manual.php
```

### Debug Mode
Enable temporary directory preservation:
```bash
export JOBS_KEEP_TMP=1
./jobs/worker.sh
```

### Log Monitoring
```bash
tail -f jobs/worker.log
```

## Benefits

1. **Correctness**: Code now matches actual database schema
2. **Maintainability**: All validation info in single field, easier to query
3. **Debugging**: Enhanced logging makes troubleshooting easier
4. **Robustness**: Cycle detection prevents infinite loops
5. **Compatibility**: Backward compatible with existing records
6. **Documentation**: Comprehensive guides for developers and users

## No Breaking Changes

- ✅ Existing API clients continue to work
- ✅ Existing validation records remain readable
- ✅ Configuration remains the same
- ✅ Worker scripts unchanged
- ✅ Database queries work with both old and new records

## Files Changed

- **Modified**: `includes/models/ZoneFile.php`
- **Disabled**: `migrations/012_add_validation_command_fields.sql` → `.disabled`
- **Added**: `migrations/README_012_DISABLED.md`
- **Added**: `ZONE_VALIDATION_FIX_DOCUMENTATION.md`
- **Added**: `ZONE_VALIDATION_FIX_QUICK_REFERENCE.md`
- **Added**: `test_validation_manual.php`

## Related Issues

This PR addresses the requirements specified in the issue:
1. ✅ Generate flattened zone file for validation
2. ✅ Pass file without $INCLUDE directives to named-checkzone
3. ✅ Don't modify exportable content in database
4. ✅ Store results in correct schema (zone_file_id, status, output, run_by, checked_at)
5. ✅ Keep tmpdir if JOBS_KEEP_TMP=1
6. ✅ Improve worker logs
7. ✅ Protect against include cycles

## Next Steps

1. Review and approve PR
2. Test in staging environment if available
3. Merge to main branch
4. Monitor `jobs/worker.log` after deployment
5. Verify validation works for zones with includes

## Questions or Issues?

See documentation files for detailed information:
- Full docs: `ZONE_VALIDATION_FIX_DOCUMENTATION.md`
- Quick ref: `ZONE_VALIDATION_FIX_QUICK_REFERENCE.md`
- Test script: `test_validation_manual.php`
