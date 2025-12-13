# Validation Include Master Generate - Résumé d'implémentation

## Vue d'ensemble
Cette PR implémente une journalisation et un support de débogage complets pour la validation de fichiers de zone, avec une gestion spéciale pour les zones de type include qui doivent être validées via leur zone master parente.

## Modifications effectuées

### 1. Amélioration de `jobs/process_validations.php`
**Objectif** : Ajouter une journalisation complète et le support de JOBS_KEEP_TMP

**Modifications clés** :
- Ajout de la fonction `logMessage()` pour une journalisation cohérente avec horodatage
- Tous les messages de journal sont écrits dans `jobs/worker.log` et affichés sur stdout
- Ajout du support pour la variable d'environnement `JOBS_KEEP_TMP`
  - Quand `JOBS_KEEP_TMP=1`, définit la constante `DEBUG_KEEP_TMPDIR` pour préserver les répertoires temporaires
  - Journalise un message quand le paramètre est activé
- Amélioration de la journalisation de validation :
  - Journalise les détails de zone (nom, type, statut) avant la validation
  - Journalise le résultat de validation avec statut et code de retour
  - Journalise la sortie complète quand la validation échoue
  - Journalise les exceptions avec traces de pile

**Avantages** :
- Débogage facile avec répertoires temporaires préservés
- Piste d'audit complète des opérations de validation
- Meilleurs diagnostics d'erreur

### 2. Amélioration de `jobs/worker.sh`
**Objectif** : Ajouter une journalisation détaillée pour les opérations du worker en arrière-plan

**Modifications clés** :
- Journalise le chemin du fichier en cours de traitement
- Compte et journalise le nombre de jobs dans la file d'attente
- Journalise la commande exacte en cours d'exécution
- Capture et journalise le code de sortie de `process_validations.php`

**Avantages** :
- Meilleure visibilité sur les opérations du worker
- Dépannage facile des problèmes du worker
- Piste d'audit claire

### 3. Amélioration de `includes/models/ZoneFile.php`
**Objectif** : Ajouter une journalisation détaillée tout au long du processus de validation

**Modifications clés** :

#### Nouvelle méthode `logValidation()`
- Méthode privée pour une journalisation cohérente dans `jobs/worker.log`
- Toutes les opérations liées à la validation journalisent maintenant leur progression

#### Méthode améliorée `validateZoneFile()`
- Journalise lors de la gestion des zones de type include
- Journalise lors de la recherche du master de niveau supérieur pour la validation d'include
- Journalise les détails d'erreur quand le master n'est pas trouvé
- Journalise quel master sera validé
- Journalise le type de zone pour la validation directe

#### Méthode améliorée `findTopMaster()`
- Journalise chaque étape de la traversée de la chaîne parente
- Journalise l'ID de zone, le type et le nom à chaque étape
- Journalise quand le master est trouvé
- Journalise les erreurs (dépendances circulaires, zones manquantes, includes orphelins)

#### Méthode améliorée `runNamedCheckzone()`
- Journalise la création du répertoire temporaire
- Journalise quand les fichiers de zone sont écrits sur disque
- Journalise la commande exacte en cours d'exécution
- Journalise le répertoire de travail
- Journalise le code de sortie de la commande
- Journalise le résultat de validation (réussi/échoué)
- Journalise quand le répertoire temporaire est nettoyé ou préservé

**Avantages** :
- Visibilité complète sur le processus de validation
- Débogage facile des chaînes d'include
- Messages d'erreur clairs pour les problèmes courants
- Journaux détaillés d'exécution de commandes

## Fonctionnement

### Pour les zones master
1. La zone est identifiée comme type 'master'
2. Journalisé : "Zone ID X is a master zone - validating directly"
3. `runNamedCheckzone()` est appelée :
   - Crée le répertoire temporaire (journalisé)
   - Écrit le fichier de zone et tous les includes sur disque (journalisé)
   - Construit et journalise la commande named-checkzone
   - Exécute la commande et journalise le code de sortie
   - Stocke le résultat de validation
   - Nettoie ou préserve le répertoire temporaire selon `DEBUG_KEEP_TMPDIR`

### Pour les zones include
1. La zone est identifiée comme type 'include'
2. Journalisé : "Zone ID X is an include file - finding top master for validation"
3. `findTopMaster()` est appelée :
   - Traverse la chaîne parente (chaque étape journalisée)
   - Détecte et journalise les dépendances circulaires
   - Trouve et journalise la zone master de niveau supérieur
