# Guide de Démarrage Rapide DNS3

> **Pour les nouveaux utilisateurs** : Ce guide vous aide à démarrer rapidement avec DNS3.

---

## 🚀 Installation en 5 Minutes

1. **Cloner le dépôt**
   ```bash
   git clone https://github.com/guittou/dns3.git
   cd dns3
   ```

2. **Créer la base de données**
   ```bash
   mysql -u root -p -e "CREATE DATABASE dns3_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
   mysql -u root -p dns3_db < database.sql
   ```

3. **Configurer l'application**
   ```bash
   cp config.php.example config.php  # Si disponible
   # Éditer config.php avec vos paramètres DB
   ```

4. **Créer un administrateur**
   ```bash
   php scripts/create_admin.php --username admin --password 'VotreMotDePasse' --email 'admin@example.com'
   ```

5. **Accéder à l'application**
   - Naviguer vers `http://localhost/dns3/`
   - Se connecter avec les identifiants créés

**📖 Guide Complet** : [docs/INSTALL.md](INSTALL.md)

---

## 📚 Documentation Essentielle

### Pour Démarrer

| Document | Description | Audience |
|----------|-------------|----------|
| [README.md](../README.md) | Vue d'ensemble du projet | Tous |
| [INSTALL.md](INSTALL.md) | Installation et configuration | Admins système |
| [GETTING_STARTED_API_TOKENS.md](../GETTING_STARTED_API_TOKENS.md) | Tokens API (démarrage rapide) | Développeurs |

### Administration

| Document | Description | Audience |
|----------|-------------|----------|
| [ADMIN_INTERFACE_GUIDE.md](ADMIN_INTERFACE_GUIDE.md) | Interface d'administration | Administrateurs |
| [ADMIN_QUICK_REFERENCE.md](ADMIN_QUICK_REFERENCE.md) | Référence rapide admin | Administrateurs |

### Gestion DNS

| Document | Description | Audience |
|----------|-------------|----------|
| [DNS_MANAGEMENT_GUIDE.md](DNS_MANAGEMENT_GUIDE.md) | Gestion des enregistrements DNS | Gestionnaires DNS |
| [import_bind_zones.md](import_bind_zones.md) | Import de zones BIND | Admins DNS |

### API et Automatisation

| Document | Description | Audience |
|----------|-------------|----------|
| [api_token_authentication.md](api_token_authentication.md) | Documentation API complète | Développeurs |

### Base de Données

| Document | Description | Audience |
|----------|-------------|----------|
| [DB_SCHEMA.md](DB_SCHEMA.md) | Schéma de la base de données | Développeurs/DBAs |
| [../migrations/README.md](../migrations/README.md) | Guide des migrations | Admins système |

---

## 🔑 Concepts Clés

### Fichiers de Zone

DNS3 gère deux types de fichiers de zone :

- **Master** : Fichiers de zone principaux contenant tous les enregistrements
- **Include** : Fichiers inclus via directive `$INCLUDE` dans les masters

### Authentification

Trois méthodes d'authentification :

1. **Base de données** : Utilisateurs locaux avec mot de passe hashé
2. **Active Directory** : Authentification via AD avec mappings de groupes
3. **OpenLDAP** : Authentification LDAP avec mappings de DN

### Tokens API

- Authentification stateless pour scripts et automatisation
- Générés via interface admin ou script
- Format : Bearer token dans en-tête `Authorization`
- Peuvent avoir une date d'expiration

### Validation de Zone

- Validation automatique via `named-checkzone`
- Exécutée en arrière-plan (worker cron)
- Résultats stockés dans `zone_file_validation`
- Accessible via API et interface web

---

## ⚡ Commandes Rapides

### Gestion des Utilisateurs

```bash
# Créer un administrateur
php scripts/create_admin.php --username admin --password 'Pass123!'

# Créer un utilisateur normal
php scripts/create_user.php --username user --password 'Pass123!' --role user
```

### Import de Zones

```bash
# Mode dry-run (test)
python3 scripts/import_bind_zones.py --dir /var/named/zones --dry-run

# Import réel
python3 scripts/import_bind_zones.py --dir /var/named/zones --skip-existing
```

### Tokens API

```bash
# Créer un token (requiert session)
curl -X POST 'http://localhost/dns3/api/admin_api.php?action=create_token' \
  -H 'Cookie: PHPSESSID=...' \
  -d '{"token_name":"MonToken","expires_in_days":365}'

# Utiliser un token
curl -H "Authorization: Bearer YOUR_TOKEN" \
  'http://localhost/dns3/api/zone_api.php?action=list_zones'
```

### Base de Données

```bash
# Backup
mysqldump -u root -p dns3_db > backup_$(date +%Y%m%d).sql

# Restauration
mysql -u root -p dns3_db < backup_20251208.sql

# Vérifier les utilisateurs
mysql -u root -p dns3_db -e "SELECT username, email, auth_method FROM users;"
```

---

## 🔧 Configuration Typique

### config.php Minimal

