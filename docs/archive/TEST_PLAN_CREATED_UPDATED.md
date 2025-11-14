# Test Plan: Created At / Updated At UI Display

## Prerequisites
- Migration `003_add_dns_fields.sql` must be applied to the database
- Database must have `created_at` and `updated_at` columns in `dns_records` table
- User must have admin privileges to access DNS management page

## Test Environment Setup
1. Navigate to the DNS Management page (`dns-management.php`)
2. Ensure you are logged in as an admin user
3. Open browser developer tools to monitor network requests and console for errors

## Test Cases

### Test Case 1: Verify Table Column Headers
**Objective:** Ensure new columns are visible in the DNS records table

**Steps:**
1. Navigate to DNS Management page
2. Observe the table header row

**Expected Results:**
- Table should have 13 columns (increased from 11)
- "Créé le" column header should appear after "Vu le"
- "Modifié le" column header should appear after "Créé le"
- All columns should be properly aligned

**Pass Criteria:** ✓ Both new column headers are visible and properly labeled

---

### Test Case 2: Create New DNS Record
**Objective:** Verify that `created_at` is properly set when creating a new record

**Steps:**
1. Click "+ Créer un enregistrement" button
2. Fill in all required fields:
   - Type: A
   - Nom: test-created-at.example.com
   - Adresse IPv4: 192.168.1.100
   - TTL: 3600
3. Verify that "Créé le" and "Modifié le" fields are NOT visible in create modal
4. Click "Enregistrer" to save the record
5. Wait for success message
6. Locate the newly created record in the table
7. Note the "Créé le" timestamp value

**Expected Results:**
- Create modal should NOT show "Créé le" or "Modifié le" fields
- Record should be created successfully
- New record should appear in the table
- "Créé le" column should show a timestamp matching the current time
- "Modifié le" column may show the same timestamp as "Créé le" (depending on DB default)

**Database Verification:**
```sql
SELECT id, name, created_at, updated_at 
FROM dns_records 
WHERE name = 'test-created-at.example.com'
ORDER BY id DESC LIMIT 1;
```
- `created_at` should be NOT NULL
- `created_at` should match the current timestamp (within a few seconds)

**Pass Criteria:** 
- ✓ `created_at` is set in database
- ✓ "Créé le" displays correctly in UI
- ✓ Fields are hidden in create modal

---

### Test Case 3: View Existing Record in Edit Modal
**Objective:** Verify that `created_at` and `updated_at` are displayed in edit mode

**Steps:**
1. Click "Modifier" button on any existing DNS record
2. Modal should open with record details

**Expected Results:**
- "Créé le" field should be visible
- "Créé le" field should display formatted timestamp (DD/MM/YYYY HH:MM)
- "Créé le" field should be disabled/readonly (cannot be edited)
- "Modifié le" field should be visible if record has been updated
- "Modifié le" field should display formatted timestamp
- "Modifié le" field should be disabled/readonly

**Pass Criteria:** 
- ✓ Both fields are visible and populated
- ✓ Fields are readonly
- ✓ Timestamps are formatted correctly

---

### Test Case 4: Update Existing Record
**Objective:** Verify that `updated_at` is properly updated when modifying a record

**Steps:**
1. Open an existing record for editing
2. Note the current "Modifié le" timestamp
3. Wait at least 2 seconds (to ensure timestamp difference)
4. Modify a field (e.g., change TTL from 3600 to 7200)
5. Click "Enregistrer"
6. Wait for success message
7. Re-open the same record for editing
8. Check the "Modifié le" timestamp

**Expected Results:**
- Record should be updated successfully
- "Modifié le" timestamp in the table should be updated to current time
- When reopening the modal, "Modifié le" should show the new timestamp
- "Créé le" should remain unchanged (original creation time)

**Database Verification:**
```sql
SELECT id, name, created_at, updated_at 
FROM dns_records 
WHERE id = [record_id];
```
- `updated_at` should be greater than `created_at`
- `updated_at` should match the current timestamp (within a few seconds)

**Pass Criteria:** 
- ✓ `updated_at` is updated in database
- ✓ "Modifié le" displays new timestamp in UI
- ✓ "Créé le" remains unchanged

---

### Test Case 5: Date Format Verification
**Objective:** Verify that dates are formatted correctly in French locale

**Steps:**
1. View any record with timestamps in the table
2. Note the format of "Créé le" and "Modifié le" columns

**Expected Results:**
- Format should be: DD/MM/YYYY HH:MM
- Example: "20/10/2025 14:35" (not "10/20/2025 2:35 PM")
- No seconds should be displayed

