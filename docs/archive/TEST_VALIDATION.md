> **ARCHIVED DOCUMENT NOTE** : Les fichiers de migration mentionnés dans ce document ont été supprimés. Pour les nouvelles installations, utilisez `database.sql` (ou `structure_ok_dns3_db.sql`).

# Test Validation Guide - DNS Metadata Fields

This document provides step-by-step instructions to validate the DNS metadata fields implementation.

## Prerequisites

1. Database with migrations applied (including 003_add_dns_fields.sql)
2. Admin user access
3. Browser with developer tools

## Test Cases

### 1. Apply Migration

**Steps:**
```bash
# Connect to database
mysql -u dns3_user -p dns3_db

# Run migration
source migrations/003_add_dns_fields.sql

# Verify columns exist
DESCRIBE dns_records;
```

**Expected Result:**
- Columns should include: `requester`, `expires_at`, `ticket_ref`, `comment`, `last_seen`, `created_at`, `updated_at`
- Indexes should exist: `idx_expires_at`, `idx_ticket_ref`

**SQL Verification:**
```sql
-- Check columns
SELECT COLUMN_NAME, COLUMN_TYPE, IS_NULLABLE, COLUMN_DEFAULT 
FROM information_schema.COLUMNS 
WHERE TABLE_SCHEMA = 'dns3_db' 
  AND TABLE_NAME = 'dns_records' 
  AND COLUMN_NAME IN ('requester', 'expires_at', 'ticket_ref', 'comment', 'last_seen', 'created_at', 'updated_at');

-- Check indexes
SELECT INDEX_NAME, COLUMN_NAME 
FROM information_schema.STATISTICS 
WHERE TABLE_SCHEMA = 'dns3_db' 
  AND TABLE_NAME = 'dns_records' 
  AND INDEX_NAME IN ('idx_expires_at', 'idx_ticket_ref');
```

---

### 2. Create Record via UI

**Steps:**
1. Login as admin
2. Navigate to DNS Management page (dns-management.php)
3. Click "Créer un enregistrement"
4. Fill in the form:
   - Type: A
   - Name: test.example.com
   - Value: 192.168.1.100
   - TTL: 3600
   - **Requester**: John Doe
   - **Expires At**: 2025-12-31T23:59
   - **Ticket Ref**: JIRA-123
   - **Comment**: Test record for validation
5. Click "Enregistrer"
6. Verify success message

**Expected Result:**
- Record created successfully
- Success message displayed
- Record appears in table with metadata visible

**Database Verification:**
```sql
SELECT id, name, value, requester, expires_at, ticket_ref, comment, last_seen, created_at 
FROM dns_records 
WHERE name = 'test.example.com' 
ORDER BY created_at DESC 
LIMIT 1;
```

**Expected:**
- `requester` = 'John Doe'
- `expires_at` = '2025-12-31 23:59:00'
- `ticket_ref` = 'JIRA-123'
- `comment` = 'Test record for validation'
- `last_seen` = NULL (not set on create)
- `created_at` = current timestamp

---

### 3. View Record (triggers markSeen)

**Steps:**
1. In DNS Management table, find the test record
2. Click "Modifier" button
3. Observe the modal opens with all fields populated
4. Note the "Vu pour la dernière fois" field

**Expected Result:**
- Modal opens with all metadata fields populated correctly
- Expires At shown in datetime-local format
- Last Seen field is now populated (after API get call)

**Database Verification:**
```sql
SELECT id, name, last_seen 
FROM dns_records 
WHERE name = 'test.example.com' 
ORDER BY created_at DESC 
LIMIT 1;
```

**Expected:**
- `last_seen` is now set to current timestamp (within last few seconds)

---

### 4. Update Record via UI

**Steps:**
1. Keep the modal open from previous test
2. Modify fields:
   - **Requester**: Jane Smith
   - **Ticket Ref**: SNOW-456
   - **Comment**: Updated for testing
3. Click "Enregistrer"
4. Verify success message

**Expected Result:**
- Record updated successfully
- Updated metadata visible in table

**Database Verification:**
```sql
SELECT requester, ticket_ref, comment, updated_at, last_seen
FROM dns_records 
WHERE name = 'test.example.com' 
ORDER BY created_at DESC 
LIMIT 1;
```

**Expected:**
- `requester` = 'Jane Smith'
- `ticket_ref` = 'SNOW-456'
- `comment` = 'Updated for testing'
- `updated_at` = recent timestamp
- `last_seen` = unchanged from previous view (not updated on save)

---

### 5. Security Test - Block last_seen from Client

**Steps:**
1. Open browser Developer Tools (F12)
2. Go to Console tab
3. Execute the following JavaScript to attempt setting last_seen:

```javascript
// Attempt to create record with last_seen
fetch(window.API_BASE + 'dns_api.php?action=create', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    credentials: 'same-origin',
    body: JSON.stringify({
        record_type: 'A',
        name: 'hack-test.example.com',
        value: '10.0.0.1',
        ttl: 3600,
        last_seen: '2020-01-01 00:00:00'  // Attempt to set past date
    })
}).then(r => r.json()).then(console.log);
```

