# Admin Interface Implementation Summary

## Overview

This implementation adds a comprehensive admin interface to DNS3 for managing users, roles, and AD/LDAP authentication mappings. The interface is accessible only to users with the 'admin' role.

## Files Added

### 1. Database Schema (auth_mappings table)
> **Note** : Les fichiers de migration ont été supprimés. Le schéma complet est maintenant disponible dans `database.sql`.

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

### 1. Import Database Schema
```bash
mysql -u dns3_user -p dns3_db < database.sql
```

> **Note** : Les fichiers de migration ont été supprimés. Pour les nouvelles installations, utilisez `database.sql` (ou `structure_ok_dns3_db.sql`).

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
- ✅ Désactivation d'utilisateurs via bouton "Supprimer" (dans la liste et le modal)
- ✅ Protection contre l'auto-désactivation (impossible de désactiver son propre compte)
- ✅ Protection contre la désactivation du dernier administrateur actif

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
POST /api/admin_api.php?action=deactivate_user&id=X - Désactive un utilisateur (is_active=0)
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

Deactivate user:
```bash
POST /api/admin_api.php?action=deactivate_user&id=5

# Réponse succès:
{ "success": true, "message": "Utilisateur désactivé avec succès" }

# Erreurs possibles:
# - 400: "Impossible de désactiver votre propre compte."
# - 400: "Impossible de désactiver le dernier administrateur actif."
# - 404: "Utilisateur non trouvé"
```

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

## Intégration Authentification AD/LDAP — Contrôle par Mappings

### Vue d'ensemble

L'intégration des mappings `auth_mappings` dans le flux d'authentification AD/LDAP est **complète et opérationnelle**. Cette implémentation renforce la sécurité en n'autorisant la création/activation des comptes AD/LDAP que si l'utilisateur correspond à au moins un mapping configuré.

### Méthodes Ajoutées dans `includes/auth.php`

#### 1. `getRoleIdsFromMappings($auth_method, $groups = [], $user_dn = '')`

Retourne un tableau d'IDs de rôle correspondant aux mappings pour la source donnée.

**Comportement :**
- Pour `ad` : Compare chaque groupe `memberOf` avec `dn_or_group` (insensible à la casse via `strcasecmp`).
- Pour `ldap` : Vérifie si le DN utilisateur contient `dn_or_group` (insensible à la casse via `stripos`).

```php
private function getRoleIdsFromMappings($auth_method, $groups = [], $user_dn = '') {
    $matchedRoleIds = [];
    // Récupère les mappings pour la source (ad/ldap)
    $stmt = $this->db->prepare("SELECT id, dn_or_group, role_id FROM auth_mappings WHERE source = ?");
    $stmt->execute([$auth_method]);
    $mappings = $stmt->fetchAll();
    
    foreach ($mappings as $mapping) {
        $matches = false;
        
        if ($auth_method === 'ad') {
            // Comparaison case-insensitive des groupes AD
            foreach ($groups as $group_dn) {
                if (strcasecmp($group_dn, $mapping['dn_or_group']) === 0) {
                    $matches = true;
                    break;
                }
            }
        } elseif ($auth_method === 'ldap') {
            // Vérifie si user_dn contient dn_or_group
            if ($user_dn && stripos($user_dn, $mapping['dn_or_group']) !== false) {
                $matches = true;
            }
        }
        
        // Évite les doublons
        if ($matches && !in_array($mapping['role_id'], $matchedRoleIds)) {
            $matchedRoleIds[] = $mapping['role_id'];
        }
    }
    return $matchedRoleIds;
}
```

#### 2. `syncUserRolesWithMappings($user_id, $auth_method, array $matchedRoleIds)`

Synchronise les rôles de l'utilisateur avec les mappings actuels.

**Comportement :**
- Récupère la liste des `role_id` définis dans `auth_mappings` pour la source.
- Ajoute les rôles mappés manquants dans `user_roles`.
- Supprime **uniquement** les rôles qui proviennent des mappings et qui ne correspondent plus.
- **Ne touche pas** aux rôles attribués manuellement (non définis dans `auth_mappings` pour cette source).

