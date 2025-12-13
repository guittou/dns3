# Validation Flattening Implementation

## Overview

This implementation addresses the issue where zone validation fails when `$INCLUDE` directives reference files not present on disk. The solution generates a single flattened zone file containing all master and include records combined for validation purposes, while keeping the database content unchanged.

## Changes Made

### 1. Database Migration (012_add_validation_command_fields.sql)

Added two new columns to the `zone_file_validation` table:
- `command` (TEXT): Stores the exact named-checkzone command executed
- `return_code` (INT): Stores the exit code from the validation command

These fields provide better debugging and auditing capabilities.

### 2. ZoneFile Model (includes/models/ZoneFile.php)

#### New Method: `generateFlatZone()`

```php
private function generateFlatZone($masterId, &$visited = [])
```

This method:
- Takes a master zone ID and generates a flattened zone file
- Recursively concatenates master content with all include contents in order
- Removes `$INCLUDE` directives from the content (since we're inlining)
- Uses a `$visited` array to prevent circular include dependencies
- Maintains the correct order based on `position` column in `zone_file_includes`

#### Updated Method: `runNamedCheckzone()`

Changed from writing multiple files to disk to writing a single flattened file:

**Before:**
- Wrote master zone file with `$INCLUDE` directives
- Recursively wrote all include files to disk in proper directory structure
- Ran named-checkzone on the master file (which then followed `$INCLUDE` directives)

**After:**
- Generates flattened content using `generateFlatZone()`
- Writes single flattened zone file to temporary directory
- Runs named-checkzone on the flattened file
- Captures and stores command and exit code
- Truncates output if longer than 5000 characters
- Respects `JOBS_KEEP_TMP=1` environment variable for debugging

#### Updated Method: `storeValidationResult()`

Added two optional parameters:
- `$command`: The command executed
- `$returnCode`: The exit code

These are stored in the database for audit and debugging purposes.

#### Updated Method: `propagateValidationToIncludes()`

Updated to pass command and return_code to child includes when propagating validation results.

## How It Works

### For Master Zones

1. User creates/updates a master zone
2. Validation is triggered (sync or async)
3. `generateFlatZone()` is called to create flattened content
4. Single zone file is written to temporary directory
5. `named-checkzone` is executed on the flattened file
6. Results (status, output, command, return_code) are stored
7. Results are propagated to all child includes
8. Temporary directory is cleaned up (unless `JOBS_KEEP_TMP=1`)

### For Include Zones

1. User creates/updates an include zone
2. Validation is triggered (sync or async)
3. `findTopMaster()` traverses the parent chain to find top master
4. Validation runs on the top master (same as above)
5. Results are stored for both master and include zones

## Cycle Detection

The implementation prevents circular dependencies in two places:

1. **`generateFlatZone()`**: Uses `$visited` array to track visited zone IDs
2. **`findTopMaster()`**: Uses `$visited` array to detect cycles in parent chain
3. **`propagateValidationToIncludes()`**: Uses BFS with visited tracking

## Debugging

Set the environment variable `JOBS_KEEP_TMP=1` to preserve temporary directories:

```bash
JOBS_KEEP_TMP=1 php jobs/process_validations.php jobs/validation_queue.json
```

The worker log (`jobs/worker.log`) now includes:
- Temporary directory path
- Executed command
- Exit code
- Size of generated flattened content

## Database Content Unchanged

Important: The `zone_files.content` column remains unchanged. It still contains `$INCLUDE` directives as stored by users. The flattening only occurs during validation and is not persisted.

## Testing

To test the implementation:

1. Create a master zone with SOA record
2. Create one or more include zones with A records
3. Assign includes to master via `zone_file_includes` table
4. Trigger validation on master or include
5. Check `zone_file_validation` table for results
6. Verify command and return_code fields are populated

## Example

Master zone content (stored in DB):
```
$ORIGIN example.com.
$TTL 3600
@   IN  SOA ns1.example.com. admin.example.com. (2024010101 3600 1800 604800 86400)
$INCLUDE "includes/hosts.inc"
```

Include zone content (stored in DB):
```
host1   IN  A   192.168.1.1
host2   IN  A   192.168.1.2
```

Flattened content (used for validation, NOT stored):
```
$ORIGIN example.com.
$TTL 3600
@   IN  SOA ns1.example.com. admin.example.com. (2024010101 3600 1800 604800 86400)

; BEGIN INCLUDE: hosts (hosts.inc)
host1   IN  A   192.168.1.1
host2   IN  A   192.168.1.2
; END INCLUDE: hosts

```

## Migration

The database schema is now available in `database.sql`. Import it for new installations:

```sql
mysql dns3_db < database.sql
```

> **Note** : Les fichiers de migration ont été supprimés.
