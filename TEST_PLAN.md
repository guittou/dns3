# Test Plan for DNS last_seen and Dynamic Form Behavior

## Summary of Changes

This PR implements the following changes to the DNS management system:

1. **Removed automatic last_seen updates from UI/API**: The `last_seen` field is no longer updated when viewing records via the web UI or API. The `markSeen()` method remains in the model for future external script use.

2. **Dynamic form field visibility**: The priority field is now only shown for MX and SRV record types, with fields dynamically showing/hiding based on the selected record type.

3. **Security enhancement**: The API explicitly ignores any client-provided `last_seen` values in create/update operations.

4. **Optimized payload**: The JavaScript only includes relevant fields in API requests (e.g., priority is only sent for MX/SRV records).

## Files Modified

- `api/dns_api.php` - Removed markSeen() call from GET action
- `assets/js/dns-records.js` - Added dynamic form behavior and optimized payload construction
- `dns-management.php` - Added id="record-priority-group" wrapper for priority field

## Test Cases

### 1. Create Record via UI - last_seen Remains NULL

**Test Steps:**
1. Log in as an admin user
2. Navigate to DNS Management page
3. Click "Create Record" button
4. Fill in all required fields (record_type, name, value)
5. Submit the form
6. Query the database: `SELECT last_seen FROM dns_records WHERE id = [new_record_id]`

**Expected Result:**
- Record is created successfully
- `last_seen` field in database is NULL

**Verification:**
```sql
SELECT id, name, last_seen FROM dns_records WHERE id = [new_record_id];
-- last_seen should be NULL
```

### 2. View Record via UI - last_seen Remains Unchanged

**Test Steps:**
1. Note the current `last_seen` value for a record (or NULL if not set)
2. Click "Edit" button for that record to view it
3. Query the database again to check `last_seen`

**Expected Result:**
- Record details are displayed correctly
- `last_seen` value in database remains unchanged (stays NULL or keeps original timestamp)

**Verification:**
```sql
-- Before viewing
SELECT id, name, last_seen FROM dns_records WHERE id = [record_id];
-- [View the record in UI]
-- After viewing
SELECT id, name, last_seen FROM dns_records WHERE id = [record_id];
-- Values should be identical
```

### 3. Edit Record via UI - last_seen Remains Unchanged

**Test Steps:**
1. Note the current `last_seen` value for a record
2. Click "Edit" button
3. Modify some fields (e.g., TTL or comment)
4. Submit the form
5. Query the database to verify `last_seen` hasn't changed

**Expected Result:**
- Record is updated successfully with new values
- `last_seen` field remains unchanged
- `updated_at` field is updated (this is expected behavior)

**Verification:**
```sql
SELECT id, name, last_seen, updated_at FROM dns_records WHERE id = [record_id];
-- last_seen should remain unchanged, updated_at should be current timestamp
```

### 4. Create MX Record - Priority Visible and Persisted

**Test Steps:**
1. Click "Create Record"
2. Select "MX" from record type dropdown
3. Verify priority field is visible
4. Fill in required fields including priority (e.g., 10)
5. Submit the form
6. Query database to verify priority was saved

**Expected Result:**
- Priority field is visible when MX is selected
- Priority value is saved to database
- API request includes priority in payload

**Verification:**
```sql
SELECT id, record_type, priority FROM dns_records WHERE id = [new_mx_record_id];
-- priority should have the value entered (e.g., 10)
```

### 5. Create SRV Record - Priority Visible and Persisted

**Test Steps:**
1. Click "Create Record"
2. Select "SRV" from record type dropdown
3. Verify priority field is visible
4. Fill in required fields including priority
5. Submit the form

**Expected Result:**
- Priority field is visible when SRV is selected
- Priority value is saved correctly

### 6. Create A Record - Priority Hidden and Not Sent

**Test Steps:**
1. Click "Create Record"
2. Select "A" from record type dropdown
3. Verify priority field is hidden
4. Fill in required fields
5. Open browser developer tools, go to Network tab
6. Submit the form
7. Inspect the POST request payload

**Expected Result:**
- Priority field is not visible in the form
- POST request payload does NOT include "priority" field
- Record is created successfully without priority

**Verification:**
- Check Network tab: POST payload should not contain `priority` key
- Database query: `SELECT id, record_type, priority FROM dns_records WHERE id = [new_a_record_id]`
- priority should be NULL

### 7. Create CNAME Record - Priority Hidden and Not Sent

**Test Steps:**
1. Click "Create Record"
2. Select "CNAME" from record type dropdown
3. Verify priority field is hidden
4. Submit with required fields

**Expected Result:**
- Priority field is hidden
- Priority not included in payload
- Record created successfully

### 8. Dynamic Field Toggle - Change Record Type

**Test Steps:**
1. Click "Create Record"
2. Select "A" - verify priority is hidden
3. Change to "MX" - verify priority appears
4. Change to "CNAME" - verify priority disappears
5. Change to "SRV" - verify priority appears
6. Change back to "A" - verify priority disappears