**Pass Criteria:** ✓ Dates use French locale format

---

### Test Case 6: Empty/Null Timestamp Handling
**Objective:** Verify proper handling of null timestamps

**Steps:**
1. If possible, check an old record that might have null `updated_at`
2. View the record in the table

**Expected Results:**
- If `created_at` is null: column should display "-"
- If `updated_at` is null: column should display "-"
- No JavaScript errors should occur

**Pass Criteria:** ✓ Null values display as "-" without errors

---

### Test Case 7: Table Sorting and Filtering
**Objective:** Ensure new columns don't break existing functionality

**Steps:**
1. Use search filter to find specific records
2. Use type filter dropdown
3. Use status filter dropdown
4. Verify all filters work correctly

**Expected Results:**
- Search should work as before
- Type filter should work as before
- Status filter should work as before
- New columns should remain visible during filtering
- Timestamps should be preserved in filtered results

**Pass Criteria:** ✓ All filters work correctly with new columns

---

### Test Case 8: Security Test - Client Timestamp Tampering
**Objective:** Verify that client cannot modify server-managed timestamps

**Steps:**
1. Open browser developer tools
2. Go to Network tab
3. Create a new DNS record
4. Intercept the API request (or modify before sending)
5. Attempt to add `created_at` or `updated_at` to the payload
6. Send the modified request

**Expected Results:**
- Server should ignore `created_at` in the payload
- Server should use `NOW()` for `created_at` regardless of client value
- Database should have server-generated timestamp, not client-provided value

**Pass Criteria:** ✓ Server ignores client-provided timestamps

---

### Test Case 9: Update Security Test
**Objective:** Verify that client cannot modify timestamps during update

**Steps:**
1. Open an existing record for editing
2. Open browser developer tools
3. Go to Network tab
4. Make a valid change to the record
5. Intercept the update API request
6. Attempt to add `created_at` or `updated_at` to the payload with custom values
7. Send the modified request

**Expected Results:**
- Server should ignore both `created_at` and `updated_at` in the payload
- `created_at` should remain unchanged
- `updated_at` should be set by server to current timestamp (not client value)

**Pass Criteria:** ✓ Server ignores client-provided timestamps

---

### Test Case 10: API Response Validation
**Objective:** Verify API returns timestamp data

**Steps:**
1. Open browser developer tools
2. Go to Network tab
3. Refresh the DNS records table
4. Find the API request to list records
5. Examine the JSON response

**Expected Results:**
- Each record should include `created_at` field
- Each record should include `updated_at` field
- Timestamps should be in SQL format: "YYYY-MM-DD HH:MM:SS"

**Pass Criteria:** ✓ API includes timestamp fields in response

---

### Test Case 11: Responsive Design Check
**Objective:** Ensure new columns don't break table layout

**Steps:**
1. Resize browser window to various widths
2. Check table on mobile viewport (320px width)
3. Check table on tablet viewport (768px width)
4. Check table on desktop viewport (1200px+ width)

**Expected Results:**
- Table should remain usable at all viewport sizes
- Columns should adapt or scroll horizontally if needed
- New columns should be visible at desktop sizes
- No content should be cut off or overlapping

**Pass Criteria:** ✓ Table layout works at all viewport sizes

---

## Test Execution Summary

| Test Case | Description | Status | Notes |
|-----------|-------------|--------|-------|
| TC1 | Table Column Headers | ⏳ Pending | |
| TC2 | Create New Record | ⏳ Pending | |
| TC3 | View in Edit Modal | ⏳ Pending | |
| TC4 | Update Record | ⏳ Pending | |
| TC5 | Date Format | ⏳ Pending | |
| TC6 | Null Handling | ⏳ Pending | |
| TC7 | Filters Still Work | ⏳ Pending | |
| TC8 | Security - Create | ⏳ Pending | |
| TC9 | Security - Update | ⏳ Pending | |
| TC10 | API Response | ⏳ Pending | |
| TC11 | Responsive Design | ⏳ Pending | |

## Known Issues / Edge Cases

None identified yet. Update this section during testing if issues are found.

## Regression Testing

After completing the above tests, perform basic regression tests:

1. **Create different record types** (A, AAAA, CNAME, PTR, TXT) - all should work
2. **Edit different record types** - all should show timestamps
3. **Delete/restore records** - timestamps should be preserved
4. **Check history tracking** - should still work (not affected by this change)

## Sign-off

**Tester Name:** _________________

**Date:** _________________

**Overall Result:** [ ] Pass [ ] Fail [ ] Pass with Issues

**Comments:**
_________________________________________________________________
_________________________________________________________________
_________________________________________________________________
