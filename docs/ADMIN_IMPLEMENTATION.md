# Admin Interface Implementation Summary

## Overview

This implementation adds a comprehensive admin interface to DNS3 for managing users, roles, and AD/LDAP authentication mappings. The interface is accessible only to users with the 'admin' role.

## Files Added

### 1. migrations/002_create_auth_mappings.sql
- Creates the `auth_mappings` table for storing AD/LDAP group/DN to role mappings
- Enables automatic role assignment during AD/LDAP authentication
- Fields: source (ad/ldap), dn_or_group, role_id, created_by, notes

### 2. includes/models/User.php
- Complete user management model with CRUD operations
- Methods:
  - `list()` - List users with filters
  - `getById()` - Get user details with roles
  - `create()` - Create new user with password hashing
  - `update()` - Update user information
  - `assignRole()` - Assign role to user
  - `removeRole()` - Remove role from user
  - `getUserRoles()` - Get user's roles
  - `listRoles()` - List all available roles
  - `getRoleById()` - Get role by ID
  - `getRoleByName()` - Get role by name

### 3. api/admin_api.php
- RESTful JSON API for admin operations
- All endpoints require admin authentication
- Endpoints:
  - User management (list, get, create, update)
  - Role assignment (assign, remove)
  - Role listing
  - Mapping management (list, create, delete)
- Proper error handling and validation
- HTTP status codes (401 Unauthorized, 403 Forbidden, 404 Not Found, etc.)

### 4. admin.php
- Main admin interface page
- Tabbed interface with 4 sections:
  1. **Users** - List, create, edit users with role assignment
  2. **Roles** - View available roles
  3. **Mappings** - Create AD/LDAP to role mappings
  4. **ACL** - Placeholder for future implementation
- Filtering capabilities for users
- Modal dialogs for create/edit operations
- Responsive design matching existing site style

### 5. assets/js/admin.js
- Client-side JavaScript for admin interface
- Features:
  - Tab navigation
  - AJAX API calls
  - Dynamic table population
  - Modal management
  - Form validation
  - Alert notifications
  - Filter functionality
- Follows existing JavaScript patterns in the project
- Proper error handling and user feedback

## Files Modified

### includes/header.php
- Added "Administration" tab in navigation
- Tab is visible only to logged-in admin users
- Maintains consistency with existing navigation style

## Database Schema

### auth_mappings table
```sql
CREATE TABLE auth_mappings (
    id INT AUTO_INCREMENT PRIMARY KEY,
    source ENUM('ad', 'ldap') NOT NULL,
    dn_or_group VARCHAR(255) NOT NULL,
    role_id INT NOT NULL,
    created_by INT DEFAULT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    notes TEXT DEFAULT NULL,
    FOREIGN KEY (role_id) REFERENCES roles(id) ON DELETE CASCADE,
    FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL,
    INDEX idx_source (source),
    INDEX idx_role_id (role_id),
    UNIQUE KEY uq_mapping (source, dn_or_group, role_id)
);
```

## Installation Steps

### 1. Apply the Migration
```bash
mysql -u dns3_user -p dns3_db < migrations/002_create_auth_mappings.sql
```

### 2. Create Admin User
```bash
php scripts/create_admin.php --username admin --password 'admin123' --email 'admin@example.local'
```

Or interactively:
```bash
php scripts/create_admin.php
```

### 3. Access Admin Interface
Navigate to: `http://your-domain/admin.php`

## Features Implemented

### User Management
- ✅ List all users with filters (username, auth method, status)
- ✅ View user details including assigned roles
- ✅ Create new users with password hashing (bcrypt)
- ✅ Update user information
- ✅ Assign/remove roles from users
- ✅ Support for multiple authentication methods (database, AD, LDAP)
- ✅ User status management (active/inactive)

### Role Management
- ✅ View all available roles
- ✅ Role information display (name, description)
- ✅ Role assignment during user creation/editing

### AD/LDAP Mapping Management
- ✅ List all auth mappings
- ✅ Create new mappings (AD group/LDAP DN → role)
- ✅ Delete existing mappings
- ✅ Support for notes/descriptions on mappings
- ✅ Validation to prevent duplicate mappings

### Security
- ✅ All admin endpoints require authentication
- ✅ Admin-only access control
- ✅ Password hashing with password_hash() (bcrypt)
- ✅ SQL injection prevention (prepared statements)
- ✅ XSS prevention (HTML escaping)
- ✅ Input validation on both client and server side