**Expected Result:**
- Record created successfully
- But `last_seen` in database should be NULL

**Database Verification:**
```sql
SELECT name, last_seen 
FROM dns_records 
WHERE name = 'hack-test.example.com';
```

**Expected:**
- Record exists
- `last_seen` = NULL (client-provided value was ignored)

**Repeat for Update:**
```javascript
// Get record ID first, then attempt to update with last_seen
// Replace {id} with actual record ID
fetch(window.API_BASE + 'dns_api.php?action=update&id={id}', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    credentials: 'same-origin',
    body: JSON.stringify({
        last_seen: '2020-01-01 00:00:00'  // Attempt to set past date
    })
}).then(r => r.json()).then(console.log);
```

**Expected:**
- Update succeeds
- `last_seen` remains unchanged in database

---

### 6. API Validation Tests

**Test A: Requester max length (255 chars)**
```javascript
fetch(window.API_BASE + 'dns_api.php?action=create', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    credentials: 'same-origin',
    body: JSON.stringify({
        record_type: 'A',
        name: 'test-long-requester.example.com',
        value: '10.0.0.2',
        requester: 'A'.repeat(256)  // 256 characters (too long)
    })
}).then(r => r.json()).then(console.log);
```

**Expected:** Error: "Requester field too long (max 255 characters)"

**Test B: Invalid date format**
```javascript
fetch(window.API_BASE + 'dns_api.php?action=create', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    credentials: 'same-origin',
    body: JSON.stringify({
        record_type: 'A',
        name: 'test-bad-date.example.com',
        value: '10.0.0.3',
        expires_at: 'not-a-date'
    })
}).then(r => r.json()).then(console.log);
```

**Expected:** Error: "Invalid expires_at date format..."

**Test C: Valid alternative date format**
```javascript
fetch(window.API_BASE + 'dns_api.php?action=create', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    credentials: 'same-origin',
    body: JSON.stringify({
        record_type: 'A',
        name: 'test-alt-date.example.com',
        value: '10.0.0.4',
        expires_at: '2025-06-15T14:30'  // HTML5 datetime-local format
    })
}).then(r => r.json()).then(console.log);
```

**Expected:** Success, record created with expires_at = '2025-06-15 14:30:00'

---

### 7. List API Returns New Fields

**Steps:**
```javascript
fetch(window.API_BASE + 'dns_api.php?action=list')
    .then(r => r.json())
    .then(data => {
        console.log('Sample record:', data.data[0]);
        console.log('Has requester?', 'requester' in data.data[0]);
        console.log('Has expires_at?', 'expires_at' in data.data[0]);
        console.log('Has ticket_ref?', 'ticket_ref' in data.data[0]);
        console.log('Has comment?', 'comment' in data.data[0]);
        console.log('Has last_seen?', 'last_seen' in data.data[0]);
    });
```

**Expected Result:**
- All new fields present in returned records
- Values correctly populated

---

### 8. UI Datetime Conversion

**Steps:**
1. Create a record with expires_at = "2025-12-31T23:59"
2. Click edit on that record
3. Check that the datetime-local input shows "2025-12-31T23:59"
4. Change to "2026-01-15T10:30"
5. Save
6. Check database

**Database Verification:**
```sql
SELECT expires_at FROM dns_records WHERE name = 'test.example.com';
```

**Expected:**
- expires_at = '2026-01-15 10:30:00' (converted from T format with :00 added)

---

### 9. Table Display

**Visual Verification:**
1. Check DNS Management table
2. Verify columns are present:
   - Demandeur (Requester)
   - Expire (Expires At)
   - Vu le (Last Seen)
3. Verify data formatting:
   - Dates show in locale format (DD/MM/YYYY HH:MM)
   - Empty fields show "-"

---

### 10. Last Seen Read-Only Behavior

**Steps:**
1. Open edit modal for a record
2. Inspect the "Vu pour la dernière fois" field
3. Verify HTML attributes

**Expected:**
- Input has `disabled` attribute
- Input has `readonly` attribute
- Field value is formatted for display
- Field group only visible when record has been viewed (has last_seen value)

---

## Cleanup

After testing, you can clean up test records:

```sql
DELETE FROM dns_records WHERE name LIKE '%test%' OR name LIKE '%hack%';
```

## Summary Checklist

- [ ] Migration applied successfully
- [ ] Columns and indexes created
- [ ] Create record with metadata works
- [ ] View record triggers markSeen
- [ ] Update record preserves metadata
- [ ] last_seen cannot be set from client (security)
- [ ] Field length validation works
- [ ] Date format validation works
- [ ] Date conversion works (HTML5 ↔ SQL)
- [ ] API returns new fields
- [ ] UI displays new fields correctly
- [ ] Last seen is read-only in UI
- [ ] Table shows metadata columns

## Notes

- All datetime operations use server time (UTC recommended in production)
- last_seen is updated ONLY on GET requests when user views the record
- Validation happens server-side (client validation is for UX only)
- All prepared statements protect against SQL injection
- Field max lengths enforced: requester (255), ticket_ref (255), comment (TEXT)
