# Zone Combobox Fix - Testing Guide

## Changes Summary

Fixed the zone combobox consistency issue where the Zones tab wasn't displaying the same zone list as the DNS tab.

### Root Cause
- `populateZoneListForDomain` helper was missing from zone-combobox.js
- Zones page was using old flow (window.ZONES_ALL / fetchZonesForMaster)
- DNS page was using the correct shared helpers

### Files Modified

1. **assets/js/zone-combobox.js**
   - Added `populateZoneListForDomain(domainId)` function
   - Exports to window.populateZoneListForDomain and window.ZoneComboboxHelpers.populateZoneListForDomain
   - Makes API call to list_zone_files with fallback to list_zones_by_domain
   - Returns ordered zones using makeOrderedZoneList (master first, then includes sorted A-Z)

2. **assets/js/zone-files.js**  
   - Updated `populateZoneFileCombobox` to use shared helper when available
   - Uses `sharedHelperSucceeded` flag to properly handle fallbacks
   - Always calls `setZoneFileComboboxEnabled(true)` after population
   - Added defensive checks and console.debug logging

## Testing Instructions

### Prerequisites
- Access to DNS3 application
- Admin user account
- At least one master zone with multiple includes

### Test Cases

#### 1. Verify Zone List Consistency Between Tabs

**DNS Tab**:
1. Navigate to dns-management.php (DNS Records page)
2. Open browser console (F12)
3. Select a domain in the "Domaine" combobox
4. Check the "Fichier de zone" dropdown
5. Note the order: master first, then includes alphabetically (A-Z)

**Zones Tab**:
1. Navigate to zone-files.php (Zone Files page)
2. Open browser console (F12)
3. Select the SAME domain in the "Domaine" combobox
4. Check the "Fichier de zone" dropdown
5. Verify: **Same order as DNS tab** (master first, then includes A-Z)

#### 2. Console Verification

After selecting a domain on Zones page, check console for:

Expected messages:
```
[populateZoneFileCombobox] Using shared helper populateZoneListForDomain
[populateZoneListForDomain] Fetched and ordered X zones for domain Y
[populateZoneFileCombobox] Shared helper returned X zones
```

Should NOT see:
```
populateZoneListForDomain: undefined
[populateZoneFileCombobox] Shared helper not available
```

#### 3. Verify Helper Exports

In browser console on Zones page, run:
```javascript
typeof window.populateZoneListForDomain
// Expected: "function"

typeof window.makeOrderedZoneList
// Expected: "function"

typeof window.ZoneComboboxHelpers.populateZoneListForDomain
// Expected: "function"
```

#### 4. Test Fallback Behavior

To test fallback (if needed):
1. In browser console, temporarily delete the helper:
   ```javascript
   delete window.populateZoneListForDomain
   ```
2. Select a domain
3. Verify the combobox still populates (using fallback implementation)
4. Console should show: `[populateZoneFileCombobox] Shared helper not available, using fallback implementation`
5. Refresh page to restore the helper

#### 5. Test Empty Result Handling

1. Create a master zone with NO includes
2. Select it in both tabs
3. Verify only the master appears in "Fichier de zone" dropdown
4. Should not trigger fallback unnecessarily

## Expected Behavior

### Before Fix
- Zones tab: inconsistent ordering or missing zones
- Console: `populateZoneListForDomain: undefined`
- Zones tab uses different API calls than DNS tab

### After Fix
- Both tabs: identical zone ordering (master first, includes A-Z)
- Console: `populateZoneListForDomain: function`
- Both tabs use the same shared helper
- Fallback works if helper fails

## Script Loading Order Verification

The correct loading order in both pages:
1. zone-combobox.js (defines helpers)
2. zone-files.js or dns-records.js (uses helpers)

Verify in page source:
- zone-files.php: `<script src=".../zone-combobox.js"></script>` before `<script src=".../zone-files.js"></script>`
- dns-management.php: `<script src=".../zone-combobox.js"></script>` before `<script src=".../dns-records.js"></script>`

## Troubleshooting

### Issue: populateZoneListForDomain still undefined

**Check**:
1. Clear browser cache and reload
2. Verify zone-combobox.js loaded before zone-files.js in Network tab
3. Check zone-combobox.js for syntax errors in Console

### Issue: Zones still not matching between tabs

**Check**:
1. Look for errors in console
2. Verify API calls are succeeding (Network tab)
3. Check if fallback is being used unnecessarily
4. Verify makeOrderedZoneList is being called

### Issue: Combobox not enabling after domain selection

**Check**:
1. Verify setZoneFileComboboxEnabled is being called (console)
2. Check if there are JavaScript errors preventing execution
3. Verify the function exists: `typeof window.setZoneFileComboboxEnabled`

## Success Criteria

✅ Zone list order is identical in DNS and Zones tabs
✅ Console shows `populateZoneListForDomain: function`  
✅ Shared helper is being used (check console logs)
✅ Fallback works if helper fails
✅ No JavaScript errors in console
✅ CodeQL security scan: 0 alerts
✅ All syntax checks pass

## Notes

- The helper uses the zone-files.js zoneApiCall pattern: `{ params: { domain_id: ... } }`
- Two different zoneApiCall implementations exist (dns-records.js vs zone-files.js)
- API parameter names (zone_id vs domain_id) are tried for backward compatibility
- Defensive programming ensures Zones page continues working even if helper fails
