# Zone Combobox Auto-Display Fix - Verification Guide

## Problem Statement

The Zones tab zone file combobox (`#zone-file-list`) was automatically displaying the dropdown list when a domain was selected, showing all zones in `window.CURRENT_ZONE_LIST`. This behavior was inconsistent with the DNS tab, which correctly:
- Updates `CURRENT_ZONE_LIST` with domain-specific zones (master + includes)
- Does NOT automatically display the dropdown list
- Requires explicit user interaction (click/focus) to show the list

## Root Cause

The real root cause was in the `initServerSearchCombobox()` function in `assets/js/zone-files.js`:

1. **`showZones()` function** (line 693): Called `populateComboboxList()` without passing a `showList` parameter, defaulting to `true`
2. **`refresh()` method** (line 837): Called `showZones()` without controlling list visibility
3. **Trigger**: When `populateZoneFileCombobox()` called `ZONE_FILE_COMBOBOX_INSTANCE.refresh()` (line 1679), it caused the list to auto-display

The previous fix attempt at line 1686 only addressed one call to `populateComboboxList`, but the `refresh()` method continued to show the list.

## Solution

Modified `assets/js/zone-files.js` to control list visibility at the source:

1. **Updated `showZones()` function** (line 693): Added `showList` parameter with default value `false`
2. **Updated `refresh()` method** (line 837): Explicitly passes `showList=false` to prevent auto-display
3. **Updated input/focus handlers** (lines 793, 804, 810): Pass `showList=true` when user is actively interacting
4. **Removed redundant code** (line 1686): Removed duplicate `populateComboboxList` call as refresh() now handles this

```javascript
// Before fix:
function showZones(zones) {
    window.CURRENT_ZONE_LIST = zones;
    populateComboboxList(list, zones, mapZoneItem, onSelect); // showList defaults to true!
}

// After fix:
function showZones(zones, showList = false) {
    window.CURRENT_ZONE_LIST = zones;
    populateComboboxList(list, zones, mapZoneItem, onSelect, showList);
}
```

## Expected Behavior After Fix

### When User Selects a Domain (Zones Tab)

1. **Domain Selection**: User selects a domain from the domain combobox
2. **Zone List Population**: 
   - `onZoneDomainSelected()` is called
   - `populateZoneFileCombobox(masterZoneId, null, true)` is called
   - Domain-specific zones are fetched (master + includes)
   - `window.CURRENT_ZONE_LIST` is updated with ordered zones
   - Master zone is auto-selected in the input field
3. **Dropdown List**: **NOT SHOWN** (fix applied here)
4. **User Can See**: Only the selected master zone in the input field

### When User Interacts with Zone File Combobox

1. **User Clicks/Focuses Input**: 
   - Focus event handler in `initServerSearchCombobox()` is triggered (line 807-810)
   - `showZones(zones)` is called
   - `populateComboboxList()` is called with default `showList=true`
   - Dropdown list is **NOW SHOWN** with domain-specific zones
2. **User Types**: 
   - Input event handler filters zones by query
   - Dropdown list shows filtered results

## How to Verify

### Test Case 1: Domain Selection Does Not Auto-Display List

1. Navigate to the Zones tab (`zone-files.php`)
2. Select a domain from the domain combobox
3. **Expected**: 
   - Master zone name appears in the zone file input field
   - Dropdown list (`#zone-file-list`) is **NOT visible**
   - `window.CURRENT_ZONE_LIST` contains domain-specific zones (verify in console)

### Test Case 2: Manual Interaction Shows List

1. Following Test Case 1, click on the zone file input field
2. **Expected**: 
   - Dropdown list appears showing master zone first, then includes sorted A-Z
   - All zones are domain-specific (no zones from other domains)

### Test Case 3: Typing Filters List

1. Following Test Case 2, type a search query in the zone file input
2. **Expected**: 
   - Dropdown list shows filtered results
   - Results are still domain-specific

### Test Case 4: Compare with DNS Tab

1. Navigate to DNS tab (`dns-management.php`)
2. Select a domain from the domain combobox
3. **Expected**: Same behavior as Zones tab (dropdown not shown on domain selection)
4. Click on zone combobox
5. **Expected**: Dropdown appears with domain-specific zones

## Technical Details

### Key Functions Modified

- **`showZones()`** (line 693): Now accepts `showList` parameter (default `false`)
- **`refresh()`** (line 837): Explicitly passes `showList=false` to prevent auto-display
- **Input event handler** (lines 793, 804): Pass `showList=true` when user is typing
- **Focus event handler** (line 810): Passes `showList=true` when user focuses input
- **`populateZoneFileCombobox()`** (line 1686): Removed redundant `populateComboboxList` call

### Key Functions Unchanged

- **`onZoneDomainSelected()`**: Still calls `populateZoneFileCombobox()` with `autoSelect=true`
- **Zone ordering**: Still uses `makeOrderedZoneList()` for consistent ordering
- **Domain filtering**: Still uses `isZoneInMasterTree()` for server search results

### Behavior Alignment

This fix aligns the Zones tab with the DNS tab's behavior:

**DNS Tab** (`dns-records.js:1007-1008`):
```javascript
// DO NOT open the combobox list - user must click/focus to see it
// DO NOT auto-select a zone - zone selection must be explicit
```

**Zones Tab** (`zone-files.js:693-713`):
```javascript
// showList defaults to false to prevent auto-display on domain selection (aligned with DNS tab)
function showZones(zones, showList = false) {
    // ...
    populateComboboxList(list, zones, mapZoneItem, onSelect, showList);
}
```

## Security Considerations

- No security vulnerabilities introduced
- Domain filtering still applies (via `isZoneInMasterTree()` in `initServerSearchCombobox`)
- ACL enforcement unchanged
- XSS protection maintained

## Performance Impact

- **Positive**: Slightly faster domain selection (no list rendering until user interaction)
- **Neutral**: Same number of API calls
- **Neutral**: Same zone filtering logic

## Backward Compatibility

- **Zone list population**: Unchanged
- **Zone auto-selection**: Unchanged (master zone still auto-selected in input field)
- **Zone filtering**: Unchanged (domain-specific zones)
- **User interaction**: Improved (list only shows on explicit user action)

## Related Code

- `assets/js/zone-files.js`: Zones tab implementation
- `assets/js/dns-records.js`: DNS tab implementation (reference for correct behavior)
- `assets/js/zone-combobox.js`: Shared zone ordering helpers
