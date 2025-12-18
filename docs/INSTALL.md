# Guide d'installation rapide - DNS3

## Installation locale pour test

Si vous souhaitez tester l'application en local, voici la procédure simplifiée :

### 1. Prérequis

Installez un environnement LAMP/WAMP/MAMP ou utilisez PHP built-in server pour un test rapide.

**Option A : Serveur PHP intégré (test rapide)**
```bash
# Installer PHP et MariaDB
sudo apt-get update
sudo apt-get install php php-mysql php-ldap mariadb-server

# Démarrer MariaDB
sudo systemctl start mariadb
```

**Option B : Apache complet**
```bash
sudo apt-get install apache2 php libapache2-mod-php php-mysql php-ldap mariadb-server
sudo a2enmod rewrite
sudo systemctl restart apache2
```

#### Validation de zones DNS (named-checkzone)

DNS3 utilise l'outil `named-checkzone` (fourni par BIND) pour valider la syntaxe des fichiers de zone DNS. Cet outil est **obligatoire** pour la fonctionnalité de validation de zones.

**Installation selon la distribution :**

- **Debian/Ubuntu :**
  ```bash
  sudo apt-get install bind9-utils
  ```

- **RHEL/CentOS/AlmaLinux/Rocky Linux :**
  ```bash
  # Pour les versions plus anciennes avec yum
  sudo yum install bind-utils
  
  # Pour les versions récentes avec dnf
  sudo dnf install bind-utils
  ```

**Vérification de l'installation :**
```bash
which named-checkzone
```

Si la commande retourne un chemin (ex: `/usr/bin/named-checkzone`), l'outil est correctement installé.

**Note importante :** Si vous activez le worker de validation en tâche CRON (voir `jobs/README.md`), assurez-vous que `named-checkzone` est présent dans le PATH du job CRON. Si nécessaire, vous pouvez spécifier le chemin complet dans `config.php` :

```php
define('NAMED_CHECKZONE_PATH', '/usr/bin/named-checkzone');
```

#### Dépendances pour les scripts d'import (Python)

Si vous prévoyez d'utiliser les scripts d'import de zones BIND (`scripts/import_bind_zones.py`), vous aurez besoin des dépendances Python suivantes.

**Installation sur Debian 12 / Ubuntu (paquets système) :**

```bash
sudo apt install -y \
  python3-dnspython \
  python3-requests \
  python3-pymysql
```

**Alternative avec pip (si les paquets système ne sont pas disponibles) :**

```bash
pip3 install dnspython requests pymysql
```

Ces dépendances permettent au script Python d'analyser correctement les fichiers de zone BIND (dnspython), de communiquer avec l'API REST (requests) et d'accéder directement à la base de données si nécessaire (pymysql).

Pour plus de détails sur l'utilisation des scripts d'import, consultez `docs/import_bind_zones.md`.

### 2. Configuration de la base de données

```bash
# Se connecter à MariaDB
sudo mysql -u root

# Créer la base et l'utilisateur
CREATE DATABASE dns3_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER 'dns3_user'@'localhost' IDENTIFIED BY 'VotreMotDePasse';
GRANT ALL PRIVILEGES ON dns3_db.* TO 'dns3_user'@'localhost';
FLUSH PRIVILEGES;
exit;

# Importer le schéma dans la base dns3_db (sélection explicite de la base)
mysql -u dns3_user -p dns3_db < database.sql
```

**Note importante** : 
- Le fichier `database.sql` utilise `SQL SECURITY INVOKER` pour les vues, ce qui permet l'import avec un compte non-SUPER. Si vous utilisez un dump personnalisé contenant `DEFINER=`, consultez la section de dépannage ci-dessous.
- Les rôles de base `admin` et `user` sont automatiquement créés lors de l'import du schéma. Vous pouvez les voir dans l'interface d'administration sous "Administration > Rôles".

### 3. Configuration de l'application

Éditer `config.php` et mettre à jour les paramètres de connexion :

```php
define('DB_HOST', 'localhost');
define('DB_NAME', 'dns3_db');
define('DB_USER', 'dns3_user');
define('DB_PASS', 'VotreMotDePasse');
```

### 4. Lancement

**Option A : Serveur PHP intégré (test uniquement)**
```bash
cd /chemin/vers/dns3
php -S localhost:8000
```

Puis accédez à : `http://localhost:8000`

**Option B : Apache**
```bash
# Copier les fichiers dans le répertoire web
sudo cp -r dns3 /var/www/html/
sudo chown -R www-data:www-data /var/www/html/dns3
```

Puis accédez à : `http://localhost/dns3`

### 5. Première connexion

- **URL** : `http://localhost:8000/login.php` (ou `/dns3/login.php` avec Apache)
- **Utilisateur** : `admin`
- **Mot de passe** : `admin123`
- **Méthode** : Base de données

**Important** : Changez le mot de passe admin immédiatement après la première connexion !

### 6. Création du compte administrateur

#### Méthode A — Créer un administrateur via script PHP (recommandée)

**Prérequis :**
- `config.php` configuré avec les identifiants de base de données
- PHP CLI disponible et fonctionnel
- Accès au répertoire `scripts/` du projet

**Commande d'exemple :**

```bash
php scripts/create_admin.php --username admin --password 'AdminPass123!'
```

Ou en mode interactif (le script vous demandera les informations) :

```bash
php scripts/create_admin.php
```

