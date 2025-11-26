> **ARCHIVED DOCUMENT NOTE** : Les fichiers de migration mentionnés dans ce document ont été supprimés. Pour les nouvelles installations, utilisez `database.sql` (ou `structure_ok_dns3_db.sql`).

## Summary

This PR implements strict server-side enforcement of database-only user creation via the admin interface, removes the ACL UI, and adds automatic role mapping for AD/LDAP users during authentication.

## Changes Implemented

### 1. Database-Only User Creation (Server-Side Enforcement) ✅

**api/admin_api.php:**
- `create_user` endpoint forces `auth_method='database'`, ignoring any client input
- `update_user` endpoint prevents changing auth_method to 'ad' or 'ldap' (returns 400 error with clear message)

**includes/models/User.php:**
- `create()` method hardcodes database auth_method server-side
- `update()` method removes auth_method update support entirely
- Password hashing enforced for all database users

**assets/js/admin.js:**
- Client automatically sets auth_method='database' for new users
- Removed unused `updatePasswordFieldVisibility()` function
- Removed auth_method change event listener

**admin.php:**
- Auth method field hidden for new users
- Auth method field shown but disabled (read-only) for existing users
- Helper text added explaining AD/LDAP users are auto-created

### 2. ACL UI Removal ✅

**admin.php:**
- Removed ACL tab button from navigation
- Removed ACL tab content section (lines 140-149)
- Only 3 tabs remain: Utilisateurs, Rôles, Mappings AD/LDAP

**includes/header.php:**
- Verified: No ACL links present (none existed)

### 3. AD/LDAP Mapping Preservation ✅

- Mappings tab remains visible and functional
- All API endpoints preserved: `list_mappings`, `create_mapping`, `delete_mapping`
- UI includes helpful examples for AD group DN and LDAP OU syntax
- Migration 002 creates `auth_mappings` table with proper constraints

### 4. AD/LDAP Authentication with Role Mapping ✅

**includes/auth.php:**
- `authenticateActiveDirectory()` retrieves user's `memberOf` groups
- `authenticateLDAP()` retrieves user's DN
- New `createOrUpdateUserWithMappings()` method:
  - Creates minimal user record if user doesn't exist
  - Sets `auth_method` to 'ad' or 'ldap' appropriately
  - Calls `applyRoleMappings()` after user creation/update
- New `applyRoleMappings()` method:
  - Queries `auth_mappings` table for rules matching the auth source
  - **For AD:** Matches group DN case-insensitively against user's `memberOf` attribute
  - **For LDAP:** Checks if user DN contains the mapped DN/OU path (case-insensitive)
  - Persists role assignments using `INSERT...ON DUPLICATE KEY UPDATE`
  - Uses prepared statements throughout
  - Defensive: handles missing LDAP attributes gracefully

## Code Quality

- ✅ All PHP files pass syntax validation (`php -l`)
- ✅ All JavaScript files pass syntax validation (`node -c`)
- ✅ Prepared statements used throughout
- ✅ Comprehensive error handling and logging
- ✅ Backwards compatible with existing users
- ✅ Security-first design (server-side validation authority)

## Files Modified

```
admin.php                | 20 ++++----------------
api/admin_api.php        | 31 ++++++++++++++-----------------
assets/js/admin.js       | 49 ++++++++++++++++++++++---------------------------
includes/auth.php        | 88 ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++------------
includes/models/User.php | 21 +++++++++++----------
ADMIN_AUTH_CHANGES.md    | 146 ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
6 files changed, 273 insertions(+), 82 deletions(-)
```

## Testing Instructions

Comprehensive testing procedures are documented in [ADMIN_AUTH_CHANGES.md](./ADMIN_AUTH_CHANGES.md).

### Quick Test Checklist

1. **Database user creation:**
   - Navigate to admin panel, create new user
   - Verify `auth_method='database'` in database
   - Verify password is hashed (bcrypt)

2. **Auth method enforcement (crafted request):**
   ```bash
   curl -X POST '.../api/admin_api.php?action=create_user' \
     -H 'Content-Type: application/json' \
     -d '{"username":"test","email":"test@ex.com","password":"pass","auth_method":"ad"}'
   ```
   Expected: User created with `auth_method='database'` (server ignores 'ad')

3. **Update prevention:**
   ```bash
   curl -X POST '.../api/admin_api.php?action=update_user&id=1' \
     -H 'Content-Type: application/json' \
     -d '{"auth_method":"ldap"}'
   ```
   Expected: HTTP 400 error with clear message

4. **ACL tab removal:**
   - Navigate to admin.php
   - Verify only 3 tabs visible (no ACL tab)

5. **AD/LDAP mapping:**
   - Create mapping: source=ad, group=CN=DNSAdmins,..., role=admin
   - Login as AD user in DNSAdmins group
   - Verify user created with `auth_method='ad'`
   - Verify role assigned in `user_roles` table

## Security Considerations

### Server-Side Authority
All `auth_method` validation happens server-side. Client hints are completely ignored to prevent:
- Privilege escalation via auth_method manipulation
- Bypassing password requirements
- Unauthorized role assignments

### Defense in Depth
1. **API Layer:** Enforces database-only creation, blocks AD/LDAP updates
2. **Model Layer:** Double-checks auth_method, ensures password hashing
3. **Authentication Layer:** Only creates AD/LDAP users during actual authentication
4. **Database Layer:** Prepared statements prevent SQL injection

### Password Security
- Database users: Password required, hashed with `PASSWORD_DEFAULT` (bcrypt)
- AD/LDAP users: Empty password field (authenticated externally)

### Role Mapping Security
- Mappings queried per-authentication (not cached)
- Case-insensitive matching prevents bypass via case changes
- `INSERT...ON DUPLICATE KEY` prevents duplicate role assignments
- Failed mappings logged but don't block authentication

## Backwards Compatibility

- ✅ Existing database users continue to work unchanged
- ✅ Existing AD/LDAP users continue to authenticate
- ✅ Auth mappings are additive (don't remove existing roles)
- ✅ No breaking API changes (same endpoints, compatible request/response)
- ✅ Database schema changes are additive (`auth_mappings` table via migration)

## Migration Notes

1. Run migration 002 to create `auth_mappings` table:
   ```bash
   mysql -u user -p dns3_db < migrations/002_create_auth_mappings.sql
   ```

2. Create initial auth mappings via admin UI:
   - Navigate to "Mappings AD/LDAP" tab
   - Add mappings for your AD groups or LDAP OUs

3. Test with a known AD/LDAP user:
   - Login should create user with correct auth_method
   - Roles should be automatically assigned based on mappings

## Related Documentation

- [ADMIN_AUTH_CHANGES.md](./ADMIN_AUTH_CHANGES.md) - Detailed implementation documentation
- [migrations/002_create_auth_mappings.sql](./migrations/002_create_auth_mappings.sql) - Database schema for mappings

## PR Checklist

- [x] Code follows project style guidelines
- [x] No syntax errors in PHP or JavaScript
- [x] Security best practices followed (prepared statements, server-side validation)
- [x] Backwards compatible with existing functionality
- [x] Documentation provided (ADMIN_AUTH_CHANGES.md)
- [x] Testing instructions included
- [ ] Manual testing completed (see testing checklist above)
- [ ] Migration 002 executed in test environment
- [ ] AD/LDAP authentication tested with role mappings
