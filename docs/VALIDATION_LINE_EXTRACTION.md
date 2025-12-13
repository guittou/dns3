# Validation de fichier de zone - Extraction du contexte de ligne

## Vue d'ensemble

Cette fonctionnalité améliore la sortie de validation de fichier de zone en extrayant et affichant automatiquement les lignes exactes qui ont causé des erreurs de validation lorsque `named-checkzone` signale des problèmes.

## Énoncé du problème

Lorsque `named-checkzone` valide des fichiers de zone, il rapporte les erreurs au format :
```
filename:LINE: message
```

Par exemple :
```
zone_1.db:13: ns1.example.com: bad owner name (check-names)
```

Auparavant, les utilisateurs voyaient ces messages d'erreur mais ne pouvaient pas facilement localiser les lignes problématiques parce que :
1. La validation s'exécute sur des fichiers temporaires inlinés (avec les includes développés)
2. Les fichiers temporaires sont supprimés après validation
3. Les numéros de ligne peuvent ne pas correspondre au fichier de zone original si des includes sont utilisés

## Solution

Le système de validation maintenant automatiquement :
1. **Analyse les messages d'erreur** - Détecte les lignes correspondant au motif `filename:line: message`
2. **Résout les chemins de fichiers** - Localise les fichiers temporaires dans le répertoire de validation
3. **Extrait le contexte de ligne** - Obtient la ligne problématique plus 2 lignes avant et après
4. **Formate le contexte** - Affiche les numéros de ligne avec un marqueur `>` pour la ligne d'erreur
5. **Ajoute à la sortie** - Ajoute le contexte extrait aux résultats de validation stockés dans la base de données

## Exemple de sortie

### Avant (erreur originale seulement) :
```
zone_1.db:13: bad..owner: bad owner name (check-names)
zone example.com/IN: has 1 errors
```

### Après (avec contexte extrait) :
```
zone_1.db:13: bad..owner: bad owner name (check-names)
zone example.com/IN: has 1 errors

=== EXTRACTED LINES FROM INLINED FILE(S) ===

File: zone_1.db, Line: 13
Message: bad..owner: bad owner name (check-names)
    11: ns1     IN      A       192.0.2.2
    12: ns2     IN      A       192.0.2.3
>   13: bad..owner      IN      A       192.0.2.4
    14: www     IN      A       192.0.2.5
    15: mail    IN      A       192.0.2.6

=== END OF EXTRACTED LINES ===
```

## Détails d'implémentation

### Méthode modifiée : `runNamedCheckzone()`
- Après l'exécution de `named-checkzone`, la sortie est enrichie avant le stockage
- Appelle `enrichValidationOutput()` pour ajouter le contexte de ligne
- Stocke et propage la sortie enrichie aux includes enfants

### Nouvelles méthodes

#### `enrichValidationOutput($outputText, $tmpDir, $zoneFilename)`
- Méthode d'enrichissement principale
- Analyse chaque ligne de sortie pour les motifs d'erreur
- Collecte les contextes de ligne et les ajoute à la sortie
- Retourne le texte de sortie enrichi

#### `resolveValidationFilePath($reportedFile, $tmpDir, $zoneFilename)`
- Résout les chemins de fichiers depuis les messages d'erreur vers les fichiers réels
- Utilise plusieurs stratégies :
  1. Chemin absolu dans tmpDir
  2. Le basename correspond au nom de fichier de zone
  3. Le basename existe dans tmpDir
  4. Chemin relatif depuis tmpDir
- Retourne null si le fichier ne peut pas être localisé

#### `getFileLineContext($path, $lineNumber, $contextLines = 2)`
- Extrait les lignes d'un fichier avec contexte
- Paramètres :
  - `$path` : Chemin du fichier
  - `$lineNumber` : Numéro de ligne cible (base 1)
  - `$contextLines` : Nombre de lignes avant/après à inclure (par défaut : 2)
- Retourne un bloc formaté avec numéros de ligne
- Utilise le préfixe `>` pour marquer la ligne cible

## Configuration

### Mode débogage
Pour conserver les fichiers temporaires pour inspection manuelle, définir :
```php
define('DEBUG_KEEP_TMPDIR', true);
```

Lorsqu'activé, les répertoires temporaires ne sont pas supprimés et leurs chemins sont journalisés.

### Chemin personnalisé named-checkzone
Si `named-checkzone` n'est pas dans le PATH système :
```php
define('NAMED_CHECKZONE_PATH', '/usr/local/bin/named-checkzone');
```

## Avantages

1. **Débogage plus rapide** - Les utilisateurs peuvent immédiatement voir ce qui ne va pas
2. **Meilleure UX** - Pas besoin de localiser les fichiers temporaires ou de compter les lignes
3. **Compatible avec les includes** - Fonctionne avec les fichiers de zone inlinés ayant des includes développés
4. **Visualisation claire** - Les numéros de ligne et les marqueurs rendent les erreurs évidentes
5. **Historique préservé** - La sortie enrichie est stockée dans la base de données pour référence future

## Tests

Un script de test est fourni : `test-validation-enrich.php`

Exécutez-le avec :
```bash
php test-validation-enrich.php
```

Le test vérifie :
- La correspondance de motif pour les lignes d'erreur
- L'extraction de ligne avec contexte
- Le flux d'enrichissement complet avec plusieurs erreurs
- Les cas limites (fichiers manquants, numéros de ligne invalides)

## Stockage en base de données

La sortie enrichie est stockée dans la table `zone_file_validation` :
- La colonne `output` (TEXT) contient la sortie de validation enrichie complète
- Cette sortie est également propagée aux includes enfants via `propagateValidationToIncludes()`

## Améliorations futures

Améliorations possibles :
1. Lignes de contexte configurables (actuellement codé en dur à 2)
2. Coloration syntaxique dans l'UI pour le contexte affiché
3. Liens directs depuis les messages d'erreur vers des lignes spécifiques dans l'éditeur de fichier de zone
4. Support d'outils de validation supplémentaires au-delà de `named-checkzone`
