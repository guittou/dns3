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

# Importer le schéma dans la base dns3_db
mysql -u dns3_user -p dns3_db < database.sql
```

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
php scripts/create_admin.php --username admin --password 'AdminPass123!' --email 'admin@example.local'
```

Ou en mode interactif (le script vous demandera les informations) :

```bash
php scripts/create_admin.php
```

**Ce que fait le script :**
1. Crée un enregistrement dans la table `users` avec le mot de passe hashé via `password_hash(..., PASSWORD_DEFAULT)`
2. Si la table `roles` contient un rôle `name='admin'`, il ajoute automatiquement une entrée dans `user_roles` pour assigner ce rôle à l'utilisateur
3. Si l'utilisateur existe déjà, le script met à jour son mot de passe
4. Affiche un message de succès ou d'erreur

**Vérifications post-exécution :**

```sql
-- Vérifier que l'utilisateur a été créé
SELECT id, username, email, auth_method, is_active FROM users WHERE username = 'admin';

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
INSERT INTO users (username, email, password, auth_method, is_active, created_at)
VALUES ('admin', 'admin@example.local', '$2y$10$...votre_hash...', 'database', 1, NOW());

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
