# Zone File Validation with Separate Include Files

## Overview

This feature implements validation of zone files with `$INCLUDE` directives by writing include files to disk in their proper directory structure, allowing `named-checkzone` to natively resolve includes.

## Problem Statement

Previously, validation with `named-checkzone` would fail when `$INCLUDE` directives referenced files that don't exist on disk. This is because:

1. Zone files are generated dynamically from the database
2. Included files don't exist as separate files on disk
3. `named-checkzone` cannot validate a zone with missing includes

## Solution

The solution writes zone files and their includes to a temporary directory with proper structure:

1. **During validation**: Write main zone file and all includes as separate files to temporary directory
2. **During validation**: Run `named-checkzone` which natively resolves `$INCLUDE` directives
3. **During download**: Keep `$INCLUDE` directives unchanged for users

## Implementation Details

### New Methods

#### 1. `writeZoneFilesToDisk($zoneId, $tmpDir, &$visited = [])`

Recursively writes zone file and all its includes to disk with proper directory structure.

**Features:**
- Writes main zone file with `$INCLUDE` directives intact
- Creates subdirectories based on zone's `directory` field
- Writes include files to their specified locations
- Recursive: processes nested includes
- Protection: Cycle detection to prevent infinite loops

**Algorithm:**
```
1. Check if zone already visited (cycle detection)
2. Mark zone as visited
3. Get zone from database
4. Generate zone content with $INCLUDE directives
5. Determine file path:
   - Master zones: tmpDir/zone_{id}.db
   - Includes: tmpDir/{directory}/{filename}
6. Create subdirectories if needed
7. Write zone content to file
8. Recursively process all direct includes
```

**Error Handling:**
- Missing zone: Throws exception with zone ID
- Circular dependency: Throws exception when zone revisited
- Directory creation failed: Throws exception with directory path
- File write failed: Throws exception with file path

#### 2. `runNamedCheckzone($zoneId, $zone, $userId)` (Updated)

Now creates a temporary directory and writes include files separately before validation.

**Flow:**
```
1. Create secure temp directory: sys_get_temp_dir()/dns3_validate_{uniqid}
2. Call writeZoneFilesToDisk() to write all files with directory structure
3. Execute: cd tmpdir && named-checkzone zoneName zone_{id}.db
4. named-checkzone natively resolves $INCLUDE directives
5. Capture output and return code
6. Enrich output with line context from errors
7. Store validation result in database
8. Propagate result to all child includes (BFS)
9. Clean up temp directory (unless DEBUG_KEEP_TMPDIR)
```

**Benefits of separate files:**
- Named-checkzone resolves $INCLUDE natively
- Line numbers in errors match actual file structure
- Validates directory structure that will be deployed
- Easier debugging with DEBUG_KEEP_TMPDIR
- More realistic - matches production BIND behavior

#### 3. `rrmdir($dir)`

Helper to recursively remove directories and contents (unchanged).

**Implementation:**
```php
function rrmdir($dir) {
    if (!is_dir($dir)) return false;
    $files = array_diff(scandir($dir), ['.', '..']);
    foreach ($files as $file) {
        $path = $dir . '/' . $file;
        is_dir($path) ? $this->rrmdir($path) : unlink($path);
    }
    return rmdir($dir);
}
```

## Configuration

### Optional Debug Flag

Set in `config.php` or define before validation:

```php
define('DEBUG_KEEP_TMPDIR', true);
```

When enabled:
- Temporary directories are NOT deleted
- Path is logged: `error_log("DEBUG: Temporary directory kept at: $tmpDir")`
- Useful for debugging validation issues

### Named-checkzone Path

Already supported via config:

```php
define('NAMED_CHECKZONE_PATH', '/usr/sbin/named-checkzone');
```

## Usage Examples

### Synchronous Validation

```php
$zoneFile = new ZoneFile();
$result = $zoneFile->validateZoneFile($zoneId, $userId, true);

// $result = [
//     'status' => 'passed',  // or 'failed'
//     'output' => '... named-checkzone output ...',
//     'return_code' => 0
// ]
```

### Asynchronous Validation

```php
$zoneFile = new ZoneFile();
$queued = $zoneFile->validateZoneFile($zoneId, $userId, false);

// Returns true if queued successfully
// Validation runs in background via worker
```

### Include File Validation

When validating an include file:

1. System finds the top master zone
2. Validates the complete master zone
3. Stores result for the master
4. Propagates result to all includes (BFS)
5. Include gets result with context: "Validation performed on parent zone '{master}'"

## Zone File Structure Examples

### Master Zone File (zone_1.db)

```bind
; Zone content
$ORIGIN example.com.
$TTL 3600

; Includes
$INCLUDE "includes/common.db"
$INCLUDE "includes/hosts.db"

; DNS Records
www     3600 IN A     192.168.1.100
```

### Include File (includes/common.db)

```bind
; Zone: Common Records (common.db)
; Type: include
; Generated: 2024-10-22 11:00:00

ns1     3600 IN A     192.168.1.10
ns2     3600 IN A     192.168.1.11
```

### Include File (includes/hosts.db)

```bind
; Zone: Host Records (hosts.db)
; Type: include
; Generated: 2024-10-22 11:00:00

mail    3600 IN A     192.168.1.50
ftp     3600 IN A     192.168.1.51
```

### Temporary Directory Structure

```
/tmp/dns3_validate_abc123/
├── zone_1.db (master zone with $INCLUDE directives)
└── includes/
    ├── common.db
    └── hosts.db
```

