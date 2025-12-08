# Authentification par Tokens API

Ce document décrit comment utiliser les tokens API pour l'authentification avec les endpoints API de dns3.

## Vue d'ensemble

L'application dns3 supporte deux méthodes d'authentification :

1. **Authentification par session** (par défaut) : Utilise des cookies de session PHP, adaptée aux clients basés sur navigateur
2. **Authentification par token Bearer** (nouveau) : Utilise des tokens API dans l'en-tête `Authorization`, adaptée aux scripts automatisés et clients non-navigateur

L'authentification par tokens API est complètement optionnelle et fonctionne en parallèle de l'authentification par session existante sans casser la rétrocompatibilité.

## Fonctionnalités

- **Sécurisé** : Les tokens sont hachés avec SHA-256 avant stockage
- **Longue durée** : Les tokens peuvent être configurés pour ne jamais expirer ou avoir une expiration personnalisée
- **Révocable** : Les tokens peuvent être révoqués sans affecter les autres tokens
- **Associé à l'utilisateur** : Chaque token est associé à un utilisateur et hérite de ses permissions
- **Traçable** : L'horodatage de dernière utilisation est enregistré pour chaque token

## Création de Tokens API

### Via l'API Admin (Recommandé)

1. D'abord, authentifiez-vous avec des cookies de session (connexion via l'interface web)

2. Créez un token :
```bash
curl -X POST 'http://votre-serveur/dns3/api/admin_api.php?action=create_token' \
  -H 'Content-Type: application/json' \
  -H 'Cookie: PHPSESSID=votre-id-session' \
  -d '{
    "token_name": "Mon Token d'Automatisation",
    "expires_in_days": 365
  }'
```

Réponse :
```json
{
  "success": true,
  "message": "Token créé avec succès. Conservez-le en lieu sûr, il ne sera plus visible.",
  "data": {
    "id": 1,
    "token": "a1b2c3d4e5f6...chaîne-hexadécimale-64-caractères...",
    "prefix": "a1b2c3d4"
  }
}
```

**IMPORTANT** : Enregistrez le token immédiatement ! Il ne sera plus jamais affiché.

### Via Accès Direct à la Base de Données

Alternativement, pour la configuration initiale, vous pouvez créer un token directement :

```php
<?php
require_once 'includes/models/ApiToken.php';
$apiToken = new ApiToken();

$result = $apiToken->generate(
    $userId,           // ID utilisateur de la table users
    'Mon Token',       // Nom lisible
    $createdBy,        // ID utilisateur qui l'a créé
    365                // Expire dans 365 jours (ou null pour pas d'expiration)
);

echo "Token: " . $result['token'] . "\n";
echo "ID: " . $result['id'] . "\n";
?>
```

## Utilisation des Tokens API

Une fois que vous avez un token, incluez-le dans l'en-tête `Authorization` avec le schéma `Bearer` :

```bash
curl -X GET 'http://votre-serveur/dns3/api/zone_api.php?action=list_zones' \
  -H 'Authorization: Bearer a1b2c3d4e5f6...votre-token...'
```

### Exemples

#### Lister les zones
```bash
curl -X GET 'http://votre-serveur/dns3/api/zone_api.php?action=list_zones' \
  -H 'Authorization: Bearer VOTRE_TOKEN'
```

#### Obtenir une zone spécifique
```bash
curl -X GET 'http://votre-serveur/dns3/api/zone_api.php?action=get_zone&id=1' \
  -H 'Authorization: Bearer VOTRE_TOKEN'
```

#### Créer une zone (admin uniquement)
```bash
curl -X POST 'http://votre-serveur/dns3/api/zone_api.php?action=create_zone' \
  -H 'Authorization: Bearer VOTRE_TOKEN' \
  -H 'Content-Type: application/json' \
  -d '{
    "name": "example.com",
    "filename": "example.com.zone",
    "file_type": "master"
  }'
```

#### Lister les enregistrements DNS
```bash
curl -X GET 'http://votre-serveur/dns3/api/dns_api.php?action=list' \
  -H 'Authorization: Bearer VOTRE_TOKEN'
```

