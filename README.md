# DNS3 - Application Web PHP

Application web développée en PHP sans framework avec support MariaDB et authentification multi-sources (Base de données, Active Directory, OpenLDAP).

## Fonctionnalités

- **Authentification multi-sources** :
  - Base de données locale avec hashage sécurisé des mots de passe
  - Active Directory (AD)
  - OpenLDAP
  - Mode automatique qui essaie toutes les méthodes

- **Interface utilisateur moderne** :
  - Bandeau fixe en haut de page avec logo et bouton de connexion
  - Onglets de navigation pour accéder aux différentes pages
  - Design responsive compatible mobile et desktop
  - Zone de contenu principal sous le bandeau

- **Support multi-chemins** :
  - Accessible via `https://monsite.fr/`
  - Accessible via `https://monsite.fr/CHEMIN/`
  - Gestion des URL propres via `.htaccess`

## Structure du projet

```
dns3/
├── config.php              # Configuration de l'application
├── database.sql            # Schéma de base de données
├── index.php               # Page d'accueil
├── login.php               # Page de connexion
├── logout.php              # Script de déconnexion
├── dashboard.php           # Tableau de bord (authentification requise)
├── services.php            # Page des services
├── about.php               # Page à propos
├── .htaccess              # Configuration Apache (URL rewriting, sécurité)
├── includes/
│   ├── db.php             # Classe de connexion à la base de données
│   ├── auth.php           # Gestionnaire d'authentification
│   ├── header.php         # En-tête avec bandeau fixe
│   └── footer.php         # Pied de page
└── assets/
    ├── css/
    │   └── style.css      # Styles CSS
    └── images/
        ├── logo.svg       # Logo de l'application
        └── logo.png       # Logo (lien symbolique)
```

## Installation

### Prérequis

- PHP 7.4 ou supérieur
- MariaDB 10.3 ou supérieur (ou MySQL 5.7+)
- Apache avec mod_rewrite activé
- Extension PHP LDAP (optionnel, pour Active Directory et OpenLDAP)

### Étapes d'installation

1. **Cloner le repository**
   ```bash
   git clone https://github.com/guittou/dns3.git
   cd dns3
   ```

2. **Configurer la base de données**
   ```bash
   mysql -u root -p < database.sql
   ```

3. **Configurer l'application**
   
   Éditer le fichier `config.php` et ajuster les paramètres :
   - Configuration de la base de données (DB_HOST, DB_NAME, DB_USER, DB_PASS)
   - Configuration Active Directory (AD_SERVER, AD_PORT, AD_BASE_DN, AD_DOMAIN)
   - Configuration OpenLDAP (LDAP_SERVER, LDAP_PORT, LDAP_BASE_DN)

4. **Configurer le serveur web**
   
   Pour Apache, créer un Virtual Host :
   ```apache
   <VirtualHost *:80>
       ServerName monsite.fr
       DocumentRoot /var/www/dns3
       
       <Directory /var/www/dns3>
           Options -Indexes +FollowSymLinks
           AllowOverride All
           Require all granted
       </Directory>
       
       ErrorLog ${APACHE_LOG_DIR}/dns3-error.log
       CustomLog ${APACHE_LOG_DIR}/dns3-access.log combined
   </VirtualHost>
   ```

5. **Activer mod_rewrite** (si ce n'est pas déjà fait)
   ```bash
   sudo a2enmod rewrite
   sudo systemctl restart apache2
   ```

6. **Configurer les permissions**
   ```bash
   sudo chown -R www-data:www-data /var/www/dns3
   sudo chmod -R 755 /var/www/dns3
   ```

## Configuration

### Base de données

Le fichier `database.sql` crée automatiquement :
- Une base de données `dns3_db`
- Une table `users` pour les utilisateurs
- Une table `sessions` pour la gestion des sessions
- Un utilisateur admin par défaut (username: `admin`, password: `admin123`)

**Important** : Changez le mot de passe admin après la première connexion !

### Active Directory

Pour activer l'authentification Active Directory, configurez les paramètres dans `config.php` :

```php
define('AD_SERVER', 'ldap://ad.example.com');
define('AD_PORT', 389);
define('AD_BASE_DN', 'DC=example,DC=com');
define('AD_DOMAIN', 'EXAMPLE');
```

### OpenLDAP

Pour activer l'authentification OpenLDAP, configurez les paramètres dans `config.php` :

```php
define('LDAP_SERVER', 'ldap://ldap.example.com');
define('LDAP_PORT', 389);
define('LDAP_BASE_DN', 'dc=example,dc=com');
define('LDAP_BIND_DN', 'cn=admin,dc=example,dc=com');
define('LDAP_BIND_PASS', 'your_ldap_password');
```

## Utilisation

### Connexion

1. Accédez à `https://monsite.fr/login.php`
2. Entrez vos identifiants
3. Sélectionnez la méthode d'authentification :
   - **Automatique** : essaie toutes les méthodes dans l'ordre
   - **Base de données** : uniquement la base de données locale
   - **Active Directory** : uniquement AD
   - **OpenLDAP** : uniquement LDAP

### Navigation

- **Accueil** : Page d'accueil avec présentation
- **Tableau de bord** : Zone personnelle (authentification requise)
- **Services** : Liste des services disponibles
- **À propos** : Informations sur l'application

## Sécurité

L'application implémente plusieurs mesures de sécurité :

- Hashage des mots de passe avec `password_hash()` (bcrypt)
- Protection contre les injections SQL via PDO et requêtes préparées
- Sessions sécurisées avec `httponly` et `strict_mode`
- Headers de sécurité HTTP (X-Frame-Options, X-XSS-Protection, etc.)
- Protection des fichiers sensibles via `.htaccess`
- Désactivation de l'affichage des erreurs en production

## Support multi-chemins

L'application supporte plusieurs configurations d'URL :

- À la racine : `https://monsite.fr/`
- Dans un sous-répertoire : `https://monsite.fr/CHEMIN/`

Ajustez la variable `BASE_URL` dans `config.php` selon votre configuration.

## Développement

### Sans framework

Cette application a été développée en PHP pur sans framework pour :
- Réduire les dépendances
- Améliorer les performances
- Faciliter la maintenance
- Offrir plus de flexibilité

### Personnalisation

- **Styles** : Modifiez `assets/css/style.css`
- **Logo** : Remplacez `assets/images/logo.png` ou `logo.svg`
- **Pages** : Ajoutez de nouvelles pages PHP et créez les liens dans `includes/header.php`

## Dépannage

### Erreur de connexion à la base de données

Vérifiez que :
- MariaDB est démarré
- Les identifiants dans `config.php` sont corrects
- La base de données existe et l'utilisateur a les permissions nécessaires

### Erreur LDAP/AD

Vérifiez que :
- L'extension PHP LDAP est installée : `php -m | grep ldap`
- Les paramètres de connexion sont corrects
- Le serveur LDAP/AD est accessible depuis le serveur web

### Problème de redirection/URL

Vérifiez que :
- `mod_rewrite` est activé
- Le fichier `.htaccess` est bien présent
- `AllowOverride All` est configuré dans le Virtual Host

## Licence

Ce projet est open source et disponible sous licence MIT.

## Contribution

Les contributions sont les bienvenues ! N'hésitez pas à ouvrir une issue ou une pull request.
