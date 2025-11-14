# Validation Include Master Generate - Implementation Summary

## Overview
This PR implements comprehensive logging and debugging support for zone file validation, with special handling for include-type zones that need to be validated through their parent master zone.

## Changes Made

### 1. Enhanced `jobs/process_validations.php`
**Purpose**: Add comprehensive logging and JOBS_KEEP_TMP support

**Key Changes**:
- Added `logMessage()` function for consistent logging with timestamps
- All log messages are written to `jobs/worker.log` and echoed to stdout
- Added support for `JOBS_KEEP_TMP` environment variable
  - When `JOBS_KEEP_TMP=1`, defines `DEBUG_KEEP_TMPDIR` constant to preserve temporary directories
  - Logs a message when the setting is enabled
- Enhanced validation logging:
  - Logs zone details (name, type, status) before validation
  - Logs validation result with status and return code
  - Logs full output when validation fails
  - Logs exceptions with stack traces

**Benefits**:
- Easy debugging with preserved temp directories
- Complete audit trail of validation operations
- Better error diagnostics

### 2. Enhanced `jobs/worker.sh`
**Purpose**: Add verbose logging for background worker operations

**Key Changes**:
- Logs the processing file path
- Counts and logs number of jobs in queue
- Logs the exact command being executed
- Captures and logs the exit code of `process_validations.php`

**Benefits**:
- Better visibility into worker operations
- Easy troubleshooting of worker issues
- Clear audit trail

### 3. Enhanced `includes/models/ZoneFile.php`
**Purpose**: Add detailed logging throughout validation process

**Key Changes**:

#### New `logValidation()` Method
- Private method for consistent logging to `jobs/worker.log`
- All validation-related operations now log their progress

#### Enhanced `validateZoneFile()` Method
- Logs when handling include-type zones
- Logs when finding top master for include validation
- Logs error details when master not found
- Logs which master will be validated
- Logs zone type for direct validation

#### Enhanced `findTopMaster()` Method
- Logs each step of parent chain traversal
- Logs zone ID, type, and name at each step
- Logs when master is found
- Logs errors (circular dependencies, missing zones, orphaned includes)

#### Enhanced `runNamedCheckzone()` Method
- Logs temporary directory creation
- Logs when zone files are written to disk
- Logs the exact command being executed
- Logs working directory
- Logs command exit code
- Logs validation result (passed/failed)
- Logs when temp directory is cleaned up or preserved

**Benefits**:
- Complete visibility into validation process
- Easy debugging of include chains
- Clear error messages for common issues
- Detailed command execution logs

## How It Works

### For Master Zones
1. Zone is identified as type 'master'
2. Logged: "Zone ID X is a master zone - validating directly"
3. `runNamedCheckzone()` is called:
   - Creates temporary directory (logged)
   - Writes zone file and all includes to disk (logged)
   - Constructs and logs the named-checkzone command
   - Executes command and logs exit code
   - Stores validation result
   - Cleans up or preserves temp directory based on `DEBUG_KEEP_TMPDIR`

### For Include Zones
1. Zone is identified as type 'include'
2. Logged: "Zone ID X is an include file - finding top master for validation"
3. `findTopMaster()` is called:
   - Traverses parent chain (each step logged)
   - Detects and logs circular dependencies
   - Finds and logs the top master zone
4. Validation is performed on the top master (not the include itself)
5. Result is stored for both the include and the master

### Error Handling
All error conditions are logged with clear messages:
- "Circular dependency detected in include chain"
- "Zone file (ID: X) not found in parent chain"
- "Include file has no master parent; cannot validate standalone"
- "Failed to write zone files: [error]"
- "Failed to create temporary directory for validation"

## Environment Variables

### JOBS_KEEP_TMP
**Usage**: `export JOBS_KEEP_TMP=1` or `JOBS_KEEP_TMP=1 php jobs/process_validations.php queue.json`

**Effect**: When set to `1`, temporary directories created during validation are preserved instead of being cleaned up. This is useful for debugging validation failures.

**Logged Output**:
```
[2025-10-23 12:34:10] [process_validations] JOBS_KEEP_TMP is set - temporary directories will be preserved for debugging
[2025-10-23 12:34:11] [ZoneFile] DEBUG: Temporary directory kept at: /tmp/dns3_validate_abc123
```

## Logging Format

All log entries follow this format:
```
[YYYY-MM-DD HH:MM:SS] [component] message
```

