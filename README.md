# DNS3

DNS3 is a PHP web application for managing DNS zone files and records. It supports `named-checkzone` validation, zone file generation with `$INCLUDE` directives, change history tracking, and multi-source authentication (database, Active Directory, OpenLDAP).

## Features

- **Zone File Management**: Create and manage master zone files and include files
- **DNS Record Management**: Full CRUD for A, AAAA, CNAME, MX, TXT, NS, SOA, PTR, and SRV records
- **Zone Validation**: Integration with `named-checkzone` for syntax validation
- **`$INCLUDE` Support**: Generate zone files with nested includes
- **Change History**: Track all modifications to zones and records
- **Multi-source Authentication**: Database, Active Directory, and OpenLDAP support
- **Role-based Access Control**: Granular permissions via ACL entries

> **Note**: The Applications feature has been removed. Any migrations that previously created the `applications` table have been archived. The `domaine_list` table has also been removed; domains are now managed directly in the `zone_files` table via the `domain` field.

## Installation

### Prerequisites

- PHP 7.4 or higher
- MariaDB 10.3+ or MySQL 5.7+
- Apache with `mod_rewrite` enabled
- PHP LDAP extension (optional, for AD/LDAP authentication)

### Steps

1. **Clone the repository**
   ```bash
   git clone https://github.com/guittou/dns3.git
   cd dns3
   ```

2. **Create the database**
   ```bash
   mysql -u root -p -e "CREATE DATABASE dns3_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
   ```

3. **Import the schema**
   ```bash
   mysql -u user -p dns3_db < database.sql
   ```

4. **Configure the application**

   Edit `config.php` and set:
   - Database connection: `DB_HOST`, `DB_NAME`, `DB_USER`, `DB_PASS`
   - Base URL: `BASE_URL` (e.g., `/` or `/dns3/`)
   - AD settings (optional): `AD_SERVER`, `AD_PORT`, `AD_BASE_DN`, `AD_DOMAIN`
   - LDAP settings (optional): `LDAP_SERVER`, `LDAP_PORT`, `LDAP_BASE_DN`

5. **Set file permissions**
   ```bash
   sudo chown -R www-data:www-data /var/www/dns3
   sudo chmod -R 755 /var/www/dns3
   ```

6. **Configure Apache**
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
   php scripts/create_admin.php --username admin --password 'AdminPass123!' --email 'admin@example.local'
   ```
   
   Ce que fait le script :
   - Crée un enregistrement dans la table `users` avec le mot de passe hashé via `password_hash(..., PASSWORD_DEFAULT)`
   - Si la table `roles` contient un rôle `name='admin'`, il ajoute une entrée dans `user_roles` pour assigner ce rôle
   - Affiche un message de succès ou d'erreur
   
   Vérifications post-exécution :
   ```sql
   SELECT id, username, email, auth_method, is_active FROM users WHERE username = 'admin';
   SELECT r.id, r.name FROM roles r WHERE r.name = 'admin';
   SELECT * FROM user_roles WHERE user_id = <id_utilisateur>;
   ```
   
   **Méthode B — Création manuelle via SQL**
   
   Voir la section [Création manuelle](#création-manuelle-via-sql) ci-dessous.
   
   > **Sécurité** : Changez le mot de passe par défaut immédiatement après la première connexion. Limitez l'accès au répertoire `scripts/` en production.

## Configuration

All settings are in `config.php`:

| Setting | Description |
|---------|-------------|
| `DB_HOST`, `DB_NAME`, `DB_USER`, `DB_PASS` | Database connection |
| `BASE_URL` | Application base path |
| `AD_*` | Active Directory settings |
| `LDAP_*` | OpenLDAP settings |

## Operation Notes

- **TTL Behavior**: If a record's TTL is NULL, the zone's default TTL is used during file generation.
- **Backups**: Use `mysqldump -u user -p dns3_db > backup.sql` before major changes.
- **Migrations**: Located in `migrations/`. Apply in order when upgrading. See `migrations/README.md` for details.
- **Zone Validation**: Runs `named-checkzone` and stores results in `zone_file_validation` table.

## Création manuelle via SQL

Si vous préférez créer un administrateur manuellement via SQL (Méthode B), voici la procédure :

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

> Pour plus de détails et d'options, consultez `scripts/create_admin.php`.

## Documentation

For detailed documentation, see [docs/SUMMARY.md](docs/SUMMARY.md).

## License

This project is open source under the MIT License.
