# Zone Validation Flattening - Quick Reference

## What Changed?

The background validation worker (`jobs/process_validations.php`) now **flattens** zone files with `$INCLUDE` directives before validation.

## Before vs After

### Before (Separate Files on Disk)
```
/tmp/dns3_validate_xyz/
├── zone_1.db              (contains: $INCLUDE common.inc)
└── common.inc             (separate file)
```

### After (Single Flattened File)
```
/tmp/dns3_validate_xyz/
└── zone_1.db              (includes are inlined, no $INCLUDE directives)
```

## Usage

### Run Worker Normally
```bash
./jobs/worker.sh
```
Temporary files are cleaned up after validation.

### Run Worker with Debug Mode
```bash
export JOBS_KEEP_TMP=1
./jobs/worker.sh
```
Temporary files are kept in `/tmp/dns3_validate_*` for inspection.

### Check Validation Results
```sql
SELECT status, output, checked_at 
FROM zone_file_validation 
WHERE zone_file_id = 42 
ORDER BY checked_at DESC 
LIMIT 1;
```

## Example: Zone Flattening in Action

### Master Zone in Database
```sql
SELECT content FROM zone_files WHERE id = 1;
```
```bind
$ORIGIN example.com.
$TTL 3600
$INCLUDE common.inc
$INCLUDE hosts.inc
www IN A 192.168.1.1
```

### Include Files in Database
```sql
SELECT filename, content FROM zone_files WHERE file_type = 'include';
```

**common.inc:**
```bind
ns1 IN A 192.168.1.10
ns2 IN A 192.168.1.11
```

**hosts.inc:**
```bind
mail IN A 192.168.1.50
ftp IN A 192.168.1.51
```

### Flattened Zone Written to Disk
```bash
cat /tmp/dns3_validate_abc123/zone_1.db
```
```bind
$ORIGIN example.com.
$TTL 3600
ns1 IN A 192.168.1.10
ns2 IN A 192.168.1.11
mail IN A 192.168.1.50
ftp IN A 192.168.1.51
www IN A 192.168.1.1
```

**Note:** The `$INCLUDE` directives are replaced with the actual content!

## Worker Log Output

### Successful Validation
```
Processing 1 validation job(s)
Validating zone ID: 42
Created temp directory: /tmp/dns3_validate_67a8b9c1d2e3f
named-checkzone exit code: 0
Output snippet: zone example.com/IN: loaded serial 2024102301
Validation completed: passed
All jobs processed
```

### Failed Validation (Missing Include)
```
Processing 1 validation job(s)
Validating zone ID: 42
Created temp directory: /tmp/dns3_validate_67a8b9c1d2e3f
Failed to flatten zone content: Include file not found: missing.inc (path: includes/missing.inc)
Validation completed: failed
All jobs processed
```

### Failed Validation (Circular Dependency)
```
Processing 1 validation job(s)
Validating zone ID: 42
Created temp directory: /tmp/dns3_validate_67a8b9c1d2e3f
Failed to flatten zone content: Circular include detected: circular1.inc
Validation completed: failed
All jobs processed
```

## Key Features

✅ **Recursive Flattening** - Handles nested includes automatically  
✅ **Circular Detection** - Prevents infinite loops  
✅ **Error Messages** - Descriptive errors for debugging  
✅ **Debug Mode** - Keep temp files with `JOBS_KEEP_TMP=1`  
✅ **No DB Changes** - Original zone content remains untouched  
✅ **Detailed Logging** - Exit codes, output snippets, temp paths  

## Troubleshooting

### Problem: "Include file not found"
**Solution:** Check that include exists in `zone_files` with `file_type='include'` and `status='active'`

### Problem: "Circular include detected"
**Solution:** Review include chain and remove the circular reference

### Problem: Want to see flattened file
**Solution:** Set `JOBS_KEEP_TMP=1` and check `/tmp/dns3_validate_*`

### Problem: Validation always fails
**Solution:** 
1. Check if `named-checkzone` is installed: `which named-checkzone`
2. Check worker logs: `cat jobs/worker.log`
3. Run manually: `php jobs/process_validations.php jobs/validation_queue.json`

## Documentation

For detailed documentation, see:
- `VALIDATION_FLATTENING_IMPLEMENTATION.md` - Complete implementation guide
- `jobs/README.md` - Worker setup and configuration