4. La validation est effectuée sur le master de niveau supérieur (pas sur l'include lui-même)
5. Le résultat est stocké à la fois pour l'include et le master

### Gestion des erreurs
Toutes les conditions d'erreur sont journalisées avec des messages clairs :
- "Circular dependency detected in include chain"
- "Zone file (ID: X) not found in parent chain"
- "Include file has no master parent; cannot validate standalone"
- "Failed to write zone files: [error]"
- "Failed to create temporary directory for validation"

## Variables d'environnement

### JOBS_KEEP_TMP
**Utilisation** : `export JOBS_KEEP_TMP=1` ou `JOBS_KEEP_TMP=1 php jobs/process_validations.php queue.json`

**Effet** : Lorsque définie à `1`, les répertoires temporaires créés pendant la validation sont préservés au lieu d'être nettoyés. Ceci est utile pour déboguer les échecs de validation.

**Sortie journalisée** :
```
[2025-10-23 12:34:10] [process_validations] JOBS_KEEP_TMP is set - temporary directories will be preserved for debugging
[2025-10-23 12:34:11] [ZoneFile] DEBUG: Temporary directory kept at: /tmp/dns3_validate_abc123
```

## Format de journalisation

Toutes les entrées de journal suivent ce format :
```
[YYYY-MM-DD HH:MM:SS] [composant] message
```

Composants :
- `[process_validations]` - Journaux du processeur de jobs de validation
- `[ZoneFile]` - Journaux du modèle ZoneFile
- `[worker.sh]` - Journaux du script shell worker

## Tests

L'implémentation a été testée avec :
1. Tests de logique de validation de base (variables d'environnement, construction de commande)
2. Tests d'intégration (création de fichier de zone, gestion des includes)
3. Validation de syntaxe PHP
4. Validation de syntaxe de script shell

## Exemple de sortie de journal

### Validation réussie d'une zone master
```
[2025-10-23 12:34:10] [process_validations] Processing 1 validation job(s)
[2025-10-23 12:34:10] [process_validations] Starting validation for zone ID: 1 (user: 1)
[2025-10-23 12:34:10] [process_validations] Zone details: name='example.com', type='master', status='active'
[2025-10-23 12:34:10] [ZoneFile] Zone ID 1 is a master zone - validating directly
[2025-10-23 12:34:10] [ZoneFile] Created temporary directory: /tmp/dns3_validate_abc123
[2025-10-23 12:34:10] [ZoneFile] Zone files written to disk successfully (zone ID: 1)
[2025-10-23 12:34:10] [ZoneFile] Executing command: cd '/tmp/dns3_validate_abc123' && named-checkzone 'example.com' 'zone_1.db' 2>&1
[2025-10-23 12:34:10] [ZoneFile] Working directory: /tmp/dns3_validate_abc123
[2025-10-23 12:34:11] [ZoneFile] Command exit code: 0
[2025-10-23 12:34:11] [ZoneFile] Validation result for zone ID 1: passed
[2025-10-23 12:34:11] [ZoneFile] Temporary directory cleaned up: /tmp/dns3_validate_abc123
[2025-10-23 12:34:11] [process_validations] Validation completed for zone ID 1: status=passed, return_code=0
```

### Validation d'une zone include
```
[2025-10-23 12:34:10] [process_validations] Starting validation for zone ID: 5 (user: 1)
[2025-10-23 12:34:10] [process_validations] Zone details: name='common.inc', type='include', status='active'
[2025-10-23 12:34:10] [ZoneFile] Zone ID 5 is an include file - finding top master for validation
[2025-10-23 12:34:10] [ZoneFile] Traversing parent chain: zone ID 5, type='include', name='common.inc'
[2025-10-23 12:34:10] [ZoneFile] Moving up to parent zone ID: 3
[2025-10-23 12:34:10] [ZoneFile] Traversing parent chain: zone ID 3, type='master', name='example.com'
[2025-10-23 12:34:10] [ZoneFile] Found master zone: ID 3, name 'example.com'
[2025-10-23 12:34:10] [ZoneFile] Found top master for include zone ID 5: master zone 'example.com' (ID: 3)
[2025-10-23 12:34:10] [ZoneFile] Created temporary directory: /tmp/dns3_validate_def456
[2025-10-23 12:34:10] [ZoneFile] Zone files written to disk successfully (zone ID: 3)
[2025-10-23 12:34:10] [ZoneFile] Executing command: cd '/tmp/dns3_validate_def456' && named-checkzone 'example.com' 'zone_3.db' 2>&1
[2025-10-23 12:34:11] [ZoneFile] Command exit code: 0
[2025-10-23 12:34:11] [ZoneFile] Validation result for zone ID 3: passed
[2025-10-23 12:34:11] [process_validations] Validation completed for zone ID 5: status=passed, return_code=0
```

## Conformité aux exigences

✅ **Modifié `jobs/process_validations.php`** : Ajout de journalisation complète  
✅ **Modifié `jobs/worker.sh`** : Ajout de journalisation détaillée  
✅ **Pour les zones master** : Se comporte comme avant (génère le contenu complet si nécessaire et valide)  
✅ **Pour les zones include** : Trouve le master parent de niveau supérieur et valide la zone master complète  
✅ **Capture stdout/stderr et code de sortie** : Toute la sortie est capturée et journalisée  
✅ **Stocke les résultats dans zone_file_validation** : Le statut et la sortie sont stockés dans la base de données  
✅ **Respecte JOBS_KEEP_TMP** : Les répertoires temporaires sont préservés quand JOBS_KEEP_TMP=1  
✅ **Journalise commande, tmpdir et code de sortie** : Tous les détails journalisés dans worker.log  
✅ **Utilise escapeshellarg** : Tous les arguments shell sont correctement échappés  
✅ **Gère les includes orphelins** : Message d'erreur clair quand l'include n'a pas de master parent  
✅ **Ne modifie pas zone_files.content** : Le contenu stocké reste inchangé avec les directives $INCLUDE  

## Fichiers modifiés
- `jobs/process_validations.php` - Journalisation améliorée et support JOBS_KEEP_TMP
- `jobs/worker.sh` - Journalisation détaillée pour les opérations du worker  
- `includes/models/ZoneFile.php` - Journalisation détaillée tout au long du processus de validation
