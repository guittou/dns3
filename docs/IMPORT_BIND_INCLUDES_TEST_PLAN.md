# BIND Import Scripts - Test Plan and Validation

This document provides comprehensive test scenarios and SQL validation queries for the BIND import scripts (`import_bind_zones.py` and `import_bind_zones.sh`).

## Table of Contents

1. [Test Scenarios](#test-scenarios)
2. [SQL Validation Queries](#sql-validation-queries)
3. [Expected Behavior](#expected-behavior)
4. [Troubleshooting](#troubleshooting)

## Test Scenarios

### Test 1: Dry-Run Mode (Python)

**Purpose**: Verify import plan without making database changes.

**Command**:
```bash
python3 scripts/import_bind_zones.py \
  --dir /path/to/zones \
  --create-includes \
  --dry-run \
  --log-file logs/import_dry_run.log \
  --log-level DEBUG \
  --db-mode \
  --db-user root \
  --db-pass secret
```

**Expected Output**:
- Log shows: "DRY-RUN mode enabled - no changes will be made"
- Master zone creation plan displayed
- Number of master records shown
- Includes resolved and creation plan shown
- zone_file_includes relationship statements displayed
- No actual database modifications

**Validation**:
```bash
# Check log file was created
ls -lh logs/import_dry_run.log

# Verify log content
grep -E "(DRY-RUN|Would create)" logs/import_dry_run.log
```

### Test 2: Dry-Run Mode (Bash)

**Purpose**: Verify bash script import plan.

**Command**:
```bash
./scripts/import_bind_zones.sh \
  --dir /path/to/zones \
  --create-includes \
  --dry-run \
  --log-file logs/import_bash_dry_run.log
```

**Expected Output**:
- Master zone SQL INSERT statements displayed
- Include zone creation plans shown
- No actual database execution

### Test 3: DB-Mode Import with Includes (Staging)

**Purpose**: Full import to staging database.

**Pre-requisites**:
1. Backup staging database
2. Ensure clean test data or use --skip-existing

**Command**:
```bash
# Backup first
mysqldump -u root -p dns3_db > backup_before_import_$(date +%Y%m%d_%H%M%S).sql

# Import
python3 scripts/import_bind_zones.py \
  --dir /path/to/zones \
  --create-includes \
  --db-mode \
  --db-user root \
  --db-pass secret \
  --db-name dns3_db \
  --log-file logs/import_staging.log \
  --log-level INFO
```

**Expected Results**:
- Master zone_files entries created (content IS NULL)
- SOA columns populated (mname, soa_rname, soa_refresh, soa_retry, soa_expire, soa_minimum)
- default_ttl column populated
- Master records inserted in dns_records with zone_file_id = master_id

**For each include**:
- zone_files entry exists with:
  - name = filename stem (e.g., `logiciel1` from `logiciel1.db`)
  - filename = actual filename (e.g., `logiciel1.db`)
  - file_type = 'include'
  - domain = effective origin
  - content = NULL
- dns_records entries have zone_file_id = include_id
- zone_file_includes relationship created

**TTL Validation**:
- Records with explicit TTL in source: dns_records.ttl = value
- Records without explicit TTL: dns_records.ttl IS NULL

### Test 4: Idempotency Test

**Purpose**: Verify --skip-existing prevents duplicates.

**Command**:
```bash
# First import
python3 scripts/import_bind_zones.py \
  --dir /path/to/zones \
  --create-includes \
  --db-mode \
  --db-user root \
  --db-pass secret \
  --log-file logs/import_first.log

# Second import (should skip)
python3 scripts/import_bind_zones.py \
  --dir /path/to/zones \
  --create-includes \
  --skip-existing \
  --db-mode \
  --db-user root \
  --db-pass secret \
  --log-file logs/import_second.log
```

**Expected Results**:
- First import: zones and records created
- Second import: 
  - Log shows "Zone {name} already exists, skipping"
  - Log shows "Include zone already exists, reusing"
  - No duplicate zone_files entries
  - Statistics show 0 zones created, N skipped

### Test 5: TTL Detection Accuracy

**Purpose**: Verify explicit vs implicit TTL detection.

**Test Zone File** (e.g., `test_data/ttl_test/example.com.zone`):
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

; Explicit TTL - should store 300 in dns_records.ttl
www 300 IN  A    192.0.2.1

; Implicit TTL - dns_records.ttl should be NULL
ftp IN  A    192.0.2.2

; Explicit TTL with time unit - should convert and store
mail 1h IN A 192.0.2.3
```

**Include File** (e.g., `test_data/ttl_test/hosts.inc`):
```bind
; No $TTL directive - inherits from master

; Implicit TTL - should be NULL
server1 IN  A  192.0.2.11

; Explicit TTL - should store 600
server2 600 IN  A  192.0.2.12
```

**Command**:
```bash
python3 scripts/import_bind_zones.py \
  --dir test_data/ttl_test \
  --create-includes \
  --db-mode \
  --db-user root \
  --db-pass secret \
  --log-level DEBUG \
  --log-file logs/import_ttl_test.log
```

**Validation Queries**:
```sql
-- Check master zone
SELECT 
    dr.name,
    dr.record_type,
    dr.ttl,
    dr.value,
    CASE 
        WHEN dr.ttl IS NULL THEN 'IMPLICIT (inherits from zone default_ttl)'
        ELSE 'EXPLICIT'
    END AS ttl_type
FROM dns_records dr
JOIN zone_files zf ON dr.zone_file_id = zf.id
WHERE zf.name = 'example.com'
ORDER BY dr.name;

-- Expected results:
-- www.example.com    | A | 300  | 192.0.2.1  | EXPLICIT
-- ftp.example.com    | A | NULL | 192.0.2.2  | IMPLICIT
-- mail.example.com   | A | 3600 | 192.0.2.3  | EXPLICIT (1h = 3600s)

-- Check include records
SELECT 
    dr.name,
    dr.record_type,
    dr.ttl,
    dr.value,
    CASE 
        WHEN dr.ttl IS NULL THEN 'IMPLICIT'
        ELSE 'EXPLICIT'
    END AS ttl_type
FROM dns_records dr
JOIN zone_files zf ON dr.zone_file_id = zf.id
WHERE zf.name = 'hosts' AND zf.file_type = 'include'
ORDER BY dr.name;

-- Expected results:
-- server1.example.com | A | NULL | 192.0.2.11 | IMPLICIT
-- server2.example.com | A | 600  | 192.0.2.12 | EXPLICIT
```

### Test 6: Include Naming Convention

**Purpose**: Verify includes use filename stem, not origin.

**Test Scenario**:
- Master zone: `example.com.zone` with domain `example.com`
- Include file: `hosts.db` with same origin `example.com`

**Without Fix**: Would cause UNIQUE constraint violation on zone_files.name
**With Fix**: Include stored with name = 'hosts' (stem), no conflict

**Command**:
```bash
python3 scripts/import_bind_zones.py \
  --dir /path/to/test \
  --create-includes \
  --db-mode \
  --db-user root \
  --db-pass secret \
  --log-file logs/import_naming_test.log
```

**Validation**:
```sql
SELECT 
    id,
    name,
    filename,
    file_type,
    domain
FROM zone_files
WHERE filename IN ('example.com.zone', 'hosts.db')
ORDER BY file_type, name;

-- Expected:
-- id | name        | filename          | file_type | domain
-- 1  | example.com | example.com.zone  | master    | example.com
-- 2  | hosts       | hosts.db          | include   | example.com
```

### Test 7: No Token Leakage in Logs

**Purpose**: Verify API tokens are never logged.

**Command**:
```bash
python3 scripts/import_bind_zones.py \
  --dir /path/to/zones \
  --api-url http://localhost/dns3 \
  --api-token "SECRET_TOKEN_12345" \
  --log-file logs/security_test.log \
  --log-level DEBUG \
  --dry-run

# Check log does NOT contain token
grep -i "SECRET_TOKEN" logs/security_test.log
# Should return nothing
```

## SQL Validation Queries

### Query 1: Verify Master Zones Created

```sql
-- Check master zones created in last hour
SELECT 
    id,
    name,
    filename,
    file_type,
    status,
    domain,
    default_ttl,
    mname,
    soa_rname,
    soa_serial,
    directory,
    created_at
FROM zone_files
WHERE file_type = 'master'
  AND created_at > DATE_SUB(NOW(), INTERVAL 1 HOUR)
ORDER BY name;
```

**Expected**:
- content column is NULL or empty
- SOA fields populated
- default_ttl populated
- directory path stored

### Query 2: Verify Includes Created

```sql
-- Check include zones created in last hour
SELECT 
    id,
    name,
    filename,
    file_type,
    domain,
    default_ttl,
    directory,
    created_at
FROM zone_files
WHERE file_type = 'include'
  AND created_at > DATE_SUB(NOW(), INTERVAL 1 HOUR)
ORDER BY name;
```

**Expected**:
- name = filename stem (not full filename, not domain)
- filename = actual include filename
- domain = effective origin

### Query 3: Verify zone_file_includes Relationships

```sql
-- Check master-include relationships
SELECT 
    zfi.id AS relationship_id,
    p.name AS parent_zone,
    p.file_type AS parent_type,
    i.name AS include_zone,
    i.filename AS include_filename,
    zfi.position,
    zfi.created_at
FROM zone_file_includes zfi
JOIN zone_files p ON zfi.parent_id = p.id
JOIN zone_files i ON zfi.include_id = i.id
WHERE p.created_at > DATE_SUB(NOW(), INTERVAL 1 HOUR)
ORDER BY p.name, zfi.position;
```

**Expected**:
- One row per $INCLUDE directive
- position reflects order in master file
- parent_type = 'master' or 'include' (for nested includes)

### Query 4: Verify Record Distribution

```sql
-- Count records by zone_file
SELECT 
    zf.name AS zone,
    zf.filename,
    zf.file_type,
    COUNT(dr.id) AS record_count,
    GROUP_CONCAT(DISTINCT dr.record_type ORDER BY dr.record_type) AS record_types
FROM zone_files zf
LEFT JOIN dns_records dr ON dr.zone_file_id = zf.id
WHERE zf.created_at > DATE_SUB(NOW(), INTERVAL 1 HOUR)
GROUP BY zf.id, zf.name, zf.filename, zf.file_type
ORDER BY zf.file_type, zf.name;
```

**Expected**:
- Master has its records (excluding those in includes)
- Each include has its own records
- No record duplication

### Query 5: Verify TTL Handling

```sql
-- Check TTL distribution (explicit vs implicit)
SELECT 
    zf.name AS zone,
    zf.file_type,
    zf.default_ttl AS zone_default_ttl,
    COUNT(*) AS total_records,
    SUM(CASE WHEN dr.ttl IS NULL THEN 1 ELSE 0 END) AS implicit_ttl_count,
    SUM(CASE WHEN dr.ttl IS NOT NULL THEN 1 ELSE 0 END) AS explicit_ttl_count,
    GROUP_CONCAT(
        DISTINCT CASE WHEN dr.ttl IS NOT NULL THEN dr.ttl END 
        ORDER BY dr.ttl
    ) AS explicit_ttl_values
FROM zone_files zf
LEFT JOIN dns_records dr ON dr.zone_file_id = zf.id
WHERE zf.created_at > DATE_SUB(NOW(), INTERVAL 1 HOUR)
  AND dr.record_type != 'SOA'
GROUP BY zf.id, zf.name, zf.file_type, zf.default_ttl
ORDER BY zf.file_type, zf.name;
```

**Expected**:
- Most records have ttl = NULL (implicit, inheriting from zone default_ttl)
- Only records with explicit TTL in source have ttl value
- explicit_ttl_values shows the unique TTL values used

### Query 6: Verify No Record Name Concatenation

```sql
-- Check that record names are properly formed (not concatenated)
SELECT 
    zf.name AS zone,
    zf.domain AS zone_domain,
    dr.name AS record_name,
    dr.record_type,
    dr.value,
    CASE 
        WHEN dr.name = zf.domain THEN 'ZONE APEX (@)'
        WHEN dr.name LIKE CONCAT('%.', zf.domain) THEN 'SUBDOMAIN (correct)'
        ELSE 'UNEXPECTED FORMAT'
    END AS name_validation
FROM dns_records dr
JOIN zone_files zf ON dr.zone_file_id = zf.id
WHERE zf.created_at > DATE_SUB(NOW(), INTERVAL 1 HOUR)
  AND dr.record_type != 'SOA'
ORDER BY zf.name, dr.name;
```

**Expected**:
- All records show 'ZONE APEX (@)' or 'SUBDOMAIN (correct)'
- No 'UNEXPECTED FORMAT' entries
- No double-domain concatenation (e.g., `www.example.com.example.com`)

### Query 7: Verify Content Field Not Populated

```sql
-- Ensure content is NULL for all zones
SELECT 
    name,
    filename,
    file_type,
    CASE 
        WHEN content IS NULL THEN 'CORRECT (NULL)'
        WHEN content = '' THEN 'CORRECT (empty)'
        ELSE 'INCORRECT (populated)'
    END AS content_status,
    CHAR_LENGTH(content) AS content_length
FROM zone_files
WHERE created_at > DATE_SUB(NOW(), INTERVAL 1 HOUR)
ORDER BY file_type, name;
```

**Expected**:
- All zones show 'CORRECT (NULL)' or 'CORRECT (empty)'
- content_length = 0 or NULL

### Query 8: Verify Import Atomicity (After Rollback Test)

**Test**: Cause an error mid-import (e.g., invalid record) to trigger rollback.

```sql
-- Check no partial imports exist
SELECT 
    zf.name,
    zf.file_type,
    COUNT(dr.id) AS record_count,
    zf.created_at
FROM zone_files zf
LEFT JOIN dns_records dr ON dr.zone_file_id = zf.id
WHERE zf.created_at > DATE_SUB(NOW(), INTERVAL 5 MINUTE)
GROUP BY zf.id, zf.name, zf.file_type, zf.created_at
HAVING record_count = 0;
```

**Expected**:
- After rollback: No orphaned zone_files without records
- Transaction ensures all-or-nothing import

## Expected Behavior

### Import Order Guarantee

1. **Master zone created first**
   - INSERT into zone_files (file_type='master')
   - Extract SOA, default_ttl
   - Returns master zone_id

2. **Master records inserted**
   - INSERT into dns_records with zone_file_id = master_id
   - TTL column set only for explicit TTLs

3. **Includes processed in order**
   - For each $INCLUDE in master file:
     - Resolve include file path
     - Check if already exists (deduplication)
     - INSERT into zone_files (file_type='include', name=stem)
     - INSERT records with zone_file_id = include_id

4. **Relationships created**
   - INSERT into zone_file_includes (parent_id, include_id, position)

### TTL Policy

**Rule**: Only explicit TTLs are stored in `dns_records.ttl`

| Source Record | TTL Column Value | Effective TTL at Runtime |
|--------------|------------------|--------------------------|
| `www IN A 1.2.3.4` | NULL | Uses zone's default_ttl |
| `www 300 IN A 1.2.3.4` | 300 | Uses explicit value (300) |
| `www 1h IN A 1.2.3.4` | 3600 | Uses explicit value (1h = 3600s) |

**Application Logic**: When serving DNS responses, if `dns_records.ttl` IS NULL, use the corresponding `zone_files.default_ttl`.

### Include Naming Convention

| File | Origin | zone_files.name | zone_files.filename | zone_files.domain |
|------|--------|----------------|---------------------|-------------------|
| example.com.zone | example.com | example.com | example.com.zone | example.com |
| hosts.db | example.com | hosts | hosts.db | example.com |
| mail.inc | example.com | mail | mail.inc | example.com |

**Rationale**: Using filename stem avoids UNIQUE constraint violations when include origin equals master origin.

## Troubleshooting

### Issue: Dry-run fails with DB connection error

**Cause**: Script attempts DB connection even in dry-run mode.

**Workaround**: 
```bash
# For dry-run, provide dummy DB credentials or use --example mode
python3 scripts/import_bind_zones.py --example
```

### Issue: TTL column always populated

**Cause**: _detect_explicit_ttls() not being called or returning empty set.

**Solution**: Check log for "Detected N record(s) with explicit TTL" messages. If N=0 for all zones, the detection logic may need adjustment.

### Issue: Include not found

**Cause**: Path resolution failed.

**Solution**: Use `--verbose` or `--log-level DEBUG` to see all attempted paths. Consider using `--include-search-paths` to add additional directories.

### Issue: UNIQUE constraint violation on zone_files.name

**Cause**: Old code that used origin as name for includes.

**Solution**: Verify code uses `include_path.stem` (Python) or `${filename%.*}` (Bash) for include naming. See implementation in import_bind_zones.py around the include zone data preparation section, and in import_bind_zones.sh in the include processing function.

### Issue: Records have double domain (www.example.com.example.com)

**Cause**: Manual concatenation in older versions.

**Solution**: Verify code uses dnspython's `derelativize()` without additional string manipulation.

## Success Criteria

After import, all of the following must be true:

✅ Master zone exists with content=NULL, SOA/TTL in columns
✅ Includes exist with name=filename_stem, content=NULL
✅ zone_file_includes relationships created
✅ Records distributed: master records → master zone_id, include records → include zone_id
✅ TTL column: NULL for implicit, value for explicit
✅ No double-domain names in dns_records.name
✅ Idempotent: re-running with --skip-existing causes no duplicates
✅ Log file created with no sensitive tokens
✅ Transaction rollback works on errors (DB mode)

## Validation Checklist

Use this checklist after each import:

```bash
# 1. Log file created
[ -f logs/import.log ] && echo "✓ Log file exists" || echo "✗ Log file missing"

# 2. No tokens in log
! grep -i "token.*[a-zA-Z0-9]{20,}" logs/import.log && echo "✓ No tokens in log" || echo "✗ Token leaked"

# 3. Zones created
mysql -u root -p -e "SELECT COUNT(*) FROM zone_files WHERE created_at > DATE_SUB(NOW(), INTERVAL 1 HOUR);" dns3_db

# 4. Records created
mysql -u root -p -e "SELECT COUNT(*) FROM dns_records WHERE created_at > DATE_SUB(NOW(), INTERVAL 1 HOUR);" dns3_db

# 5. Relationships created
mysql -u root -p -e "SELECT COUNT(*) FROM zone_file_includes WHERE created_at > DATE_SUB(NOW(), INTERVAL 1 HOUR);" dns3_db

# 6. Content field not populated
mysql -u root -p -e "SELECT COUNT(*) FROM zone_files WHERE created_at > DATE_SUB(NOW(), INTERVAL 1 HOUR) AND content IS NOT NULL AND content != '';" dns3_db
# Should return 0

# 7. TTL policy check
mysql -u root -p -e "SELECT COUNT(*) AS implicit_ttl FROM dns_records WHERE created_at > DATE_SUB(NOW(), INTERVAL 1 HOUR) AND ttl IS NULL;" dns3_db
mysql -u root -p -e "SELECT COUNT(*) AS explicit_ttl FROM dns_records WHERE created_at > DATE_SUB(NOW(), INTERVAL 1 HOUR) AND ttl IS NOT NULL;" dns3_db
```

## References

- Main documentation: `docs/IMPORT_INCLUDES_GUIDE.md`
- Python script: `scripts/import_bind_zones.py`
- Bash script: `scripts/import_bind_zones.sh`
