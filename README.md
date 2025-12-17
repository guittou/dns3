# DNS3

DNS3 est une application web PHP pour la gestion de fichiers de zone DNS et d'enregistrements DNS. Elle prend en charge la validation `named-checkzone`, la génération de fichiers de zone avec les directives `$INCLUDE`, le suivi de l'historique des modifications et l'authentification multi-sources (base de données, Active Directory, OpenLDAP).

## Fonctionnalités

- **Gestion des fichiers de zone** : Créer et gérer des fichiers de zone maîtres et des fichiers d'inclusion
- **Gestion des enregistrements DNS** : CRUD complet pour les enregistrements A, AAAA, CNAME, MX, TXT, NS, SOA, PTR et SRV
- **Validation de zone** : Intégration avec `named-checkzone` pour la validation de syntaxe
- **Support `$INCLUDE`** : Générer des fichiers de zone avec des inclusions imbriquées
- **Historique des modifications** : Suivre toutes les modifications apportées aux zones et enregistrements
- **Authentification multi-sources** : Support de la base de données, Active Directory et OpenLDAP
- **Contrôle d'accès basé sur les rôles** : Permissions granulaires via des entrées ACL

> **Schéma de base de données** : Le schéma canonique se trouve dans `database.sql` (exporté le 2025-12-04). Pour une documentation détaillée incluant les descriptions des tables, les clés étrangères et des exemples de requêtes, consultez [docs/DB_SCHEMA.md](docs/DB_SCHEMA.md).

> **Note** : La fonctionnalité Applications a été supprimée. Toutes les migrations qui créaient précédemment la table `applications` ont été archivées. La table `domaine_list` a également été supprimée ; les domaines sont maintenant gérés directement dans la table `zone_files` via le champ `domain`.

## Installation

### Prérequis

