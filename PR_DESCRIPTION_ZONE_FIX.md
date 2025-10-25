# PR: fix(api/testdata/ui): return zone_file_id & zone_name; ensure generator fills zone_file_id; add UI fallback

## Summary

This PR addresses the issue where the DNS Records table shows the zone filename but the edit popup does not pre-select the zone (empty select). The root cause was:

1. Inconsistent zone field handling in API responses
2. Missing defensive logging to debug zone field issues
3. Legacy column references in SQL queries that may not exist in all environments
4. Test data generator not populating compatibility columns when present
5. Insufficient error logging in the JavaScript UI

## Changes Made

### 1. `api/dns_api.php` - Enhanced API Error Handling and Logging

**Changes:**
- Added defensive logging for records missing `zone_file_id` or `zone_name` in both list and get handlers
- Enhanced error logging with action context and stack traces to aid debugging
- Ensured consistent JSON structure: `{ success: true, data: [...], count: N }`

**Impact:**
- Server logs will now show warnings when records are missing zone information
- Better debugging capabilities for production issues
- Errors include full context (action, trace) for troubleshooting

### 2. `includes/models/DnsRecord.php` - Improved Zone Field Handling

**Changes:**
- Removed references to legacy columns (`dr.zone_name`, `dr.zone`) in SQL queries
- Changed to `COALESCE(zf.name, '')` to always return non-null zone_name
- Added explicit null checks and empty string defaults for zone_name and zone_file_name
- Ensured all returned records have these fields populated (even if empty)

**Impact:**
- Works correctly even when legacy columns don't exist
- API responses always contain zone_name and zone_file_name fields
- Prevents null pointer issues in frontend

### 3. `assets/js/dns-records.js` - Robust URL Construction and Zone Selection

**Changes:**
- Updated `getApiUrl()` and `getZoneApiUrl()` with fallbacks: `window.API_BASE || window.BASE_URL || '/api/'`
- Added URL normalization to ensure proper path construction
- Added `console.debug()` logging for all API requests and responses
- Enhanced error logging with detailed status, headers, and response bodies
- Improved `openEditModal()` zone selection fallback:
  - First tries to select by `zone_file_id`
  - Verifies the option exists
  - Falls back to matching by zone name if needed
  - Logs all selection attempts for debugging

**Impact:**
- Works even if `window.API_BASE` is not defined
- Browser console shows detailed API request/response logs
- Zone dropdown properly pre-selects even with partial data
- Easier debugging of API issues in production

### 4. `scripts/generate_test_data.php` - Compatibility Column Support

**Changes:**
- Added `SHOW COLUMNS` detection for compatibility columns: `zone`, `zone_name`, `zone_file_name`, `zone_file`
- After each record insert, updates compatibility columns if they exist
- Fetches zone file name and filename from `zone_files` table
- Only updates columns that exist in the schema

**Impact:**
- Generator works correctly across different schema versions
- Compatibility with environments that have legacy columns
- Test data is fully populated and functional for all scenarios

## Testing Instructions

### Prerequisites
```bash
# Ensure you have a user created
php scripts/create_admin.php

# Note the user ID (typically 1)
```

### Test Steps

#### 1. Clean existing data
```bash
./scripts/cleanup_zones_and_records.sh
# Confirm when prompted
```

#### 2. Generate test data
```bash
php scripts/generate_test_data.php --records=200 --user=1
```

**Expected Output:**
- Should show "Checking for compatibility columns..."
- Should list any detected compatibility columns
- Should create master zones, include zones, and DNS records
- Should show progress every 100 records

#### 3. Verify data in database

**Check zone_file_id population:**
```sql
-- All records should have zone_file_id set
SELECT COUNT(*) as total_records,
       COUNT(zone_file_id) as with_zone_file_id,
       COUNT(*) - COUNT(zone_file_id) as missing_zone_file_id
FROM dns_records;
```

**Expected:** `missing_zone_file_id` should be 0