## Validation Flow

### For Master Zones

```
1. User triggers validation
2. System generates zone with $INCLUDE directives
3. Creates temp directory: /tmp/dns3_validate_*
4. Writes main zone file with $INCLUDE directives intact
5. Writes all include files to proper subdirectories
6. Runs named-checkzone which natively resolves $INCLUDE
7. Stores result for master zone
8. Propagates result to all child includes
9. Cleans up temp directory
10. Returns result to user
```

### For Include Zones

```
1. User triggers validation on include
2. System finds top master zone
3. Validates master (see above flow)
4. Result propagated to include
5. Include result prefixed with: "Validation performed on parent zone '{master}'"
6. Returns result to user
```

## Error Handling

### Missing Include

```
Status: failed
Output: Failed to write zone files: Zone file not found: ID 123
```

### Circular Dependency

```
Status: failed
Output: Failed to write zone files: Circular dependency detected in include chain
```

### Directory Creation Failed

```
Status: failed
Output: Failed to write zone files: Failed to create directory: includes/nested
```

### Directory Creation Failed

```
Status: failed
Output: Failed to create temporary directory for validation
```

## Testing

### Manual Test

```bash
# Enable debug mode
echo "define('DEBUG_KEEP_TMPDIR', true);" >> config.php

# Trigger validation via API
curl -X GET "http://localhost/api/zone_api.php?action=validate_zone&id=1&trigger=true&sync=true"

# Check temp directory (path in logs)
ls -la /tmp/dns3_validate_*
tree /tmp/dns3_validate_*
cat /tmp/dns3_validate_*/zone_*.db
cat /tmp/dns3_validate_*/includes/*.db
```

### Automated Tests

```bash
# Run unit tests
php /tmp/test_include_inlining.php

# Run integration tests
php /tmp/test_integration.php

# Run existing tests
bash test-zone-generation.sh
```

## Compatibility

### No Breaking Changes

- `generateZoneFile()` **unchanged** - still generates `$INCLUDE` directives
- Database schema **unchanged** - schema is in `database.sql`
- API **unchanged** - same endpoints and parameters
- UI **unchanged** - no interface modifications

### Backward Compatibility

- Disk-based includes still work as fallback
- Existing validations continue to work
- Configuration options preserved

## Performance Considerations

### Temporary Directory

- Created per validation
- Unique ID prevents collisions
- Secure permissions (0700)
- Automatic cleanup

### File Operations

- Multiple files written per validation
- Subdirectories created as needed
- Minimal I/O overhead

### Database Queries

- One query per zone/include
- Efficient for typical zone structures
- BFS traversal for include propagation

## Security

### Temp Directory Security

- Permissions: 0700 (owner only)
- Unique ID prevents prediction
- Automatic cleanup prevents leaks

### Command Execution

- `escapeshellcmd()` for command
- `escapeshellarg()` for arguments
- Execution from temp directory isolates filesystem access

### Path Validation

- Only reads from database-referenced files
- Fallback uses `realpath()` validation
- No arbitrary file access

## Future Enhancements

### Potential Improvements

1. Cache directory structure for repeated validations
2. Parallel validation for multiple zones
3. Validation preview before save
4. Support for alternative validation tools

### Not Implemented (By Design)

1. Modifying `generateZoneFile()` - preserves $INCLUDE
2. Database schema changes - not needed
3. UI changes - transparent to users
4. New API endpoints - existing endpoints sufficient
5. Inlining for download - users need $INCLUDE directives

## Troubleshooting

### Validation Fails with "Zone file not found"

**Cause:** Include file not in database

**Solution:**
1. Check include exists in `zone_files` table
2. Verify include is `status='active'`
3. Check zone_file_includes relationship is correct

### Validation Fails with "Circular dependency"

**Cause:** Include references itself directly or indirectly

**Solution:**
1. Review include hierarchy
2. Break the cycle by removing problematic include
3. Restructure includes to be acyclic

### Validation Fails with "Failed to create directory"

**Cause:** Permission issues or invalid directory path

**Solution:**
1. Check write permissions on /tmp
2. Verify directory field in zone_files table is valid
3. Ensure no special characters in directory path

### Temp Directory Not Cleaned Up

**Cause:** `DEBUG_KEEP_TMPDIR` enabled or crash during cleanup

**Solution:**
1. Check if `DEBUG_KEEP_TMPDIR` is defined
2. Manually remove: `rm -rf /tmp/dns3_validate_*`
3. Check error logs for cleanup failures

### Named-checkzone Not Found

**Cause:** Binary not in PATH or wrong path configured

**Solution:**
1. Install bind-utils: `apt install bind9-utils` or `yum install bind-utils`
2. Set path in config: `define('NAMED_CHECKZONE_PATH', '/usr/bin/named-checkzone')`
3. Verify: `which named-checkzone`

## Summary

This implementation provides robust, secure validation of zone files with `$INCLUDE` directives by:

1. ✅ Writing include files to disk with proper directory structure
2. ✅ Allowing native `$INCLUDE` resolution by named-checkzone
3. ✅ Preserving original `$INCLUDE` directives in downloads
4. ✅ Protecting against circular dependencies
5. ✅ Providing accurate line numbers in error messages
6. ✅ Cleaning up temporary files automatically
7. ✅ Supporting debugging with optional temp directory retention
8. ✅ Maintaining full backward compatibility
9. ✅ Requiring no database or UI changes
10. ✅ Matching production BIND behavior