```php
private function syncUserRolesWithMappings($user_id, $auth_method, array $matchedRoleIds) {
    // Récupère les role_id définis dans auth_mappings pour cette source
    $stmt = $this->db->prepare("SELECT DISTINCT role_id FROM auth_mappings WHERE source = ?");
    $stmt->execute([$auth_method]);
    $mappingRoleIds = array_column($stmt->fetchAll(), 'role_id');
    
    // Récupère les rôles actuels de l'utilisateur
    $stmt = $this->db->prepare("SELECT role_id FROM user_roles WHERE user_id = ?");
    $stmt->execute([$user_id]);
    $currentRoleIds = array_column($stmt->fetchAll(), 'role_id');
    
    // Ajoute les rôles mappés manquants
    foreach ($matchedRoleIds as $roleId) {
        if (!in_array($roleId, $currentRoleIds)) {
            $stmt = $this->db->prepare("INSERT INTO user_roles (user_id, role_id, assigned_at) VALUES (?, ?, NOW())");
            $stmt->execute([$user_id, $roleId]);
        }
    }
    
    // Supprime les rôles provenant de mappings qui ne correspondent plus
    foreach ($currentRoleIds as $roleId) {
        if (in_array($roleId, $mappingRoleIds) && !in_array($roleId, $matchedRoleIds)) {
            $stmt = $this->db->prepare("DELETE FROM user_roles WHERE user_id = ? AND role_id = ?");
            $stmt->execute([$user_id, $roleId]);
        }
    }
}
```

#### 3. `findAndDisableExistingUser($username, $auth_method)`

Recherche un utilisateur existant avec ce `username` et `auth_method`, et le désactive si trouvé.

```php
private function findAndDisableExistingUser($username, $auth_method) {
    $stmt = $this->db->prepare("SELECT id FROM users WHERE username = ? AND auth_method = ?");
    $stmt->execute([$username, $auth_method]);
    $existingUser = $stmt->fetch();
    
    if ($existingUser) {
        $this->disableUserAccount($existingUser['id']);
        return true;
    }
    return false;
}
```

### Points d'Intégration

#### Dans `authenticateActiveDirectory()` et `authenticateLDAP()`

1. Après un bind LDAP réussi et la récupération des groupes/DN utilisateur.
2. Calcul de `$matchedRoleIds` via `getRoleIdsFromMappings()` **avant** de créer/mettre à jour l'utilisateur.
3. Si `$matchedRoleIds` est vide :
   - Recherche et désactive l'utilisateur existant via `findAndDisableExistingUser()`.
   - Ferme la connexion LDAP et retourne `false` (refus de connexion).
4. Si `$matchedRoleIds` n'est pas vide :
   - Appelle `createOrUpdateUserWithMappings()` (comportement existant).
   - Recharge l'utilisateur et assure `is_active = 1` via `reactivateUserAccount()`.
   - Synchronise les rôles via `syncUserRolesWithMappings()`.

### Workflow d'Acceptation/Refus

```
Authentification AD/LDAP
        │
        ▼
   Bind LDAP réussi ?
        │
   Non ─┤
        │     └──► Retourne false (échec auth)
   Oui ─┤
        ▼
   Récupérer groupes/DN
        │
        ▼
   getRoleIdsFromMappings()
        │
        ▼
   Mappings trouvés ?
        │
   Non ─┤
        │     └──► findAndDisableExistingUser()
        │         └──► Retourne false (accès refusé)
   Oui ─┤
        ▼
   createOrUpdateUserWithMappings()
        │
        ▼
   reactivateUserAccount()
        │
        ▼
   syncUserRolesWithMappings()
        │
        ▼
   Retourne true (connexion autorisée)
```

### Notes Opérationnelles

1. **Réactivation automatique** : Un compte désactivé est automatiquement réactivé si un mapping correspond à nouveau. Pour empêcher la réactivation automatique d'un compte manuellement désactivé par un admin, un flag `admin_disabled` peut être ajouté ultérieurement.

2. **Utilisateurs database** : Les utilisateurs avec `auth_method = 'database'` ne sont pas affectés par cette politique. Leur création/gestion reste via l'API admin.

3. **Performance** : Les requêtes `auth_mappings` sont exécutées à chaque connexion AD/LDAP. Pour les environnements à fort trafic, envisagez un cache.

4. **Logs** : Les erreurs sont enregistrées via `error_log()`. Consultez les logs PHP pour le debugging.

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

### Tests Authentification AD/LDAP avec Mappings

#### Cas Positif — Utilisateur mappé
1. Créer un mapping AD : `CN=DNSAdmins,OU=Groups,DC=example,DC=com` → rôle `admin`
2. Utilisateur membre du groupe DNSAdmins tente de se connecter
3. **Attendu** : Login réussi, utilisateur créé/activé, rôle `admin` appliqué

