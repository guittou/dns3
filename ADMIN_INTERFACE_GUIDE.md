# Guide d'Utilisation de l'Interface d'Administration

## Vue d'ensemble

L'interface d'administration de DNS3 permet de gérer les utilisateurs, les rôles et les mappings AD/LDAP pour l'authentification automatique. Cette interface est accessible uniquement aux utilisateurs ayant le rôle **admin**.

## Installation et Configuration

### 1. Appliquer la Migration de Base de Données

Exécutez la migration pour créer la table `auth_mappings` :

```bash
mysql -u dns3_user -p dns3_db < migrations/002_create_auth_mappings.sql
```

### 2. Créer un Utilisateur Administrateur

Utilisez le script fourni pour créer ou réinitialiser l'utilisateur admin :

```bash
php scripts/create_admin.php --username admin --password 'admin123' --email 'admin@example.local'
```

Ou en mode interactif :

```bash
php scripts/create_admin.php
```

### 3. Accéder à l'Interface

Connectez-vous avec les identifiants admin, puis accédez à :
```
http://votre-domaine/admin.php
```

## Fonctionnalités

### Onglet Utilisateurs

#### Lister les Utilisateurs
- Affiche tous les utilisateurs avec leurs informations : nom d'utilisateur, email, méthode d'authentification, rôles, statut
- **Filtres disponibles** :
  - Recherche par nom d'utilisateur
  - Filtrage par méthode d'authentification (database, AD, LDAP)
  - Filtrage par statut (actif/inactif)

#### Créer un Utilisateur
1. Cliquez sur **"Créer un utilisateur"**
2. Remplissez le formulaire :
   - **Nom d'utilisateur*** : requis, unique
   - **Email*** : requis, unique
   - **Méthode d'authentification*** : 
     - `database` : authentification locale (nécessite un mot de passe)
     - `ad` : Active Directory (pas de mot de passe local)
     - `ldap` : OpenLDAP (pas de mot de passe local)
   - **Mot de passe*** : requis uniquement pour la méthode `database`
   - **Statut** : actif ou inactif
   - **Rôles** : sélectionnez les rôles à attribuer (admin, user, etc.)
3. Cliquez sur **"Enregistrer"**

#### Modifier un Utilisateur
1. Cliquez sur **"Modifier"** dans la ligne de l'utilisateur
2. Modifiez les champs souhaités
3. Pour changer le mot de passe (utilisateurs `database` uniquement), entrez un nouveau mot de passe
4. Ajoutez ou supprimez des rôles en cochant/décochant les cases
5. Cliquez sur **"Enregistrer"**

### Onglet Rôles

Affiche la liste des rôles disponibles dans l'application :
- **admin** : accès complet à toutes les fonctionnalités
- **user** : accès en lecture seule

Les rôles sont définis dans la base de données et ne peuvent pas être modifiés via cette interface.

### Onglet Mappings AD/LDAP

Les mappings permettent d'attribuer automatiquement des rôles aux utilisateurs lors de l'authentification AD/LDAP, en fonction de leur appartenance à un groupe ou d'leur position dans l'arborescence LDAP.

#### Lister les Mappings
Affiche tous les mappings configurés avec :
- Source (AD ou LDAP)
- DN ou groupe associé
- Rôle attribué
- Créateur et date de création
- Notes

#### Créer un Mapping

1. Cliquez sur **"Créer un mapping"**
2. Remplissez le formulaire :
   - **Source*** : `ad` ou `ldap`
   - **DN/Groupe*** : 
     - Pour AD : DN complet du groupe, ex: `CN=DNSAdmins,OU=Groups,DC=example,DC=com`
     - Pour LDAP : DN ou chemin OU, ex: `ou=IT,dc=example,dc=com`
   - **Rôle*** : sélectionnez le rôle à attribuer (admin, user, etc.)
   - **Notes** : description optionnelle du mapping
3. Cliquez sur **"Créer"**

#### Supprimer un Mapping
1. Cliquez sur **"Supprimer"** dans la ligne du mapping
2. Confirmez la suppression

### Onglet ACL

Cette section est prévue pour une implémentation future et permettra de définir des permissions granulaires sur les ressources DNS.

## API Administration

L'interface utilise une API REST sécurisée accessible uniquement aux administrateurs.

### Endpoints Disponibles

#### Utilisateurs
- `GET /api/admin_api.php?action=list_users` - Lister les utilisateurs
- `GET /api/admin_api.php?action=get_user&id=X` - Obtenir un utilisateur
- `POST /api/admin_api.php?action=create_user` - Créer un utilisateur
- `POST /api/admin_api.php?action=update_user&id=X` - Modifier un utilisateur
- `POST /api/admin_api.php?action=assign_role&user_id=X&role_id=Y` - Attribuer un rôle
- `POST /api/admin_api.php?action=remove_role&user_id=X&role_id=Y` - Retirer un rôle

#### Rôles
- `GET /api/admin_api.php?action=list_roles` - Lister les rôles