**Check if zone fields are joinable:**
```sql
-- Verify records can join to zone_files
SELECT 
    COUNT(dr.id) as total_records,
    COUNT(zf.id) as with_valid_zone,
    COUNT(dr.id) - COUNT(zf.id) as orphaned_records
FROM dns_records dr
LEFT JOIN zone_files zf ON dr.zone_file_id = zf.id;
```

**Expected:** `orphaned_records` should be 0

**Sample records with zone info:**
```sql
-- Get sample records with zone details
SELECT 
    dr.id,
    dr.name,
    dr.record_type,
    dr.zone_file_id,
    zf.name as zone_name,
    zf.filename as zone_file_name
FROM dns_records dr
LEFT JOIN zone_files zf ON dr.zone_file_id = zf.id
LIMIT 10;
```

**Expected:** All rows should have non-null zone_file_id, zone_name, and zone_file_name

#### 4. Test UI functionality

1. **Open the DNS management page** in your browser
2. **Open browser console** (F12) and go to Console tab
3. **Refresh the page**

**Check console logs:**
- Should see `[API Request] Constructed URL: ...` for API calls
- Should see `[API Response] Success: ...` with response data
- Should NOT see any errors about missing API_BASE

4. **Click "Créer" button** to open create modal
   - Zone selector should be populated with options

5. **Edit an existing record**
   - Click "Modifier" on any record
   - **Check that zone dropdown is pre-selected** (not empty)
   - Console should show `[Edit Modal] Set zone_file_id: X`
   - If zone_file_id is missing, should see fallback messages

6. **Check API responses in Network tab:**
   - Go to Network tab, filter by XHR
   - Reload page to trigger API calls
   - Click on `dns_api.php?action=list` request
   - Check Response tab
   - Should see JSON with `success: true, data: [...], count: N`
   - Each record in data array should have:
     - `zone_file_id`
     - `zone_name`
     - `zone_file_name`

### SQL Verification Queries

**Check compatibility column population (if they exist):**
```sql
-- Only run if your schema has these columns
SELECT 
    COUNT(*) as total,
    COUNT(zone_file_id) as has_zone_file_id,
    COUNT(zone) as has_zone,
    COUNT(zone_name) as has_zone_name,
    COUNT(zone_file_name) as has_zone_file_name
FROM dns_records;
```

**Verify consistency between canonical and compatibility columns:**
```sql
-- If you have compatibility columns, verify they match
SELECT 
    dr.id,
    dr.zone_file_id,
    zf.name as canonical_zone_name,
    zf.filename as canonical_zone_file_name,
    dr.zone_name as compat_zone_name,
    dr.zone_file_name as compat_zone_file_name
FROM dns_records dr
LEFT JOIN zone_files zf ON dr.zone_file_id = zf.id
WHERE dr.zone_name != zf.name
   OR dr.zone_file_name != zf.filename
LIMIT 10;
```

**Expected:** No mismatches (empty result)

## Security Considerations

- No new security vulnerabilities introduced
- All database queries use prepared statements
- Error logging does not expose sensitive data
- JavaScript console logging uses debug level (can be filtered out in production)

## Breaking Changes

None. All changes are backward compatible.

## Rollback Plan

If issues are discovered:
```bash
git revert <commit-hash>
```

The changes are non-destructive and do not modify the database schema.

## Additional Notes

- The `COALESCE(zf.name, '')` approach assumes zone_files table always has valid data
- JavaScript fallback logic handles edge cases where zone_file_id exists but option is not found
- Compatibility column detection is automatic - no configuration needed
- All logging is defensive and will not break functionality if log targets are unavailable

## Checklist

- [x] Code follows existing style and patterns
- [x] PHP syntax validated (`php -l`)
- [x] JavaScript syntax validated (`node -c`)
- [x] SQL queries use prepared statements
- [x] Error handling includes logging
- [x] Backward compatible
- [ ] Manually tested in browser (pending deployment)
- [ ] SQL verification queries run (pending deployment)
- [ ] Code review requested
- [ ] Security scan passed
