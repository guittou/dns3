# Résumé de l'implémentation de l'interface d'administration

## Vue d'ensemble

Cette implémentation ajoute une interface d'administration complète à DNS3 pour gérer les utilisateurs, les rôles et les mappings d'authentification AD/LDAP. L'interface est accessible uniquement aux utilisateurs ayant le rôle 'admin'.

## Fichiers ajoutés

### 1. Schéma de base de données (table auth_mappings)
> **Note** : Les fichiers de migration ont été supprimés. Le schéma complet est maintenant disponible dans `database.sql`.

- Crée la table `auth_mappings` pour stocker les mappings groupe AD/DN LDAP vers rôle
- Active l'attribution automatique de rôles lors de l'authentification AD/LDAP
- Champs : source (ad/ldap), dn_or_group, role_id, created_by, notes

### 2. includes/models/User.php
- Modèle complet de gestion des utilisateurs avec opérations CRUD
- Méthodes :
  - `list()` - Liste des utilisateurs avec filtres
  - `getById()` - Détails utilisateur avec rôles
  - `create()` - Créer un nouvel utilisateur avec hashage du mot de passe
  - `update()` - Mettre à jour les informations utilisateur
  - `assignRole()` - Assigner un rôle à un utilisateur
  - `removeRole()` - Retirer un rôle d'un utilisateur
  - `getUserRoles()` - Obtenir les rôles de l'utilisateur
  - `listRoles()` - Lister tous les rôles disponibles
  - `getRoleById()` - Obtenir un rôle par ID
  - `getRoleByName()` - Obtenir un rôle par nom

### 3. api/admin_api.php
- API JSON RESTful pour les opérations d'administration
- Tous les endpoints requièrent une authentification admin
- Points de terminaison :
  - Gestion utilisateurs (liste, récupération, création, mise à jour)
  - Attribution de rôles (assigner, retirer)
  - Liste des rôles
  - Gestion des mappings (liste, création, suppression)
- Gestion appropriée des erreurs et validation
- Codes de statut HTTP (401 Non autorisé, 403 Interdit, 404 Non trouvé, etc.)

### 4. admin.php
- Page principale de l'interface d'administration
- Interface à onglets avec 4 sections :
  1. **Utilisateurs** - Liste, création, édition d'utilisateurs avec attribution de rôles
  2. **Rôles** - Visualisation des rôles disponibles
  3. **Mappings** - Création de mappings AD/LDAP vers rôles
  4. **ACL** - Espace réservé pour implémentation future
- Capacités de filtrage pour les utilisateurs
- Boîtes de dialogue modales pour les opérations de création/édition
- Design responsive correspondant au style existant du site

### 5. assets/js/admin.js
- JavaScript côté client pour l'interface d'administration
- Fonctionnalités :
  - Navigation par onglets
  - Appels API AJAX
  - Remplissage dynamique des tables
  - Gestion des modales
  - Validation de formulaires
  - Notifications d'alerte
  - Fonctionnalité de filtrage
- Suit les patterns JavaScript existants du projet
- Gestion appropriée des erreurs et retour utilisateur

## Fichiers modifiés

### includes/header.php
- Ajout de l'onglet "Administration" dans la navigation
- L'onglet est visible uniquement pour les utilisateurs admin connectés
- Maintient la cohérence avec le style de navigation existant

## Schéma de base de données

### Table auth_mappings
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

## Étapes d'installation

### 1. Importer le schéma de base de données
```bash
mysql -u dns3_user -p dns3_db < database.sql
```

> **Note** : Les fichiers de migration ont été supprimés. Pour les nouvelles installations, utilisez `database.sql` (ou `structure_ok_dns3_db.sql`).

### 2. Créer un utilisateur administrateur
```bash
php scripts/create_admin.php --username admin --password 'admin123'
```

Ou de manière interactive :
```bash
php scripts/create_admin.php
```

### 3. Accéder à l'interface d'administration
Naviguer vers : `http://votre-domaine/admin.php`

## Fonctionnalités implémentées

