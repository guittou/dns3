> **ARCHIVED DOCUMENT NOTE** : Les fichiers de migration mentionnés dans ce document ont été supprimés. Pour les nouvelles installations, utilisez `database.sql` (ou `structure_ok_dns3_db.sql`).

# Testing Guide: Paginated Zone Files Feature

This guide provides instructions for testing the new paginated zone files list and dedicated detail page feature.

## Prerequisites

1. Database should be set up with the `dns3_db` schema
2. Run migration 007 to add performance indexes:
   ```bash
   mysql -u dns3_user -p dns3_db < migrations/007_add_zone_files_indexes.sql
   ```
3. Have admin credentials to access the zone files management interface

## Test Scenarios

### 1. Pagination Testing

**Objective:** Verify that pagination works correctly with large datasets

**Steps:**
1. Create at least 200 zone files (mix of master and include types) using the API or UI
2. Navigate to `zone-files.php`
3. Verify that the page loads with the first 25 zones displayed (default page size)
4. Check that pagination controls show correct page numbers (e.g., "Page 1 sur 8")
5. Click "Suivant" to go to next page
6. Verify URL doesn't change (client-side pagination)
7. Verify that different zones are displayed
8. Click "Précédent" to go back
9. Change "per page" selector to 50 and verify display updates
10. Change to 100 per page and verify

**Expected Results:**
- Page loads within 1-2 seconds even with 200+ zones
- Pagination controls are functional
- Correct number of zones displayed per page
- Total count is accurate
- Navigation buttons are enabled/disabled appropriately

### 2. Search Functionality

**Objective:** Test search with debouncing and partial matching

**Steps:**
1. Navigate to `zone-files.php`
2. Type slowly in the search box: "example"
3. Verify search doesn't trigger until you stop typing (300ms debounce)
4. Verify results show zones with "example" in name or filename
5. Clear search and verify all zones return
6. Search for a filename pattern like ".zone"
7. Verify both name and filename are searched

**Expected Results:**
- Search debounce prevents excessive API calls
- Results update automatically after typing stops
- Partial matches work (LIKE %query%)
- Both name and filename fields are searched
- Page resets to 1 when search changes
- Results count updates correctly

### 3. Filter Testing

**Objective:** Verify type and status filters work correctly

**Steps:**
1. Navigate to `zone-files.php`
2. Select "Master" from type filter
3. Verify only master zones are displayed
4. Select "Include" from type filter
5. Verify only include zones are displayed
6. Change status filter to "Inactifs"
7. Verify only inactive zones shown
8. Try "Tous" for both filters
9. Combine filters: Master + Active
10. Verify combined filtering works

**Expected Results:**
- Type filter correctly filters by file_type
- Status filter correctly filters by status
- Filters can be combined
- Results count updates with filters
- Pagination resets to page 1 on filter change

### 4. Detail Page Navigation

**Objective:** Test navigation to and from detail page

**Steps:**
1. From zone list, click "View" (eye icon) on a zone
2. Verify navigation to `zone-file.php?id=X`
3. Verify zone details load correctly
4. Click "Retour à la liste" button
5. Verify return to zone list at same page
6. From list, click "Edit" (pencil icon) on a zone
7. Verify navigation to detail page with editor tab active
8. Click breadcrumb "Fichiers de zone" link
9. Verify return to list

**Expected Results:**
- Clean navigation between list and detail
- Detail page loads zone data correctly
- Back button returns to list
- Edit button opens editor tab
- Breadcrumbs work correctly
- "Zones" tab in header is highlighted on both pages

### 5. Autocomplete for Includes

**Objective:** Test autocomplete when adding includes

**Steps:**
1. Navigate to detail page of a master zone
2. Click "Includes" tab
3. Click "Ajouter include" button
4. In the search field, start typing (e.g., "test")
5. Verify autocomplete results appear after 300ms
6. Verify only include-type zones are shown
7. Verify current zone is excluded from results
8. Click on an autocomplete result
9. Verify selection is populated
10. Click "Ajouter" to add the include
11. Verify include appears in tree

**Expected Results:**
- Autocomplete triggers after typing pause
- Results limited to include-type zones only
- Maximum 20 results shown
- Shows both name and filename
- Selection works correctly
- No circular references possible
- API call uses `search_zones` endpoint

### 6. Lazy Loading of Includes

**Objective:** Verify includes tree loads lazily

