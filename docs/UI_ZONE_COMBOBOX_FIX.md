# UI Zone Combobox and Modal Parent Fix

## Overview

This document describes the fixes applied to the zone file combobox and zone modal parent selection in the DNS3 web interface.

## Issues Fixed

### 1. Zone File Combobox Not Showing All Zones

**Problem**: The zone file combobox (`zone-file-input`) did not consistently display all expected zone files (master + includes) for a selected domain.

**Root Cause**: The `file_type` field in zone records may contain variations in case or whitespace (e.g., `'include'`, `' include'`, `'Include'`, or even `null`), causing strict equality checks to fail.

**Solution**: 
- Normalized all `file_type` checks to use `.toLowerCase().trim()` before comparison
- Added null/undefined handling to treat missing `file_type` gracefully
- Updated the following functions:
  - `getFilteredZonesForCombobox()`
  - `populateZoneFileCombobox()`
  - `populateIncludeParentCombobox()`

**Code Example**:
```javascript
// Before (strict equality)
if (zone.file_type !== 'include') return false;

// After (normalized comparison)
const fileType = (zone.file_type || '').toLowerCase().trim();
if (fileType !== 'include') return false;
```

### 2. Zone Modal Parent Selection Not Displayed

**Problem**: When opening the zone edit modal for an include zone that has a parent, the Parent dropdown showed "Aucun parent" instead of the actual parent zone name.

**Root Causes**:
1. The global `window.currentZone` variable was not set before calling `loadParentOptions()`
2. The `loadParentOptions()` function relied on `currentZone` being available, but had no fallback mechanism

**Solution**:
- Set `window.currentZone = zone` immediately after fetching zone data in `openZoneModal()`, BEFORE calling `loadParentOptions()`
- Added fallback logic in `loadParentOptions()` to fetch zone data if `currentZone` is not available
- Added debug logging to warn when `currentZone` is missing
- Improved parent option selection logic with both string and numeric ID comparison

**Code Changes**:
```javascript
// In openZoneModal() - set currentZone globally BEFORE loading parent options
currentZoneId = zoneId;
currentZone = zone;
window.currentZone = zone; // NEW: Expose globally for helper functions
originalZoneData = JSON.parse(JSON.stringify(zone));

// In loadParentOptions() - added fallback
if (!currentZone && !window.currentZone) {
    console.warn('[loadParentOptions] currentZone is not set, using fallback');
    // Fetch zone data using zoneId from hidden field
    // ...
}
```

## Debug Logging Added

To facilitate troubleshooting, debug logging has been added to key functions:

### `populateZoneFileCombobox()`
- Logs the master zone ID and name
- Logs the number of include zones found in cache
- Logs when API fetch is triggered vs. cache hit
- Logs the final combobox items count

### `populateIncludeParentCombobox()`
- Logs the starting master ID
- Logs when include-to-master resolution occurs
- Logs the number of zones fetched
- Logs fallback operations

### `loadParentOptions()`
- Warns when `currentZone` is not available
- Logs which parent option was selected
- Warns if a provided parent ID is not found in options

**Viewing Debug Logs**:
```javascript
// In browser console, check for debug messages:
// [populateZoneFileCombobox] masterZoneId: 42 masterZone: example.com
// [populateZoneFileCombobox] includeZones from cache: 5
// [loadParentOptions] Selected parent: fr.gouv.intradef id: 123
```

## Cache Deduplication Enhancement

**Problem**: When merging fetched zones into the `window.ZONES_ALL` cache, numeric ID comparisons could lead to duplicates due to type coercion issues.

**Solution**: 
- Changed all deduplication logic to compare IDs as strings: `String(x.id) === String(z.id)`
- Ensures both `'42'` and `42` are treated as the same zone

**Code**:
```javascript
// Before
if (!window.ZONES_ALL.find(x => x.id === z.id)) { ... }

// After (string comparison)
if (!window.ZONES_ALL.find(x => String(x.id) === String(z.id))) { ... }
```

## ACL Impact on Visible Items

**Important Note for Non-Admin Users**: 

The zone API endpoints apply Access Control List (ACL) filtering for non-admin users. This means:

1. **Admin Users**: Can see ALL zones in the system
2. **Non-Admin Users**: Only see zones they have explicit permissions for

When troubleshooting "missing zones" in the combobox:
- First verify the user's ACL permissions for the zone in question
- Check the API response in browser DevTools Network tab
- Admin users will always see more zones than non-admin users