### Gestion des utilisateurs
- ✅ Liste de tous les utilisateurs avec filtres (nom d'utilisateur, méthode d'authentification, statut)
- ✅ Visualisation des détails utilisateur incluant les rôles assignés
- ✅ Création de nouveaux utilisateurs avec hashage du mot de passe (bcrypt)
- ✅ Mise à jour des informations utilisateur
- ✅ Attribution/retrait de rôles aux utilisateurs
- ✅ Support de multiples méthodes d'authentification (base de données, AD, LDAP)
- ✅ Gestion du statut utilisateur (actif/inactif)
- ✅ Désactivation d'utilisateurs via bouton "Supprimer" (dans la liste et le modal)
- ✅ Protection contre l'auto-désactivation (impossible de désactiver son propre compte)
- ✅ Protection contre la désactivation du dernier administrateur actif

### Gestion des rôles
- ✅ Visualisation de tous les rôles disponibles
- ✅ Affichage des informations de rôle (nom, description)
- ✅ Attribution de rôle lors de la création/édition d'utilisateur

### Gestion des mappings AD/LDAP
- ✅ Liste de tous les mappings d'authentification
- ✅ Création de nouveaux mappings (groupe AD/DN LDAP → rôle)
- ✅ Suppression de mappings existants
- ✅ Support des notes/descriptions sur les mappings
- ✅ Validation pour prévenir les mappings dupliqués

### Sécurité
- ✅ Tous les endpoints admin requièrent une authentification
- ✅ Contrôle d'accès réservé aux admins
- ✅ Hashage de mot de passe avec password_hash() (bcrypt)
- ✅ Prévention d'injection SQL (requêtes préparées)
- ✅ Prévention XSS (échappement HTML)
- ✅ Validation des entrées côté client et serveur

