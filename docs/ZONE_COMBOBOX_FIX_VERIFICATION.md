# Zone Combobox Auto-Display Fix - Verification Guide

## Problem Statement

The Zones tab zone file combobox (`#zone-file-list`) was automatically displaying the dropdown list when a domain was selected, showing all zones in `window.CURRENT_ZONE_LIST`. This behavior was inconsistent with the DNS tab, which correctly:
- Updates `CURRENT_ZONE_LIST` with domain-specific zones (master + includes)
- Does NOT automatically display the dropdown list
- Requires explicit user interaction (click/focus) to show the list

## Root Cause

In `assets/js/zone-files.js` at line 1686, the `populateZoneFileCombobox()` function was calling:

```javascript
populateComboboxList(listEl, orderedZones, mapper, handler, autoSelect);
```

When `autoSelect=true` (which is the case when a domain is selected), this passed `true` as the `showList` parameter to `populateComboboxList()`, causing the list to be displayed automatically.

## Solution

Modified line 1686 in `assets/js/zone-files.js` to always pass `false` for the `showList` parameter:

```javascript
populateComboboxList(listEl, orderedZones, mapper, handler, false);
```

Also removed the conditional logic (lines 1687-1691) that tried to hide the list when `autoSelect` was false, as this is now unnecessary.

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

- **`populateZoneFileCombobox()`** (line 1686): Now always passes `false` for `showList` parameter

### Key Functions Unchanged

- **`initServerSearchCombobox()`**: Focus event handler (line 807-810) still shows list on user interaction
- **`showZones()`**: Still calls `populateComboboxList()` with default `showList=true`
- **`onZoneDomainSelected()`**: Still calls `populateZoneFileCombobox()` with `autoSelect=true`

### Behavior Alignment

This fix aligns the Zones tab with the DNS tab's behavior:

**DNS Tab** (`dns-records.js:1007-1008`):
```javascript
// DO NOT open the combobox list - user must click/focus to see it
// DO NOT auto-select a zone - zone selection must be explicit
```

**Zones Tab** (`zone-files.js:1683-1684`):
```javascript
// Populate the visible list so user sees updated options
// NEVER show the list automatically - user must click/focus to see it (aligned with DNS tab behavior)
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
