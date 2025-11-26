# DNS Metadata Fields - Implementation Documentation

## Overview

This document describes the implementation of business metadata fields for DNS records, including requester, expiration date, ticket reference, comment, and last-seen tracking.

## Objective

Add business metadata fields to DNS records and expose them properly through the database, model, API, and user interface. The `last_seen` field is managed exclusively server-side and cannot be modified via the interface or API create/update endpoints.

## Changes Summary

### 1. Database Schema

> **Note** : Les fichiers de migration ont été supprimés. Le schéma complet est maintenant disponible dans `database.sql`.

**Features:**
- Adds columns: `requester`, `expires_at`, `ticket_ref`, `comment`, `last_seen`, `created_at`, `updated_at`
- Creates indexes on `expires_at` and `ticket_ref` for performance

**Column Specifications:**
- `requester` VARCHAR(255) - Person or system requesting the DNS record
- `expires_at` DATETIME NULL - Expiration date for temporary records
- `ticket_ref` VARCHAR(255) - Reference to ticket system (JIRA, ServiceNow, etc.)
- `comment` TEXT - Additional notes or comments
- `last_seen` DATETIME NULL - Last time record was viewed (server-managed only)
- `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
- `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP

**Usage:**
```bash
mysql -u dns3_user -p dns3_db < database.sql
```

---

### 2. Model Updates (`includes/models/DnsRecord.php`)

**Modified Methods:**

#### `create($data, $user_id)`
- Accepts new fields: `requester`, `expires_at`, `ticket_ref`, `comment`
- **Security:** Explicitly removes `last_seen` from client data with `unset($data['last_seen'])`
- Uses prepared statements with proper parameter binding
- Returns `lastInsertId` on success

**Example:**
```php
$data = [
    'record_type' => 'A',
    'name' => 'example.com',
    'value' => '192.168.1.1',
    'requester' => 'John Doe',
    'expires_at' => '2025-12-31 23:59:00',
    'ticket_ref' => 'JIRA-123',
    'comment' => 'Production web server'
];
$record_id = $dnsRecord->create($data, $user_id);
```

#### `update($id, $data, $user_id)`
- Accepts updates to metadata fields
- **Security:** Explicitly removes `last_seen` from client data with `unset($data['last_seen'])`
- Preserves existing values if fields not provided in update
- Uses `isset()` to differentiate between NULL and missing fields

**Example:**
```php
$data = [
    'requester' => 'Jane Smith',
    'ticket_ref' => 'SNOW-456',
    'comment' => 'Updated configuration'
];
$success = $dnsRecord->update($record_id, $data, $user_id);
```

#### `markSeen($id, $user_id = null)` (NEW)
- Updates `last_seen` to current timestamp (NOW())
- Called when a record is viewed/retrieved
- Server-side only operation
- Optional `user_id` parameter for future extensions (e.g., tracking who viewed)

**Example:**
```php
$dnsRecord->markSeen($record_id, $user_id);
```

---

### 3. API Updates (`api/dns_api.php`)

**Modified Endpoints:**

#### `GET ?action=get&id=X`
- **NEW BEHAVIOR:** Calls `markSeen()` after fetching record
- Updates `last_seen` automatically when authenticated user views record
- Refreshes record data to include updated `last_seen` timestamp
- Returns record with history

**Example Response:**
```json
{
    "success": true,
    "data": {
        "id": 1,
        "name": "example.com",
        "requester": "John Doe",
        "expires_at": "2025-12-31 23:59:00",
        "ticket_ref": "JIRA-123",
        "comment": "Production server",
        "last_seen": "2024-10-20 14:30:00",
        ...
    },
    "history": [...]
}
```

#### `POST ?action=create`
- **NEW FIELDS:** Accepts `requester`, `expires_at`, `ticket_ref`, `comment`
- **Security:** Explicitly removes `last_seen` with `unset($input['last_seen'])`
- **Validation:**
  - Requester max 255 characters
  - Ticket ref max 255 characters
  - Expires_at must be valid datetime format (supports SQL and HTML5 formats)
- **Date Conversion:** Converts `YYYY-MM-DDTHH:MM` to `YYYY-MM-DD HH:MM:SS`

**Example Request:**
```javascript
fetch('/api/dns_api.php?action=create', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
        record_type: 'A',
        name: 'test.example.com',
        value: '192.168.1.100',
        ttl: 3600,
        requester: 'John Doe',
        expires_at: '2025-12-31T23:59',
        ticket_ref: 'JIRA-123',
        comment: 'Test record'
    })
});
```

#### `POST ?action=update&id=X`
- **NEW FIELDS:** Accepts updates to `requester`, `expires_at`, `ticket_ref`, `comment`
- **Security:** Explicitly removes `last_seen` with `unset($input['last_seen'])`
- **Validation:** Same as create endpoint
- **Date Conversion:** Same as create endpoint