**Expected Result:**
- Priority field visibility toggles correctly based on record type
- No JavaScript console errors
- Smooth transition (no flickering)

### 9. Security Test - Attempt to Send last_seen from Client

**Test Steps:**
1. Open browser developer tools
2. In Console tab, intercept the form submission or modify the request
3. Try to include `last_seen` in the payload:
   ```javascript
   // Modify the request to include last_seen
   const data = {
       record_type: 'A',
       name: 'test.example.com',
       value: '192.168.1.1',
       ttl: 3600,
       last_seen: '2025-10-20 12:00:00'  // Malicious injection
   };
   ```
4. Submit the crafted request
5. Check database to verify last_seen was NOT set

**Expected Result:**
- Server ignores the client-provided `last_seen` value
- `last_seen` in database remains NULL (for new records)
- No server error
- API returns success

**Verification:**
```sql
SELECT id, name, last_seen FROM dns_records WHERE name = 'test.example.com';
-- last_seen should be NULL despite client attempting to set it
```

### 10. Edit Form - Priority Visibility Based on Record Type

**Test Steps:**
1. Create or select an existing MX record
2. Click "Edit"
3. Verify priority field is visible and shows current value
4. Create or select an A record
5. Click "Edit"
6. Verify priority field is hidden

**Expected Result:**
- Priority field visibility in edit mode matches the record type
- Existing priority values are displayed correctly for MX/SRV

### 11. Verify No JavaScript Console Errors

**Test Steps:**
1. Open browser developer tools, Console tab
2. Navigate to DNS Management page
3. Perform the following actions:
   - View records list
   - Click "Create Record"
   - Change record types multiple times
   - Submit a new record
   - Edit an existing record
   - Delete a record
   - Restore a deleted record

**Expected Result:**
- No JavaScript errors in console
- All actions complete successfully
- UI is responsive

### 12. List Records - Verify All Flows Still Work

**Test Steps:**
1. Navigate to DNS Management page
2. Use search filter to find records
3. Use type filter to filter by record type
4. Use status filter to show deleted records
5. Verify pagination works (if implemented)

**Expected Result:**
- All filters work correctly
- Records are displayed properly
- last_seen column shows existing values or "-" for NULL
- No errors in console or UI

### 13. Delete Record - last_seen Remains Unchanged

**Test Steps:**
1. Note the `last_seen` value for a record
2. Click "Delete" button
3. Confirm deletion
4. Query database to verify last_seen hasn't changed

**Expected Result:**
- Record status changes to "deleted"
- `last_seen` value remains unchanged
- `updated_at` is updated (expected)

**Verification:**
```sql
SELECT id, status, last_seen, updated_at FROM dns_records WHERE id = [record_id];
-- status should be 'deleted', last_seen unchanged, updated_at current
```

### 14. Restore Record - last_seen Remains Unchanged

**Test Steps:**
1. Filter to show deleted records
2. Note the `last_seen` value for a deleted record
3. Click "Restore" button
4. Confirm restoration
5. Query database to verify last_seen hasn't changed

**Expected Result:**
- Record status changes to "active"
- `last_seen` value remains unchanged

### 15. markSeen() Method Still Available for Scripts

**Test Steps:**
1. Create a test PHP script that calls the markSeen() method directly:
   ```php
   <?php
   require_once 'includes/models/DnsRecord.php';
   $dnsRecord = new DnsRecord();
   $result = $dnsRecord->markSeen(1, 1); // record_id=1, user_id=1
   echo $result ? "Success" : "Failed";
   ```
2. Run the script
3. Query database to verify last_seen was updated

**Expected Result:**
- markSeen() method executes successfully
- `last_seen` timestamp is updated in database
- This confirms the method is preserved for future external script use

**Verification:**
```sql
-- Before running script
SELECT id, last_seen FROM dns_records WHERE id = 1;
-- [Run the test script]
-- After running script
SELECT id, last_seen FROM dns_records WHERE id = 1;
-- last_seen should now be updated to current timestamp
```

## Backward Compatibility Checks

### User Management
- Verify user creation, editing, and deletion still works
- Verify authentication still works

### ACL/Mappings
- Verify ACL mappings interface still works (if present)
- Verify role-based access control is not affected

### DNS Record History
- Verify history tracking still works for all operations
- Verify history is displayed correctly in UI

## Performance Considerations

- Form field toggling should be instant (< 50ms)
- API requests should not be slower than before
- Database queries should not be affected

## Browser Compatibility

Test in the following browsers:
- Chrome/Edge (latest)
- Firefox (latest)
- Safari (latest, if possible)

## Notes for Reviewers

1. The `markSeen()` method in `includes/models/DnsRecord.php` has been preserved intentionally for future external script use.

2. The API already had security measures to unset client-provided `last_seen` values; this PR ensures the GET action doesn't update it either.

3. The dynamic form behavior only affects the UI; the server still validates all inputs.

4. Priority field is conditionally sent in payload (only for MX/SRV), but the server handles NULL priority values gracefully for all record types.

5. The `last_seen` field remains in the database schema and in the UI (read-only in edit mode) but is never updated by web UI actions.