**Ce que fait le script :**
1. Crée un enregistrement dans la table `users` avec le mot de passe hashé via `password_hash(..., PASSWORD_DEFAULT)`
2. Assigne automatiquement le rôle `admin` à l'utilisateur (le rôle existe déjà après l'import du schéma)
3. Si l'utilisateur existe déjà, le script met à jour son mot de passe
4. Affiche un message de succès ou d'erreur

**Vérifications post-exécution :**

```sql
-- Vérifier que l'utilisateur a été créé
SELECT id, username, auth_method, is_active FROM users WHERE username = 'admin';

-- Vérifier que le rôle admin existe
SELECT r.id, r.name FROM roles r WHERE r.name = 'admin';

-- Vérifier que le rôle a été assigné (remplacer <id_utilisateur> par l'ID retourné)
SELECT * FROM user_roles WHERE user_id = <id_utilisateur>;
```

**Résultat attendu :**
- L'utilisateur apparaît dans la table `users` avec `auth_method = 'database'` et `is_active = 1`
- Une entrée existe dans `user_roles` liant l'utilisateur au rôle `admin`

> Pour plus d'options et de détails, consultez directement le fichier `scripts/create_admin.php`.

#### Méthode B — Création manuelle via SQL (alternative)

Si vous préférez créer l'administrateur directement en SQL :

```bash
# Générer le hash du mot de passe
php -r "echo password_hash('VotreMotDePasse', PASSWORD_DEFAULT) . PHP_EOL;"
```

```sql
-- Insérer l'utilisateur (remplacer $2y$10$...votre_hash... par le hash généré)
INSERT INTO users (username, password, auth_method, is_active, created_at)
VALUES ('admin', '$2y$10$...votre_hash...', 'database', 1, NOW());

-- Assigner le rôle admin
INSERT INTO user_roles (user_id, role_id, assigned_at)
SELECT u.id, r.id, NOW() FROM users u, roles r
WHERE u.username = 'admin' AND r.name = 'admin';
```

#### Note de sécurité

- **Changez le mot de passe par défaut** immédiatement après la première connexion
- **Limitez l'accès au répertoire `scripts/`** en production (via `.htaccess` ou configuration serveur)
- **Ne commitez jamais** de mots de passe en clair dans le code source
- Utilisez des mots de passe forts (minimum 12 caractères, mélange de lettres, chiffres et caractères spéciaux)

### 7. Configuration LDAP/AD (optionnel)

Si vous voulez tester avec Active Directory ou OpenLDAP :

1. Assurez-vous que l'extension PHP LDAP est installée :
   ```bash
   php -m | grep ldap
   ```

2. Si absente, installez-la :
   ```bash
   sudo apt-get install php-ldap
   sudo systemctl restart apache2  # ou redémarrez le serveur PHP
   ```

3. Configurez les paramètres dans `config.php`

## Test rapide sans base de données

Pour tester l'interface sans configurer la base de données, vous pouvez commenter temporairement les lignes de connexion dans `includes/header.php` et voir directement les pages statiques.

## Dépannage rapide

### Erreur "Access denied; you need (at least one of) the SUPER, SET USER privilege(s)"

Cette erreur se produit lors de l'import d'un dump SQL contenant des clauses `DEFINER=` sur les vues, procédures stockées ou triggers.

**Le fichier `database.sql` fourni** a été corrigé pour utiliser `SQL SECURITY INVOKER` sans `DEFINER`, évitant ce problème.

**Si vous importez un dump personnalisé** contenant `DEFINER`, deux solutions :

**Solution 1 : Importer en tant que root**
```bash
# Importer avec l'utilisateur root (possède les privilèges SUPER)
sudo mysql -u root dns3_db < votre_dump.sql
```

**Solution 2 : Nettoyer le DEFINER avant l'import**
```bash
# Retirer toutes les clauses DEFINER du fichier SQL
sed -i 's/DEFINER=`[^`]*`@`[^`]*` //g' votre_dump.sql

# Puis importer normalement
mysql -u dns3_user -p dns3_db < votre_dump.sql
```

**Remarque** : La solution 2 est recommandée car elle évite d'avoir à utiliser le compte root et permet à la vue d'utiliser les privilèges de l'utilisateur qui l'interroge (`SQL SECURITY INVOKER`).

### Erreur "No database selected"

Si vous obtenez cette erreur lors de l'import, assurez-vous de spécifier explicitement le nom de la base de données dans la commande d'import :

```bash
# Correct - spécifie la base dns3_db
mysql -u dns3_user -p dns3_db < database.sql

# Incorrect - aucune base sélectionnée
mysql -u dns3_user -p < database.sql
```

### Erreur "Call to undefined function ldap_connect"
```bash
sudo apt-get install php-ldap
sudo systemctl restart apache2
```

### Erreur de connexion PDO
Vérifiez que :
- MariaDB est démarré : `sudo systemctl status mariadb`
- Les identifiants dans `config.php` sont corrects
- L'extension PDO MySQL est installée : `php -m | grep pdo_mysql`

### Page blanche
Activez l'affichage des erreurs temporairement dans `config.php` :
```php
ini_set('display_errors', 1);
error_reporting(E_ALL);
```

## Production

Pour un déploiement en production, suivez le README.md complet qui inclut :
- Configuration HTTPS
- Sécurisation du serveur
- Optimisation des performances
- Backup et monitoring