#### `GET ?action=list`
- **NEW FIELDS:** Returns all metadata fields in response
- No changes to request format, but response includes new fields

---

### 4. UI Updates (`dns-management.php`)

**Table Columns Added:**
- Demandeur (Requester)
- Expire (Expires At)
- Vu le (Last Seen)

**Total columns:** 10 (was 7)

**Form Fields Added:**

```html
<!-- Requester -->
<input type="text" id="record-requester" name="requester" 
       placeholder="Nom de la personne ou du système">

<!-- Expiration Date -->
<input type="datetime-local" id="record-expires-at" name="expires_at">

<!-- Ticket Reference -->
<input type="text" id="record-ticket-ref" name="ticket_ref" 
       placeholder="JIRA-123 ou REF-456">

<!-- Comment -->
<textarea id="record-comment" name="comment" rows="3" 
          placeholder="Notes additionnelles..."></textarea>

<!-- Last Seen (read-only, only visible in edit mode) -->
<input type="text" id="record-last-seen" name="last_seen" 
       disabled readonly placeholder="Non encore consulté">
```

**Behavior:**
- Last seen field only shown in edit mode when value exists
- Last seen field is disabled and readonly
- Datetime-local input for expires_at (HTML5 native picker)
- Textarea for comment (multi-line support)

---

### 5. JavaScript Updates (`assets/js/dns-records.js`)

**New Helper Functions:**

#### `sqlToDatetimeLocal(sqlDatetime)`
Converts SQL format to HTML5 datetime-local format.
- Input: `"2025-12-31 23:59:00"`
- Output: `"2025-12-31T23:59"`

#### `datetimeLocalToSql(datetimeLocal)`
Converts HTML5 datetime-local to SQL format.
- Input: `"2025-12-31T23:59"`
- Output: `"2025-12-31 23:59:00"`

#### `formatDateTime(datetime)`
Formats datetime for display in table.
- Input: `"2025-12-31 23:59:00"`
- Output: `"31/12/2025 23:59"` (locale-dependent)

**Modified Functions:**

#### `loadDnsTable()`
- Updated to display new columns
- Shows formatted dates
- Shows "-" for empty values
- Updated colspan for "no records" message

#### `openEditModal(recordId)`
- Populates new form fields from record data
- Converts SQL datetime to datetime-local for expires_at
- Shows/hides last_seen field based on value existence
- Formats last_seen for display

#### `submitDnsForm(event)`
- Collects new field values
- Converts datetime-local to SQL format for expires_at
- Sends NULL for empty optional fields
- **Security:** Never sends last_seen field to server

**Example Date Conversion Flow:**

1. **From Database to UI (Edit):**
   ```
   Database: "2025-12-31 23:59:00"
   → sqlToDatetimeLocal()
   → Input field: "2025-12-31T23:59"
   ```

2. **From UI to Database (Save):**
   ```
   Input field: "2025-12-31T23:59"
   → datetimeLocalToSql()
   → API request: "2025-12-31 23:59:00"
   ```

3. **For Display in Table:**
   ```
   Database: "2025-12-31 23:59:00"
   → formatDateTime()
   → Table cell: "31/12/2025 23:59"
   ```

---

## Security Considerations

### 1. last_seen Protection

**Server-Side:**
- Model `create()` and `update()` explicitly call `unset($data['last_seen'])`
- API create and update endpoints call `unset($input['last_seen'])`
- Only `markSeen()` method can update this field
- `markSeen()` called only on authenticated GET requests

**Client-Side:**
- JavaScript never includes `last_seen` in form submissions
- Input field is disabled and readonly (defense in depth)
- Field only shown in edit mode for information

**Attack Prevention:**
Even if a malicious user crafts a request with last_seen:
```javascript
// Attacker attempts:
fetch('/api/dns_api.php?action=create', {
    body: JSON.stringify({
        name: 'test.com',
        last_seen: '2020-01-01 00:00:00'  // Malicious value
    })
});
```

**Result:** Server explicitly removes it before processing:
```php
unset($input['last_seen']);  // Removed
$dnsRecord->create($input, $user_id);  // Saved without last_seen
```

### 2. Input Validation

**Field Length Limits:**
- `requester`: 255 characters (enforced in API)
- `ticket_ref`: 255 characters (enforced in API)
- `comment`: TEXT type (65,535 bytes max)

**Date Validation:**
- Format checking: YYYY-MM-DD HH:MM:SS or YYYY-MM-DDTHH:MM
- Invalid formats return HTTP 400 error
- Automatic conversion between formats

**SQL Injection Prevention:**
- All queries use prepared statements with parameter binding
- PDO handles escaping automatically

---

## Testing Checklist

