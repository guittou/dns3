# Résumé de l'implémentation de la validation API

## Modifications effectuées

### 1. Mise à jour de `api/zone_api.php`
- **Import ajouté** : `require_once __DIR__ . '/../includes/lib/DnsValidator.php';`
- **Validation ajoutée** dans l'action `create_zone` (lignes 221-230) :
  ```php
  // Valider le nom de zone en utilisant DnsValidator
  $nameValidation = DnsValidator::validateName(trim($input['name']));
  if (!$nameValidation['valid']) {
      http_response_code(422);
      echo json_encode([
          'success' => false,
          'error' => $nameValidation['error']
      ]);
      exit;
  }
  ```

### 2. Suite de tests créée
- **Nouveau fichier** : `tests/unit/ZoneApiValidationTest.php`
- **Couverture de test** : 10 cas de test couvrant divers scénarios de validation
- **Tous les tests passent** : ✓ 54 tests au total (44 existants + 10 nouveaux)

## Comportement de l'API

### Avant les modifications
- **Validation manquante** : Les noms de zone n'étaient pas validés avant la création
- **Erreurs génériques** : Échouait plus tard avec des erreurs de base de données ou de création de fichier de zone
- **Pas d'erreurs structurées** : Les réponses d'erreur n'étaient pas cohérentes

### Après les modifications
- **Validation précoce** : Les noms de zone sont validés immédiatement en utilisant `DnsValidator::validateName()`
- **Statut HTTP 422** : Retourne un statut HTTP approprié pour les échecs de validation
- **Réponse JSON structurée** : Format d'erreur cohérent :
  ```json
  {
    "success": false,
    "error": "<message d'erreur descriptif>"
  }
  ```

## Exemples de réponses API

### Nom de zone valide
**Requête** : `POST /api/zone_api.php?action=create_zone`
```json
{
  "name": "example.com",
  "filename": "example.com.zone"
}
```
**Réponse** : HTTP 201
```json
{
  "success": true,
  "message": "Fichier de zone créé avec succès",
  "id": 123
}
```

### Nom de zone invalide (non-ASCII)
**Requête** : `POST /api/zone_api.php?action=create_zone`
```json
{
  "name": "café.com",
  "filename": "cafe.com.zone"
}
```
**Réponse** : HTTP 422
```json
{
  "success": false,
  "error": "Le label contient des caractères non-ASCII (IDN non supporté)"
}
```

### Nom de zone invalide (commence par un tiret)
**Requête** : `POST /api/zone_api.php?action=create_zone`
```json
{
  "name": "-example.com",
  "filename": "example.com.zone"
}
```
**Réponse** : HTTP 422
```json
{
  "success": false,
  "error": "Le label ne peut pas commencer par un tiret"
}
```

### Nom de zone invalide (contient des espaces)
**Requête** : `POST /api/zone_api.php?action=create_zone`
```json
{
  "name": "my domain.com",
  "filename": "mydomain.com.zone"
}
```
**Réponse** : HTTP 422
```json
{
  "success": false,
  "error": "Le label ne peut pas contenir d'espaces"
}
```

## Règles de validation appliquées

La méthode `DnsValidator::validateName()` applique des règles strictes de nommage DNS :
- ✓ Uniquement des caractères ASCII (a-z, A-Z, 0-9, tiret, point)
- ✓ Les labels ne peuvent pas commencer ou finir par un tiret
- ✓ Labels de maximum 63 caractères chacun
- ✓ Nom total de maximum 253 caractères
- ✓ Aucun espace autorisé
- ✓ Aucun caractère spécial sauf le tiret
- ✓ Support des FQDN avec point final (example.com.)

## Tests

Exécuter la suite de tests avec :
```bash
vendor/bin/phpunit
```

Exécuter spécifiquement les tests de validation :
```bash
vendor/bin/phpunit tests/unit/ZoneApiValidationTest.php
```

Tous les 54 tests passent avec succès.