### Interface utilisateur
- ✅ Cohérent avec le design existant du site
- ✅ Interface à onglets pour différentes sections d'administration
- ✅ Boîtes de dialogue modales pour les formulaires
- ✅ Filtrage et recherche en temps réel
- ✅ Badges de statut (actif/inactif, rôles, méthodes d'authentification)
- ✅ Notifications d'alerte pour les messages de succès/erreur
- ✅ Design responsive

## Documentation API

### Authentification
Tous les endpoints API requièrent :
- L'utilisateur doit être connecté
- L'utilisateur doit avoir le rôle 'admin'

### Points de terminaison

#### Utilisateurs
```
GET  /api/admin_api.php?action=list_users[&username=X&auth_method=Y&is_active=Z]
GET  /api/admin_api.php?action=get_user&id=X
POST /api/admin_api.php?action=create_user (corps JSON)
POST /api/admin_api.php?action=update_user&id=X (corps JSON)
POST /api/admin_api.php?action=deactivate_user&id=X - Désactive un utilisateur (is_active=0)
POST /api/admin_api.php?action=assign_role&user_id=X&role_id=Y
POST /api/admin_api.php?action=remove_role&user_id=X&role_id=Y
```

#### Rôles
```
GET  /api/admin_api.php?action=list_roles
```

#### Mappings
```
GET  /api/admin_api.php?action=list_mappings
POST /api/admin_api.php?action=create_mapping (corps JSON)
POST /api/admin_api.php?action=delete_mapping&id=X
```

### Exemples de requêtes

Désactiver un utilisateur :
```bash
POST /api/admin_api.php?action=deactivate_user&id=5

# Réponse succès :
{ "success": true, "message": "Utilisateur désactivé avec succès" }

# Erreurs possibles :
# - 400 : "Impossible de désactiver votre propre compte."
# - 400 : "Impossible de désactiver le dernier administrateur actif."
# - 404 : "Utilisateur non trouvé"
```

Créer un utilisateur :
```json
POST /api/admin_api.php?action=create_user
{
  "username": "john.doe",
  "auth_method": "database",
  "password": "SecurePass123",
  "is_active": 1,
  "role_ids": [2]
}
```

Créer un mapping :
```json
POST /api/admin_api.php?action=create_mapping
{
  "source": "ad",
  "dn_or_group": "CN=DNSAdmins,OU=Groups,DC=example,DC=com",
  "role_id": 1,
  "notes": "Attribution automatique du rôle admin aux membres du groupe DNS Admins"
}
```

## Exemples d'utilisation

### Création d'un utilisateur administrateur (première installation)

#### Méthode A — Via script PHP (recommandée)

**Prérequis :**
- `config.php` configuré avec les credentials de base de données
- PHP CLI disponible et fonctionnel

**Commande :**
```bash
php scripts/create_admin.php --username admin --password 'AdminPass123!'
```

**Ce que fait le script :**
1. Crée un enregistrement dans la table `users` avec le mot de passe hashé via `password_hash(..., PASSWORD_DEFAULT)`
2. Si la table `roles` contient un rôle `name='admin'`, ajoute automatiquement une entrée dans `user_roles`
3. Si l'utilisateur existe déjà, met à jour son mot de passe
4. Affiche un message de succès ou d'erreur

**Vérifications SQL post-exécution :**
```sql
SELECT id, username, auth_method, is_active FROM users WHERE username = 'admin';
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
INSERT INTO users (username, password, auth_method, is_active, created_at)
VALUES ('admin', '$2y$10$...votre_hash...', 'database', 1, NOW());

-- Assigner le rôle admin
INSERT INTO user_roles (user_id, role_id, assigned_at)
SELECT u.id, r.id, NOW() FROM users u, roles r
WHERE u.username = 'admin' AND r.name = 'admin';
```

**⚠️ Note de sécurité :** Changez le mot de passe par défaut immédiatement après la première connexion. Limitez l'accès au répertoire `scripts/` en production.

### Création d'un utilisateur de base de données (via l'interface)
1. Naviguer vers admin.php
2. Cliquer sur "Créer un utilisateur"
3. Remplir :
   - Nom d'utilisateur : john.doe
   - Email : john@example.com
   - Méthode d'authentification : database
   - Mot de passe : SecurePassword123
   - Rôles : Cocher "user"
4. Cliquer sur "Enregistrer"

### Création d'un mapping AD
1. Naviguer vers l'onglet "Mappings AD/LDAP"
2. Cliquer sur "Créer un mapping"
3. Remplir :
   - Source : Active Directory
   - DN/Groupe : CN=DNSAdmins,OU=Groups,DC=example,DC=com
   - Rôle : admin
   - Notes : Groupe des administrateurs DNS
4. Cliquer sur "Créer"

## Intégration Authentification AD/LDAP — Contrôle par mappings

### Vue d'ensemble

L'intégration des mappings `auth_mappings` dans le flux d'authentification AD/LDAP est **complète et opérationnelle**. Cette implémentation renforce la sécurité en n'autorisant la création/activation des comptes AD/LDAP que si l'utilisateur correspond à au moins un mapping configuré.

### Méthodes ajoutées dans `includes/auth.php`

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

### Points d'intégration

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

### Workflow d'acceptation/refus

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

### Notes opérationnelles

1. **Réactivation automatique** : Un compte désactivé est automatiquement réactivé si un mapping correspond à nouveau. Pour empêcher la réactivation automatique d'un compte manuellement désactivé par un admin, un flag `admin_disabled` peut être ajouté ultérieurement.

2. **Utilisateurs database** : Les utilisateurs avec `auth_method = 'database'` ne sont pas affectés par cette politique. Leur création/gestion reste via l'API admin.

3. **Performance** : Les requêtes `auth_mappings` sont exécutées à chaque connexion AD/LDAP. Pour les environnements à fort trafic, envisagez un cache.

4. **Logs** : Les erreurs sont enregistrées via `error_log()`. Consultez les logs PHP pour le debugging.

## Tests

### Liste de vérification des tests manuels
- [ ] Accéder à admin.php en tant qu'utilisateur non-admin (devrait rediriger)
- [ ] Accéder à admin.php en tant qu'utilisateur admin (devrait afficher l'interface)
- [ ] Lister les utilisateurs avec divers filtres
- [ ] Créer un utilisateur de base de données avec mot de passe
- [ ] Créer un utilisateur AD sans mot de passe
- [ ] Modifier un utilisateur et changer le mot de passe
- [ ] Assigner/retirer des rôles d'un utilisateur
- [ ] Créer un mapping AD
- [ ] Créer un mapping LDAP
- [ ] Supprimer un mapping
- [ ] Visualiser la liste des rôles

### Tests Authentification AD/LDAP avec mappings

#### Cas positif — Utilisateur mappé
1. Créer un mapping AD : `CN=DNSAdmins,OU=Groups,DC=example,DC=com` → rôle `admin`
2. Utilisateur membre du groupe DNSAdmins tente de se connecter
3. **Attendu** : Login réussi, utilisateur créé/activé, rôle `admin` appliqué

