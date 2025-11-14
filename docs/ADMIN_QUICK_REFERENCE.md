# Admin Interface - Quick Reference Card

## 🚀 Quick Start

### Installation (3 steps)
```bash
# 1. Apply migration
mysql -u dns3_user -p dns3_db < migrations/002_create_auth_mappings.sql

# 2. Create admin user
php scripts/create_admin.php --username admin --password 'admin123' --email 'admin@example.local'

# 3. Access
http://your-domain/admin.php
```

---

## 👥 User Management

### Create User (Database Auth)
```
Navigation: Admin → Utilisateurs → Créer un utilisateur
Fields:
  - Username: required, unique
  - Email: required, unique
  - Auth method: database
  - Password: required (hashed with bcrypt)
  - Status: active/inactive
  - Roles: select one or more
```

### Create User (AD/LDAP Auth)
```
Navigation: Admin → Utilisateurs → Créer un utilisateur
Fields:
  - Username: required, unique
  - Email: required, unique
  - Auth method: ad OR ldap
  - Password: NOT required
  - Status: active/inactive
  - Roles: select one or more
```

### Edit User
```
Navigation: Admin → Utilisateurs → Click "Modifier"
Can change:
  - Email
  - Password (optional, leave blank to keep current)
  - Auth method
  - Status
  - Roles
```

### Filter Users
```
Available filters:
  - Username (text search)
  - Auth method (database/ad/ldap)
  - Status (active/inactive)
```

---

## 🔐 Role Management

### Available Roles
| Role  | Description                    | Badge Color |
|-------|--------------------------------|-------------|
| admin | Full access to all features    | Red         |
| user  | Read-only access               | Blue        |

### View Roles
```
Navigation: Admin → Rôles
Shows: ID, Name, Description, Created date
```

---

## 🌐 AD/LDAP Mappings

### Create AD Mapping
```
Navigation: Admin → Mappings AD/LDAP → Créer un mapping

Example:
  Source: Active Directory
  DN/Group: CN=DNSAdmins,OU=Groups,DC=example,DC=com
  Role: admin
  Notes: DNS Administrators group - auto-assign admin role
```

### Create LDAP Mapping
```
Navigation: Admin → Mappings AD/LDAP → Créer un mapping

Example:
  Source: LDAP
  DN/Group: ou=IT,dc=example,dc=com
  Role: user
  Notes: IT department - auto-assign user role
```

### Delete Mapping
```
Navigation: Admin → Mappings AD/LDAP → Click "Supprimer"
Requires: Confirmation
```

---

## 🔧 API Usage

### Authentication
All API calls require:
- Active session (logged in)
- Admin role

### Common Endpoints

#### List Users
```bash
curl 'http://domain/api/admin_api.php?action=list_users' \
  --cookie "PHPSESSID=your_session_id"
```

#### Create User
```bash
curl -X POST 'http://domain/api/admin_api.php?action=create_user' \
  -H 'Content-Type: application/json' \
  -d '{
    "username": "john.doe",
    "email": "john@example.com",
    "auth_method": "database",
    "password": "SecurePass123",
    "role_ids": [2]
  }' \
  --cookie "PHPSESSID=your_session_id"
```

#### Create Mapping
```bash
curl -X POST 'http://domain/api/admin_api.php?action=create_mapping' \
  -H 'Content-Type: application/json' \
  -d '{
    "source": "ad",
    "dn_or_group": "CN=DNSAdmins,OU=Groups,DC=example,DC=com",
    "role_id": 1,
    "notes": "DNS Admins"
  }' \
  --cookie "PHPSESSID=your_session_id"
```

---

## 🎨 UI Elements

### Badge Colors
| Type       | Color  | Example        |
|------------|--------|----------------|
| admin role | Red    | [admin]        |
| user role  | Blue   | [user]         |
| Active     | Green  | [Actif]        |
| Inactive   | Gray   | [Inactif]      |
| Database   | Teal   | [DB]           |
| AD         | Purple | [AD]           |
| LDAP       | Orange | [LDAP]         |

### Tabs
- **Utilisateurs** - Manage users
- **Rôles** - View roles
- **Mappings AD/LDAP** - Configure auth mappings
- **ACL** - (Future) Access control lists

---

## ⚠️ Common Issues

### "Admin tab not visible"
**Solution:**
```sql
-- Check if user has admin role
SELECT u.username, r.name 
FROM users u
JOIN user_roles ur ON u.id = ur.user_id
JOIN roles r ON ur.role_id = r.id
WHERE u.username = 'your_username';

-- If missing, assign admin role
INSERT INTO user_roles (user_id, role_id)
SELECT u.id, r.id FROM users u, roles r
WHERE u.username = 'your_username' AND r.name = 'admin';
```

