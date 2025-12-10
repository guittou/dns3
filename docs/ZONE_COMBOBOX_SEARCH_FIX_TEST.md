# Zone Combobox Server Search Fix - Manual Test Plan

## Bug Description

Before this fix, when a user performed a server search (≥2 characters) in the zone-file combobox, the search results from ALL domains would overwrite `CURRENT_ZONE_LIST`, causing zones from other domains to appear after clearing the search.

## Fix Applied

Added domain filtering to server search results in `initServerSearchCombobox` function (zone-files.js, lines 778-784).

## Manual Test Steps

### Prerequisites
1. Ensure you have at least 2 domains in the system
   - Domain A (e.g., "example.com")
   - Domain B (e.g., "test.org")
2. Each domain should have some zone files (master and includes)
3. Log in to the application

### Test 1: Zone File Combobox Without Search

**Steps:**
1. Navigate to the Zones tab
2. Select Domain A from the domain combobox
3. Click on the zone file combobox (without typing anything)
4. **Expected**: Dropdown shows only zones for Domain A (master first, then includes sorted A-Z)
5. Select Domain B from the domain combobox
6. Click on the zone file combobox
7. **Expected**: Dropdown shows only zones for Domain B

**Status**: ✅ PASS / ❌ FAIL

---

### Test 2: Zone File Combobox With Short Search (<2 chars)

**Steps:**
1. Navigate to the Zones tab
2. Select Domain A from the domain combobox
3. Click on the zone file combobox and type "e"
4. **Expected**: Dropdown shows only zones for Domain A that contain "e" in their name
5. Clear the search (backspace to empty)
6. **Expected**: Dropdown shows all zones for Domain A

**Status**: ✅ PASS / ❌ FAIL

---

### Test 3: Zone File Combobox With Server Search (≥2 chars) - MAIN FIX TEST

**Steps:**
1. Navigate to the Zones tab
2. Select Domain A (e.g., "example.com")
3. Note which zones belong to Domain A
4. Click on the zone file combobox and type "te" or "test"
5. **Expected**: 
   - Browser console shows: `[initServerSearchCombobox] server search for query: te`
   - Browser console shows: `[initServerSearchCombobox] Filtered server results by domain: X → Y` (where Y ≤ X)
   - Dropdown shows only zones for Domain A that match the search
   - **No zones from Domain B appear**
6. Clear the search (backspace to empty)
7. **Expected**: Dropdown shows all zones for Domain A
8. **Critical Check**: Verify that no zones from Domain B appear in the list

**Status**: ✅ PASS / ❌ FAIL

---

### Test 4: Cross-Domain Search Verification

**Steps:**
1. Navigate to the Zones tab
2. Select Domain A
3. Type a search query that would match zones in BOTH Domain A and Domain B
4. **Expected**: Only zones from Domain A appear (filtered by domain)
5. Note the zone count in the console: `Filtered server results by domain: X → Y`
6. X should be greater than Y (proving filtering occurred)
7. Select Domain B
8. Type the same search query
9. **Expected**: Only zones from Domain B appear
10. The zone list should be different from step 4

**Status**: ✅ PASS / ❌ FAIL

---

### Test 5: No Domain Selected

**Steps:**
1. Navigate to the Zones tab
2. Ensure no domain is selected (click "Réinitialiser" if needed)
3. Try to click on the zone file combobox
4. **Expected**: 
   - Combobox is disabled
   - Placeholder shows: "Sélectionnez d'abord un domaine"
   - Cannot type or search

**Status**: ✅ PASS / ❌ FAIL

---

### Test 6: DNS Tab Consistency Check

**Steps:**
1. Navigate to the DNS Records tab
2. Select Domain A from the domain combobox
3. Click on the zone combobox and type a search query (≥2 chars)
4. **Expected**: 
   - Behavior matches Zones tab
   - Only zones from Domain A appear
   - No zones from other domains

**Status**: ✅ PASS / ❌ FAIL

---

## Browser Console Verification

When performing Test 3 (server search with ≥2 characters), check the browser console for:

```
[initServerSearchCombobox] server search for query: <your_query>
[initServerSearchCombobox] Filtered server results by domain: <before_count> → <after_count>
[initServerSearchCombobox] server returned <after_count> results
```

**Key Points:**
- `<before_count>` should be the total number of zones matching the query across ALL domains
- `<after_count>` should be the number of zones matching the query ONLY in the selected domain
- `<after_count>` should be ≤ `<before_count>`
- If `<after_count>` < `<before_count>`, this proves the filtering is working

## Expected Results Summary

All tests should PASS with the following behaviors:
- ✅ Zone file combobox always shows domain-specific zones
- ✅ Server search filters results by selected domain
- ✅ CURRENT_ZONE_LIST maintains domain-specific zones even after search
- ✅ No zones from other domains leak into the dropdown
- ✅ Console logs show domain filtering in action

## Regression Check

Ensure the fix does not break existing functionality:
- [ ] Domain selection still works
- [ ] Zone file selection still works
- [ ] Auto-selection of master zone still works
- [ ] Zone ordering (master first, includes A-Z) is maintained
- [ ] Client search (<2 chars) still works
- [ ] DNS tab functionality is not affected

## Notes for Testers

1. Use browser developer tools (F12) to monitor console output
2. Test with multiple domains that have similar zone names to verify filtering
3. Test with domains that have many zones (>20) to verify performance
4. Clear browser cache between tests if needed

## Bug Fixed Date
2025-12-10

## Related Files
- `assets/js/zone-files.js` (lines 778-784)
- `docs/ZONES_TAB_COMBOBOX_VERIFICATION.md` (updated)

## Status
🔧 **FIX APPLIED - AWAITING MANUAL VERIFICATION**