#### Mappings
- `GET /api/admin_api.php?action=list_mappings` - Lister les mappings
- `POST /api/admin_api.php?action=create_mapping` - Créer un mapping
- `POST /api/admin_api.php?action=delete_mapping&id=X` - Supprimer un mapping

### Exemples d'Utilisation de l'API

#### Créer un utilisateur
```bash
curl -X POST http://votre-domaine/api/admin_api.php?action=create_user \
  -H "Content-Type: application/json" \
  -d '{
    "username": "john.doe",
    "email": "john.doe@example.com",
    "auth_method": "database",
    "password": "SecurePassword123",
    "is_active": 1,
    "role_ids": [2]
  }'
```

#### Créer un mapping AD
```bash
curl -X POST http://votre-domaine/api/admin_api.php?action=create_mapping \
  -H "Content-Type: application/json" \
  -d '{
    "source": "ad",
    "dn_or_group": "CN=DNSAdmins,OU=Groups,DC=example,DC=com",
    "role_id": 1,
    "notes": "Attribution automatique du rôle admin pour les membres du groupe DNSAdmins"
  }'
```

## Sécurité

### Contrôle d'Accès
- L'interface et l'API nécessitent une authentification
- Seuls les utilisateurs avec le rôle **admin** peuvent accéder à ces fonctionnalités
- Les tentatives d'accès non autorisées retournent une erreur 403 Forbidden

### Mots de Passe
- Les mots de passe sont hachés avec `password_hash()` (bcrypt) avant stockage
- Les mots de passe ne sont jamais affichés en clair
- La modification d'un utilisateur ne change pas le mot de passe si le champ est laissé vide

### Validation des Données
- Tous les champs requis sont validés côté serveur
- Les données sont échappées pour prévenir les injections SQL et XSS
- Les méthodes d'authentification sont limitées à : database, ad, ldap

## Intégration avec AD/LDAP

Les mappings créés dans l'interface doivent être utilisés lors de l'authentification AD/LDAP. Pour cela :

1. Après une authentification AD/LDAP réussie, le système doit :
   - Récupérer les groupes de l'utilisateur (AD) ou son DN (LDAP)
   - Interroger la table `auth_mappings` pour trouver les rôles correspondants
   - Attribuer automatiquement ces rôles à l'utilisateur

2. Cette logique peut être implémentée dans `includes/auth.php` dans les méthodes :
   - `authenticateActiveDirectory()`
   - `authenticateLDAP()`

### Exemple de Code d'Intégration

```php
// Après authentification AD réussie
$groups = ldap_get_entries($ldap, ldap_search($ldap, AD_BASE_DN, "(sAMAccountName=$username)", ['memberOf']));

// Pour chaque groupe de l'utilisateur
foreach ($groups[0]['memberof'] as $groupDn) {
    // Chercher le mapping correspondant
    $stmt = $this->db->prepare("SELECT role_id FROM auth_mappings WHERE source = 'ad' AND dn_or_group = ?");
    $stmt->execute([$groupDn]);
    
    // Attribuer le rôle si un mapping existe
    if ($mapping = $stmt->fetch()) {
        $userModel = new User();
        $userModel->assignRole($user['id'], $mapping['role_id']);
    }
}
```

## Dépannage

### L'onglet Administration n'apparaît pas
- Vérifiez que vous êtes connecté avec un compte admin
- Vérifiez que le rôle 'admin' est bien attribué à votre utilisateur dans la table `user_roles`

### Erreur "Failed to create user"
- Le nom d'utilisateur ou l'email existe peut-être déjà
- Vérifiez que tous les champs requis sont remplis
- Pour un utilisateur `database`, le mot de passe est obligatoire

### Erreur lors de la création d'un mapping
- Vérifiez que le mapping n'existe pas déjà (même source, DN/groupe et rôle)
- Vérifiez que le format du DN est correct
- Assurez-vous que le rôle sélectionné existe

### Problèmes de permissions
- Vérifiez que les tables `roles`, `user_roles` et `auth_mappings` existent
- Vérifiez les permissions de la base de données pour l'utilisateur DNS3

## Maintenance

### Sauvegarde
Avant toute modification importante, sauvegardez la base de données :
```bash
mysqldump -u dns3_user -p dns3_db > backup_$(date +%Y%m%d_%H%M%S).sql
```

### Audit
Toutes les modifications sont enregistrées avec :
- L'utilisateur qui a effectué la modification
- La date et l'heure de la modification
- Les valeurs avant/après (pour les historiques DNS et ACL)

### Logs
Les erreurs sont enregistrées dans les logs PHP. Consultez :
```bash
tail -f /var/log/php/error.log
# ou
tail -f /var/log/apache2/error.log
```

## Support

Pour toute question ou problème :
1. Consultez les logs d'erreur
2. Vérifiez la configuration de la base de données
3. Assurez-vous que toutes les migrations ont été appliquées
4. Vérifiez les permissions des utilisateurs admin
