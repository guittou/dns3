# Manual Testing Instructions for Database-Only User Creation

This document provides step-by-step instructions for testing the enforcement of database-only user creation and the removal of ACL functionality.

## Changes Implemented

### 1. Server-Side Enforcement (api/admin_api.php)
- **Create User Endpoint**: Forces `auth_method='database'` regardless of what the client sends
- **Update User Endpoint**: Removes any attempt to change `auth_method` from the update request
- Both endpoints now properly validate required fields and return clear error messages

### 2. UI Changes (admin.php)
- **Removed ACL Tab**: The "ACL" tab button and content have been completely removed
- **Auth Method Field**: Changed from dropdown to read-only text field showing "Base de données"
- **Filter Options**: Removed AD and LDAP options from the auth method filter dropdown

### 3. Client-Side Changes (assets/js/admin.js)
- **Forced Database Auth**: Client always sends `auth_method='database'` when creating/updating users
- **Removed ACL Code**: All ACL-related event handlers and display logic have been removed
- **Simplified Password Logic**: Password field is always visible since only database users are supported

## Test Cases

### Test 1: Create User via Admin UI (Normal Path)
**Objective**: Verify that creating a user through the UI works correctly and only creates database users.

**Steps**:
1. Log in as an admin user
2. Navigate to the Administration page (`/admin.php`)
3. Click on "Créer un utilisateur" button
4. Fill in the form:
   - Username: `testuser1`
   - Email: `testuser1@example.com`
   - Password: `SecurePassword123!`
   - Status: Active
   - Select any roles as needed
5. Observe the "Méthode d'authentification" field
6. Submit the form

**Expected Results**:
- The auth method field displays "Base de données" and is disabled/read-only
- User is created successfully
- User appears in the users table with auth method badge showing "database"
- Success message is displayed

---

### Test 2: Verify ACL Tab Removal
**Objective**: Confirm that the ACL tab has been completely removed from the administration interface.

**Steps**:
1. Log in as an admin user
2. Navigate to the Administration page (`/admin.php`)
3. Examine the tab navigation at the top of the page

**Expected Results**:
- Only three tabs are visible: "Utilisateurs", "Rôles", and "Mappings AD/LDAP"
- No "ACL" tab is present
- All three remaining tabs function correctly when clicked

---

### Test 3: Attempt to Create Non-Database User via DevTools (Security Test)
**Objective**: Verify server-side enforcement by attempting to bypass client-side restrictions.

**Steps**:
1. Log in as an admin user
2. Navigate to the Administration page (`/admin.php`)
3. Open browser DevTools (F12)
4. Go to the Console tab
5. Execute the following JavaScript code to attempt creating an AD user:

```javascript
fetch(window.API_BASE + 'admin_api.php?action=create_user', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    credentials: 'same-origin',
    body: JSON.stringify({
        username: 'hackuser',
        email: 'hack@example.com',
        password: 'Password123!',
        auth_method: 'ad'  // Attempt to set non-database auth
    })
})
.then(r => r.json())
.then(data => console.log('Response:', data));
```

6. Check the response in the console
7. Query the database or refresh the users list to verify the user

**Expected Results**:
- API accepts the request (returns success)
- User is created with `auth_method='database'` (NOT 'ad')
- Server-side enforcement works correctly, ignoring the client's attempted override

---

### Test 4: Attempt to Change Auth Method via Update (Security Test)
**Objective**: Verify that existing users cannot have their auth_method changed.

**Steps**:
1. Log in as an admin user
2. Create a test user (if not already present) via the UI
3. Note the user's ID from the users table
4. Open browser DevTools (F12)
5. Execute the following JavaScript (replace USER_ID with actual ID):