- PHP 7.4 ou supérieur
- MariaDB 10.3+ ou MySQL 5.7+
- Apache avec `mod_rewrite` activé
- Extension PHP LDAP (optionnelle, pour l'authentification AD/LDAP)

### Étapes

1. **Cloner le dépôt**
   ```bash
   git clone https://github.com/guittou/dns3.git
   cd dns3
   ```

2. **Créer la base de données**
   ```bash
   mysql -u root -p -e "CREATE DATABASE dns3_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
   ```

3. **Importer le schéma**
   ```bash
   mysql -u user -p dns3_db < database.sql
   ```

4. **Configurer l'application**

   Éditer `config.php` et définir :
   - Connexion à la base de données : `DB_HOST`, `DB_NAME`, `DB_USER`, `DB_PASS`
   - URL de base : `BASE_URL` (par exemple, `/` ou `/dns3/`)
   - Paramètres AD (optionnel) : `AD_SERVER`, `AD_PORT`, `AD_BASE_DN`, `AD_DOMAIN`
   - Paramètres LDAP (optionnel) : `LDAP_SERVER`, `LDAP_PORT`, `LDAP_BASE_DN`

5. **Définir les permissions de fichiers**
   ```bash
   sudo chown -R www-data:www-data /var/www/dns3
   sudo chmod -R 755 /var/www/dns3
   ```

6. **Configurer Apache**
   ```apache
   <VirtualHost *:80>
       ServerName dns3.example.com
       DocumentRoot /var/www/dns3
       <Directory /var/www/dns3>
           AllowOverride All
           Require all granted
       </Directory>
   </VirtualHost>
   ```

7. **Créer un compte administrateur**

   **Méthode A — Créer un administrateur via script PHP (recommandée)**
   
   Prérequis : `config.php` configuré (credentials DB), PHP CLI disponible.
   
   ```bash
   php scripts/create_admin.php --username admin --password 'AdminPass123!'
   ```
   
   Ce que fait le script :
   - Crée un enregistrement dans la table `users` avec le mot de passe hashé via `password_hash(..., PASSWORD_DEFAULT)`
   - Si la table `roles` contient un rôle `name='admin'`, il ajoute une entrée dans `user_roles` pour assigner ce rôle
   - Affiche un message de succès ou d'erreur
   
   Vérifications post-exécution :
   ```sql
   SELECT id, username, auth_method, is_active FROM users WHERE username = 'admin';
   SELECT r.id, r.name FROM roles r WHERE r.name = 'admin';
   SELECT * FROM user_roles WHERE user_id = <id_utilisateur>;
   ```
   
   **Méthode B — Création manuelle via SQL**
   
   Voir la section [Création manuelle](#création-manuelle-via-sql) ci-dessous.
   
   > **Sécurité** : Changez le mot de passe par défaut immédiatement après la première connexion. Limitez l'accès au répertoire `scripts/` en production.

## Configuration

Tous les paramètres sont dans `config.php` :

| Paramètre | Description |
|-----------|-------------|
| `DB_HOST`, `DB_NAME`, `DB_USER`, `DB_PASS` | Connexion à la base de données |
| `BASE_URL` | Chemin de base de l'application |
| `AD_*` | Paramètres Active Directory |
| `LDAP_*` | Paramètres OpenLDAP |

## Notes d'utilisation

- **Comportement du TTL** : Si le TTL d'un enregistrement est NULL, le TTL par défaut de la zone est utilisé lors de la génération du fichier.
- **Sauvegardes** : Utilisez `mysqldump -u user -p dns3_db > backup.sql` avant les modifications importantes.
- **Configuration de la base de données** : Pour les nouvelles installations, importez `database.sql` pour initialiser la base de données. Le schéma a été exporté pour la dernière fois le **2025-12-04** depuis `structure_ok_dns3_db.sql`. Pour une documentation détaillée du schéma, consultez [docs/DB_SCHEMA.md](docs/DB_SCHEMA.md).
- **Validation de zone** : Exécute `named-checkzone` et stocke les résultats dans la table `zone_file_validation`.

## Authentification AD/LDAP — Contrôle par Mappings

L'application applique une politique de sécurité renforcée pour les authentifications Active Directory (AD) et OpenLDAP : un utilisateur ne sera créé ou autorisé à se connecter **que s'il correspond à au moins un mapping défini dans la table `auth_mappings`**.

### Comportement

1. **Création conditionnelle** : Lors d'un bind LDAP réussi, l'application vérifie si l'utilisateur correspond à un mapping (via ses groupes AD ou son DN LDAP). Si aucun mapping ne correspond, l'accès est refusé et aucun compte local n'est créé.

2. **Désactivation automatique** : Si un utilisateur AD/LDAP existant ne correspond plus à aucun mapping lors d'une tentative de connexion, son compte est automatiquement désactivé (`is_active = 0`).

3. **Réactivation automatique** : Si un utilisateur AD/LDAP désactivé correspond à nouveau à un mapping valide, son compte est automatiquement réactivé (`is_active = 1`).

4. **Synchronisation des rôles** : À chaque connexion, les rôles de l'utilisateur sont synchronisés avec les mappings :
   - Les rôles mappés manquants sont ajoutés.
   - Les rôles qui proviennent des mappings mais ne correspondent plus sont retirés.
   - Les rôles attribués manuellement (non définis dans `auth_mappings`) sont conservés.

### Configuration des Mappings

Pour configurer un mapping, insérez un enregistrement dans la table `auth_mappings` :

```sql
-- Exemple : Mapper le groupe AD "DNSAdmins" au rôle "admin"
INSERT INTO auth_mappings (source, dn_or_group, role_id, notes)
SELECT 'ad', 'CN=DNSAdmins,OU=Groups,DC=example,DC=com', r.id, 'Administrateurs DNS'
FROM roles r WHERE r.name = 'admin';

-- Exemple : Mapper une OU LDAP au rôle "user"
INSERT INTO auth_mappings (source, dn_or_group, role_id, notes)
SELECT 'ldap', 'ou=IT,dc=example,dc=com', r.id, 'Personnel IT'
FROM roles r WHERE r.name = 'user';
```

### Nouveaux Formats de Mapping

Le champ `dn_or_group` supporte désormais des formats préfixés pour mapper directement des attributs utilisateur :

**Active Directory :**
- `sAMAccountName:<login>` - Mapper un login AD spécifique
  ```sql
  INSERT INTO auth_mappings (source, dn_or_group, role_id, notes)
  SELECT 'ad', 'sAMAccountName:john.doe', r.id, 'Accès pour john.doe'
  FROM roles r WHERE r.name = 'admin';
  ```

**OpenLDAP :**
- `uid:<login>` - Mapper un login LDAP spécifique
  ```sql
  INSERT INTO auth_mappings (source, dn_or_group, role_id, notes)
  SELECT 'ldap', 'uid:foobar', r.id, 'Accès pour foobar'
  FROM roles r WHERE r.name = 'user';
  ```
- `departmentNumber:<valeur>` - Mapper un département LDAP
  ```sql
  INSERT INTO auth_mappings (source, dn_or_group, role_id, notes)
  SELECT 'ldap', 'departmentNumber:12345', r.id, 'Département IT'
  FROM roles r WHERE r.name = 'zone_editor';
  ```

### Comparaison des Mappings

- **Active Directory** : 
  - Groupes (`memberOf`) : comparaison insensible à la casse du DN complet
  - `sAMAccountName:value` : comparaison exacte insensible à la casse
- **OpenLDAP** : 
  - DN utilisateur : doit contenir la chaîne `dn_or_group` (insensible à la casse)
  - `uid:value` : comparaison exacte insensible à la casse
  - `departmentNumber:value` : comparaison exacte insensible à la casse

### Tests avec ldapsearch

```bash
# Tester la connexion AD et récupérer les groupes
ldapsearch -x -H ldap://ad.example.com -D "DOMAIN\\username" -W \
  -b "DC=example,DC=com" "(sAMAccountName=username)" memberOf

# Tester la connexion LDAP et récupérer le DN
ldapsearch -x -H ldap://ldap.example.com -D "cn=admin,dc=example,dc=com" -W \
  -b "dc=example,dc=com" "(uid=username)" dn
```

### Vérifications SQL après Connexion

```sql
-- Vérifier l'état d'un utilisateur
SELECT id, username, auth_method, is_active, last_login 
FROM users WHERE username = 'username';

-- Vérifier les rôles assignés
SELECT u.username, r.name as role
FROM users u
JOIN user_roles ur ON u.id = ur.user_id
JOIN roles r ON ur.role_id = r.id
WHERE u.username = 'username';

-- Lister tous les mappings actifs
SELECT am.source, am.dn_or_group, r.name as role, am.notes
FROM auth_mappings am
JOIN roles r ON am.role_id = r.id;
```

> **Note** : Les utilisateurs avec `auth_method = 'database'` ne sont pas affectés par cette politique. Leur gestion reste manuelle via l'interface d'administration.

## Création manuelle via SQL

Si vous préférez créer un administrateur manuellement via SQL (Méthode B), voici la procédure :

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

> Pour plus de détails et d'options, consultez `scripts/create_admin.php`.

## Documentation

Pour la documentation complète, consultez [docs/SUMMARY.md](docs/SUMMARY.md).

### Documentation Principale

- **[Sommaire Global](docs/SUMMARY.md)** - Index de toute la documentation
- **[Guide d'installation](docs/INSTALL.md)** - Installation et configuration initiale
- **[Guide d'administration](docs/ADMIN_INTERFACE_GUIDE.md)** - Gestion des utilisateurs et de l'interface admin
- **[Démarrage rapide avec les tokens API](docs/GETTING_STARTED_API_TOKENS.md)** - Guide de démarrage pour l'authentification par tokens API
- **[Authentification API par tokens](docs/api_token_authentication.md)** - Documentation de l'API et des tokens
- **[Import de zones BIND](docs/import_bind_zones.md)** - Import de zones BIND existantes
- **[Schéma de base de données](docs/DB_SCHEMA.md)** - Documentation du schéma DB
- **[Guide de test](docs/TESTING_GUIDE.md)** - Procédures et scénarios de test
- **[Plan de test](docs/TEST_PLAN.md)** - Plan de test complet pour DNS et formulaires dynamiques

### Utilitaires / Scripts

- **Mise à jour last_seen depuis logs BIND**: `scripts/update_last_seen_from_bind_logs.sh` — Parse les logs BIND (plain / .gz), extrait les FQDN uniques pour un type de requête (par défaut A), résout master/includes et met à jour en batch `dns_records.last_seen`. Documentation complète : [docs/UPDATE_LAST_SEEN_FROM_BIND_LOGS.md](docs/UPDATE_LAST_SEEN_FROM_BIND_LOGS.md)
- **Workers de validation**: Voir [jobs/README.md](jobs/README.md) pour la configuration des jobs de validation en arrière-plan

### Contribuer à la Documentation

Pour ajouter ou modifier la documentation, consultez le [Guide de Contribution](docs/CONTRIBUTING_DOCS.md).

## Licence

Ce projet est open source sous licence MIT.