### User Interface
- ✅ Consistent with existing site design
- ✅ Tabbed interface for different admin sections
- ✅ Modal dialogs for forms
- ✅ Real-time filtering and search
- ✅ Status badges (active/inactive, roles, auth methods)
- ✅ Alert notifications for success/error messages
- ✅ Responsive design

## API Documentation

### Authentication
All API endpoints require:
- User must be logged in
- User must have 'admin' role

### Endpoints

#### Users
```
GET  /api/admin_api.php?action=list_users[&username=X&auth_method=Y&is_active=Z]
GET  /api/admin_api.php?action=get_user&id=X
POST /api/admin_api.php?action=create_user (JSON body)
POST /api/admin_api.php?action=update_user&id=X (JSON body)
POST /api/admin_api.php?action=assign_role&user_id=X&role_id=Y
POST /api/admin_api.php?action=remove_role&user_id=X&role_id=Y
```

#### Roles
```
GET  /api/admin_api.php?action=list_roles
```

#### Mappings
```
GET  /api/admin_api.php?action=list_mappings
POST /api/admin_api.php?action=create_mapping (JSON body)
POST /api/admin_api.php?action=delete_mapping&id=X
```

### Request Examples

Create user:
```json
POST /api/admin_api.php?action=create_user
{
  "username": "john.doe",
  "email": "john@example.com",
  "auth_method": "database",
  "password": "SecurePass123",
  "is_active": 1,
  "role_ids": [2]
}
```

Create mapping:
```json
POST /api/admin_api.php?action=create_mapping
{
  "source": "ad",
  "dn_or_group": "CN=DNSAdmins,OU=Groups,DC=example,DC=com",
  "role_id": 1,
  "notes": "Auto-assign admin role to DNS Admins group members"
}
```

## Usage Examples

### Creating an Admin User (First Installation)

#### Méthode A — Via script PHP (recommandée)

**Prérequis :**
- `config.php` configuré avec les credentials de base de données
- PHP CLI disponible et fonctionnel

**Commande :**
```bash
php scripts/create_admin.php --username admin --password 'AdminPass123!' --email 'admin@example.local'
```

**Ce que fait le script :**
1. Crée un enregistrement dans la table `users` avec le mot de passe hashé via `password_hash(..., PASSWORD_DEFAULT)`
2. Si la table `roles` contient un rôle `name='admin'`, ajoute automatiquement une entrée dans `user_roles`
3. Si l'utilisateur existe déjà, met à jour son mot de passe
4. Affiche un message de succès ou d'erreur

**Vérifications SQL post-exécution :**
```sql
SELECT id, username, email, auth_method, is_active FROM users WHERE username = 'admin';
SELECT r.id, r.name FROM roles r WHERE r.name = 'admin';
SELECT * FROM user_roles WHERE user_id = <id_utilisateur>;
```

> Pour plus d'options (mode interactif, etc.), voir `scripts/create_admin.php`.

#### Méthode B — Via SQL direct (alternative)

```bash
# Générer le hash du mot de passe
php -r "echo password_hash('VotreMotDePasse', PASSWORD_DEFAULT) . PHP_EOL;"
```

```sql
-- Insérer l'utilisateur
INSERT INTO users (username, email, password, auth_method, is_active, created_at)
VALUES ('admin', 'admin@example.local', '$2y$10$...votre_hash...', 'database', 1, NOW());

-- Assigner le rôle admin
INSERT INTO user_roles (user_id, role_id, assigned_at)
SELECT u.id, r.id, NOW() FROM users u, roles r
WHERE u.username = 'admin' AND r.name = 'admin';
```

**⚠️ Note de sécurité :** Changez le mot de passe par défaut immédiatement après la première connexion. Limitez l'accès au répertoire `scripts/` en production.

### Creating a Database User (via Interface)
1. Navigate to admin.php
2. Click "Créer un utilisateur"
3. Fill in:
   - Username: john.doe
   - Email: john@example.com
   - Auth method: database
   - Password: SecurePassword123
   - Roles: Check "user"
4. Click "Enregistrer"

