# Validation Guide: Duplicate Request Fix

## Objective
Verify that duplicate API requests (`list_zones` and `list_zone_files`) have been eliminated on the Zones tab.

## Pre-requisites
- DNS3 application running locally or on test server
- Browser with DevTools (Chrome, Firefox, or Edge)
- Login credentials for the application
- At least one master zone with includes configured in the database

## Test Scenarios

### Test 1: Initial Page Load - Single Requests Per Type

**Steps:**
1. Open browser DevTools (F12)
2. Go to the **Network** tab
3. Clear network log (trash icon)
4. Navigate to the Zones page (`/zone-files.php` or equivalent)
5. Wait for page to fully load (3-5 seconds)

**Expected Results:**
- ✅ Only ONE request to `zone_api.php?action=list_zones&file_type=include&per_page=1000`
- ✅ Only ONE request to `zone_api.php?action=list_zones&file_type=master&status=active&per_page=1000`
- ✅ Zero or ONE request to `zone_api.php?action=list_zone_files` (only if a default domain is pre-selected)

**Failure Indicators:**
- ❌ Multiple identical `list_zones` requests (duplicate file_type + status + per_page)
- ❌ Multiple identical `list_zone_files` requests with same `domain_id`

**How to Check:**
1. Filter network requests by "zone_api.php" in the search box
2. Count requests with the same action and parameters
3. Use the "Preview" or "Response" tab to verify they return the same data

---

### Test 2: Domain Switching - No Duplicate list_zone_files

**Steps:**
1. Ensure Zones page is loaded
2. Open DevTools Network tab
3. Clear network log
4. Select a master domain from the "Domaine" dropdown
5. Wait for combobox to populate
6. Immediately select a different domain
7. Wait 2 seconds

**Expected Results:**
- ✅ For each unique `domain_id`, only ONE `list_zone_files` request
- ✅ If domain is switched before request completes, the in-flight request is reused

**Failure Indicators:**
- ❌ Multiple `list_zone_files` requests with identical `domain_id` parameter
- ❌ Requests with same `domain_id` starting before previous one completes

---

### Test 3: Fallback Timer Deduplication

**Steps:**
1. Clear browser cache completely (Ctrl+Shift+Delete)
2. Open DevTools Network tab with "Disable cache" enabled
3. Hard refresh the Zones page (Ctrl+F5)
4. Monitor network requests for 5 seconds
5. Check console logs for messages like `[Fallback 30ms]`, `[Fallback 800ms]`

**Expected Results:**
- ✅ Only ONE set of initialization requests despite multiple fallback timers
- ✅ Console shows messages like "Initialization already in progress, returning existing promise"
- ✅ Console shows "UI components already initialized, skipping" on subsequent attempts

**Failure Indicators:**
- ❌ Multiple initialization sequences visible in network log
- ❌ Console shows multiple "Initializing UI components..." messages
- ❌ Same API requests triggered multiple times within 3 seconds

---

### Test 4: Data Refresh After Creating Include

**Steps:**
1. Open Zones page
2. Open DevTools Network tab
3. Clear network log
4. Click "Nouveau fichier de zone" button
5. Fill out form and save a new include
6. Monitor network requests

**Expected Results:**
- ✅ After save, ONE `list_zones` request to refresh data
- ✅ ONE `populateZoneDomainSelect` operation
- ✅ No duplicate initialization of UI components

**Failure Indicators:**
- ❌ Multiple `list_zones` requests after save operation
- ❌ Console shows "Initializing UI components..." after save (should skip as already initialized)

---

### Test 5: Quick Tab Switching

**Steps:**
1. Open Zones page
2. Open DevTools Network tab
3. Clear network log
4. Quickly switch to DNS Records tab
5. Quickly switch back to Zones tab
6. Repeat 2-3 times
7. Check network requests

**Expected Results:**
- ✅ Minimal API requests on tab switch (data should be cached)
- ✅ No duplicate initialization requests

**Failure Indicators:**
- ❌ Full re-initialization on every tab switch
- ❌ Multiple concurrent API requests when switching back

