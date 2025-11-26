> **ARCHIVED DOCUMENT NOTE** : Les fichiers de migration mentionnés dans ce document ont été supprimés. Pour les nouvelles installations, utilisez `database.sql` (ou `structure_ok_dns3_db.sql`).

# NULL TTL Testing Guide

This document describes how to manually test the NULL TTL feature implementation.

## Overview

The NULL TTL feature allows DNS records to be created without an explicit TTL value. When a record has a NULL TTL, the zone file generator will omit the TTL from the BIND-format record line, causing BIND to use the zone's default $TTL directive.

## Database Migration

First, apply the migration to allow NULL TTL values:

```bash
mysql -u [user] -p [database] < migrations/017_make_dns_records_ttl_nullable.sql
```

This will modify the `dns_records.ttl` column from `DEFAULT 3600` to `DEFAULT NULL`.

## Test Cases

### Test 1: Create Record with NULL TTL (Frontend Sends NULL)

**API Request:**
```bash
curl -X POST http://localhost/api/dns_api.php?action=create \
  -H "Content-Type: application/json" \
  -d '{
    "zone_file_id": 1,
    "record_type": "A",
    "name": "test-null-ttl",
    "address_ipv4": "192.0.2.1",
    "ttl": null
  }'
```

**Expected Result:**
- Record is created successfully
- Database verification: `SELECT ttl FROM dns_records WHERE name='test-null-ttl'` should return NULL
- Zone file generation should omit the TTL:
  ```
  test-null-ttl                        IN A      192.0.2.1
  ```

### Test 2: Create Record Without TTL Field

**API Request:**
```bash
curl -X POST http://localhost/api/dns_api.php?action=create \
  -H "Content-Type: application/json" \
  -d '{
    "zone_file_id": 1,
    "record_type": "A",
    "name": "test-no-ttl",
    "address_ipv4": "192.0.2.2"
  }'
```

**Expected Result:**
- Record is created successfully with NULL TTL
- Database verification: `SELECT ttl FROM dns_records WHERE name='test-no-ttl'` should return NULL

### Test 3: Create Record with Explicit TTL

**API Request:**
```bash
curl -X POST http://localhost/api/dns_api.php?action=create \
  -H "Content-Type: application/json" \
  -d '{
    "zone_file_id": 1,
    "record_type": "A",
    "name": "test-explicit-ttl",
    "address_ipv4": "192.0.2.3",
    "ttl": 7200
  }'
```

**Expected Result:**
- Record is created with TTL=7200
- Database verification: `SELECT ttl FROM dns_records WHERE name='test-explicit-ttl'` should return 7200
- Zone file generation should include the TTL:
  ```
  test-explicit-ttl                  7200 IN A      192.0.2.3
  ```

### Test 4: Update Record to NULL TTL

**API Request:**
```bash
curl -X POST http://localhost/api/dns_api.php?action=update&id=123 \
  -H "Content-Type: application/json" \
  -d '{
    "ttl": null
  }'
```

**Expected Result:**
- Record's TTL is updated to NULL
- Database verification should show NULL TTL
- Zone file should omit TTL

### Test 5: Update Record Without Touching TTL

**API Request:**
```bash
curl -X POST http://localhost/api/dns_api.php?action=update&id=123 \
  -H "Content-Type: application/json" \
  -d '{
    "comment": "Updated comment"
  }'
```

**Expected Result:**
- Record's TTL remains unchanged (either NULL or previous value)
- Only the comment field is updated

### Test 6: Update Record with New TTL Value

**API Request:**
```bash
curl -X POST http://localhost/api/dns_api.php?action=update&id=123 \
  -H "Content-Type: application/json" \
  -d '{
    "ttl": 3600
  }'
```

**Expected Result:**
- Record's TTL is updated to 3600
- Zone file includes the TTL value

## Zone File Generation Testing

After creating records with various TTL values (NULL, explicit values), generate a zone file and verify the output:

```bash
# Navigate to the zone file generation page
# Or use the API to generate the zone file for a specific zone
```

**Expected Zone File Format:**

```bind
; Zone file with mixed TTL values

; Record with NULL TTL (uses zone default)
test-null-ttl                        IN A      192.0.2.1

; Record with explicit TTL
test-explicit-ttl                  7200 IN A      192.0.2.3

; Another NULL TTL record
test-no-ttl                          IN A      192.0.2.2
```

## Validation Testing

### Valid Cases (Should Succeed)
- Creating/updating with `ttl: null`
- Creating/updating with `ttl: 300` (5 minutes)
- Creating/updating with `ttl: 86400` (1 day)
- Creating/updating without the `ttl` field

### Invalid Cases (Should Fail - if validation is added)
Note: Current implementation doesn't validate TTL values, but if validation is added later:
- `ttl: -1` (negative values)
- `ttl: 0` (zero)
- `ttl: "abc"` (non-numeric strings)

## Backward Compatibility

Existing records with `ttl=3600` should continue to work as before:
- They will display with TTL 3600 in the zone file
- Updating them without touching TTL will preserve the value
- Setting them to NULL will work correctly

## Database Verification Queries

```sql
-- Check records with NULL TTL
SELECT id, name, record_type, ttl FROM dns_records WHERE ttl IS NULL;

-- Check records with explicit TTL
SELECT id, name, record_type, ttl FROM dns_records WHERE ttl IS NOT NULL;

-- Check records in a specific zone
SELECT id, name, record_type, ttl FROM dns_records WHERE zone_file_id = 1;

-- Verify history table also handles NULL
SELECT record_id, ttl, changed_at FROM dns_record_history WHERE record_id = 123 ORDER BY changed_at DESC;
```

## Frontend Integration Notes

The frontend should be updated to:
1. Allow the TTL field to be empty (which translates to NULL)
2. Display records with NULL TTL as "Default" or leave the field empty
3. When editing, preserve the NULL state if the user doesn't change it
4. Provide a checkbox or option to "Use zone default TTL"

## Security Considerations

- The implementation properly distinguishes between "field not provided" and "field set to NULL"
- No SQL injection vulnerabilities (uses prepared statements)
- TTL validation can be added later without changing the NULL handling logic
