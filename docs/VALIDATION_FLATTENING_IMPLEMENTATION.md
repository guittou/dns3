# Implémentation de l'aplatissement pour la validation

## Vue d'ensemble

Cette implémentation résout le problème où la validation de zone échoue lorsque les directives `$INCLUDE` référencent des fichiers non présents sur disque. La solution génère un fichier de zone aplati unique contenant tous les enregistrements master et include combinés à des fins de validation, tout en gardant le contenu de la base de données inchangé.

## Modifications effectuées

### 1. Migration de base de données (012_add_validation_command_fields.sql)

Ajout de deux nouvelles colonnes à la table `zone_file_validation` :
- `command` (TEXT) : Stocke la commande named-checkzone exacte exécutée
- `return_code` (INT) : Stocke le code de sortie de la commande de validation

Ces champs fournissent de meilleures capacités de débogage et d'audit.

### 2. Modèle ZoneFile (includes/models/ZoneFile.php)

#### Nouvelle méthode : `generateFlatZone()`

```php
private function generateFlatZone($masterId, &$visited = [])
```

Cette méthode :
- Prend un ID de zone master et génère un fichier de zone aplati
- Concatène récursivement le contenu master avec tous les contenus d'inclusion dans l'ordre
- Supprime les directives `$INCLUDE` du contenu (puisque nous inlinons)
- Utilise un tableau `$visited` pour éviter les dépendances d'inclusion circulaires
- Maintient l'ordre correct basé sur la colonne `position` dans `zone_file_includes`

#### Méthode mise à jour : `runNamedCheckzone()`

Changement de l'écriture de plusieurs fichiers sur disque à l'écriture d'un seul fichier aplati :

**Avant :**
- Écrivait le fichier de zone master avec les directives `$INCLUDE`
- Écrivait récursivement tous les fichiers include sur disque dans une structure de répertoire appropriée
- Exécutait named-checkzone sur le fichier master (qui suivait alors les directives `$INCLUDE`)

**Après :**
- Génère le contenu aplati en utilisant `generateFlatZone()`
- Écrit un seul fichier de zone aplati dans le répertoire temporaire
- Exécute named-checkzone sur le fichier aplati
- Capture et stocke la commande et le code de sortie
- Tronque la sortie si elle dépasse 5000 caractères
- Respecte la variable d'environnement `JOBS_KEEP_TMP=1` pour le débogage

#### Méthode mise à jour : `storeValidationResult()`

Ajout de deux paramètres optionnels :
- `$command` : La commande exécutée
- `$returnCode` : Le code de sortie

Ceux-ci sont stockés dans la base de données à des fins d'audit et de débogage.

#### Méthode mise à jour : `propagateValidationToIncludes()`

Mise à jour pour transmettre command et return_code aux includes enfants lors de la propagation des résultats de validation.

## Fonctionnement

### Pour les zones master

1. L'utilisateur crée/met à jour une zone master
2. La validation est déclenchée (synchrone ou asynchrone)
3. `generateFlatZone()` est appelée pour créer le contenu aplati
4. Un fichier de zone unique est écrit dans le répertoire temporaire
5. `named-checkzone` est exécuté sur le fichier aplati
6. Les résultats (status, output, command, return_code) sont stockés
7. Les résultats sont propagés à tous les includes enfants
8. Le répertoire temporaire est nettoyé (sauf si `JOBS_KEEP_TMP=1`)

### Pour les zones include

1. L'utilisateur crée/met à jour une zone include
2. La validation est déclenchée (synchrone ou asynchrone)
3. `findTopMaster()` traverse la chaîne parente pour trouver le master de niveau supérieur
4. La validation s'exécute sur le master de niveau supérieur (comme ci-dessus)
5. Les résultats sont stockés pour les zones master et include

## Détection de cycles

L'implémentation empêche les dépendances circulaires à deux endroits :

1. **`generateFlatZone()`** : Utilise un tableau `$visited` pour suivre les IDs de zone visités
2. **`findTopMaster()`** : Utilise un tableau `$visited` pour détecter les cycles dans la chaîne parente
3. **`propagateValidationToIncludes()`** : Utilise BFS avec suivi des visites

## Débogage

Définissez la variable d'environnement `JOBS_KEEP_TMP=1` pour préserver les répertoires temporaires :

```bash
JOBS_KEEP_TMP=1 php jobs/process_validations.php jobs/validation_queue.json
```

Le journal du worker (`jobs/worker.log`) inclut maintenant :
- Chemin du répertoire temporaire
- Commande exécutée
- Code de sortie
- Taille du contenu aplati généré

## Contenu de la base de données inchangé

Important : La colonne `zone_files.content` reste inchangée. Elle contient toujours les directives `$INCLUDE` telles que stockées par les utilisateurs. L'aplatissement se produit uniquement pendant la validation et n'est pas persisté.

## Tests

Pour tester l'implémentation :

1. Créer une zone master avec un enregistrement SOA
2. Créer une ou plusieurs zones include avec des enregistrements A
3. Assigner les includes au master via la table `zone_file_includes`
4. Déclencher la validation sur master ou include
5. Vérifier la table `zone_file_validation` pour les résultats
6. Vérifier que les champs command et return_code sont remplis

## Exemple

Contenu de la zone master (stocké dans la BD) :
```
$ORIGIN example.com.
$TTL 3600
@   IN  SOA ns1.example.com. admin.example.com. (2024010101 3600 1800 604800 86400)
$INCLUDE "includes/hosts.inc"
```

Contenu de la zone include (stocké dans la BD) :
```
host1   IN  A   192.168.1.1
host2   IN  A   192.168.1.2
```

Contenu aplati (utilisé pour la validation, NON stocké) :
```
$ORIGIN example.com.
$TTL 3600
@   IN  SOA ns1.example.com. admin.example.com. (2024010101 3600 1800 604800 86400)

; BEGIN INCLUDE: hosts (hosts.inc)
host1   IN  A   192.168.1.1
host2   IN  A   192.168.1.2
; END INCLUDE: hosts

```

## Migration

Le schéma de base de données est maintenant disponible dans `database.sql`. Importez-le pour les nouvelles installations :

```sql
mysql dns3_db < database.sql
```

> **Note** : Les fichiers de migration ont été supprimés.