```sql
-- Vérifier après connexion
SELECT id, username, is_active, auth_method FROM users WHERE username = 'testuser';
SELECT r.name FROM user_roles ur JOIN roles r ON ur.role_id = r.id WHERE ur.user_id = <id>;
```

#### Cas Refusé — Utilisateur non mappé
1. Aucun mapping ne correspond à l'utilisateur AD
2. Le bind LDAP peut réussir mais la connexion est refusée
3. **Attendu** : Aucun utilisateur créé. Si l'utilisateur existait, `is_active = 0`

```sql
-- Vérifier qu'aucun utilisateur n'a été créé OU qu'il est désactivé
SELECT id, username, is_active FROM users WHERE username = 'unmapped_user';
```

#### Retrait d'un Mapping
1. Un utilisateur correspondait à un mapping (connexion précédemment réussie)
2. Le mapping est supprimé de `auth_mappings`
3. L'utilisateur tente de se reconnecter
4. **Attendu** : Connexion refusée, compte désactivé (`is_active = 0`)

#### Synchronisation des Rôles
1. L'utilisateur a le mapping `group_A → role_admin` et `group_B → role_user`
2. L'admin retire manuellement l'utilisateur du `group_B` dans AD
3. L'utilisateur se reconnecte
4. **Attendu** : Le rôle `role_user` est retiré, `role_admin` est conservé
5. Si l'admin avait assigné manuellement un rôle non mappé, celui-ci reste inchangé

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

---

## Zone ACL (Access Control Lists)

### Présentation

La fonctionnalité ACL par fichier de zone permet de contrôler finement l'accès aux zones DNS pour les utilisateurs non-administrateurs. Un nouveau rôle `zone_editor` est disponible pour les utilisateurs qui doivent pouvoir modifier des zones spécifiques sans avoir accès à l'interface d'administration globale.

### Politique d'autorisation AD/LDAP

**Mapping OU ACL requis pour la connexion :** Les utilisateurs AD/LDAP ne sont autorisés à se connecter que s'ils :
- Correspondent à au moins un mapping `auth_mappings` configuré, **OU**
- Apparaissent dans au moins une entrée ACL (par username, rôle ou groupe AD)

Si aucune de ces conditions n'est remplie, la connexion est refusée et tout compte local existant est désactivé (`is_active = 0`).

### Composants

#### 1. Table `zone_acl_entries`

```sql
CREATE TABLE zone_acl_entries (
  id INT AUTO_INCREMENT PRIMARY KEY,
  zone_file_id INT NOT NULL,
  subject_type ENUM('user','role','ad_group') NOT NULL,
  subject_identifier VARCHAR(255) NOT NULL,
  permission ENUM('read','write','admin') NOT NULL DEFAULT 'read',
  created_by INT NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (zone_file_id) REFERENCES zone_files(id) ON DELETE CASCADE,
  FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE CASCADE
);
```

#### 2. Rôle `zone_editor`

- Permet d'accéder à la page `zone-files.php` sans être admin
- Ne donne PAS accès à l'interface d'administration (`admin.php`)
- L'accès aux zones est contrôlé par les entrées ACL

#### 3. Migration SQL

```bash
mysql -u dns3_user -p dns3_db < scripts/001_add_acl_entries_and_zone_editor.sql
```

### Fonctionnement

#### Hiérarchie des permissions

| Permission | Niveau | Droits |
|------------|--------|--------|
| `read`     | 1      | Visualiser la zone |
| `write`    | 2      | Modifier la zone |
| `admin`    | 3      | Toutes les permissions pour cette zone |

#### Types de sujets ACL

| Type       | Description                                    |
|------------|------------------------------------------------|
| `user`     | Username (normalisé en minuscules)             |
| `role`     | Nom du rôle (ex: `zone_editor`)                |
| `ad_group` | DN ou nom du groupe Active Directory           |

**Note :** Pour le type `user`, le `subject_identifier` peut être un username même si l'utilisateur n'existe pas encore en base de données. Cela permet de pré-autoriser des utilisateurs externes (AD/LDAP) avant leur première connexion.

#### Bypass Admin

Les utilisateurs avec le rôle `admin` ont automatiquement accès à toutes les zones, indépendamment des ACL configurées.

### API Endpoints