```sql
-- Vérifier après connexion
SELECT id, username, is_active, auth_method FROM users WHERE username = 'testuser';
SELECT r.name FROM user_roles ur JOIN roles r ON ur.role_id = r.id WHERE ur.user_id = <id>;
```

#### Cas refusé — Utilisateur non mappé
1. Aucun mapping ne correspond à l'utilisateur AD
2. Le bind LDAP peut réussir mais la connexion est refusée
3. **Attendu** : Aucun utilisateur créé. Si l'utilisateur existait, `is_active = 0`

```sql
-- Vérifier qu'aucun utilisateur n'a été créé OU qu'il est désactivé
SELECT id, username, is_active FROM users WHERE username = 'unmapped_user';
```

#### Retrait d'un mapping
1. Un utilisateur correspondait à un mapping (connexion précédemment réussie)
2. Le mapping est supprimé de `auth_mappings`
3. L'utilisateur tente de se reconnecter
4. **Attendu** : Connexion refusée, compte désactivé (`is_active = 0`)

#### Synchronisation des rôles
1. L'utilisateur a le mapping `group_A → role_admin` et `group_B → role_user`
2. L'admin retire manuellement l'utilisateur du `group_B` dans AD
3. L'utilisateur se reconnecte
4. **Attendu** : Le rôle `role_user` est retiré, `role_admin` est conservé
5. Si l'admin avait assigné manuellement un rôle non mappé, celui-ci reste inchangé

### Tests API
```bash
# Test de création d'utilisateur (requiert authentification admin)
curl -X POST http://localhost/api/admin_api.php?action=create_user \
  -H "Content-Type: application/json" \
  -d '{"username":"test","auth_method":"database","password":"test123"}'

# Test de liste des utilisateurs
curl http://localhost/api/admin_api.php?action=list_users

# Test de création de mapping
curl -X POST http://localhost/api/admin_api.php?action=create_mapping \
  -H "Content-Type: application/json" \
  -d '{"source":"ad","dn_or_group":"CN=Test,DC=example,DC=com","role_id":1}'
```

## Dépannage

### Problèmes courants

1. **L'onglet Admin n'est pas visible**
   - S'assurer que l'utilisateur a le rôle admin assigné
   - Vérifier la table `user_roles`
   - Vérifier que la session est active

2. **Impossible de créer un utilisateur**
   - Vérifier les permissions de base de données
   - Vérifier que le nom d'utilisateur est unique
   - Pour l'authentification database, le mot de passe est requis

3. **La création de mapping échoue**
   - Vérifier les mappings dupliqués (même source+dn_or_group+role)
   - Vérifier que role_id existe
   - Vérifier les contraintes de clés étrangères

4. **L'API retourne 401/403**
   - S'assurer que l'utilisateur est connecté
   - Vérifier que l'utilisateur a le rôle admin
   - Vérifier la configuration de session

## Maintenance

### Sauvegarde avant modifications
```bash
mysqldump -u dns3_user -p dns3_db > backup_$(date +%Y%m%d_%H%M%S).sql
```

### Visualiser les informations d'audit
Toutes les modifications sont suivies avec horodatages et informations utilisateur dans la base de données.

### Logs
Vérifier les logs d'erreur PHP pour les problèmes :
```bash
tail -f /var/log/php/error.log
```

## Qualité du code

