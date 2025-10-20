# Pull Request: Add DNS Record Metadata Fields

## Overview
This PR implements business metadata fields for DNS records as specified in the requirements, including requester tracking, expiration dates, ticket references, comments, and server-managed last-seen timestamps.

## Changes

### 1. Database Migration
**File:** `migrations/003_add_dns_fields.sql` (NEW)
- Idempotent migration that checks for existing columns before adding
- Adds metadata columns: `requester`, `expires_at`, `ticket_ref`, `comment`, `last_seen`
- Ensures `created_at` and `updated_at` exist with proper defaults
- Creates performance indexes on `expires_at` and `ticket_ref`

### 2. Model Layer
**File:** `includes/models/DnsRecord.php` (MODIFIED)
- **create()**: Accepts new metadata fields, explicitly blocks `last_seen` from client
- **update()**: Updates metadata fields, explicitly blocks `last_seen` from client
- **markSeen()**: NEW method to update `last_seen` server-side only

### 3. API Layer
**File:** `api/dns_api.php` (MODIFIED)
- **create endpoint**: Validates and sanitizes new fields, blocks `last_seen`
- **update endpoint**: Validates and sanitizes new fields, blocks `last_seen`
- **get endpoint**: Automatically calls `markSeen()` when authenticated user views record
- Date format validation and conversion (supports SQL and HTML5 formats)
- Field length validation (requester/ticket_ref max 255 chars)

### 4. User Interface
**File:** `dns-management.php` (MODIFIED)
- Added form fields: Requester, Expiration Date (datetime-local), Ticket Reference, Comment
- Added read-only Last Seen field (only visible in edit mode)
- Updated table to show: Demandeur, Expire, Vu le columns

### 5. JavaScript
**File:** `assets/js/dns-records.js` (MODIFIED)
- Added datetime conversion helpers: `sqlToDatetimeLocal()`, `datetimeLocalToSql()`, `formatDateTime()`
- Updated form submission to include metadata fields
- **Security**: Never sends `last_seen` to server (comment in code)
- Populates new fields when opening edit modal
- Formats dates for display in table

### 6. Documentation
**Files:** `TEST_VALIDATION.md`, `DNS_METADATA_IMPLEMENTATION.md` (NEW)
- Complete test validation guide with 10 test cases
- Technical documentation with API examples
- Security considerations and troubleshooting

## Key Features

### Security
✅ **last_seen Protection**: Blocked at 4 points (Model create/update, API create/update)
✅ **Server-Side Only**: `last_seen` only updated via `markSeen()` method
✅ **Input Validation**: Field lengths, date formats enforced
✅ **SQL Injection Prevention**: All queries use prepared statements

### New Fields
- **requester** (VARCHAR 255): Person/system requesting the DNS record
- **expires_at** (DATETIME): Expiration date for temporary records
- **ticket_ref** (VARCHAR 255): Reference to ticket system (JIRA, ServiceNow, etc.)
- **comment** (TEXT): Additional notes or comments
- **last_seen** (DATETIME): Last time record was viewed (server-managed only)

### Backward Compatibility
✅ All new fields optional (default to NULL)
✅ Existing API clients work without changes
✅ Migration is idempotent (safe to re-run)
✅ No breaking changes

## Testing Instructions

### 1. Apply Migration
```bash
mysql -u dns3_user -p dns3_db < migrations/003_add_dns_fields.sql
```

Verify columns:
```sql
DESCRIBE dns_records;
```

### 2. Create Record with Metadata
1. Login as admin
2. Navigate to DNS Management
3. Create record with all metadata fields filled
4. Verify in database:
```sql
SELECT requester, expires_at, ticket_ref, comment, last_seen 
FROM dns_records 
WHERE name = 'your-test-record' 
ORDER BY created_at DESC LIMIT 1;
```
Expected: All metadata saved, `last_seen` = NULL

### 3. View Record (Test markSeen)
1. Click "Modifier" on the record
2. Note the "Vu pour la dernière fois" field
3. Verify in database:
```sql
SELECT last_seen FROM dns_records WHERE name = 'your-test-record';
```
Expected: `last_seen` now has current timestamp

### 4. Security Test (Block last_seen)
Execute in browser console:
```javascript
fetch(window.API_BASE + 'dns_api.php?action=create', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    credentials: 'same-origin',
    body: JSON.stringify({
        record_type: 'A',
        name: 'security-test.example.com',
        value: '10.0.0.1',
        last_seen: '2020-01-01 00:00:00'  // Attempt to set past date
    })
}).then(r => r.json()).then(console.log);
```

Verify in database:
```sql
SELECT last_seen FROM dns_records WHERE name = 'security-test.example.com';
```
Expected: `last_seen` = NULL (client value ignored)

### 5. Complete Test Suite
See `TEST_VALIDATION.md` for detailed test procedures (10 test cases).

## Validation

✅ PHP syntax validated (no errors)
✅ Security measures verified (4 unset points)
✅ All new fields optional
✅ Datetime conversion tested
✅ Backward compatibility confirmed

## Files Changed
```
DNS_METADATA_IMPLEMENTATION.md (NEW)
TEST_VALIDATION.md (NEW)
api/dns_api.php (MODIFIED)
assets/js/dns-records.js (MODIFIED)
dns-management.php (MODIFIED)
includes/models/DnsRecord.php (MODIFIED)
migrations/003_add_dns_fields.sql (NEW)
```

## Screenshots
_To be added after deployment to test environment_

## Checklist
- [x] Migration created and tested
- [x] Model updated with validation
- [x] API endpoints handle new fields
- [x] UI forms include new fields
- [x] JavaScript handles datetime conversion
- [x] Security measures implemented (last_seen protection)
- [x] Documentation created
- [x] Test guide provided
- [x] Backward compatibility maintained
- [ ] Integration testing (post-deployment)
- [ ] UI screenshots (post-deployment)

## Notes
- All datetime fields use DATETIME type (not TIMESTAMP) for better timezone handling
- Recommend using UTC in production with client-side conversion for display
- Migration is idempotent and safe to re-run
- No breaking changes to existing functionality

## Next Steps
1. Review code changes
2. Apply migration to test environment
3. Execute test procedures from TEST_VALIDATION.md
4. Capture UI screenshots
5. Merge to main branch
