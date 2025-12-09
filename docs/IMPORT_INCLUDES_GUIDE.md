# Using $INCLUDE Directives with BIND Import Scripts

This guide explains how to use the `--create-includes` feature in the BIND import scripts to properly handle zone files containing `$INCLUDE` directives.

## Table of Contents

1. [Overview](#overview)
2. [Python Script Usage](#python-script-usage)
3. [Bash Script Usage](#bash-script-usage)
4. [Testing Scenarios](#testing-scenarios)
5. [Security Considerations](#security-considerations)
6. [Troubleshooting](#troubleshooting)

## Overview

The enhanced import scripts now support `$INCLUDE` directives by:
- Creating separate `zone_file` entries for master and include files
- Establishing `zone_file_includes` relationships
- Preserving `$INCLUDE` directives in master zone content
- Deduplicating includes by path or content hash
- Detecting circular includes and limiting recursion depth
- Preventing path traversal attacks
- **Robust path resolution**: tries multiple strategies to locate include files

## Include Path Resolution

When the scripts encounter a `$INCLUDE` directive with a relative path, they try to resolve it using the following strategies in order:

1. **Relative to master zone's directory** (base_dir): Most common case
2. **Relative to import root** (--dir argument): For includes stored in the root import directory
3. **Relative to current working directory** (CWD): When running from a specific location
4. **Search paths** (--include-search-paths): Additional directories to search
5. **Recursive search** (basename only): If include is just a filename without path separators, recursively search under import_root

### Using --include-search-paths

The `--include-search-paths` option allows you to specify additional directories where the scripts should look for include files. This is useful when your include files are stored in standard locations outside the zone directory.

**Format**: Colon-separated (`:`) or comma-separated (`,`) list of directory paths

**Example with Python**:
```bash
python3 scripts/import_bind_zones.py \
  --dir /var/named/zones \
  --create-includes \
  --include-search-paths "/var/named/includes:/etc/bind/includes" \
  --db-mode \
  --db-user root \
  --db-pass secret
```

**Example with Bash**:
```bash
./scripts/import_bind_zones.sh \
  --dir /var/named/zones \
  --create-includes \
  --include-search-paths "/var/named/includes:/etc/bind/includes" \
  --db-user root \
  --db-pass secret
```

### Resolution Examples

Given this zone file in `/var/named/zones/example.com.zone`:
```bind
$ORIGIN example.com.
$INCLUDE common/hosts.inc
```

The scripts will try:
1. `/var/named/zones/common/hosts.inc` (relative to zone file)
2. `/var/named/zones/common/hosts.inc` (relative to --dir, same in this case)
3. `$(pwd)/common/hosts.inc` (relative to CWD)
4. `/var/named/includes/common/hosts.inc` (if in search paths)
5. `/etc/bind/includes/common/hosts.inc` (if in search paths)

If the include is just a basename like `$INCLUDE hosts.inc`, the script will recursively search under the import root directory.

### Verbose Logging

Use `--verbose` (Python) to see all attempted paths when an include file is not found:

```bash
python3 scripts/import_bind_zones.py \
  --dir /path/to/zones \
  --create-includes \
  --verbose \
  --db-mode \
  --db-user root \
  --db-pass secret
```

Output example:
```
ERROR: Include file not found: common/hosts.inc
Attempted paths:
  - base_dir -> /var/named/zones/common/hosts.inc
  - import_root -> /var/named/zones/common/hosts.inc
  - cwd -> /home/user/common/hosts.inc
  - search_path:/var/named/includes -> /var/named/includes/common/hosts.inc
  - recursive_search under /var/named/zones -> no matches
```

## Python Script Usage

### Basic Syntax

```bash
python3 scripts/import_bind_zones.py --dir /path/to/zones --create-includes [OPTIONS]
```

### Examples

#### 1. Dry-Run Mode (Recommended First Step)

```bash
# Test what would happen without making changes
python3 scripts/import_bind_zones.py \
  --dir /path/to/zones \
  --dry-run \
  --create-includes \
  --verbose \
  --db-mode \
  --db-user root \
  --db-pass secret
```

#### 2. DB Mode Import with Includes

```bash
# Import zones directly to database
python3 scripts/import_bind_zones.py \
  --dir /path/to/zones \
  --create-includes \
  --db-mode \
  --db-user root \
  --db-pass secret \
  --db-name dns3_db \
  --skip-existing
```

#### 3. API Mode Import with Includes

```bash
# Import via API endpoints
python3 scripts/import_bind_zones.py \
  --dir /path/to/zones \
  --create-includes \
  --api-url http://localhost/dns3 \
  --api-token YOUR_API_TOKEN \
  --skip-existing
```

#### 4. Allow Absolute Include Paths

```bash
# By default, absolute paths in $INCLUDE are blocked for security
# Use --allow-abs-include to override (use with caution)
python3 scripts/import_bind_zones.py \
  --dir /path/to/zones \
  --create-includes \
  --allow-abs-include \
  --db-mode \
  --db-user root \
  --db-pass secret
```

### Command-Line Options

| Option | Description |
|--------|-------------|
| `--create-includes` | Enable $INCLUDE directive processing (required) |
| `--allow-abs-include` | Allow absolute paths in $INCLUDE directives |
| `--include-search-paths PATHS` | Additional search paths for includes (colon/comma separated) |
| `--skip-existing` | Skip zones that already exist (deduplication) |
| `--dry-run` | Show what would be done without making changes |
| `--verbose` | Enable detailed logging (shows all attempted paths on errors) |
| `--db-mode` | Use direct database insertion (default: API mode) |
| `--user-id ID` | User ID for created_by field (default: 1) |

## Bash Script Usage

### Basic Syntax

```bash
./scripts/import_bind_zones.sh --dir /path/to/zones --create-includes [OPTIONS]
```

### Examples

#### 1. Dry-Run Mode

```bash
# Test import without making changes
./scripts/import_bind_zones.sh \
  --dir /path/to/zones \
  --dry-run \
  --create-includes
```

#### 2. Database Import with Includes

```bash
# Import zones with $INCLUDE support
./scripts/import_bind_zones.sh \
  --dir /path/to/zones \
  --create-includes \
  --db-user root \
  --db-pass secret \
  --skip-existing
```

#### 3. Allow Absolute Includes

```bash
./scripts/import_bind_zones.sh \
  --dir /path/to/zones \
  --create-includes \
  --allow-abs-include \
  --db-user root \
  --db-pass secret
```

### Command-Line Options

| Option | Description |
|--------|-------------|
| `--create-includes` | Enable $INCLUDE directive processing (required) |
| `--allow-abs-include` | Allow absolute paths in $INCLUDE directives |
| `--include-search-paths PATHS` | Additional search paths for includes (colon/comma separated) |
| `--skip-existing` | Skip zones that already exist |
| `--dry-run` | Show what would be done without making changes |
| `--db-user USER` | Database user (default: root) |
| `--db-pass PASS` | Database password |
| `--db-name NAME` | Database name (default: dns3_db) |

## Testing Scenarios

### Test Case 1: Simple Zone with Includes

#### File Structure
```
/tmp/test_zones/
├── example.com.zone (master)
├── hosts.inc (included)
└── mail.inc (included)
```

#### Master Zone (example.com.zone)
```bind
$ORIGIN example.com.
$TTL 3600

@   IN  SOA  ns1.example.com. admin.example.com. (
             2024120801 ; serial
             10800      ; refresh
             900        ; retry
             604800     ; expire
             3600       ; minimum
             )

    IN  NS   ns1.example.com.
    IN  NS   ns2.example.com.

$INCLUDE hosts.inc
$INCLUDE mail.inc example.com.

www IN  A    192.0.2.1
```

#### Include File (hosts.inc)
```bind
; Host records
server1 IN  A  192.0.2.11
server2 IN  A  192.0.2.12
```

#### Include File (mail.inc)
```bind
; Mail servers
mail IN  A   192.0.2.30
@    IN  MX  10 mail.example.com.
```

#### Run Test
```bash
# Dry-run first
python3 scripts/import_bind_zones.py \
  --dir /tmp/test_zones \
  --dry-run \
  --create-includes \
  --verbose \
  --db-mode \
  --db-user root \
  --db-pass secret

# Actual import
python3 scripts/import_bind_zones.py \
  --dir /tmp/test_zones \
  --create-includes \
  --db-mode \
  --db-user root \
  --db-pass secret
```

#### Expected Results
- 3 zone_files created: 1 master + 2 includes
- 2 zone_file_includes relationships created
- DNS records correctly associated with their respective zone_file_id
- Master zone content preserves $INCLUDE directives

### Test Case 2: Deduplication

```bash
# First import
python3 scripts/import_bind_zones.py \
  --dir /tmp/test_zones \
  --create-includes \
  --db-mode \
  --db-user root \
  --db-pass secret

# Second import (should skip existing)
python3 scripts/import_bind_zones.py \
  --dir /tmp/test_zones \
  --create-includes \
  --skip-existing \
  --db-mode \
  --db-user root \
  --db-pass secret
```

Expected: Second run should skip existing zones.

### Test Case 3: Nested Includes

#### Master Zone
```bind
$ORIGIN example.com.
$INCLUDE level1.inc
```

#### level1.inc
```bind
$INCLUDE level2.inc
server1 IN A 192.0.2.1
```

#### level2.inc
```bind
server2 IN A 192.0.2.2
```

Expected: All three zone_files created with proper relationships.

## Security Considerations

### Path Traversal Protection

By default, the scripts prevent includes from referencing files outside the base directory:

```bash
# This will FAIL by default
$INCLUDE /etc/passwd
$INCLUDE ../../../etc/passwd
```

To override (use with caution):
```bash
python3 scripts/import_bind_zones.py \
  --dir /path/to/zones \
  --create-includes \
  --allow-abs-include \
  --db-mode
```

### Circular Include Detection

The scripts detect and prevent circular includes:

```bind
# master.zone
$INCLUDE a.inc

# a.inc
$INCLUDE b.inc

# b.inc
$INCLUDE a.inc  ← Circular reference detected!
```

### Depth Limiting

Maximum include depth is limited to 50 levels to prevent excessive recursion.

## Troubleshooting

### Issue: "Include file not found"

**Cause**: Include path cannot be resolved using any of the resolution strategies.

**Solutions**: 
1. **Check file location**: Verify include files exist in expected location
2. **Use relative paths**: Reference includes relative to the master zone's directory
3. **Verify permissions**: Ensure files are readable
4. **Use --verbose**: See all attempted paths to understand why resolution failed
5. **Use --include-search-paths**: Add additional directories where includes may be located
   ```bash
   --include-search-paths "/var/named/includes:/etc/bind/includes"
   ```
6. **Check path separators**: For basename-only includes (no `/` or `\`), recursive search is used

**Example diagnostic run**:
```bash
python3 scripts/import_bind_zones.py \
  --dir /path/to/zones \
  --create-includes \
  --verbose \
  --dry-run \
  --db-mode
```

This will show all attempted resolution paths.
### Issue: "Absolute include path not allowed"

**Cause**: Security protection against absolute paths.

**Solution**: 
- Use relative paths in $INCLUDE directives
- Or add `--allow-abs-include` flag (not recommended)

### Issue: "Circular include detected"

**Cause**: Include files reference each other in a loop.

**Solution**: Review and fix include structure to remove circular dependencies.

### Issue: "Maximum include depth exceeded"

**Cause**: Too many nested includes (>50 levels).

**Solution**: Flatten include hierarchy or increase limit in code.

### Issue: "Include already processed (dedup by hash)"

**Status**: This is informational, not an error.

**Explanation**: The same include file was referenced multiple times. The script reuses the existing zone_file entry.

## Database Verification

After import, verify the results:

```sql
-- Check created zones
SELECT id, name, filename, file_type, status 
FROM zone_files 
WHERE created_at > DATE_SUB(NOW(), INTERVAL 1 HOUR)
ORDER BY file_type, name;

-- Check zone_file_includes relationships
SELECT 
    p.name AS parent_zone,
    i.name AS include_zone,
    zfi.position
FROM zone_file_includes zfi
JOIN zone_files p ON zfi.parent_id = p.id
JOIN zone_files i ON zfi.include_id = i.id
ORDER BY p.name, zfi.position;

-- Check DNS records by zone_file
SELECT 
    zf.name AS zone,
    zf.file_type,
    COUNT(dr.id) AS record_count
FROM zone_files zf
LEFT JOIN dns_records dr ON dr.zone_file_id = zf.id
WHERE zf.created_at > DATE_SUB(NOW(), INTERVAL 1 HOUR)
GROUP BY zf.id, zf.name, zf.file_type
ORDER BY zf.file_type, zf.name;
```

## Best Practices

1. **Always use dry-run first** to preview changes
2. **Backup database** before importing to production
3. **Test in staging** environment first
4. **Use --skip-existing** to avoid duplicates
5. **Monitor logs** for warnings and errors
6. **Verify results** with SQL queries after import
7. **Keep include paths relative** for portability and security
8. **Document include structure** in zone comments
9. **Limit include depth** to maintain maintainability
10. **Use Python script** for complex zones (Bash is heuristic)

## Rollback Procedure

If import fails or produces incorrect results:

### Python Script (DB Mode)
The Python script uses transactions - if an error occurs, changes are automatically rolled back.

### Manual Rollback
```sql
-- Identify imported zones
SELECT id, name, filename, created_at 
FROM zone_files 
WHERE created_at > 'YYYY-MM-DD HH:MM:SS';

-- Delete records and zones (adjust timestamp)
DELETE dr FROM dns_records dr
JOIN zone_files zf ON dr.zone_file_id = zf.id
WHERE zf.created_at > 'YYYY-MM-DD HH:MM:SS';

DELETE FROM zone_file_includes
WHERE parent_id IN (
    SELECT id FROM zone_files 
    WHERE created_at > 'YYYY-MM-DD HH:MM:SS'
);

DELETE FROM zone_files
WHERE created_at > 'YYYY-MM-DD HH:MM:SS';
```

Or restore from backup:
```bash
mysql -u root -p dns3_db < backup_before_import.sql
```