### Standards suivis
- ✅ Formatage du code PHP de style PSR
- ✅ Requêtes préparées pour SQL (pas d'injection SQL)
- ✅ Échappement HTML pour la sortie (pas de XSS)
- ✅ Design d'API RESTful
- ✅ Gestion cohérente des erreurs
- ✅ Codes de statut HTTP appropriés
- ✅ Commentaires inline complets
- ✅ Suit les patterns existants du projet

### Dépendances
- PHP 7.4+ (utilise password_hash, PDO)
- MySQL/MariaDB
- Infrastructure DNS3 existante (config.php, db.php, auth.php)

## Documentation

- `ADMIN_INTERFACE_GUIDE.md` - Guide utilisateur pour l'interface d'administration
- `ADMIN_IMPLEMENTATION.md` - Ce fichier, détails techniques d'implémentation
- Commentaires de code inline dans tous les fichiers PHP/JS
- Migration SQL avec commentaires explicatifs

---

## ACL de zone (listes de contrôle d'accès)

### Présentation

La fonctionnalité ACL par fichier de zone permet de contrôler finement l'accès aux zones DNS pour les utilisateurs non-administrateurs. Un nouveau rôle `zone_editor` est disponible pour les utilisateurs qui doivent pouvoir modifier des zones spécifiques sans avoir accès à l'interface d'administration globale.

### Politique d'autorisation AD/LDAP

**Mapping OU ACL requis pour la connexion :** Les utilisateurs AD/LDAP ne sont autorisés à se connecter que s'ils :
- Correspondent à au moins un mapping `auth_mappings` configuré, **OU**
- Apparaissent dans au moins une entrée ACL (par nom d'utilisateur, rôle ou groupe AD)

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

#### 3. Schéma de base de données

Le schéma ACL est inclus dans `database.sql`. Pour une installation fraîche, importez simplement le schéma complet :

```bash
mysql -u dns3_user -p dns3_db < database.sql
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
| `user`     | Nom d'utilisateur (normalisé en minuscules)    |
| `role`     | Nom du rôle (ex : `zone_editor`)               |
| `ad_group` | DN ou nom du groupe Active Directory           |

**Note :** Pour le type `user`, le `subject_identifier` peut être un nom d'utilisateur même si l'utilisateur n'existe pas encore en base de données. Cela permet de pré-autoriser des utilisateurs externes (AD/LDAP) avant leur première connexion.

#### Bypass Admin

Les utilisateurs avec le rôle `admin` ont automatiquement accès à toutes les zones, indépendamment des ACL configurées.

### Points de terminaison API

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

**Note :** Le `subject_identifier` pour le type `user` accepte un nom d'utilisateur (pas un ID). Cela permet de pré-autoriser des utilisateurs externes non encore créés.

#### Supprimer une entrée ACL
```
POST /api/admin_api.php?action=delete_acl&id=X
```

#### Créer un utilisateur externe (pré-création)
```json
POST /api/admin_api.php?action=create_external_user
{
  "username": "john.doe",
  "auth_method": "ad",
  "is_active": 0
}
```

Permet à un admin de pré-créer un utilisateur AD/LDAP. Le nom d'utilisateur est normalisé en minuscules. Par défaut, `is_active = 0`.

### Interface utilisateur

L'onglet "ACL" est disponible dans le modal d'édition d'une zone (accessible uniquement aux admins). Il permet de :

1. Visualiser les entrées ACL existantes
2. Ajouter de nouvelles entrées (utilisateur, rôle, ou groupe AD)
3. Supprimer des entrées existantes

### Fichiers modifiés/ajoutés

| Fichier | Description |
|---------|-------------|
| `database.sql` | Schéma de base de données complet (inclut les tables ACL) |
| `includes/models/ZoneAcl.php` | Modèle ACL (CRUD + isAllowed + hasAnyAclForUser) |
| `includes/auth.php` | Méthodes isZoneEditor(), getUserRoles(), getUserContext(), vérification ACL |
| `includes/models/ZoneFile.php` | Méthodes listForUser(), countForUser() |
| `api/admin_api.php` | Points de terminaison list_acl, create_acl, delete_acl, create_external_user |
| `zone-files.php` | Accès zone_editor + onglet ACL |
| `assets/js/zone-files.js` | Fonctions JavaScript ACL |

### Tests manuels

1. **Importer le schéma de base de données**
   ```bash
   mysql -u dns3_user -p dns3_db < database.sql
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

Cette implémentation fournit une interface d'administration complète, sécurisée et conviviale pour gérer les utilisateurs, les rôles et les mappings AD/LDAP. Elle suit les patterns de code existants, maintient la cohérence avec l'interface utilisateur actuelle, et est prête pour une utilisation en production après des tests appropriés.

L'intégration des mappings `auth_mappings` dans le flux d'authentification AD/LDAP est **opérationnelle**. Les utilisateurs AD/LDAP ne sont créés ou activés que s'ils correspondent à au moins un mapping configuré **OU** s'ils apparaissent dans une ACL. Les comptes non mappés et sans ACL sont automatiquement désactivés pour renforcer la sécurité.

La fonctionnalité ACL par zone permet un contrôle d'accès granulaire pour les utilisateurs non-admin, avec support pour les utilisateurs, rôles et groupes AD.
