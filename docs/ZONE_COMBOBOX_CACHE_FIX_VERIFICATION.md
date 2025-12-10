# Zone Combobox Cache Fix - Verification Guide

## Overview

This document describes how to verify the fix for the zone combobox `CURRENT_ZONE_LIST` cache overwrite issue.

## Problem Fixed

When a domain was selected on the Zones page, the `window.CURRENT_ZONE_LIST` cache was being overwritten by the `refresh()` method, causing:
- Race conditions where the cache could be cleared unexpectedly
- Potential exposure of zones from other domains
- UI "flash" as the cache was repopulated

## Root Cause

The `showZones()` function in `initServerSearchCombobox` unconditionally overwrote `window.CURRENT_ZONE_LIST = zones;` even when called from `refresh()` with zones that were already derived from `CURRENT_ZONE_LIST`.

## Solution

Added `updateCache` parameter (default: `true`) to `showZones()`:
- `refresh()` now passes `updateCache=false` to prevent cache overwrite
- User interactions (typing, focus) still update the cache as expected

## Verification Steps

### Prerequisites
- Access to DNS3 application (zone-files.php page)
- Browser with developer console (F12)
- At least one master zone with multiple includes

### Test 1: Verify Cache Preservation on Domain Selection

1. Navigate to zone-files.php (Zones page)
2. Open browser console (F12)
3. Run this command to monitor cache changes:
   ```javascript
   let lastCache = null;
   setInterval(() => {
     if (window.CURRENT_ZONE_LIST !== lastCache) {
       console.log('[CACHE MONITOR]', 'CURRENT_ZONE_LIST changed:', 
         'length =', (window.CURRENT_ZONE_LIST || []).length,
         'zones =', (window.CURRENT_ZONE_LIST || []).map(z => z.name || z.filename));
       lastCache = window.CURRENT_ZONE_LIST;
     }
   }, 100);
   ```
4. Select a domain in the "Domaine" combobox
5. Observe console logs

**Expected behavior:**
- Cache is populated once with domain-specific zones
- Cache is NOT overwritten by refresh
- No "flash" or multiple cache updates for a single domain selection

**What to look for:**
```
[populateZoneFileCombobox] Final items for combobox: X (master first, then includes sorted A-Z)
[syncZoneFileComboboxInstance] Successfully synced combobox state
[CACHE MONITOR] CURRENT_ZONE_LIST changed: length = X zones = [master, include1, include2, ...]
```

**Should NOT see:**
```
[CACHE MONITOR] CURRENT_ZONE_LIST changed: length = 0
[CACHE MONITOR] CURRENT_ZONE_LIST changed: length = X  ← multiple times for same selection
```

### Test 2: Verify Dropdown Does NOT Auto-Display

1. Navigate to zone-files.php (Zones page)
2. Open browser console (F12)
3. Select a domain in the "Domaine" combobox
4. Observe the "Fichier de zone" combobox

**Expected behavior:**
- Dropdown list (UL) does NOT auto-display after domain selection
- Input field is populated with master zone name
- Dropdown only appears when user clicks or focuses the input

**Visual check:**
- After domain selection, the zone file combobox input shows the master zone name
- The dropdown list (UL) is hidden (`display: none`, `aria-hidden: true`)
- Clicking the input shows the dropdown with ordered zones

### Test 3: Verify Server Search Still Updates Cache

1. Navigate to zone-files.php (Zones page)
2. Open browser console (F12)
3. Focus the "Fichier de zone" input
4. Type a search query (at least 2 characters) to trigger server search
5. Observe console logs

**Expected behavior:**
- Server search is triggered
- `CURRENT_ZONE_LIST` is updated with server results
- Dropdown shows filtered results

**Console output:**
```
[initServerSearchCombobox] server search for query: <query>
[initServerSearchCombobox] server returned X results
```

### Test 4: Verify Client Filtering Still Works

1. Navigate to zone-files.php (Zones page)
2. Select a domain
3. Focus the "Fichier de zone" input
4. Type a single character (to trigger client filtering, not server search)
5. Observe the dropdown

**Expected behavior:**
- Client filtering is used (query < 2 chars)
- Dropdown shows zones matching the query
- Zones are filtered from `CURRENT_ZONE_LIST`

