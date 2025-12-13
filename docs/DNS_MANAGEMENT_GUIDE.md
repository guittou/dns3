# Fonctionnalité de Gestion DNS - Guide d'Installation et de Test

Ce document fournit les instructions pour installer et tester la fonctionnalité de gestion DNS qui a été ajoutée à l'application DNS3.

## Vue d'ensemble

La fonctionnalité de gestion DNS fournit:
- Opérations CRUD complètes pour les enregistrements DNS
- Suivi automatique de l'historique pour tous les changements
- Listes de Contrôle d'Accès (ACL) avec historique
- Contrôle d'accès basé sur les rôles (Admin/Utilisateur)
- API REST pour la gestion des enregistrements DNS
- Interface moderne pour gérer les enregistrements DNS

## Installation

### 1. Initialiser le Schéma de Base de Données

Pour les nouvelles installations, importer le schéma complet:

```bash
mysql -u dns3_user -p dns3_db < database.sql
```

> **Note** : Les fichiers de migration ont été supprimés. Pour les nouvelles installations, utilisez `database.sql` (ou `structure_ok_dns3_db.sql`).

Cela créera les tables suivantes:
- `roles` - Rôles utilisateurs (admin, user)
- `user_roles` - Affectations utilisateur-rôle
- `dns_records` - Stockage des enregistrements DNS
- `dns_record_history` - Historique des modifications des enregistrements DNS
- `acl_entries` - Entrées de contrôle d'accès
- `acl_history` - Historique des modifications ACL

### 2. Vérifier l'Utilisateur Admin

La migration attribue automatiquement le rôle admin à l'utilisateur admin par défaut (ID=1). 

Pour vérifier, se connecter avec:
- **Nom d'utilisateur**: `admin`
- **Mot de passe**: `admin123`

**Important**: Changer le mot de passe par défaut immédiatement après la première connexion!

### 3. Configurer l'Application

Aucune configuration supplémentaire n'est nécessaire. La fonctionnalité utilise la connexion à la base de données existante de `config.php`.

## Tester l'API

### Prérequis
- L'utilisateur doit être connecté (tous les endpoints requièrent l'authentification)
- Les privilèges admin sont requis pour les opérations create, update et set_status

### 1. Lister les Enregistrements DNS

```bash
# En tant qu'utilisateur authentifié
curl -b cookies.txt 'http://localhost:8000/api/dns_api.php?action=list'

# Avec filtres
curl -b cookies.txt 'http://localhost:8000/api/dns_api.php?action=list&name=example&type=A&status=active'
```

Réponse attendue:
```json
{
  "success": true,
  "data": [],
  "count": 0
}
```

### 2. Créer un Enregistrement DNS (Admin Uniquement)

```bash
# Sauvegarder la session d'abord
curl -c cookies.txt -X POST http://localhost:8000/login.php \
  -d "username=admin&password=admin123&auth_method=database"

# Créer un enregistrement A
curl -b cookies.txt -X POST 'http://localhost:8000/api/dns_api.php?action=create' \
  -H 'Content-Type: application/json' \
  -d '{
    "record_type": "A",
    "name": "example.com",
    "address_ipv4": "192.168.1.1",
    "ttl": 3600
  }'

# Ou utiliser l'alias value pour la rétrocompatibilité
curl -b cookies.txt -X POST 'http://localhost:8000/api/dns_api.php?action=create' \
  -H 'Content-Type: application/json' \
  -d '{
    "record_type": "A",
    "name": "example.com",
    "value": "192.168.1.1",
    "ttl": 3600
  }'

# Créer un enregistrement CNAME
curl -b cookies.txt -X POST 'http://localhost:8000/api/dns_api.php?action=create' \
  -H 'Content-Type: application/json' \
  -d '{
    "record_type": "CNAME",
    "name": "www.example.com",
    "cname_target": "example.com",
    "ttl": 3600
  }'

# Créer un enregistrement TXT
curl -b cookies.txt -X POST 'http://localhost:8000/api/dns_api.php?action=create' \
  -H 'Content-Type: application/json' \
  -d '{
    "record_type": "TXT",
    "name": "example.com",
    "txt": "v=spf1 include:_spf.example.com ~all",
    "ttl": 3600
  }'
```

Réponse attendue:
```json
{
  "success": true,
  "message": "DNS record created successfully",
  "id": 1
}
```

### 3. Obtenir un Enregistrement Spécifique

```bash
curl -b cookies.txt 'http://localhost:8000/api/dns_api.php?action=get&id=1'
```