### "Cannot create user - username exists"
**Solution:**
- Choose different username
- Or edit existing user

### "Password required for database auth"
**Solution:**
- For auth_method='database', password is required
- For AD/LDAP, password should be empty

### "Mapping creation fails"
**Solution:**
- Check for duplicate (same source+dn_or_group+role)
- Verify role_id exists
- Ensure DN format is correct

---

## 📊 Database Tables

### users
```
Columns: id, username, email, password, auth_method, created_at, 
         last_login, is_active
```

### roles
```
Columns: id, name, description, created_at
```

### user_roles
```
Columns: user_id, role_id, assigned_at
```

### auth_mappings
```
Columns: id, source, dn_or_group, role_id, created_by, 
         created_at, notes
```

---

## 🔍 Useful Queries

### List all admins
```sql
SELECT u.username, u.email 
FROM users u
JOIN user_roles ur ON u.id = ur.user_id
JOIN roles r ON ur.role_id = r.id
WHERE r.name = 'admin' AND u.is_active = 1;
```

### Count users by auth method
```sql
SELECT auth_method, COUNT(*) as count
FROM users
GROUP BY auth_method;
```

### List all mappings
```sql
SELECT am.source, am.dn_or_group, r.name as role_name, am.notes
FROM auth_mappings am
JOIN roles r ON am.role_id = r.id
ORDER BY am.source, r.name;
```

### Find users without roles
```sql
SELECT u.id, u.username, u.email
FROM users u
LEFT JOIN user_roles ur ON u.id = ur.user_id
WHERE ur.role_id IS NULL;
```

---

## 📝 Best Practices

### Password Policy
- Minimum 8 characters
- Mix of letters, numbers, special chars
- Never share passwords
- Change default admin password immediately

### User Creation
- Use descriptive usernames (firstname.lastname)
- Assign minimal required roles
- Set inactive for temporary users
- Document AD/LDAP users in notes

### Mapping Strategy
- One mapping per AD group
- Document purpose in notes field
- Review mappings quarterly
- Test before production deployment

### Security
- Regular password rotation
- Monitor user activity
- Review admin users monthly
- Backup before bulk changes

---

## 🆘 Emergency Procedures

### Reset Admin Password
```bash
php scripts/create_admin.php --username admin --password 'NewSecurePass123'
```

### Manually Create Admin User
```sql
-- Generate hash in PHP first:
-- php -r "echo password_hash('YourPassword', PASSWORD_DEFAULT);"

INSERT INTO users (username, email, password, auth_method, is_active)
VALUES ('admin', 'admin@example.local', '$2y$10$...hash...', 'database', 1);

INSERT INTO user_roles (user_id, role_id)
SELECT u.id, r.id FROM users u, roles r
WHERE u.username = 'admin' AND r.name = 'admin';
```

### Disable User Access
```sql
UPDATE users SET is_active = 0 WHERE username = 'username';
```

### Remove Admin Rights
```sql
DELETE FROM user_roles 
WHERE user_id = (SELECT id FROM users WHERE username = 'username')
AND role_id = (SELECT id FROM roles WHERE name = 'admin');
```

---

## 📞 Support Checklist

Before asking for help:
- [ ] Check error logs: `/var/log/php/error.log`
- [ ] Verify database connection
- [ ] Confirm migrations applied
- [ ] Check user has admin role
- [ ] Clear browser cache/cookies
- [ ] Try different browser
- [ ] Review documentation

---

## 🔗 Related Documentation

- **Full Guide:** `ADMIN_INTERFACE_GUIDE.md`
- **Technical Details:** `ADMIN_IMPLEMENTATION.md`
- **UI Overview:** `ADMIN_UI_OVERVIEW.md`
- **Release Notes:** `ADMIN_RELEASE_NOTES.md`

---

## 💡 Tips & Tricks

### Keyboard Shortcuts
- `ESC` - Close modal
- `Enter` - Submit form (when focused in input)
- `Tab` - Navigate form fields

### Performance
- Use filters to reduce result set
- Clear cache after major changes
- Monitor database size

### Workflow
1. Create user
2. Assign basic role (user)
3. Test login
4. Upgrade to admin if needed
5. Document in notes

---

**Version:** 1.0.0  
**Last Updated:** 2025-10-20  
**Questions?** See full documentation files.
