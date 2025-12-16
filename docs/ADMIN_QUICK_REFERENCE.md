# Interface d'Administration - Carte de Référence Rapide

## 🚀 Démarrage Rapide

### Installation (3 étapes)
```bash
# 1. Importer le schéma de base de données
mysql -u dns3_user -p dns3_db < database.sql

# 2. Créer un utilisateur admin
php scripts/create_admin.php --username admin --password 'admin123'

# 3. Accéder
http://your-domain/admin.php
```

> **Note** : Les fichiers de migration ont été supprimés. Pour les nouvelles installations, utilisez `database.sql` (ou `structure_ok_dns3_db.sql`).

---

## 🔑 Créer un admin (Méthode A)

### Méthode A — Créer un administrateur via script PHP (recommandée)

**Prérequis :**
- `config.php` configuré (credentials DB)
- PHP CLI disponible

**Commande CLI :**
```bash
php scripts/create_admin.php --username admin --password 'AdminPass123!'
```

**Mode interactif :**
```bash
php scripts/create_admin.php
# Le script vous demandera username, password
```

**Ce que fait le script :**
1. Crée un enregistrement dans `users` avec `password_hash(..., PASSWORD_DEFAULT)`
2. Si `roles` contient `name='admin'`, ajoute une entrée dans `user_roles`
3. Affiche un message de succès ou d'erreur

**Vérifications SQL :**
```sql
SELECT id, username, auth_method, is_active FROM users WHERE username = 'admin';
SELECT * FROM user_roles WHERE user_id = <id_utilisateur>;
```

**Équivalent API (si déjà connecté en admin) :**
```bash
curl -X POST 'http://domain/api/admin_api.php?action=create_user' \
  -H 'Content-Type: application/json' \
  -d '{
    "username": "admin",
    "email": "admin@example.local",
    "auth_method": "database",
    "password": "AdminPass123!",
    "role_ids": [1]
  }' \
  --cookie "PHPSESSID=your_session_id"
```

**⚠️ Sécurité :**
- Changez le mot de passe par défaut immédiatement
- Limitez l'accès au répertoire `scripts/` en production
- Voir `scripts/create_admin.php` pour options détaillées

