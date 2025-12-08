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
| `--skip-existing` | Skip zones that already exist (deduplication) |
| `--dry-run` | Show what would be done without making changes |
| `--verbose` | Enable detailed logging |
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

**Cause**: Include path cannot be resolved.

**Solution**: 
- Check that include files exist in the expected location
- Use relative paths from the master zone's directory
- Verify file permissions

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
