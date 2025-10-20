# Type-Specific Fields Implementation - Complete Summary

## Overview
This implementation adds dedicated database columns for each DNS record type (A, AAAA, CNAME, PTR, TXT) instead of using a generic `value` field. The system is now limited to managing only these 5 basic record types.

## What Changed

### 1. Database Schema
**New Columns in `dns_records` table:**
- `address_ipv4` VARCHAR(15) - for A records
- `address_ipv6` VARCHAR(45) - for AAAA records
- `cname_target` VARCHAR(255) - for CNAME records
- `ptrdname` VARCHAR(255) - for PTR records
- `txt` TEXT - for TXT records

**New Columns in `dns_record_history` table:**
Same 5 columns added for complete history tracking.

**Indexes Added:**
- `idx_address_ipv4`
- `idx_address_ipv6`
- `idx_cname_target`

**Migration File:** `migrations/005_add_type_specific_fields.sql`
- Idempotent (can be run multiple times safely)
- Automatically migrates existing data from `value` to dedicated columns
- Keeps `value` column for backward compatibility and rollback

### 2. Backend Model (`includes/models/DnsRecord.php`)

**New Helper Methods:**
- `getValueFromDedicatedField()` - Computes value from dedicated columns
- `getValueFromDedicatedFieldData()` - Gets value from input data
- `mapValueToDedicatedField()` - Maps value alias to dedicated field
- `extractDedicatedFields()` - Extracts dedicated fields from input

**Modified Methods:**
- `search()` - Now computes `value` field from dedicated columns
- `getById()` - Now computes `value` field from dedicated columns
- `create()` - Writes to dedicated columns, accepts value alias
- `update()` - Writes to dedicated columns, accepts value alias
- `writeHistory()` - Includes dedicated fields in history

### 3. API (`api/dns_api.php`)

**Type Restrictions:**
- Only A, AAAA, CNAME, PTR, TXT are allowed
- MX, SRV, NS, SOA return 400 error

**Validation Updates:**
- `validateRecordByType()` now validates dedicated fields
- Accepts both dedicated field names and `value` alias
- Type-specific semantic validation (IPv4/IPv6 format, hostname validation, etc.)

**Security:**
- `last_seen` is always removed from input (unset)
- Server-managed fields cannot be set by clients

### 4. Frontend (`dns-management.php`)

**Form Changes:**
- Removed: Single `record-value` field
- Removed: `record-priority-group` field
- Added: 5 dedicated field groups (one for each type)
  - `record-address-ipv4-group`
  - `record-address-ipv6-group`
  - `record-cname-target-group`
  - `record-ptrdname-group`
  - `record-txt-group`

**Type Filter:**
Updated dropdown to show only 5 supported types.

### 5. JavaScript (`assets/js/dns-records.js`)

**Field Visibility:**
- `updateFieldVisibility()` - Shows/hides fields based on record type
- Only one dedicated field visible at a time

**Validation:**
- Updated `REQUIRED_BY_TYPE` for dedicated fields
- Updated `validatePayloadForType()` for semantic validation
- Type-specific validation (IPv4, IPv6, hostname, text)

**Payload Building:**
- `submitDnsForm()` builds payload with both dedicated field AND value alias
- Never includes `last_seen` in payload

**Edit Modal:**
- `openEditModal()` populates dedicated fields from record data
- Handles fallback to `value` field for backward compatibility

### 6. Documentation

**Updated Files:**
- `DNS_MANAGEMENT_GUIDE.md` - Updated examples and field descriptions
- `TYPE_SPECIFIC_FIELDS_TEST_PLAN.md` - Comprehensive test plan (new)
- `UI_CHANGES_DOCUMENTATION.md` - Visual UI changes documentation (new)

## Design Decisions

### Option: accept-value ✅
API accepts `value` as an alias for backward compatibility.
```json
// Both formats work
{"record_type": "A", "address_ipv4": "192.168.1.1"}
{"record_type": "A", "value": "192.168.1.1"}
```

### Option: keep-temporary ✅
`value` column kept in database for one release to allow rollback.

### Option: implicit-class ✅
No `class` column added to database (implicitly "IN").

### Option: ptr-require-reverse ✅
PTR records require user to provide the reverse DNS name.

## Validation Rules

### A Records
- Field: `address_ipv4`
- Format: Valid IPv4 address
- Example: "192.168.1.1"

### AAAA Records
- Field: `address_ipv6`
- Format: Valid IPv6 address
- Example: "2001:db8::1"

### CNAME Records
- Field: `cname_target`
- Format: Valid hostname (no IP addresses)
- Example: "target.example.com"

### PTR Records
- Field: `ptrdname`
- Format: Valid hostname (reverse DNS name)
- Example: "1.1.168.192.in-addr.arpa"

### TXT Records
- Field: `txt`
- Format: Any non-empty text
- Example: "v=spf1 include:_spf.example.com ~all"

## Testing

### Automated Tests
- PHP syntax validation: ✅ All files pass
- Helper function unit tests: ✅ All 8 tests pass

### Manual Testing Required
See `TYPE_SPECIFIC_FIELDS_TEST_PLAN.md` for comprehensive test plan.

## Files Modified

1. **migrations/005_add_type_specific_fields.sql** (new)
2. **includes/models/DnsRecord.php** (modified)
3. **api/dns_api.php** (modified)
4. **dns-management.php** (modified)
5. **assets/js/dns-records.js** (modified)
6. **DNS_MANAGEMENT_GUIDE.md** (modified)
7. **TYPE_SPECIFIC_FIELDS_TEST_PLAN.md** (new)
8. **UI_CHANGES_DOCUMENTATION.md** (new)

## Conclusion

This implementation successfully adds type-specific fields for DNS records while maintaining backward compatibility. The migration is idempotent and safe, with the ability to rollback if needed.
