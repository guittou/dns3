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

# Créer un utilisateur et importer le schéma
CREATE USER 'dns3_user'@'localhost' IDENTIFIED BY 'VotreMotDePasse';
GRANT ALL PRIVILEGES ON dns3_db.* TO 'dns3_user'@'localhost';
FLUSH PRIVILEGES;
exit;

# Importer le schéma
mysql -u dns3_user -p < database.sql
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

### 6. Configuration LDAP/AD (optionnel)

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