**Example**: If an admin sees 10 includes for a domain but a non-admin sees only 3, this is expected behavior controlled by ACL rules in the database.

## Testing Instructions

### Manual Test 1: Zone Modal Parent Display

1. Navigate to the "Gestion des fichiers de zone" page
2. Find an include zone that has a parent (visible in the "Parent" column)
3. Click on the zone row or "Modifier" button to open the edit modal
4. Verify that the "Parent" dropdown shows the correct parent zone name (e.g., `fr.gouv.intradef (master)`)
5. The parent should match the value shown in the table's "Parent" column

**Expected Result**: Parent dropdown displays the correct parent name, not "Aucun parent"

### Manual Test 2: Zone File Combobox Population

1. Navigate to the "Gestion des fichiers de zone" page
2. In the domain combobox, select a master domain (e.g., `example.com`)
3. Click into the "Fichier de zone" combobox (do NOT type anything)
4. Observe the dropdown list

**Expected Result**: 
- The list should contain the master zone + all its includes
- Verify count matches what you see in the table below
- If you're an admin, you should see all zones
- If you're a non-admin, you should see only zones you have access to

### Console Verification Tests

Open browser DevTools Console and run the following checks:

```javascript
// Test 1: Verify ZONES_ALL cache is populated
console.log('ZONES_ALL count:', window.ZONES_ALL.length);
console.log('First 3 zones:', window.ZONES_ALL.slice(0, 3));

// Test 2: Verify CURRENT_ZONE_LIST after selecting domain
// (After selecting a domain in the UI)
console.log('CURRENT_ZONE_LIST count:', window.CURRENT_ZONE_LIST.length);
console.log('Zones:', window.CURRENT_ZONE_LIST.map(z => z.name));

// Test 3: Verify currentZone when modal is open
// (After opening a zone modal)
console.log('currentZone:', window.currentZone);
console.log('currentZone name:', window.currentZone?.name);
console.log('currentZone parent_id:', window.currentZone?.parent_id);
```

### Automated Testing (Future)

Consider adding automated tests for:
- Zone cache population and deduplication
- Parent selection in modal after openZoneModal
- Combobox filtering with various file_type values
- ACL-based filtering for different user roles

## Files Modified

- `assets/js/zone-files.js`: Main changes to zone management UI

## Related Documentation

- [IMPORT_INCLUDES_GUIDE.md](./IMPORT_INCLUDES_GUIDE.md) - BIND zone import documentation
- [ZONE_FILES_IMPLEMENTATION_SUMMARY.md](./ZONE_FILES_IMPLEMENTATION_SUMMARY.md) - Zone files feature overview
- [ZONEFILE_COMBOBOX_VERIFICATION.md](./ZONEFILE_COMBOBOX_VERIFICATION.md) - Combobox verification tests

## Troubleshooting

### Problem: Combobox still shows fewer zones than expected

**Check**:
1. Open browser console and check for debug logs starting with `[populateZoneFileCombobox]`
2. Verify the user has ACL permissions for the "missing" zones
3. Check the API response in Network tab for `zone_api.php?action=list_zones`
4. Verify zone `file_type` in database is set correctly

### Problem: Parent still shows "Aucun parent" in modal

**Check**:
1. Open browser console before opening the modal
2. Look for warning: `[loadParentOptions] currentZone is not set, using fallback`
3. Check if zone object has a valid `parent_id` field
4. Verify the parent zone exists and is not deleted (`status != 'deleted'`)
5. Run `console.log(window.currentZone)` after opening modal to verify currentZone is set

## Performance Considerations

The changes maintain existing performance characteristics:
- Cache-first approach for zone lists (minimizes API calls)
- Debug logging uses `console.debug()` which can be filtered out in production
- String comparisons for IDs have negligible performance impact
- No additional HTTP requests are made unless cache is empty

## Future Improvements

Potential enhancements for future iterations:

1. **Type Safety**: Use TypeScript to ensure `file_type` values are always normalized
2. **Unit Tests**: Add Jest tests for cache deduplication and normalization logic
3. **Real-time Updates**: Implement WebSocket or polling for zone cache updates
4. **Better Error Messages**: Show user-friendly messages when zones are filtered by ACL
5. **Caching Strategy**: Consider IndexedDB for persistent client-side zone cache
