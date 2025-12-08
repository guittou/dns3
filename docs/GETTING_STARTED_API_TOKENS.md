# Démarrage Rapide avec l'Authentification par Tokens API

## Guide de Démarrage

Ce guide vous aidera à démarrer avec la fonctionnalité d'authentification par tokens API.

> **Note** : Ce guide suppose que vous partez d'une installation DNS3 à jour incluant le support des API tokens. La table `api_tokens` est déjà présente dans la base de données.

## Créer Votre Premier Token

### Option 1 : Via l'API Admin (Après Connexion)

1. Connectez-vous à l'interface web pour obtenir une session
2. Utilisez la session pour créer un token :

```bash
curl -X POST 'http://votre-serveur/dns3/api/admin_api.php?action=create_token' \
  -H 'Content-Type: application/json' \
  -H 'Cookie: PHPSESSID=votre-id-session' \
  -d '{
    "token_name": "Mon Premier Token",
    "expires_in_days": 365
  }'
```

La réponse contiendra votre token (conservez-le !) :
```json
{
  "success": true,
  "message": "Token créé avec succès...",
  "data": {
    "id": 1,
    "token": "a1b2c3d4e5f6...chaîne-64-caractères...",
    "prefix": "a1b2c3d4"
  }
}
```

### Méthode Alternative (DB)

> **⚠️ Avertissement** : Cette méthode est réservée aux situations d'urgence ou à la configuration initiale. En conditions normales, utilisez l'API Admin (Option 1 ci-dessus) pour créer des tokens.

Créez un script PHP simple :

```php
<?php
require_once 'config.php';
require_once 'includes/models/ApiToken.php';

// Trouvez votre ID utilisateur
$db = Database::getInstance()->getConnection();
$stmt = $db->prepare("SELECT id FROM users WHERE username = ?");
$stmt->execute(['votre-nom-utilisateur']);
$user = $stmt->fetch();

if ($user) {
    $apiToken = new ApiToken();
    $result = $apiToken->generate(
        $user['id'],           // user_id
        'Mon Premier Token',   // token_name
        $user['id'],           // created_by
        null                   // pas d'expiration
    );
    
    echo "Token créé avec succès !\n";
    echo "Token: " . $result['token'] . "\n";
    echo "Conservez ce token - vous ne le verrez plus !\n";
} else {
    echo "Utilisateur non trouvé\n";
}
?>
```

Exécutez-le une fois :
```bash
php create_token.php
```

## Utiliser Votre Token

Maintenant vous pouvez faire des requêtes API sans cookies de session :

```bash
# Définissez votre token
export API_TOKEN="votre-token-64-caractères"

# Lister les zones
curl -X GET 'http://votre-serveur/dns3/api/zone_api.php?action=list_zones' \
  -H "Authorization: Bearer $API_TOKEN"

# Obtenir les détails d'une zone
curl -X GET 'http://votre-serveur/dns3/api/zone_api.php?action=get_zone&id=1' \
  -H "Authorization: Bearer $API_TOKEN"

# Créer un enregistrement DNS
curl -X POST 'http://votre-serveur/dns3/api/dns_api.php?action=create' \
  -H "Authorization: Bearer $API_TOKEN" \
  -H 'Content-Type: application/json' \
  -d '{
    "zone_file_id": 1,
    "name": "test",
    "record_type": "A",
    "address_ipv4": "192.0.2.1",
    "ttl": 3600
  }'
```

## Tester Votre Configuration

Utilisez le script de test fourni :

```bash
export API_TOKEN="votre-token"
export API_URL="http://votre-serveur/dns3"
./test_api_token.sh
```

## Gestion des Tokens

### Lister vos tokens
```bash
curl -X GET 'http://votre-serveur/dns3/api/admin_api.php?action=list_tokens' \
  -H "Authorization: Bearer $API_TOKEN"
```

### Révoquer un token
```bash
curl -X POST 'http://votre-serveur/dns3/api/admin_api.php?action=revoke_token&id=1' \
  -H "Authorization: Bearer $API_TOKEN"
```

### Supprimer un token
```bash
curl -X POST 'http://votre-serveur/dns3/api/admin_api.php?action=delete_token&id=1' \
  -H "Authorization: Bearer $API_TOKEN"
```

## Utilisation dans des Scripts

### Exemple Python

```python
import requests

API_URL = "http://votre-serveur/dns3"
API_TOKEN = "votre-token-ici"

headers = {
    "Authorization": f"Bearer {API_TOKEN}",
    "Content-Type": "application/json"
}

# Lister les zones
response = requests.get(
    f"{API_URL}/api/zone_api.php?action=list_zones",
    headers=headers
)
zones = response.json()
print(zones)

# Créer un enregistrement DNS
record_data = {
    "zone_file_id": 1,
    "name": "api-test",
    "record_type": "A",
    "address_ipv4": "192.0.2.100",
    "ttl": 3600
}

response = requests.post(
    f"{API_URL}/api/dns_api.php?action=create",
    headers=headers,
    json=record_data
)
result = response.json()
print(result)
```

### Exemple de Script Bash

```bash
#!/bin/bash

API_URL="http://votre-serveur/dns3"
API_TOKEN="votre-token-ici"

# Lister les zones
curl -X GET "${API_URL}/api/zone_api.php?action=list_zones" \
  -H "Authorization: Bearer ${API_TOKEN}" \
  -s | jq '.data[] | {id, name, file_type}'

# Créer une zone
curl -X POST "${API_URL}/api/zone_api.php?action=create_zone" \
  -H "Authorization: Bearer ${API_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "example.com",
    "filename": "example.com.zone",
    "file_type": "master"
  }'
```

## Conseils de Sécurité

1. **Stockez les tokens de manière sécurisée** : Utilisez des variables d'environnement ou des coffres-forts sécurisés
2. **Ne committez jamais les tokens** : Ajoutez-les au `.gitignore` s'ils sont stockés dans des fichiers
3. **Utilisez HTTPS** : Utilisez toujours HTTPS en production
4. **Définissez une expiration** : Utilisez `expires_in_days` pour des tokens à durée limitée
5. **Rotation régulière** : Créez de nouveaux tokens et révoquez les anciens périodiquement
6. **Surveillez l'utilisation** : Vérifiez régulièrement les timestamps `last_used_at`

## Dépannage

### Le token ne fonctionne pas ?
- Vérifiez que la migration a été exécutée avec succès
- Vérifiez que le token est correct (64 caractères hexadécimaux)
- Assurez-vous que le compte utilisateur est actif
- Vérifiez que le token n'a pas expiré ou été révoqué

### Permission refusée ?
- Vérifiez que l'utilisateur a les rôles appropriés (admin pour les opérations d'écriture)
- Vérifiez les permissions ACL de la zone pour les utilisateurs non-admin

### Erreurs 401 ?
- Assurez-vous que l'en-tête `Authorization` est correctement formaté
- Vérifiez les fautes de frappe dans le token
- Vérifiez que le token existe dans la base de données

## Plus d'Informations

Consultez la documentation complète dans [api_token_authentication.md](api_token_authentication.md) pour :
- Documentation détaillée des endpoints API
- Exemples complets pour toutes les opérations
- Bonnes pratiques de sécurité
- Modèles d'utilisation avancés