### Creating an AD Mapping
1. Navigate to "Mappings AD/LDAP" tab
2. Click "Créer un mapping"
3. Fill in:
   - Source: Active Directory
   - DN/Group: CN=DNSAdmins,OU=Groups,DC=example,DC=com
   - Role: admin
   - Notes: DNS Administrators group
4. Click "Créer"

## Future Integration

### AD/LDAP Authentication Integration
The `auth_mappings` table is ready to be used. To integrate with authentication:

1. Modify `includes/auth.php` in `authenticateActiveDirectory()`:
```php
// After successful AD bind
$groups = /* get user's AD groups */;
foreach ($groups as $groupDn) {
    $stmt = $this->db->prepare("
        SELECT role_id FROM auth_mappings 
        WHERE source = 'ad' AND dn_or_group = ?
    ");
    $stmt->execute([$groupDn]);
    while ($mapping = $stmt->fetch()) {
        $userModel = new User();
        $userModel->assignRole($user['id'], $mapping['role_id']);
    }
}
```

2. Similarly for `authenticateLDAP()`:
```php
// After successful LDAP bind
$userDn = /* user's DN */;
$stmt = $this->db->prepare("
    SELECT role_id FROM auth_mappings 
    WHERE source = 'ldap' AND dn_or_group LIKE ?
");
// Check if user DN matches any mapping pattern
```

## Testing

### Manual Testing Checklist
- [ ] Access admin.php as non-admin user (should redirect)
- [ ] Access admin.php as admin user (should show interface)
- [ ] List users with various filters
- [ ] Create a database user with password
- [ ] Create an AD user without password
- [ ] Edit user and change email
- [ ] Assign/remove roles from user
- [ ] Create AD mapping
- [ ] Create LDAP mapping
- [ ] Delete mapping
- [ ] View roles list

### API Testing
```bash
# Test user creation (requires admin authentication)
curl -X POST http://localhost/api/admin_api.php?action=create_user \
  -H "Content-Type: application/json" \
  -d '{"username":"test","email":"test@test.com","auth_method":"database","password":"test123"}'

# Test user listing
curl http://localhost/api/admin_api.php?action=list_users

# Test mapping creation
curl -X POST http://localhost/api/admin_api.php?action=create_mapping \
  -H "Content-Type: application/json" \
  -d '{"source":"ad","dn_or_group":"CN=Test,DC=example,DC=com","role_id":1}'
```

## Troubleshooting

### Common Issues

1. **Admin tab not visible**
   - Ensure user has admin role assigned
   - Check `user_roles` table
   - Verify session is active

2. **Cannot create user**
   - Check database permissions
   - Verify username/email is unique
   - For database auth, password is required

3. **Mapping creation fails**
   - Check for duplicate mapping (same source+dn_or_group+role)
   - Verify role_id exists
   - Check foreign key constraints

4. **API returns 401/403**
   - Ensure user is logged in
   - Verify user has admin role
   - Check session configuration

## Maintenance

### Backup Before Changes
```bash
mysqldump -u dns3_user -p dns3_db > backup_$(date +%Y%m%d_%H%M%S).sql
```

### View Audit Information
All changes are tracked with timestamps and user information in the database.

### Logs
Check PHP error logs for issues:
```bash
tail -f /var/log/php/error.log
```

## Code Quality

### Standards Followed
- ✅ PSR-style PHP code formatting
- ✅ Prepared statements for SQL (no SQL injection)
- ✅ HTML escaping for output (no XSS)
- ✅ RESTful API design
- ✅ Consistent error handling
- ✅ Proper HTTP status codes
- ✅ Comprehensive inline comments
- ✅ Follows existing project patterns

### Dependencies
- PHP 7.4+ (uses password_hash, PDO)
- MySQL/MariaDB
- Existing DNS3 infrastructure (config.php, db.php, auth.php)

## Documentation

- `ADMIN_INTERFACE_GUIDE.md` - User guide for the admin interface
- `ADMIN_IMPLEMENTATION.md` - This file, technical implementation details
- Inline code comments in all PHP/JS files
- SQL migration with explanatory comments

## Conclusion

This implementation provides a complete, secure, and user-friendly admin interface for managing users, roles, and AD/LDAP mappings. It follows the existing code patterns, maintains consistency with the current UI, and is ready for production use after proper testing.

The auth_mappings infrastructure is in place and ready to be integrated into the AD/LDAP authentication flow for automatic role assignment based on group membership.