La réponse attendue inclut les données de l'enregistrement et l'historique:
```json
{
  "success": true,
  "data": {
    "id": "1",
    "record_type": "A",
    "name": "example.com",
    "value": "192.168.1.1",
    "ttl": "3600",
    "status": "active",
    ...
  },
  "history": [...]
}
```

### 4. Mettre à Jour un Enregistrement DNS (Admin Uniquement)

```bash
curl -b cookies.txt -X POST 'http://localhost:8000/api/dns_api.php?action=update&id=1' \
  -H 'Content-Type: application/json' \
  -d '{
    "address_ipv4": "192.168.1.2",
    "ttl": 7200
  }'
```

Réponse attendue:
```json
{
  "success": true,
  "message": "DNS record updated successfully"
}
```

### 5. Changer le Statut d'un Enregistrement (Admin Uniquement)

```bash
# Supprimer doucement un enregistrement
curl -b cookies.txt 'http://localhost:8000/api/dns_api.php?action=set_status&id=1&status=deleted'

# Restaurer un enregistrement supprimé
curl -b cookies.txt 'http://localhost:8000/api/dns_api.php?action=set_status&id=1&status=active'
```

Réponse attendue:
```json
{
  "success": true,
  "message": "DNS record status changed to deleted"
}
```

## Tester l'Interface Utilisateur

### 1. Accéder à la Page de Gestion DNS

1. Naviguer vers `http://localhost:8000/login.php`
2. Se connecter en tant qu'admin (nom d'utilisateur: `admin`, mot de passe: `admin123`)
3. Cliquer sur l'onglet "DNS" dans le menu de navigation
4. Vous devriez voir l'interface de gestion DNS

### 2. Fonctionnalités de l'Interface à Tester

#### Créer un Enregistrement
1. Cliquer sur le bouton "+ Créer un enregistrement"
2. Remplir le formulaire:
   - Type: Sélectionner le type d'enregistrement (A, AAAA, CNAME, etc.)
   - Nom: Entrer le nom de domaine (ex: "test.example.com")
   - Valeur: Entrer la valeur (ex: "192.168.1.10")
   - TTL: Entrer le TTL en secondes (par défaut: 3600)
   - Priorité: Optionnel pour les enregistrements MX/SRV
3. Cliquer sur "Enregistrer"
4. Vérifier que l'enregistrement apparaît dans le tableau

#### Rechercher et Filtrer
1. Utiliser la boîte de recherche pour filtrer par nom
2. Utiliser le menu déroulant de type pour filtrer par type d'enregistrement
3. Utiliser le menu déroulant de statut pour filtrer par statut
4. Vérifier que le tableau se met à jour en temps réel

#### Modifier un Enregistrement
1. Cliquer sur le bouton "Modifier" sur n'importe quel enregistrement
2. Mettre à jour les champs
3. Cliquer sur "Enregistrer"
4. Vérifier que les modifications sont reflétées dans le tableau

#### Changer le Statut
1. Cliquer sur "Supprimer" pour supprimer doucement un enregistrement
2. Vérifier que le badge de statut change en "deleted"
3. Utiliser le filtre de statut pour afficher les enregistrements supprimés
4. Cliquer sur "Restaurer" pour restaurer l'enregistrement
5. Vérifier que le badge de statut revient à "active"

#### Supprimer un Enregistrement
1. Cliquer sur le bouton "Supprimer"
2. Confirmer la suppression
3. Vérifier que l'enregistrement est supprimé doucement (status = deleted)

## Vérifier le Suivi de l'Historique

Tous les changements sont automatiquement suivis dans les tables d'historique. Pour vérifier:

```sql
-- Voir l'historique des enregistrements DNS
SELECT * FROM dns_record_history ORDER BY changed_at DESC;

-- Voir l'historique ACL (si des ACL ont été créées)
SELECT * FROM acl_history ORDER BY changed_at DESC;
```

## Notes de Sécurité

1. **Authentification Requise**: Tous les endpoints de l'API requièrent l'authentification utilisateur
2. **Privilèges Admin**: Les opérations de création, mise à jour et changement de statut requièrent le rôle admin
3. **Pas de Suppression Physique**: Les enregistrements ne sont jamais supprimés physiquement, seulement supprimés doucement (status = 'deleted')
4. **Piste d'Audit**: Tous les changements sont enregistrés dans les tables d'historique avec l'utilisateur et l'horodatage
5. **Validation des Entrées**: L'API valide toutes les entrées avant traitement
6. **Champs Gérés par le Serveur**: Le champ `last_seen` est géré exclusivement par le serveur et ne peut pas être défini par les clients. Toute tentative de le définir via l'API sera silencieusement ignorée.
7. **Restrictions de Type**: Seuls les types d'enregistrements A, AAAA, CNAME, PTR et TXT sont supportés. Les tentatives de créer d'autres types retourneront une erreur 400.

