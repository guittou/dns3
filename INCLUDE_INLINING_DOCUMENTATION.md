# $INCLUDE Inlining for named-checkzone Validation

## Overview

This feature implements inline expansion of `$INCLUDE` directives during zone file validation with `named-checkzone`, while preserving the original `$INCLUDE` directives in files downloaded by users.

## Problem Statement

Previously, validation with `named-checkzone` would fail when `$INCLUDE` directives referenced files that don't exist on disk. This is because:

1. Zone files are generated dynamically from the database
2. Included files don't exist as separate files on disk
3. `named-checkzone` cannot validate a zone with missing includes

## Solution

The solution implements **inline expansion** of `$INCLUDE` directives specifically for validation:

1. **During validation**: Replace all `$INCLUDE` directives with the actual generated content
2. **During download**: Keep `$INCLUDE` directives unchanged for users

## Implementation Details

### New Methods

#### 1. `inlineIncludes($content, &$visited = [], $depth = 0)`

Recursively replaces `$INCLUDE` directives with generated content.

**Features:**
- Pattern matching: Finds `$INCLUDE "path"` or `$INCLUDE path` directives
- Database lookup: Searches `zone_files` table by `filename` column
- Fallback: Optional disk read for backward compatibility
- Debug comments: Adds `; BEGIN INCLUDE` and `; END INCLUDE` markers
- Protection: Cycle detection and depth limiting (max 10 levels)

**Algorithm:**
```
1. Parse content for $INCLUDE directives using regex
2. For each include:
   a. Check if already visited (cycle detection)
   b. Mark as visited
   c. Look up include by filename in zone_files table
   d. Generate content via generateZoneFile(includeId)
   e. Recursively inline any nested includes
   f. Replace directive with inlined content + comments
3. Return fully inlined content
```

**Error Handling:**
- Missing include: Throws exception with descriptive message
- Circular dependency: Throws exception when include revisited
- Depth exceeded: Throws exception when depth > 10

#### 2. `runNamedCheckzone($zoneId, $zone, $userId)` (Updated)

Now creates a temporary directory and inlines includes before validation.

**Flow:**
```
1. Create secure temp directory: sys_get_temp_dir()/dns3_validation_{uniqid}
2. Generate zone content with $INCLUDE directives
3. Call inlineIncludes() to replace all $INCLUDE with content
4. Write inlined content to temp file
5. Execute: cd tmpdir && named-checkzone zoneName zoneFile
6. Capture output and return code
7. Store validation result in database
8. Propagate result to all child includes (BFS)
9. Clean up temp directory (unless DEBUG_KEEP_TMPDIR)
```

**Benefits of temp directory:**
- Relative paths in content work correctly
- Isolated from other validations
- Secure permissions (0700)
- Easy cleanup

#### 3. `rrmdir($dir)`

Helper to recursively remove directories and contents.

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

### Master Zone (Generated)

```bind
; Zone content
$ORIGIN example.com.
$TTL 3600

; Includes
$INCLUDE "common.db"
$INCLUDE "hosts.db"

; DNS Records
www     3600 IN A     192.168.1.100
```

### After Inlining (For Validation Only)

```bind
; Zone content
$ORIGIN example.com.
$TTL 3600

; Includes
; BEGIN INCLUDE: common.db
; Zone: Common Records (common.db)
; Type: include
; Generated: 2024-10-22 11:00:00

ns1     3600 IN A     192.168.1.10
ns2     3600 IN A     192.168.1.11
; END INCLUDE: common.db

; BEGIN INCLUDE: hosts.db
; Zone: Host Records (hosts.db)
; Type: include
; Generated: 2024-10-22 11:00:00

mail    3600 IN A     192.168.1.50
ftp     3600 IN A     192.168.1.51
; END INCLUDE: hosts.db

; DNS Records
www     3600 IN A     192.168.1.100
```

## Validation Flow

### For Master Zones

```
1. User triggers validation
2. System generates zone with $INCLUDE directives
3. System inlines all includes recursively
4. Creates temp directory
5. Writes inlined content to temp file
6. Runs named-checkzone from temp directory
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
Output: Included file not found for validation: common.db (path: includes/common.db)
```

### Circular Dependency

```
Status: failed
Output: Failed to inline includes: Circular include detected: common.db
```

### Depth Exceeded

```
Status: failed
Output: Failed to inline includes: Maximum include depth (10) exceeded
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
ls -la /tmp/dns3_validation_*
cat /tmp/dns3_validation_*/zone_*.db
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
- Database schema **unchanged** - no migrations needed
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

### Recursion Limits

- Max depth: 10 levels
- Protects against stack overflow
- Reasonable for real-world zone files

### Database Queries

- One query per include
- Indexed by filename
- Efficient lookup

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

1. Cache inlined content for repeated validations
2. Parallel validation for multiple zones
3. Validation preview before save
4. Inline expansion for download (optional)

### Not Implemented (By Design)

1. Modifying `generateZoneFile()` - preserves $INCLUDE
2. Database schema changes - not needed
3. UI changes - transparent to users
4. New API endpoints - existing endpoints sufficient

## Troubleshooting

### Validation Fails with "Include not found"

**Cause:** Include file not in database or filename mismatch

**Solution:**
1. Check `zone_files.filename` matches `$INCLUDE` basename
2. Verify include is `status='active'`
3. Check include exists in database

### Validation Fails with "Circular include"

**Cause:** Include references itself directly or indirectly

**Solution:**
1. Review include hierarchy
2. Break the cycle by removing problematic include
3. Restructure includes to be acyclic

### Temp Directory Not Cleaned Up

**Cause:** `DEBUG_KEEP_TMPDIR` enabled or crash during cleanup

**Solution:**
1. Check if `DEBUG_KEEP_TMPDIR` is defined
2. Manually remove: `rm -rf /tmp/dns3_validation_*`
3. Check error logs for cleanup failures

### Named-checkzone Not Found

**Cause:** Binary not in PATH or wrong path configured

**Solution:**
1. Install bind-utils: `apt install bind9-utils` or `yum install bind-utils`
2. Set path in config: `define('NAMED_CHECKZONE_PATH', '/usr/bin/named-checkzone')`
3. Verify: `which named-checkzone`

## Summary

This implementation provides robust, secure validation of zone files with `$INCLUDE` directives by:

1. ✅ Inlining includes transparently during validation
2. ✅ Preserving original `$INCLUDE` directives in downloads
3. ✅ Protecting against cycles and excessive depth
4. ✅ Providing clear error messages
5. ✅ Cleaning up temporary files automatically
6. ✅ Supporting debugging with optional temp directory retention
7. ✅ Maintaining full backward compatibility
8. ✅ Requiring no database or UI changes