#### Lister les ACL d'une zone
```
GET /api/admin_api.php?action=list_acl&zone_id=X
```

#### Créer une entrée ACL
```json
POST /api/admin_api.php?action=create_acl
{
  "zone_id": 1,
  "subject_type": "user",
  "subject_identifier": "john.doe",
  "permission": "write"
}
```

**Note :** Le `subject_identifier` pour le type `user` accepte un username (pas un ID). Cela permet de pré-autoriser des utilisateurs externes non encore créés.

#### Supprimer une entrée ACL
```
POST /api/admin_api.php?action=delete_acl&id=X
```

#### Créer un utilisateur externe (pré-création)
```json
POST /api/admin_api.php?action=create_external_user
{
  "username": "john.doe",
  "email": "john.doe@example.com",
  "auth_method": "ad",
  "is_active": 0
}
```

Permet à un admin de pré-créer un utilisateur AD/LDAP. Le username est normalisé en minuscules. Par défaut, `is_active = 0`.

### Interface utilisateur

L'onglet "ACL" est disponible dans le modal d'édition d'une zone (accessible uniquement aux admins). Il permet de :

1. Visualiser les entrées ACL existantes
2. Ajouter de nouvelles entrées (utilisateur, rôle, ou groupe AD)
3. Supprimer des entrées existantes

### Fichiers modifiés/ajoutés

| Fichier | Description |
|---------|-------------|
| `scripts/001_add_acl_entries_and_zone_editor.sql` | Migration SQL |
| `includes/models/ZoneAcl.php` | Modèle ACL (CRUD + isAllowed + hasAnyAclForUser) |
| `includes/auth.php` | Méthodes isZoneEditor(), getUserRoles(), getUserContext(), ACL check |
| `includes/models/ZoneFile.php` | Méthodes listForUser(), countForUser() |
| `api/admin_api.php` | Endpoints list_acl, create_acl, delete_acl, create_external_user |
| `zone-files.php` | Accès zone_editor + onglet ACL |
| `assets/js/zone-files.js` | Fonctions JavaScript ACL |

### Tests manuels

1. **Import de la migration**
   ```bash
   mysql -u dns3_user -p dns3_db < scripts/001_add_acl_entries_and_zone_editor.sql
   ```

2. **Vérifier le rôle zone_editor**
   ```sql
   SELECT * FROM roles WHERE name = 'zone_editor';
   ```

3. **Créer une ACL via l'interface**
   - Connectez-vous en tant qu'admin
   - Ouvrez une zone en édition
   - Cliquez sur l'onglet "ACL"
   - Ajoutez une entrée pour un utilisateur/rôle

4. **Tester l'accès zone_editor**
   - Créez un utilisateur avec le rôle `zone_editor`
   - Ajoutez une ACL `write` pour cet utilisateur sur une zone
   - Connectez-vous avec cet utilisateur
   - Vérifiez qu'il ne voit que les zones autorisées

5. **Vérifier le bypass admin**
   - Un admin doit voir toutes les zones sans ACL explicite

6. **Test connexion AD/LDAP avec ACL**
   - Utilisateur membre d'un groupe mappé → autorisé
   - Utilisateur non mappé MAIS présent dans une ACL (user/role/ad_group) → autorisé
   - Utilisateur n'ayant ni mapping ni ACL → connexion refusée ; si compte local existant → is_active=0

7. **Test pré-création utilisateur externe**
   ```bash
   curl -X POST 'http://domain/api/admin_api.php?action=create_external_user' \
     -H 'Content-Type: application/json' \
     -d '{"username": "ext.user", "auth_method": "ad", "is_active": 0}' \
     --cookie "PHPSESSID=..."
   ```

---

## Conclusion

This implementation provides a complete, secure, and user-friendly admin interface for managing users, roles, and AD/LDAP mappings. It follows the existing code patterns, maintains consistency with the current UI, and is ready for production use after proper testing.

L'intégration des mappings `auth_mappings` dans le flux d'authentification AD/LDAP est **opérationnelle**. Les utilisateurs AD/LDAP ne sont créés ou activés que s'ils correspondent à au moins un mapping configuré **OU** s'ils apparaissent dans une ACL. Les comptes non mappés et sans ACL sont automatiquement désactivés pour renforcer la sécurité.

La fonctionnalité ACL par zone permet un contrôle d'accès granulaire pour les utilisateurs non-admin, avec support pour les utilisateurs, rôles et groupes AD.