## Dépannage

### Erreur "Authentication required"
- S'assurer d'être connecté avant de faire des appels API
- Vérifier que les cookies de session sont envoyés avec les requêtes

### Erreur "Admin privileges required"
- Vérifier que l'utilisateur a le rôle admin assigné
- Vérifier la table `user_roles` pour l'affectation des rôles

### Erreur "Table doesn't exist"
- S'assurer que le SQL de migration a été appliqué
- Vérifier les paramètres de connexion à la base de données dans `config.php`

### L'interface ne charge pas les enregistrements
- Vérifier la console du navigateur pour les erreurs JavaScript
- Vérifier que l'endpoint de l'API est accessible
- Vérifier l'onglet réseau pour les requêtes échouées

## Schéma de Base de Données

### Tables Créées

1. **roles**: Rôles utilisateurs (admin, user)
2. **user_roles**: Table de jonction pour les affectations utilisateur-rôle
3. **dns_records**: Table principale des enregistrements DNS
4. **dns_record_history**: Piste d'audit pour les enregistrements DNS
5. **acl_entries**: Entrées de contrôle d'accès
6. **acl_history**: Piste d'audit pour les changements ACL

### Données par Défaut

- Deux rôles: `admin` et `user`
- Le rôle admin est automatiquement assigné à l'utilisateur ID 1 (utilisateur admin par défaut)

## Référence de l'API

### Points de Terminaison

| Méthode | Endpoint | Auth | Description |
|---------|----------|------|-------------|
| GET | `/api/dns_api.php?action=list` | Utilisateur | Lister les enregistrements DNS |
| GET | `/api/dns_api.php?action=get&id=X` | Utilisateur | Obtenir un enregistrement spécifique |
| POST | `/api/dns_api.php?action=create` | Admin | Créer un nouvel enregistrement |
| POST | `/api/dns_api.php?action=update&id=X` | Admin | Mettre à jour un enregistrement |
| GET | `/api/dns_api.php?action=set_status&id=X&status=Y` | Admin | Changer le statut |

### Types d'Enregistrements

Le système de gestion DNS supporte les types d'enregistrements suivants:

- **A** - Adresse IPv4 (utilise le champ `address_ipv4`)
- **AAAA** - Adresse IPv6 (utilise le champ `address_ipv6`)
- **CNAME** - Nom canonique (utilise le champ `cname_target`)
- **PTR** - Pointeur/DNS inverse (utilise le champ `ptrdname`, nécessite un nom DNS inverse)
- **TXT** - Enregistrement texte (utilise le champ `txt`)

**Note**: Les autres types d'enregistrements (MX, NS, SOA, SRV) ne sont pas supportés dans cette version.

### Champs Dédiés

Chaque type d'enregistrement utilise maintenant un champ dédié au lieu du champ générique `value`:

- **Enregistrements A**: `address_ipv4` - Adresse IPv4 (ex: "192.168.1.1")
- **Enregistrements AAAA**: `address_ipv6` - Adresse IPv6 (ex: "2001:0db8:85a3:0000:0000:8a2e:0370:7334")
- **Enregistrements CNAME**: `cname_target` - Nom d'hôte cible (ex: "target.example.com")
- **Enregistrements PTR**: `ptrdname` - Nom DNS inverse (ex: "1.1.168.192.in-addr.arpa")
- **Enregistrements TXT**: `txt` - Contenu texte (n'importe quel texte)

Pour la rétrocompatibilité, l'API continue d'accepter `value` comme alias pour le champ dédié.
Le champ `value` dans la base de données est conservé temporairement pour la capacité de rollback.

### Valeurs de Statut

- `active` - L'enregistrement est actif et en utilisation
- `deleted` - L'enregistrement est supprimé doucement (affiché uniquement lors du filtrage par statut supprimé)

## Prochaines Étapes

1. Tester tous les endpoints de l'API avec différents rôles utilisateurs
2. Vérifier le suivi de l'historique pour toutes les opérations
3. Tester la réactivité de l'interface sur les appareils mobiles
4. Configurer les ACL pour un contrôle d'accès à granularité fine
5. Considérer l'implémentation d'opérations en masse
6. Ajouter une fonctionnalité d'export/import pour les enregistrements DNS

## Support

Pour les problèmes ou questions, veuillez ouvrir une issue sur le dépôt GitHub.