```javascript
const userId = 1; // Replace with actual user ID
fetch(window.API_BASE + 'admin_api.php?action=update_user&id=' + userId, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    credentials: 'same-origin',
    body: JSON.stringify({
        auth_method: 'ldap',  // Attempt to change to LDAP
        email: 'updated@example.com'
    })
})
.then(r => r.json())
.then(data => console.log('Response:', data));
```

6. Refresh the users list
7. Click "Modifier" on the user to check their details

**Expected Results**:
- API accepts the request (returns success)
- User's auth_method remains 'database' (NOT changed to 'ldap')
- Other fields (like email) are updated correctly
- Server-side enforcement prevents auth_method changes

---

### Test 5: Edit Existing User via UI
**Objective**: Verify that editing users through the UI works correctly.

**Steps**:
1. Log in as an admin user
2. Navigate to the Administration page (`/admin.php`)
3. Click "Modifier" on any existing user
4. Observe the form fields
5. Modify the email address or other fields (not auth method)
6. Submit the form

**Expected Results**:
- Modal opens with user data pre-filled
- Auth method field shows "Base de données" and is disabled
- Changes are saved successfully
- User's auth_method remains unchanged

---

### Test 6: Password Requirements
**Objective**: Verify password validation for database users.

**Steps**:
1. Log in as an admin user
2. Click "Créer un utilisateur"
3. Fill in username and email
4. Leave password field empty
5. Try to submit

**Expected Results**:
- Client-side validation prevents submission (required field)
- If bypassed, server returns error: "Password is required for database authentication"

---

### Test 7: Filter Users by Auth Method
**Objective**: Verify that auth method filtering still works (database only).

**Steps**:
1. Navigate to Administration > Users tab
2. Check the "Méthode d'authentification" filter dropdown
3. Try filtering by "Base de données"

**Expected Results**:
- Dropdown only shows two options: "Toutes les méthodes" and "Base de données"
- No AD or LDAP options are present
- Filtering works correctly

---

## Database Verification Queries

If you have direct database access, you can verify the changes with these SQL queries:

### Check Auth Methods of All Users
```sql
SELECT id, username, email, auth_method, created_at 
FROM users 
ORDER BY created_at DESC;
```

**Expected**: All users created through the admin interface after this change should have `auth_method='database'`

### Verify No Non-Database Users Created Recently
```sql
SELECT id, username, auth_method, created_at 
FROM users 
WHERE auth_method != 'database' 
  AND created_at > '2025-10-20'
ORDER BY created_at DESC;
```

**Expected**: Empty result set (no non-database users created after the deployment)

---

## Security Validation Checklist

- [ ] ACL tab is completely removed from the UI
- [ ] Cannot create users with auth_method other than 'database' via UI
- [ ] Cannot create users with auth_method other than 'database' via API (even with crafted requests)
- [ ] Cannot update user's auth_method via UI
- [ ] Cannot update user's auth_method via API (even with crafted requests)
- [ ] Password is required when creating database users (enforced on both client and server)
- [ ] Existing functionality (role assignment, user activation, etc.) still works correctly
- [ ] All three remaining tabs (Users, Roles, Mappings) function correctly

---

## Rollback Plan

If issues are discovered, the changes can be rolled back by:
1. Reverting the commit or checking out the previous version
2. The changes are minimal and localized to three files:
   - `api/admin_api.php`
   - `admin.php`
   - `assets/js/admin.js`

---

## Notes for Testers

- **Browser Cache**: Clear browser cache or use hard refresh (Ctrl+Shift+R) to ensure you're loading the latest JavaScript
- **Session**: If you encounter issues, try logging out and back in to refresh the session
- **Error Messages**: Check browser console for any JavaScript errors
- **Server Logs**: Check server error logs for any PHP errors

---

## Success Criteria

The implementation is successful if:
1. ✅ All test cases pass as expected
2. ✅ No ACL-related UI elements are visible
3. ✅ Server-side enforcement cannot be bypassed
4. ✅ Existing admin functionality remains intact
5. ✅ No errors in browser console or server logs