Components:
- `[process_validations]` - Logs from the validation job processor
- `[ZoneFile]` - Logs from the ZoneFile model
- `[worker.sh]` - Logs from the shell worker script

## Testing

The implementation has been tested with:
1. Basic validation logic tests (environment variables, command construction)
2. Integration tests (zone file creation, include handling)
3. PHP syntax validation
4. Shell script syntax validation

## Example Log Output

### Successful Master Zone Validation
```
[2025-10-23 12:34:10] [process_validations] Processing 1 validation job(s)
[2025-10-23 12:34:10] [process_validations] Starting validation for zone ID: 1 (user: 1)
[2025-10-23 12:34:10] [process_validations] Zone details: name='example.com', type='master', status='active'
[2025-10-23 12:34:10] [ZoneFile] Zone ID 1 is a master zone - validating directly
[2025-10-23 12:34:10] [ZoneFile] Created temporary directory: /tmp/dns3_validate_abc123
[2025-10-23 12:34:10] [ZoneFile] Zone files written to disk successfully (zone ID: 1)
[2025-10-23 12:34:10] [ZoneFile] Executing command: cd '/tmp/dns3_validate_abc123' && named-checkzone 'example.com' 'zone_1.db' 2>&1
[2025-10-23 12:34:10] [ZoneFile] Working directory: /tmp/dns3_validate_abc123
[2025-10-23 12:34:11] [ZoneFile] Command exit code: 0
[2025-10-23 12:34:11] [ZoneFile] Validation result for zone ID 1: passed
[2025-10-23 12:34:11] [ZoneFile] Temporary directory cleaned up: /tmp/dns3_validate_abc123
[2025-10-23 12:34:11] [process_validations] Validation completed for zone ID 1: status=passed, return_code=0
```

### Include Zone Validation
```
[2025-10-23 12:34:10] [process_validations] Starting validation for zone ID: 5 (user: 1)
[2025-10-23 12:34:10] [process_validations] Zone details: name='common.inc', type='include', status='active'
[2025-10-23 12:34:10] [ZoneFile] Zone ID 5 is an include file - finding top master for validation
[2025-10-23 12:34:10] [ZoneFile] Traversing parent chain: zone ID 5, type='include', name='common.inc'
[2025-10-23 12:34:10] [ZoneFile] Moving up to parent zone ID: 3
[2025-10-23 12:34:10] [ZoneFile] Traversing parent chain: zone ID 3, type='master', name='example.com'
[2025-10-23 12:34:10] [ZoneFile] Found master zone: ID 3, name 'example.com'
[2025-10-23 12:34:10] [ZoneFile] Found top master for include zone ID 5: master zone 'example.com' (ID: 3)
[2025-10-23 12:34:10] [ZoneFile] Created temporary directory: /tmp/dns3_validate_def456
[2025-10-23 12:34:10] [ZoneFile] Zone files written to disk successfully (zone ID: 3)
[2025-10-23 12:34:10] [ZoneFile] Executing command: cd '/tmp/dns3_validate_def456' && named-checkzone 'example.com' 'zone_3.db' 2>&1
[2025-10-23 12:34:11] [ZoneFile] Command exit code: 0
[2025-10-23 12:34:11] [ZoneFile] Validation result for zone ID 3: passed
[2025-10-23 12:34:11] [process_validations] Validation completed for zone ID 5: status=passed, return_code=0
```

## Compliance with Requirements

✅ **Modified `jobs/process_validations.php`**: Added comprehensive logging  
✅ **Modified `jobs/worker.sh`**: Added verbose logging  
✅ **For master zones**: Behaves as before (generates complete content if needed and validates)  
✅ **For include zones**: Finds top master parent and validates the complete master zone  
✅ **Captures stdout/stderr and exit code**: All output is captured and logged  
✅ **Stores results in zone_file_validation**: Status and output are stored in database  
✅ **Respects JOBS_KEEP_TMP**: Temporary directories preserved when JOBS_KEEP_TMP=1  
✅ **Logs command, tmpdir, and exit code**: All details logged to worker.log  
✅ **Uses escapeshellarg**: All shell arguments are properly escaped  
✅ **Handles orphaned includes**: Clear error message when include has no master parent  
✅ **Does not modify zone_files.content**: Stored content remains unchanged with $INCLUDE directives  

## Files Changed
- `jobs/process_validations.php` - Enhanced logging and JOBS_KEEP_TMP support
- `jobs/worker.sh` - Verbose logging for worker operations  
- `includes/models/ZoneFile.php` - Detailed logging throughout validation process
