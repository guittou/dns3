# Zone Validation with Include Flattening

## Overview

This document describes the implementation of zone file validation with include flattening in the background validation worker (`jobs/process_validations.php`).

## Problem Statement

When master zones reference include files using `$INCLUDE` directives, validation with `named-checkzone` previously failed because the include files were not present on disk. The previous implementation wrote separate include files to disk, but this new implementation takes a different approach: **flattening** all includes into a single zone file.

## Solution

The validation worker now builds a **flattened zone file** for validation by:

1. **Inlining** the contents of all referenced include files recursively into the master zone content
2. Writing a single flattened zone file to a temporary directory
3. Running `named-checkzone` against the flattened file
4. Storing validation results in the database
5. Cleaning up temporary files (unless `JOBS_KEEP_TMP=1`)

## Key Features

### 1. Include Flattening

The `flattenZoneContent()` function:
- Searches for all `$INCLUDE` directives in zone content (with or without quotes)
- Looks up each include file by filename in the `zone_files` table
- Replaces the `$INCLUDE` directive with the actual content of the include file
- Processes includes **recursively** to handle nested includes
- Preserves include content **as-is** without extra wrapping

### 2. Circular Dependency Detection

The flattening algorithm tracks visited include filenames to prevent infinite loops:
- Maintains a `$visited` array of processed include filenames
- Throws an exception if an include is encountered twice in the same chain
- Prevents both self-includes and circular include chains (A → B → A)

### 3. Error Handling

Descriptive error messages for common issues:
- **Missing include**: `"Include file not found: filename.inc (path: includes/filename.inc)"`
- **Circular dependency**: `"Circular include detected: filename.inc"`
- **Zone not found**: `"Zone file not found"`
- **Directory creation failed**: `"Failed to create temporary directory for validation"`
- **File write failed**: `"Failed to write flattened zone file"`

### 4. Improved Logging

The worker now logs:
- Number of validation jobs being processed
- Zone ID being validated
- Temporary directory path created
- Named-checkzone exit code
- Output snippet (first 200 characters)
- Validation status (passed/failed)
- Whether temporary files are being kept

Example output:
```
Processing 1 validation job(s)
Validating zone ID: 42
Created temp directory: /tmp/dns3_validate_67a8b9c1d2e3f
named-checkzone exit code: 0
Output snippet: zone example.com/IN: loaded serial 2024102301
Validation completed: passed
```

### 5. Temporary File Management

The worker supports the `JOBS_KEEP_TMP` environment variable:
- **Not set or `0`**: Temporary files are removed after validation (default)
- **Set to `1`**: Temporary files are kept for debugging

Set the environment variable before running the worker:
```bash
export JOBS_KEEP_TMP=1
./jobs/worker.sh
```

## Implementation Details

### Modified File

- `jobs/process_validations.php`: Complete rewrite of validation logic

### New Functions

#### `flattenZoneContent($db, $content, &$visited = [])`

Recursively flattens zone content by inlining all `$INCLUDE` directives.

**Parameters:**
- `$db`: PDO database connection
- `$content`: Zone content with `$INCLUDE` directives
- `$visited`: Array of visited filenames (by reference, for cycle detection)

**Returns:**
- Flattened zone content with all includes inlined

**Throws:**
- Exception if include not found
- Exception if circular dependency detected

**Algorithm:**
1. Use regex to find all `$INCLUDE` directives
2. For each directive:
   - Extract the include filename
   - Check if already visited (cycle detection)
   - Look up include in database by filename
   - Recursively flatten the include content
   - Replace the `$INCLUDE` directive with flattened content
3. Return the fully flattened content

#### `storeValidationResult($db, $zoneId, $status, $output, $userId)`

Stores validation results in the `zone_file_validation` table.

**Parameters:**
- `$db`: PDO database connection
- `$zoneId`: Zone file ID
- `$status`: Validation status (`pending`, `passed`, `failed`)
- `$output`: Output from `named-checkzone`
- `$userId`: User ID who triggered validation (or `NULL` for background jobs)

**Returns:**
- `true` on success, `false` on failure

## Validation Flow

```
1. Worker reads validation queue file
2. For each queued zone:
   a. Load zone from database
   b. Create temporary directory (/tmp/dns3_validate_*)
   c. Flatten zone content by inlining includes
   d. Write flattened content to temp file
   e. Run named-checkzone on flattened file
   f. Capture output and exit code
   g. Store result in database
   h. Clean up temp files (unless JOBS_KEEP_TMP=1)
3. Worker completes and exits
```

## Database Interactions

### Queries Used

**Load zone file:**
```sql
SELECT id, name, filename, content, file_type 
FROM zone_files 
WHERE id = ? AND status != 'deleted'
```

**Load include file:**
```sql
SELECT id, filename, content 
FROM zone_files 
WHERE (filename = ? OR filename = ?) 
  AND file_type = 'include' 
  AND status = 'active' 
LIMIT 1
```

**Store validation result:**
```sql
INSERT INTO zone_file_validation 
  (zone_file_id, status, output, run_by, checked_at)
VALUES (?, ?, ?, ?, NOW())
```

## Example Usage

### Queue a Validation

Validation jobs are queued in `jobs/validation_queue.json`:
```json
[
  {
    "zone_id": 42,
    "user_id": 1,
    "queued_at": "2024-10-23 12:00:00"
  }
]
```

### Run the Worker

```bash
# Process queued validations
./jobs/worker.sh

# Or run directly with a queue file
php jobs/process_validations.php jobs/validation_queue.json

# With debugging (keep temp files)
JOBS_KEEP_TMP=1 php jobs/process_validations.php jobs/validation_queue.json
```