See `TEST_VALIDATION.md` for detailed test cases.

### Quick Validation:
1. ✅ Migration applies successfully
2. ✅ Create record with metadata
3. ✅ View record updates last_seen
4. ✅ Update record preserves metadata
5. ✅ last_seen cannot be set from client
6. ✅ Field validation enforced
7. ✅ Date conversion works
8. ✅ UI displays all fields

---

## API Examples

### Create Record with Metadata
```bash
curl -X POST "http://localhost:8000/api/dns_api.php?action=create" \
  -H "Content-Type: application/json" \
  -d '{
    "record_type": "A",
    "name": "server.example.com",
    "value": "192.168.1.100",
    "ttl": 3600,
    "requester": "IT Department",
    "expires_at": "2025-12-31T23:59",
    "ticket_ref": "TICKET-12345",
    "comment": "Production web server - expires end of year"
  }'
```

### Update Record Metadata Only
```bash
curl -X POST "http://localhost:8000/api/dns_api.php?action=update&id=123" \
  -H "Content-Type: application/json" \
  -d '{
    "requester": "DevOps Team",
    "expires_at": "2026-06-30T23:59",
    "comment": "Extended for another 6 months"
  }'
```

### Get Record (Triggers markSeen)
```bash
curl "http://localhost:8000/api/dns_api.php?action=get&id=123"
# Response includes updated last_seen timestamp
```

---

## Database Queries

### Find Expiring Records
```sql
SELECT id, name, requester, expires_at, ticket_ref
FROM dns_records
WHERE expires_at IS NOT NULL
  AND expires_at <= DATE_ADD(NOW(), INTERVAL 30 DAY)
  AND status = 'active'
ORDER BY expires_at ASC;
```

### Records by Requester
```sql
SELECT id, name, value, created_at, expires_at
FROM dns_records
WHERE requester LIKE '%John%'
  AND status = 'active'
ORDER BY created_at DESC;
```

### Records by Ticket
```sql
SELECT id, name, value, requester, comment
FROM dns_records
WHERE ticket_ref = 'JIRA-123'
ORDER BY created_at DESC;
```

### Recently Viewed Records
```sql
SELECT id, name, last_seen
FROM dns_records
WHERE last_seen IS NOT NULL
  AND status = 'active'
ORDER BY last_seen DESC
LIMIT 10;
```

---

## Backward Compatibility

### Existing Records
- All new fields default to NULL
- Existing functionality unchanged
- Old API clients continue to work (new fields optional)

### Migration Safety
- Idempotent - can be run multiple times
- Checks for existing columns before adding
- No data loss or modification

### API Compatibility
- Old create/update requests work without new fields
- Old list/get responses now include new fields (additive change)
- No breaking changes

---

## Future Enhancements

### Suggested Improvements:
1. **last_seen_by**: Track which user viewed the record
2. **Expiration Notifications**: Alert when records approach expires_at
3. **Bulk Operations**: Update metadata for multiple records
4. **Audit Trail**: Include metadata changes in history table
5. **Ticket Integration**: Link to external ticket systems
6. **Auto-Archive**: Automatically disable expired records

### Implementation Notes:
```php
// Example: Add last_seen_by
public function markSeen($id, $user_id = null) {
    $sql = "UPDATE dns_records 
            SET last_seen = NOW(), last_seen_by = ?
            WHERE id = ? AND status != 'deleted'";
    $stmt = $this->db->prepare($sql);
    $stmt->execute([$user_id, $id]);
}
```

---

## Troubleshooting

### Migration Fails
**Issue:** Column already exists
**Solution:** Migration is idempotent, safe to re-run

### Date Format Errors
**Issue:** Invalid expires_at date format
**Solution:** Use YYYY-MM-DD HH:MM:SS or YYYY-MM-DDTHH:MM

### last_seen Not Updating
**Issue:** Record viewed but last_seen still NULL
**Solution:** Check that user is authenticated when calling GET

### UI Fields Not Showing
**Issue:** New fields not visible in form
**Solution:** Clear browser cache and reload page

---

## Files Modified

1. `includes/models/DnsRecord.php` - MODIFIED
2. `api/dns_api.php` - MODIFIED
3. `dns-management.php` - MODIFIED
4. `assets/js/dns-records.js` - MODIFIED
5. `TEST_VALIDATION.md` - NEW (documentation)
6. `DNS_METADATA_IMPLEMENTATION.md` - NEW (this file)

> **Note** : Les fichiers de migration ont été supprimés. Le schéma complet est dans `database.sql`.

---

## Support

For questions or issues:
1. Check `TEST_VALIDATION.md` for validation procedures
2. Review error logs in browser console and PHP error log
3. Verify database schema matches migration
4. Test with browser developer tools

---

Last Updated: 2024-10-20
Version: 1.0