**Console output:**
```
[initServerSearchCombobox] client filter for query: <query>
```

### Test 5: Cross-Check with DNS Tab

1. Navigate to dns-management.php (DNS Records page)
2. Select a domain
3. Observe the "Fichier de zone" combobox behavior
4. Navigate to zone-files.php (Zones page)
5. Select the SAME domain
6. Compare the behavior

**Expected behavior:**
- Both tabs have identical behavior:
  - Master zone is auto-selected in the input
  - Dropdown does NOT auto-display
  - Zone list is ordered (master first, includes A-Z)
  - Cache is populated once and preserved

## Console Commands for Debugging

### Check if fix is applied
```javascript
// Check showZones signature (should have 3 parameters)
console.log(window.initServerSearchCombobox.toString().match(/function showZones\([^)]+\)/));
// Expected: "function showZones(zones, showList = false, updateCache = true)"
```

### Monitor CURRENT_ZONE_LIST changes
```javascript
let lastLength = -1;
setInterval(() => {
  const len = (window.CURRENT_ZONE_LIST || []).length;
  if (len !== lastLength) {
    console.log('[MONITOR]', 'CURRENT_ZONE_LIST length changed:', lastLength, '→', len);
    lastLength = len;
  }
}, 100);
```

### Inspect current cache
```javascript
console.table(
  (window.CURRENT_ZONE_LIST || []).map(z => ({
    id: z.id,
    name: z.name || z.filename,
    type: z.file_type,
    parent: z.parent_id
  }))
);
```

## Success Criteria

✅ Cache is populated once per domain selection  
✅ Cache is NOT overwritten by refresh  
✅ Dropdown does NOT auto-display on domain selection  
✅ Server search still updates cache correctly  
✅ Client filtering works correctly  
✅ Behavior matches DNS tab  
✅ No JavaScript errors in console  
✅ CodeQL security scan: 0 alerts  

## Troubleshooting

### Issue: Cache is still being overwritten

**Check:**
1. Clear browser cache and hard reload (Ctrl+Shift+R)
2. Verify zone-files.js loaded correctly (Network tab)
3. Check for JavaScript errors in console
4. Verify the fix is applied (see "Console Commands" above)

### Issue: Dropdown auto-displays on domain selection

**Check:**
1. Verify `showList=false` in refresh method
2. Check if there are custom event handlers interfering
3. Inspect `populateComboboxList` calls in console

### Issue: Server search not working

**Check:**
1. Verify query length ≥ 2 characters
2. Check Network tab for API calls
3. Verify `serverSearchZones` function exists
4. Check console for server search errors

## Related Documentation

- [ZONE_COMBOBOX_FIX_TESTING.md](ZONE_COMBOBOX_FIX_TESTING.md) - Previous combobox fix testing
- [ZONE_COMBOBOX_SEARCH_FIX_TEST.md](ZONE_COMBOBOX_SEARCH_FIX_TEST.md) - Server search fix testing
- [TESTING_GUIDE.md](TESTING_GUIDE.md) - General testing guide

## Technical Details

### Code Changes

File: `assets/js/zone-files.js`

1. Modified `showZones()` function signature:
   ```javascript
   // Before:
   function showZones(zones, showList = false) { ... }
   
   // After:
   function showZones(zones, showList = false, updateCache = true) { ... }
   ```

2. Modified cache update logic:
   ```javascript
   // Before:
   window.CURRENT_ZONE_LIST = zones;
   
   // After:
   if (updateCache) {
       window.CURRENT_ZONE_LIST = zones;
   }
   ```

3. Modified `refresh()` method:
   ```javascript
   // Before:
   refresh: () => {
       const zones = getClientZones('');
       showZones(zones, false);
   }
   
   // After:
   refresh: () => {
       const zones = getClientZones('');
       showZones(zones, false, false);  // updateCache=false
   }
   ```

### Impact Analysis

**Functions affected:**
- `showZones()` - Added `updateCache` parameter
- `refresh()` - Passes `updateCache=false`

**Functions NOT affected:**
- User input handler - Still uses default `updateCache=true`
- Focus handler - Still uses default `updateCache=true`
- Server search - Still updates cache correctly

**Backward compatibility:**
- Default parameter ensures existing calls work correctly
- No breaking changes to public API
