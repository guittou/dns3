# Modifications de l'authentification admin

## Vue d'ensemble
Ce document décrit les modifications apportées pour imposer la création d'utilisateurs en base de données uniquement via l'interface d'administration et implémenter le mapping de rôles AD/LDAP lors de l'authentification.

**Branche :** feature/fix-admin-db-only

## Modifications effectuées

### 1. Création d'utilisateurs en base de données uniquement (application côté serveur)

#### api/admin_api.php
- Le point de terminaison `create_user` **impose** maintenant `auth_method = 'database'` côté serveur
- Toute valeur `auth_method` fournie par le client est ignorée
- Le mot de passe est requis pour tous les utilisateurs créés par l'admin
- Le point de terminaison `update_user` **empêche** le changement de `auth_method` vers 'ad' ou 'ldap'
- Retourne une erreur HTTP 400 avec un message clair si une tentative de basculement vers AD/LDAP est effectuée

#### includes/models/User.php
- La méthode `create()` force `auth_method = 'database'`
- Le hashage de mot de passe est imposé pour tous les utilisateurs de base de données
- La méthode `update()` supprime complètement le support de changement de `auth_method`
- La validation côté serveur assure l'intégrité de auth_method

#### assets/js/admin.js
- Le client définit `auth_method: 'database'` pour les nouveaux utilisateurs
- Le champ de méthode d'authentification est masqué lors de la création de nouveaux utilisateurs
- Le champ de méthode d'authentification est affiché mais désactivé (lecture seule) lors de l'édition d'utilisateurs existants
- Le champ de mot de passe est affiché/masqué selon l'auth_method de l'utilisateur

#### admin.php
- Le champ de méthode d'authentification dans le modal est marqué comme désactivé
- Texte d'aide ajouté expliquant que les utilisateurs créés par l'admin utilisent l'authentification par base de données
- Les utilisateurs AD/LDAP sont notés comme étant créés automatiquement lors de la première connexion

### 2. Suppression de l'UI ACL

#### admin.php
- Bouton d'onglet ACL retiré de la navigation
- Section de contenu de l'onglet ACL supprimée
- Seulement 3 onglets restent : Utilisateurs, Rôles, Mappings AD/LDAP

#### includes/header.php
- Vérifié : Aucun lien ACL présent (il n'y en avait pas)

### 3. Implémentation du mapping de rôles AD/LDAP

#### includes/auth.php
- `authenticateActiveDirectory()` récupère maintenant les groupes `memberOf` de l'utilisateur
- `authenticateLDAP()` récupère le DN de l'utilisateur
- Nouvelle méthode `createOrUpdateUserWithMappings()` :
  - Crée un enregistrement utilisateur minimal si l'utilisateur n'existe pas
  - Définit `auth_method` à 'ad' ou 'ldap' de manière appropriée
  - Appelle la logique de mapping de rôles après création/mise à jour de l'utilisateur
- Nouvelle méthode `applyRoleMappings()` :
  - Interroge la table `auth_mappings` pour trouver les règles correspondantes
  - Pour AD : Fait correspondre le DN de groupe avec l'attribut `memberOf` de l'utilisateur
  - Pour LDAP : Vérifie si le DN de l'utilisateur contient le chemin DN/OU mappé
  - Persiste les attributions de rôles en utilisant `INSERT...ON DUPLICATE KEY UPDATE`
  - Utilise des requêtes préparées pour la sécurité
  - Défensif : gère les attributs manquants avec élégance

#### Schéma de base de données
- Table `auth_mappings` (de la migration 002) :
  - Mappe les groupes AD ou chemins DN/OU LDAP vers les rôles d'application
  - Supporte les sources 'ad' et 'ldap'
  - La contrainte unique empêche les mappings dupliqués

## Instructions de test

### Test 1 : Création d'utilisateur en base de données
1. Naviguer vers le panneau d'administration (admin.php)
2. Cliquer sur "Créer un utilisateur"
3. Remplir nom d'utilisateur, mot de passe
4. Noter que le champ auth_method n'est pas affiché
5. Enregistrer l'utilisateur
6. Vérifier dans la base de données : `SELECT username, auth_method FROM users WHERE username='testuser';`
7. Attendu : `auth_method = 'database'`

### Test 2 : Application de la méthode d'authentification (requête craftée)
```bash
curl -X POST 'http://localhost/api/admin_api.php?action=create_user' \
  -H 'Content-Type: application/json' \
  -d '{
    "username": "testuser2",
    "password": "password123",
    "auth_method": "ad"
  }'
```
Attendu : Utilisateur créé avec `auth_method='database'` (le serveur ignore 'ad')

### Test 3 : Empêcher le changement de méthode d'authentification
```bash
curl -X POST 'http://localhost/api/admin_api.php?action=update_user&id=1' \
  -H 'Content-Type: application/json' \
  -d '{
    "auth_method": "ldap"
  }'
```
Attendu : Erreur HTTP 400 avec message concernant l'impossibilité de changer auth_method

### Test 4 : Suppression de l'onglet ACL
1. Naviguer vers le panneau d'administration (admin.php)
2. Vérifier que seulement 3 onglets sont visibles :
   - Utilisateurs
   - Rôles
   - Mappings AD/LDAP
3. Vérifier qu'il n'y a pas d'onglet ACL

### Test 5 : Mapping de rôles AD/LDAP
1. Naviguer vers l'onglet "Mappings AD/LDAP"
2. Créer un mapping :
   - Source : Active Directory (ou LDAP)
   - DN/Groupe : `CN=DNSAdmins,OU=Groups,DC=example,DC=com`
   - Rôle : admin
3. Se connecter en tant qu'utilisateur AD membre du groupe DNSAdmins
4. Vérifier dans la base de données :
   ```sql
   SELECT u.username, u.auth_method, r.name as role
   FROM users u
   JOIN user_roles ur ON u.id = ur.user_id
   JOIN roles r ON ur.role_id = r.id
   WHERE u.username = 'aduser';
   ```
5. Attendu : Utilisateur créé avec `auth_method='ad'` et rôle 'admin' assigné

## Considérations de sécurité

1. **Autorité côté serveur** : Toute validation de auth_method se fait côté serveur. Les indices côté client sont secondaires et ne peuvent pas outrepasser la logique serveur.

2. **Hashage de mot de passe** : Tous les utilisateurs de base de données ont leurs mots de passe hashés en utilisant `PASSWORD_DEFAULT` (bcrypt).

3. **Requêtes préparées** : Toutes les requêtes de base de données utilisent des requêtes préparées pour prévenir l'injection SQL.

4. **Séparation des préoccupations** : 
   - Les utilisateurs créés par l'admin sont toujours des utilisateurs de base de données
   - Les utilisateurs AD/LDAP sont créés automatiquement lors de l'authentification
   - Cela empêche l'escalade de privilèges via la manipulation de auth_method

## Compatibilité rétroactive

- Les utilisateurs de base de données existants ne sont pas affectés
- Les utilisateurs AD/LDAP existants continuent de fonctionner
- Les mappings d'authentification sont additifs - ils ne suppriment pas les rôles existants
- Aucune modification cassante de la structure de l'API (les points de terminaison restent les mêmes)
