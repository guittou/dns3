# Admin Authentication Changes

## Overview
This document describes the changes made to enforce database-only user creation via the admin interface and implement AD/LDAP role mapping during authentication.

## Changes Made

### 1. Database-Only User Creation (Server-Side Enforcement)

#### api/admin_api.php
- `create_user` endpoint now **forces** `auth_method = 'database'` server-side
- Any client-provided `auth_method` value is ignored
- Password is required for all admin-created users
- `update_user` endpoint **prevents** changing `auth_method` to 'ad' or 'ldap'
- Returns HTTP 400 error with clear message if attempt is made to switch to AD/LDAP

#### includes/models/User.php
- `create()` method hardcodes `auth_method = 'database'`
- Password hashing is enforced for all database users
- `update()` method completely removes support for changing `auth_method`
- Server-side validation ensures auth_method integrity

#### assets/js/admin.js
- Client sets `auth_method: 'database'` for new users
- Auth method field hidden when creating new users
- Auth method field shown but disabled (read-only) when editing existing users
- Password field shown/hidden based on user's auth_method

#### admin.php
- Auth method field in modal marked as disabled
- Helper text added explaining that admin-created users use database auth
- AD/LDAP users are noted to be created automatically on first login

### 2. ACL UI Removal

#### admin.php
- ACL tab button removed from navigation
- ACL tab content section removed
- Only 3 tabs remain: Utilisateurs, Rôles, Mappings AD/LDAP

#### includes/header.php
- Verified: No ACL links present (none were there)

### 3. AD/LDAP Role Mapping Implementation

#### includes/auth.php
- `authenticateActiveDirectory()` now retrieves user's `memberOf` groups
- `authenticateLDAP()` retrieves user's DN
- New `createOrUpdateUserWithMappings()` method:
  - Creates minimal user record if user doesn't exist
  - Sets `auth_method` to 'ad' or 'ldap' appropriately
  - Calls role mapping logic after user creation/update
- New `applyRoleMappings()` method:
  - Queries `auth_mappings` table for matching rules
  - For AD: Matches group DN against user's `memberOf` attribute
  - For LDAP: Checks if user DN contains the mapped DN/OU path
  - Persists role assignments using `INSERT...ON DUPLICATE KEY UPDATE`
  - Uses prepared statements for security
  - Defensive: handles missing attributes gracefully

#### Database Schema
- `auth_mappings` table (from migration 002):
  - Maps AD groups or LDAP DN/OU paths to application roles
  - Supports both 'ad' and 'ldap' sources
  - Unique constraint prevents duplicate mappings

## Testing Instructions

### Test 1: Database User Creation
1. Navigate to admin panel (admin.php)
2. Click "Créer un utilisateur"
3. Fill in username, email, password
4. Notice auth_method field is not shown
5. Save user
6. Verify in database: `SELECT username, auth_method FROM users WHERE username='testuser';`
7. Expected: `auth_method = 'database'`

### Test 2: Auth Method Enforcement (Crafted Request)
```bash
curl -X POST 'http://localhost/api/admin_api.php?action=create_user' \
  -H 'Content-Type: application/json' \
  -d '{
    "username": "testuser2",
    "email": "test2@example.com",
    "password": "password123",
    "auth_method": "ad"
  }'
```
Expected: User created with `auth_method='database'` (server ignores 'ad')

### Test 3: Prevent Auth Method Change
```bash
curl -X POST 'http://localhost/api/admin_api.php?action=update_user&id=1' \
  -H 'Content-Type: application/json' \
  -d '{
    "auth_method": "ldap"
  }'
```
Expected: HTTP 400 error with message about not being able to change auth_method

### Test 4: ACL Tab Removal
1. Navigate to admin panel (admin.php)
2. Verify only 3 tabs are visible:
   - Utilisateurs
   - Rôles
   - Mappings AD/LDAP
3. Verify no ACL tab

### Test 5: AD/LDAP Role Mapping
1. Navigate to "Mappings AD/LDAP" tab
2. Create a mapping:
   - Source: Active Directory (or LDAP)
   - DN/Group: `CN=DNSAdmins,OU=Groups,DC=example,DC=com`
   - Role: admin
3. Login as AD user who is member of DNSAdmins group
4. Verify in database:
   ```sql
   SELECT u.username, u.auth_method, r.name as role
   FROM users u
   JOIN user_roles ur ON u.id = ur.user_id
   JOIN roles r ON ur.role_id = r.id
   WHERE u.username = 'aduser';
   ```
5. Expected: User created with `auth_method='ad'` and role 'admin' assigned

## Security Considerations

1. **Server-Side Authority**: All auth_method validation happens server-side. Client hints are secondary and cannot override server logic.

2. **Password Hashing**: All database users have passwords hashed using `PASSWORD_DEFAULT` (bcrypt).

3. **Prepared Statements**: All database queries use prepared statements to prevent SQL injection.

4. **Separation of Concerns**: 
   - Admin-created users are always database users
   - AD/LDAP users are created automatically during authentication
   - This prevents privilege escalation via auth_method manipulation

## Backwards Compatibility

- Existing database users are unaffected
- Existing AD/LDAP users continue to work
- Auth mappings are additive - they don't remove existing roles
- No breaking changes to the API structure (endpoints remain the same)