#### Créer un enregistrement DNS
```bash
curl -X POST 'http://votre-serveur/dns3/api/dns_api.php?action=create' \
  -H 'Authorization: Bearer VOTRE_TOKEN' \
  -H 'Content-Type: application/json' \
  -d '{
    "zone_file_id": 1,
    "name": "www",
    "record_type": "A",
    "address_ipv4": "192.0.2.1",
    "ttl": 3600
  }'
```

## Gestion des Tokens

### Lister vos tokens
```bash
curl -X GET 'http://votre-serveur/dns3/api/admin_api.php?action=list_tokens' \
  -H 'Authorization: Bearer VOTRE_TOKEN'
```

### Lister les tokens d'un utilisateur spécifique (admin uniquement)
```bash
curl -X GET 'http://votre-serveur/dns3/api/admin_api.php?action=list_tokens&user_id=2' \
  -H 'Authorization: Bearer VOTRE_TOKEN'
```

### Révoquer un token
```bash
curl -X POST 'http://votre-serveur/dns3/api/admin_api.php?action=revoke_token&id=1' \
  -H 'Authorization: Bearer VOTRE_TOKEN'
```

### Supprimer un token définitivement
```bash
curl -X POST 'http://votre-serveur/dns3/api/admin_api.php?action=delete_token&id=1' \
  -H 'Authorization: Bearer VOTRE_TOKEN'
```

## Bonnes Pratiques de Sécurité

1. **Traitez les tokens comme des mots de passe** : Ne les committez jamais dans un contrôle de version et ne les partagez pas en clair
2. **Utilisez des variables d'environnement** : Stockez les tokens dans des variables d'environnement, pas dans le code
3. **Définissez une expiration** : Utilisez le paramètre `expires_in_days` pour des tokens à durée limitée
4. **Révoquez les tokens inutilisés** : Auditez et révoquez régulièrement les tokens qui ne sont plus nécessaires
5. **Utilisez HTTPS** : Utilisez toujours HTTPS en production pour protéger les tokens en transit
6. **Limitez la portée des tokens** : Créez des tokens séparés pour différentes applications/objectifs
7. **Rotation des tokens** : Générez périodiquement de nouveaux tokens et révoquez les anciens

## Stockage des Tokens

Les tokens sont stockés dans la table `api_tokens` avec les informations suivantes :

- `token_hash` : Hash SHA-256 du token (jamais le token en clair)
- `token_prefix` : Les 8 premiers caractères pour l'identification
- `user_id` : ID utilisateur associé
- `token_name` : Nom lisible
- `last_used_at` : Horodatage de dernière utilisation (mis à jour à chaque authentification réussie)
- `expires_at` : Date d'expiration (NULL = pas d'expiration)
- `revoked_at` : Horodatage de révocation (NULL = actif)

## Dépannage

### Erreur "Authentication required"
- Vérifiez que le token est correct et n'a pas expiré
- Vérifiez que l'en-tête `Authorization` est correctement formaté : `Authorization: Bearer VOTRE_TOKEN`
- Assurez-vous que le compte utilisateur associé au token est actif

### Erreur "Admin privileges required"
- L'endpoint nécessite des privilèges admin
- Vérifiez que l'utilisateur associé au token a le rôle `admin`

### Token ne fonctionne pas après création
- Assurez-vous d'utiliser le token complet de 64 caractères de la réponse de création
- Vérifiez que le token n'a pas été révoqué
- Vérifiez que le token n'a pas expiré

## Migration

Pour activer l'authentification par tokens API dans une installation existante :

1. Exécutez la migration de base de données :
```bash
mysql -u root -p dns3_db < migrations/20251208_add_api_tokens_table.sql
```

2. Aucun changement de code requis - la fonctionnalité est automatiquement disponible

3. Créez votre premier token en utilisant l'API Admin ou l'accès direct à la base de données

## Compatibilité

- L'authentification par tokens API est entièrement compatible avec l'authentification par session existante
- Les scripts existants utilisant des cookies de session continueront à fonctionner sans modification
- L'API vérifie d'abord les tokens Bearer, puis revient à l'authentification par session
- Aucun changement cassant pour les endpoints API existants