**Alternative (Méthode B — SQL direct) :** Voir section [Emergency Procedures](#-emergency-procedures) pour création manuelle via SQL.

---

## 👥 Gestion des Utilisateurs

### Créer un Utilisateur (Auth Base de données)
```
Navigation: Admin → Utilisateurs → Créer un utilisateur
Champs:
  - Username: requis, unique
  - Email: requis, unique
  - Méthode d'auth: database
  - Mot de passe: requis (hashé avec bcrypt)
  - Statut: actif/inactif
  - Rôles: sélectionner un ou plusieurs
```

### Créer un Utilisateur (Auth AD/LDAP)
```
Navigation: Admin → Utilisateurs → Créer un utilisateur
Champs:
  - Username: requis, unique
  - Email: requis, unique
  - Méthode d'auth: ad OU ldap
  - Mot de passe: NON requis
  - Statut: actif/inactif
  - Rôles: sélectionner un ou plusieurs
```

### Modifier un Utilisateur
```
Navigation: Admin → Utilisateurs → Cliquer sur "Modifier"
Peut modifier:
  - Email
  - Mot de passe (optionnel, laisser vide pour conserver l'actuel)
  - Méthode d'auth
  - Statut
  - Rôles
```

### Désactiver un utilisateur (Supprimer)
```
Navigation: Admin → Utilisateurs → Click "Supprimer" (dans la liste ou dans le modal d'édition)

Comportement:
  - Le bouton "Supprimer" désactive le compte utilisateur (is_active = 0)
  - L'historique est conservé (pas de suppression en base)
  - L'utilisateur désactivé ne peut plus se connecter

Restrictions:
  - Impossible de désactiver son propre compte
  - Impossible de désactiver le dernier administrateur actif
  - Le bouton n'apparaît pas pour les utilisateurs déjà inactifs

Confirmation:
  - Une popup de confirmation s'affiche avant la désactivation
```

### Filtrer les Utilisateurs
```
Filtres disponibles:
  - Username (recherche texte)
  - Méthode d'auth (database/ad/ldap)
  - Statut (actif/inactif)
```

---

## 🔐 Gestion des Rôles

### Rôles Disponibles
| Rôle        | Description                                                        | Couleur Badge |
|-------------|-------------------------------------------------------------------|---------------|
| admin       | Accès complet à toutes les fonctionnalités                        | Rouge         |
| user        | Accès en lecture seule                                             | Bleu          |
| zone_editor | Peut voir/éditer les zones avec permissions ACL (pas d'accès admin) | Vert          |

### Visualiser les Rôles
```
Navigation: Admin → Rôles
Affiche: ID, Nom, Description, Date de création
```

---

## 🌐 Mappings AD/LDAP

### Créer un Mapping AD
```
Navigation: Admin → Mappings AD/LDAP → Créer un mapping

Exemple:
  Source: Active Directory
  DN/Group: CN=DNSAdmins,OU=Groups,DC=example,DC=com
  Rôle: admin
  Notes: Groupe administrateurs DNS - attribution automatique du rôle admin
```

### Créer un Mapping LDAP
```
Navigation: Admin → Mappings AD/LDAP → Créer un mapping

Exemple:
  Source: LDAP
  DN/Group: ou=IT,dc=example,dc=com
  Rôle: user
  Notes: Département IT - attribution automatique du rôle user
```

### Supprimer un Mapping
```
Navigation: Admin → Mappings AD/LDAP → Cliquer sur "Supprimer"
Requiert: Confirmation
```

---

## 🔒 Contrôle Authentification AD/LDAP par Mappings

### Flux de Connexion AD/LDAP

```
1. Bind LDAP réussi
        ↓
2. Vérification des mappings (auth_mappings)
        ↓
   Mapping trouvé ?
        ↓
   ✓ OUI → Création/activation compte + attribution rôles
   ✗ NON → Connexion refusée + désactivation compte existant
```

### Comportement Clé

| Situation | Résultat |
|-----------|----------|
| Utilisateur mappé, nouveau | Compte créé, activé, rôles assignés |
| Utilisateur mappé, existant actif | Rôles synchronisés |
| Utilisateur mappé, existant inactif | Compte réactivé, rôles synchronisés |
| Utilisateur non mappé, nouveau | Connexion refusée, pas de compte créé |
| Utilisateur non mappé, existant | Connexion refusée, compte désactivé |

### Vérifications Rapides

```sql
-- Vérifier si un utilisateur est activé
SELECT username, is_active, auth_method FROM users WHERE username = 'jdoe';

-- Lister les rôles d'un utilisateur
SELECT u.username, r.name as role
FROM users u
JOIN user_roles ur ON u.id = ur.user_id
JOIN roles r ON ur.role_id = r.id
WHERE u.username = 'jdoe';

-- Lister tous les mappings
SELECT source, dn_or_group, r.name as role
FROM auth_mappings am JOIN roles r ON am.role_id = r.id;
```

### Exemple : Créer un Mapping AD

```sql
INSERT INTO auth_mappings (source, dn_or_group, role_id, notes)
SELECT 'ad', 'CN=DNSAdmins,OU=Groups,DC=example,DC=com', r.id, 'Admins DNS'
FROM roles r WHERE r.name = 'admin';
```

### Test avec ldapsearch

```bash
# AD : Vérifier les groupes d'un utilisateur
ldapsearch -x -H ldap://ad.example.com -D "DOMAIN\\user" -W \
  -b "DC=example,DC=com" "(sAMAccountName=user)" memberOf

# LDAP : Vérifier le DN d'un utilisateur
ldapsearch -x -H ldap://ldap.example.com -D "cn=admin,dc=example,dc=com" -W \
  -b "dc=example,dc=com" "(uid=user)" dn
```

---

## 🔧 Utilisation de l'API

### Authentification
Tous les appels API requièrent:
- Session active (connecté)
- Rôle admin

### Points de Terminaison Courants

#### Lister les Utilisateurs
```bash
curl 'http://domain/api/admin_api.php?action=list_users' \
  --cookie "PHPSESSID=your_session_id"
```

#### Créer un Utilisateur
```bash
curl -X POST 'http://domain/api/admin_api.php?action=create_user' \
  -H 'Content-Type: application/json' \
  -d '{
    "username": "john.doe",
    "auth_method": "database",
    "password": "SecurePass123",
    "role_ids": [2]
  }' \
  --cookie "PHPSESSID=your_session_id"
```

#### Créer un Mapping
```bash
curl -X POST 'http://domain/api/admin_api.php?action=create_mapping' \
  -H 'Content-Type: application/json' \
  -d '{
    "source": "ad",
    "dn_or_group": "CN=DNSAdmins,OU=Groups,DC=example,DC=com",
    "role_id": 1,
    "notes": "DNS Admins"
  }' \
  --cookie "PHPSESSID=your_session_id"
```

---

## 🔒 Zone ACL (Contrôle d'Accès par Zone)

### Présentation
Le système ACL permet de définir des permissions d'accès spécifiques par fichier de zone pour les utilisateurs non-admin.

### Politique d'autorisation AD/LDAP
Les utilisateurs AD/LDAP ne sont autorisés à se connecter que s'ils :
- Correspondent à au moins un mapping `auth_mappings`, **OU**
- Apparaissent dans au moins une entrée ACL (par username, rôle ou groupe AD)

Si aucune condition n'est remplie : connexion refusée + compte désactivé.

### Permissions
| Niveau  | Description                         |
|---------|-------------------------------------|
| read    | Visualiser la zone                  |
| write   | Modifier la zone                    |
| admin   | Toutes les permissions pour la zone |

### Types de Sujets
| Type      | Exemple                                      |
|-----------|----------------------------------------------|
| user      | Username (ex: john.doe) - normalisé en minuscules |
| role      | Nom du rôle (ex: zone_editor)                |
| ad_group  | DN du groupe AD (ex: CN=DNS,OU=Groups,DC=...) |

**Note :** Le type `user` accepte un username même si l'utilisateur n'existe pas encore (pré-autorisation).

### Interface
```
Navigation: Fichiers de Zone → Modifier une zone → Onglet ACL

Actions disponibles:
- Visualiser les ACL existantes
- Ajouter une entrée ACL (utilisateur/rôle/groupe AD)
- Supprimer une entrée ACL
```

### API Endpoints

#### Lister les ACL d'une zone
```bash
curl 'http://domain/api/admin_api.php?action=list_acl&zone_id=1' \
  --cookie "PHPSESSID=your_session_id"
```

#### Créer une ACL
```bash
curl -X POST 'http://domain/api/admin_api.php?action=create_acl' \
  -H 'Content-Type: application/json' \
  -d '{
    "zone_id": 1,
    "subject_type": "user",
    "subject_identifier": "john.doe",
    "permission": "write"
  }' \
  --cookie "PHPSESSID=your_session_id"
```

#### Supprimer une ACL
```bash
curl -X POST 'http://domain/api/admin_api.php?action=delete_acl&id=1' \
  --cookie "PHPSESSID=your_session_id"
```

#### Créer un utilisateur externe (pré-création)
```bash
curl -X POST 'http://domain/api/admin_api.php?action=create_external_user' \
  -H 'Content-Type: application/json' \
  -d '{
    "username": "ext.user",
    "auth_method": "ad",
    "is_active": 0
  }' \
  --cookie "PHPSESSID=your_session_id"
```

### Rôle zone_editor
- Accès à `zone-files.php` sans être admin
- Voit uniquement les zones avec ACL configuré
- Pas d'accès à `admin.php`

### Installation du schéma
```bash
mysql -u dns3_user -p dns3_db < database.sql
```

---

## 🎨 Éléments d'Interface

### Couleurs des Badges
| Type        | Couleur | Exemple        |
|-------------|---------|----------------|
| admin role  | Rouge   | [admin]        |
| user role   | Bleu    | [user]         |
| zone_editor | Vert    | [zone_editor]  |
| Active      | Vert    | [Actif]        |
| Inactive    | Gris    | [Inactif]      |
| Database    | Teal    | [DB]           |
| AD          | Violet  | [AD]           |
| LDAP        | Orange  | [LDAP]         |

### Onglets
- **Utilisateurs** - Gestion des utilisateurs
- **Rôles** - Visualisation des rôles
- **Mappings AD/LDAP** - Configuration des mappings d'authentification

### Onglets du Modal d'Édition de Zone
- **Détails** - Propriétés de la zone
- **Éditeur** - Éditeur de contenu de zone
- **Includes** - Fichiers de zone inclus
- **ACL** - Listes de contrôle d'accès (admin uniquement)

---

## ⚠️ Problèmes Courants

### "L'onglet Admin n'est pas visible"
**Solution:**
```sql
-- Vérifier si l'utilisateur a le rôle admin
SELECT u.username, r.name 
FROM users u
JOIN user_roles ur ON u.id = ur.user_id
JOIN roles r ON ur.role_id = r.id
WHERE u.username = 'your_username';

-- Si manquant, assigner le rôle admin
INSERT INTO user_roles (user_id, role_id)
SELECT u.id, r.id FROM users u, roles r
WHERE u.username = 'your_username' AND r.name = 'admin';
```

### "Impossible de créer l'utilisateur - username existe"
**Solution:**
- Choisir un username différent
- Ou modifier l'utilisateur existant

### "Mot de passe requis pour l'auth database"
**Solution:**
- Pour auth_method='database', le mot de passe est requis
- Pour AD/LDAP, le mot de passe doit être vide

### "La création du mapping échoue"
**Solution:**
- Vérifier les doublons (même source+dn_or_group+rôle)
- Vérifier que le role_id existe
- S'assurer que le format du DN est correct

---

## 📊 Tables de Base de Données

### users
```
Colonnes: id, username, password, auth_method, created_at, 
          last_login, is_active
```

### roles
```
Colonnes: id, name, description, created_at
```

### user_roles
```
Colonnes: user_id, role_id, assigned_at
```

### auth_mappings
```
Colonnes: id, source, dn_or_group, role_id, created_by, 
          created_at, notes
```

---

## 🔍 Requêtes Utiles

### Lister tous les administrateurs
```sql
SELECT u.username 
FROM users u
JOIN user_roles ur ON u.id = ur.user_id
JOIN roles r ON ur.role_id = r.id
WHERE r.name = 'admin' AND u.is_active = 1;
```

### Compter les utilisateurs par méthode d'auth
```sql
SELECT auth_method, COUNT(*) as count
FROM users
GROUP BY auth_method;
```

### Lister tous les mappings
```sql
SELECT am.source, am.dn_or_group, r.name as role_name, am.notes
FROM auth_mappings am
JOIN roles r ON am.role_id = r.id
ORDER BY am.source, r.name;
```

### Trouver les utilisateurs sans rôles
```sql
SELECT u.id, u.username
FROM users u
LEFT JOIN user_roles ur ON u.id = ur.user_id
WHERE ur.role_id IS NULL;
```

---

## 📝 Bonnes Pratiques

### Politique de Mot de Passe
- Minimum 8 caractères
- Mélange de lettres, chiffres, caractères spéciaux
- Ne jamais partager les mots de passe
- Changer le mot de passe admin par défaut immédiatement

### Création d'Utilisateur
- Utiliser des usernames descriptifs (prenom.nom)
- Assigner les rôles minimaux requis
- Définir comme inactif pour les utilisateurs temporaires
- Documenter les utilisateurs AD/LDAP dans les notes

### Stratégie de Mapping
- Un mapping par groupe AD
- Documenter l'objectif dans le champ notes
- Réviser les mappings trimestriellement
- Tester avant le déploiement en production

### Sécurité
- Rotation régulière des mots de passe
- Surveiller l'activité des utilisateurs
- Réviser les utilisateurs admin mensuellement
- Sauvegarder avant les modifications en masse

---

## 🆘 Procédures d'Urgence

### Réinitialiser le Mot de Passe Admin
```bash
php scripts/create_admin.php --username admin --password 'NewSecurePass123'
```

### Créer Manuellement un Utilisateur Admin
```sql
-- Générer le hash en PHP d'abord:
-- php -r "echo password_hash('VotreMotDePasse', PASSWORD_DEFAULT);"

INSERT INTO users (username, password, auth_method, is_active)
VALUES ('admin', '$2y$10$...hash...', 'database', 1);

INSERT INTO user_roles (user_id, role_id)
SELECT u.id, r.id FROM users u, roles r
WHERE u.username = 'admin' AND r.name = 'admin';
```

### Désactiver l'Accès d'un Utilisateur
```sql
UPDATE users SET is_active = 0 WHERE username = 'username';
```

### Retirer les Droits Admin
```sql
DELETE FROM user_roles 
WHERE user_id = (SELECT id FROM users WHERE username = 'username')
AND role_id = (SELECT id FROM roles WHERE name = 'admin');
```

---

## 📞 Checklist de Support

Avant de demander de l'aide:
- [ ] Vérifier les logs d'erreur: `/var/log/php/error.log`
- [ ] Vérifier la connexion à la base de données
- [ ] Confirmer que `database.sql` a été importé correctement
- [ ] Vérifier que l'utilisateur a le rôle admin
- [ ] Vider le cache/cookies du navigateur
- [ ] Essayer un navigateur différent
- [ ] Consulter la documentation

---

## 🔗 Documentation Associée

- **Guide Complet:** `ADMIN_INTERFACE_GUIDE.md`
- **Détails Techniques:** `ADMIN_IMPLEMENTATION.md`
- **Aperçu de l'UI:** `ADMIN_UI_OVERVIEW.md`
- **Notes de Version:** `ADMIN_RELEASE_NOTES.md`

---

## 💡 Astuces et Conseils

### Raccourcis Clavier
- `ESC` - Fermer le modal
- `Entrée` - Soumettre le formulaire (quand focus dans un champ)
- `Tab` - Naviguer entre les champs du formulaire

### Performance
- Utiliser les filtres pour réduire l'ensemble de résultats
- Vider le cache après des modifications majeures
- Surveiller la taille de la base de données

### Workflow
1. Créer un utilisateur
2. Assigner un rôle de base (user)
3. Tester la connexion
4. Promouvoir en admin si nécessaire
5. Documenter dans les notes

---

**Version:** 1.0.0  
**Dernière mise à jour:** 2025-10-20  
**Des questions?** Consultez les fichiers de documentation complets.