---

## Console Debug Messages

When testing, enable verbose console logging to see deduplication in action:

### Good Messages (Expected)
```
[fetchZonesForMaster] Request already in flight for master X - returning existing promise
[ensureZonesCache] Fetch already in progress, returning existing promise
[initializeComboboxes] UI components already initialized, skipping
[populateZoneListForDomain] Request already in flight for domain X - returning existing promise
[Fallback 800ms] Zones already initialized successfully, skipping
```

### Bad Messages (Indicates Problem)
```
[fetchZonesForMaster] Fetching zones for master X (appearing multiple times with same X)
[initializeComboboxes] Initializing UI components... (appearing multiple times)
Multiple [Fallback XXms] messages without "skipping" or "in progress" indicators
```

---

## Network Request Timeline

Use the **Timeline** view in DevTools Network tab to visualize:

1. **Ideal Pattern:**
   ```
   list_zones (file_type=master) ─────────
   list_zones (file_type=include) ───────
   list_zone_files (domain_id=X)   ────────
   ```

2. **Problem Pattern (to avoid):**
   ```
   list_zones (file_type=master) ─────────
   list_zones (file_type=master) ─────────  ← DUPLICATE
   list_zones (file_type=include) ───────
   list_zones (file_type=include) ───────  ← DUPLICATE
   list_zone_files (domain_id=X)   ────────
   list_zone_files (domain_id=X)   ────────  ← DUPLICATE
   ```

---

## Browser Compatibility

Test in at least two browsers:
- ✅ Chrome/Edge (Chromium)
- ✅ Firefox

All browsers should show same deduplication behavior.

---

## Regression Tests

Verify no functionality was broken:

1. **Zone List Display**
   - ✅ Zones table populates correctly
   - ✅ Pagination works
   - ✅ Search/filter works

2. **Combobox Functionality**
   - ✅ Domain combobox shows all master zones
   - ✅ Zone file combobox populates when domain selected
   - ✅ Combobox search works
   - ✅ Selecting items updates hidden fields

3. **CRUD Operations**
   - ✅ Creating new include works
   - ✅ Editing zone works
   - ✅ Deleting zone works
   - ✅ Assigning includes to masters works

4. **Page Refresh**
   - ✅ Hard refresh (Ctrl+F5) loads page correctly
   - ✅ Soft refresh (F5) loads page correctly
   - ✅ Direct navigation to `/zone-files.php` works

---

## Performance Metrics

Compare before and after:

**Before Fix (Expected Issues):**
- 3-6 `list_zones` requests on page load
- 2-4 `list_zone_files` requests per domain selection
- Page load time: ~1-2 seconds (depending on network)

**After Fix (Expected Improvements):**
- 2 `list_zones` requests on page load (one for masters, one for includes)
- 1 `list_zone_files` request per unique domain selection
- Page load time: ~0.5-1 second (50% improvement expected)

---

## Troubleshooting

If tests fail:

1. **Clear browser cache completely**
   - JavaScript files might be cached
   - Do a hard refresh (Ctrl+Shift+F5)

2. **Check console for errors**
   - Look for JavaScript errors that might break deduplication
   - Check for 404s on included scripts

3. **Verify script loading order**
   - Check that `zone-combobox.js` loads before `zone-files.js`
   - Verify `combobox-utils.js` is loaded

4. **Check server configuration**
   - Ensure API endpoints are responding correctly
   - Verify session/authentication is working

---

## Success Criteria

The fix is validated when:
- ✅ All 5 test scenarios pass
- ✅ No duplicate API requests visible in Network tab
- ✅ Console shows deduplication debug messages
- ✅ No regressions in functionality
- ✅ Page load feels faster

---

## Reporting Issues

If you find problems:

1. Note which test scenario failed
2. Include:
   - Browser version
   - Network tab screenshot
   - Console log excerpt
   - Steps to reproduce
3. Check if issue is consistent across browsers
4. Try with cache disabled to rule out caching issues