**Steps:**
1. Navigate to detail page
2. Observe network tab in browser DevTools
3. Verify `get_zone` is called on page load
4. Verify `get_tree` is NOT called initially
5. Click "Includes" tab
6. Verify `get_tree` is called only now
7. Switch to "Détails" tab and back to "Includes"
8. Verify tree is already cached (no new request)

**Expected Results:**
- get_tree endpoint only called when Includes tab is opened
- Reduces initial page load time
- Tree data is cached client-side during session
- Only direct includes in get_zone response

### 7. Performance Testing

**Objective:** Measure performance with large datasets

**Steps:**
1. Create test dataset:
   - 500 master zones
   - 300 include zones
   - Various include relationships
2. Measure page load time for list view
3. Measure search response time
4. Measure autocomplete response time
5. Check database query performance
6. Verify indexes are being used

**Expected Results:**
- List view loads in < 2 seconds
- Search results return in < 1 second
- Autocomplete results in < 500ms
- Database uses idx_zone_type_status_name index
- No N+1 query problems

### 8. API Endpoint Testing

**Objective:** Verify API responses are correct

**Test list_zones endpoint:**
```bash
curl -X GET 'http://yoursite/api/zone_api.php?action=list_zones&page=1&per_page=25' \
  -H 'Cookie: PHPSESSID=your_session_id'
```

Expected response:
```json
{
  "success": true,
  "data": [...],
  "total": 150,
  "page": 1,
  "per_page": 25,
  "total_pages": 6
}
```

**Test search_zones endpoint:**
```bash
curl -X GET 'http://yoursite/api/zone_api.php?action=search_zones&q=test&file_type=include&limit=20' \
  -H 'Cookie: PHPSESSID=your_session_id'
```

Expected response:
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "name": "test-include",
      "filename": "test.zone",
      "file_type": "include"
    }
  ]
}
```

**Test with filters:**
```bash
curl -X GET 'http://yoursite/api/zone_api.php?action=list_zones&file_type=master&status=active&q=example&page=2&per_page=50' \
  -H 'Cookie: PHPSESSID=your_session_id'
```

### 9. Cross-Browser Testing

**Objective:** Ensure compatibility across browsers

**Browsers to test:**
- Chrome/Chromium (latest)
- Firefox (latest)
- Safari (if available)
- Edge (latest)

**Test on each:**
1. List view pagination
2. Search with debounce
3. Filter dropdowns
4. Detail page navigation
5. Autocomplete widget
6. Modal interactions

### 10. Mobile Responsiveness

**Objective:** Verify mobile-friendly design

**Steps:**
1. Open zone-files.php on mobile device or emulator
2. Verify table is scrollable horizontally
3. Verify filters stack vertically on small screens
4. Test pagination controls on mobile
5. Open detail page on mobile
6. Verify tabs work on touch devices
7. Test autocomplete on mobile

**Expected Results:**
- Table scrolls horizontally on small screens
- Filters are usable on mobile
- Touch interactions work smoothly
- No horizontal overflow issues
- Buttons are touch-friendly (min 44x44px)

## Regression Testing

Verify existing functionality still works:

1. **Create Zone:** Create new zone from list page modal
2. **Edit Zone Details:** Update name, filename, type, status
3. **Edit Content:** Modify zone file content in editor
4. **Assign Include:** Add include to master zone
5. **Remove Include:** Remove include from zone
6. **View Resolved Content:** Generate flattened zone content
7. **Download Zone:** Download zone file
8. **Delete Zone:** Mark zone as deleted
9. **History:** View zone change history
10. **Cycle Detection:** Try to create circular include dependency

## Known Limitations (MVP)

- Editor is plain textarea (CodeMirror planned for future)
- History tab loads all history at once (pagination planned)
- No infinite scroll option (pagination only)
- Search doesn't use FULLTEXT index (can be added if needed)
- Autocomplete shows max 20 results (fixed limit)

## Reporting Issues

When reporting issues, please include:
- Browser and version
- Steps to reproduce
- Expected vs actual behavior
- Console errors (if any)
- Network requests (from DevTools)
- Database query logs (if performance related)

## Success Criteria

All tests pass when:
- ✅ Pagination works correctly with 200+ zones
- ✅ Search returns accurate results within 1 second
- ✅ Autocomplete provides relevant suggestions
- ✅ Detail page loads zone data correctly
- ✅ Lazy loading reduces initial load time
- ✅ No JavaScript errors in console
- ✅ No SQL errors in logs
- ✅ Mobile responsive design works
- ✅ All existing features still work
- ✅ Database indexes improve query performance