```php
<?php
// Base de données
define('DB_HOST', 'localhost');
define('DB_NAME', 'dns3_db');
define('DB_USER', 'dns3_user');
define('DB_PASS', 'VotreMotDePasse');

// URL de base
define('BASE_URL', '/dns3/');

// Active Directory (optionnel)
define('AD_ENABLED', false);
define('AD_SERVER', 'ad.example.com');
define('AD_PORT', 389);
define('AD_BASE_DN', 'DC=example,DC=com');

// OpenLDAP (optionnel)
define('LDAP_ENABLED', false);
define('LDAP_SERVER', 'ldap.example.com');
define('LDAP_PORT', 389);
define('LDAP_BASE_DN', 'dc=example,dc=com');

// Validation
define('NAMED_CHECKZONE_PATH', '/usr/sbin/named-checkzone');
define('ZONE_VALIDATE_SYNC', false); // true = synchrone, false = async
?>
```

---

## 🐛 Dépannage Rapide

### Problème : Erreur de connexion à la base de données

**Symptôme** : `SQLSTATE[HY000] [1045] Access denied`

**Solution** :
```bash
# Vérifier les credentials dans config.php
# Vérifier que l'utilisateur existe
mysql -u root -p -e "SELECT User, Host FROM mysql.user WHERE User='dns3_user';"

# Créer l'utilisateur si nécessaire
mysql -u root -p -e "CREATE USER 'dns3_user'@'localhost' IDENTIFIED BY 'password';"
mysql -u root -p -e "GRANT ALL ON dns3_db.* TO 'dns3_user'@'localhost';"
```

### Problème : named-checkzone non trouvé

**Symptôme** : Validation échoue avec "command not found"

**Solution** :
```bash
# Trouver le chemin
which named-checkzone

# Mettre à jour config.php
define('NAMED_CHECKZONE_PATH', '/usr/sbin/named-checkzone');
```

### Problème : Permissions fichiers

**Symptôme** : Erreurs d'écriture de fichiers

**Solution** :
```bash
# Définir les bonnes permissions
sudo chown -R www-data:www-data /var/www/dns3
sudo chmod -R 755 /var/www/dns3
sudo chmod -R 775 /var/www/dns3/jobs  # Pour les workers
```

### Problème : Authentification AD/LDAP ne fonctionne pas

**Symptôme** : Impossible de se connecter avec credentials AD

**Solution** :
1. Vérifier que l'extension PHP LDAP est installée : `php -m | grep ldap`
2. Tester la connexion LDAP manuellement
3. Vérifier les mappings dans `auth_mappings`
4. Consulter les logs : `/var/log/apache2/error.log`

---

## 📞 Support et Ressources

### Documentation Complète

- **Index Global** : [docs/SUMMARY.md](SUMMARY.md)
- **Guide de Contribution** : [docs/CONTRIBUTING_DOCS.md](CONTRIBUTING_DOCS.md)
- **État des Traductions** : [docs/TRANSLATION_STATUS.md](TRANSLATION_STATUS.md)

### Scripts Utiles

- `scripts/create_admin.php` - Créer un administrateur
- `scripts/import_bind_zones.py` - Importer des zones BIND
- `scripts/update_last_seen_from_bind_logs.sh` - Mettre à jour last_seen
- `jobs/worker.sh` - Worker de validation (cron)

### Fichiers de Configuration

- `config.php` - Configuration principale
- `.htaccess` - Configuration Apache
- `database.sql` - Schéma initial

### Logs

- `/var/log/apache2/error.log` - Logs Apache/PHP
- `jobs/worker.log` - Logs du worker de validation

---

## 🎯 Cas d'Usage Courants

### 1. Ajouter un Enregistrement DNS

**Via Interface Web** :
1. Connexion → DNS Management
2. Sélectionner une zone
3. Cliquer "Ajouter un enregistrement"
4. Remplir le formulaire
5. Sauvegarder

**Via API** :
```bash
curl -X POST 'http://localhost/dns3/api/dns_api.php?action=create' \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H 'Content-Type: application/json' \
  -d '{
    "zone_file_id": 1,
    "name": "www",
    "record_type": "A",
    "address_ipv4": "192.0.2.1",
    "ttl": 3600
  }'
```

### 2. Importer des Zones Existantes

```bash
# Dry-run d'abord
python3 scripts/import_bind_zones.py \
  --dir /var/named/zones \
  --api-url http://localhost/dns3 \
  --api-token YOUR_TOKEN \
  --dry-run

# Import réel après vérification
python3 scripts/import_bind_zones.py \
  --dir /var/named/zones \
  --api-url http://localhost/dns3 \
  --api-token YOUR_TOKEN \
  --skip-existing
```

### 3. Configurer l'Authentification AD

```sql
-- Créer un mapping pour le groupe AD "DNSAdmins"
INSERT INTO auth_mappings (source, dn_or_group, role_id, notes)
SELECT 'ad', 'CN=DNSAdmins,OU=Groups,DC=example,DC=com', r.id, 'Administrateurs DNS'
FROM roles r WHERE r.name = 'admin';
```

### 4. Backup Automatique

```bash
#!/bin/bash
# Ajouter à crontab : 0 2 * * * /path/to/backup.sh

BACKUP_DIR="/backup/dns3"
DATE=$(date +%Y%m%d_%H%M%S)

mysqldump -u root -p'password' dns3_db > "$BACKUP_DIR/dns3_db_$DATE.sql"

# Garder seulement les 7 derniers backups
cd "$BACKUP_DIR"
ls -t dns3_db_*.sql | tail -n +8 | xargs rm -f
```

---

**💡 Astuce** : Marquez cette page en favori pour un accès rapide aux ressources essentielles !

**📖 Pour aller plus loin** : Consultez [docs/SUMMARY.md](SUMMARY.md) pour la documentation complète.