### Check Validation Results

Results are stored in the `zone_file_validation` table:
```sql
SELECT * FROM zone_file_validation 
WHERE zone_file_id = 42 
ORDER BY checked_at DESC 
LIMIT 1;
```

## Example Zone Flattening

### Input (Master Zone)
```bind
$ORIGIN example.com.
$TTL 3600

@ IN SOA ns1.example.com. admin.example.com. (
    2024102301 ; serial
    3600       ; refresh
    1800       ; retry
    604800     ; expire
    86400 )    ; minimum

$INCLUDE common.inc
$INCLUDE hosts.inc

www IN A 192.168.1.1
```

### Include Files

**common.inc:**
```bind
; Common records
ns1 IN A 192.168.1.10
ns2 IN A 192.168.1.11
```

**hosts.inc:**
```bind
; Host records
mail IN A 192.168.1.50
ftp IN A 192.168.1.51
```

### Output (Flattened Zone)
```bind
$ORIGIN example.com.
$TTL 3600

@ IN SOA ns1.example.com. admin.example.com. (
    2024102301 ; serial
    3600       ; refresh
    1800       ; retry
    604800     ; expire
    86400 )    ; minimum

; Common records
ns1 IN A 192.168.1.10
ns2 IN A 192.168.1.11
; Host records
mail IN A 192.168.1.50
ftp IN A 192.168.1.51

www IN A 192.168.1.1
```

## Compatibility

### Database Schema

No database changes required. Uses existing tables:
- `zone_files`: For loading zone and include content
- `zone_file_validation`: For storing validation results

### Configuration

Uses existing configuration from `config.php`:
- `NAMED_CHECKZONE_PATH`: Path to named-checkzone binary (default: `named-checkzone`)

### Backward Compatibility

- The ZoneFile model's `validateZoneFile()` method is **not modified**
- Existing API endpoints continue to work
- The validation queue format is unchanged
- Synchronous validation via the API still uses the old method

## Security Considerations

### Command Injection Prevention

- Uses `escapeshellcmd()` for the command
- Uses `escapeshellarg()` for arguments
- No user input is directly interpolated into shell commands

### Temporary Directory Security

- Permissions: `0700` (owner-only read/write/execute)
- Unique ID prevents path prediction: `/tmp/dns3_validate_{uniqid()}`
- Automatic cleanup prevents disk space leaks

### SQL Injection Prevention

- All database queries use prepared statements with parameter binding
- No direct string interpolation in SQL queries

## Performance

### Temporary Files

- One temporary directory per validation
- One temporary file per zone (not per include)
- Files are typically small (KB to MB range)

### Database Queries

- One query to load master zone
- One query per include file referenced
- One query to store validation result
- Typical total: 2-10 queries per validation

### Processing Time

- File I/O is minimal (one write per validation)
- Flattening is fast (simple string replacement)
- Most time spent in `named-checkzone` execution

## Troubleshooting

### Validation Fails with "Include file not found"

**Cause:** Include file not in database or filename mismatch

**Solution:**
1. Check include exists: `SELECT * FROM zone_files WHERE filename = 'common.inc'`
2. Verify status is 'active': `UPDATE zone_files SET status='active' WHERE filename='common.inc'`
3. Check filename matches exactly (including extension)

### Validation Fails with "Circular include detected"

**Cause:** Include references itself directly or indirectly

**Solution:**
1. Review include hierarchy
2. Break the cycle by removing problematic `$INCLUDE` directive
3. Restructure includes to be acyclic

### Temp Files Not Cleaned Up

**Cause:** `JOBS_KEEP_TMP=1` is set or worker crashed

**Solution:**
1. Check environment: `echo $JOBS_KEEP_TMP`
2. Manually remove: `rm -rf /tmp/dns3_validate_*`
3. Check worker logs for errors

### Named-checkzone Not Found

**Cause:** Binary not in PATH or wrong path configured

**Solution:**
1. Install: `apt install bind9-utils` or `yum install bind-utils`
2. Configure path: `define('NAMED_CHECKZONE_PATH', '/usr/bin/named-checkzone');`
3. Test: `which named-checkzone`

## Testing

### Manual Testing

1. Create a master zone with `$INCLUDE` directives
2. Create the referenced include files
3. Queue a validation job
4. Run the worker with `JOBS_KEEP_TMP=1`
5. Check the temporary directory for the flattened file
6. Verify validation results in the database

### Unit Testing

See `/tmp/test_flattening.php` and `/tmp/test_circular.php` for examples of:
- Basic include flattening
- Multiple includes
- Nested includes
- Missing include error handling
- Circular dependency detection

### Integration Testing

See `/tmp/test_integration.php` for full validation flow testing:
- Temporary directory creation
- File writing
- Include inlining verification
- JOBS_KEEP_TMP environment variable behavior

## Future Enhancements

Potential improvements:
1. Cache flattened content for repeated validations
2. Support for include file parameters (origin, domain)
3. Parallel validation for multiple zones
4. Detailed line number mapping for errors

## Summary

This implementation provides:
- ✅ Flattened zone file validation by inlining all includes
- ✅ Recursive include processing with cycle detection
- ✅ Improved worker logging with detailed output
- ✅ Support for JOBS_KEEP_TMP debugging flag
- ✅ Graceful error handling with descriptive messages
- ✅ No database schema changes required
- ✅ Security best practices (prepared statements, escaped commands)
- ✅ Automatic temporary file cleanup
- ✅ Full backward compatibility
