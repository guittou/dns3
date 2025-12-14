# Flux de la modale d'aperçu de zone - Documentation visuelle

## Structure de la modale

```
┌─────────────────────────────────────────────────────────────┐
│  zonePreviewModal (z-index: 9999)                          │
│  ┌───────────────────────────────────────────────────────┐  │
│  │ Modal Header                                          │  │
│  │ "Aperçu du fichier de zone"                    [×]   │  │
│  ├───────────────────────────────────────────────────────┤  │
│  │ Modal Body                                            │  │
│  │                                                       │  │
│  │ Label: "Contenu généré du fichier de zone"          │  │
│  │ ┌───────────────────────────────────────────────┐   │  │
│  │ │ #zoneGeneratedPreview (textarea, readonly)    │   │  │
│  │ │                                                │   │  │
│  │ │ Shows:                                         │   │  │
│  │ │ - "Chargement…" (initial state)               │   │  │
│  │ │ - Generated zone file content (on success)    │   │  │
│  │ │ - Error message (on failure)                  │   │  │
│  │ │                                                │   │  │
│  │ └───────────────────────────────────────────────┘   │  │
│  │                                                       │  │
│  │ ┌─────────────────────────────────────────────────┐ │  │
│  │ │ #zoneValidationResults (initially hidden)      │ │  │
│  │ │                                                 │ │  │
│  │ │ "Résultat de la validation (named-checkzone)"  │ │  │
│  │ │                                                 │ │  │
│  │ │ ┌─────────────────────────────────────────┐   │ │  │
│  │ │ │ #zoneValidationStatus                   │   │ │  │
│  │ │ │ ✅ Validation réussie (green)           │   │ │  │
│  │ │ │ ❌ Validation échouée (red)             │   │ │  │
│  │ │ │ ⏳ Validation en cours (yellow)         │   │ │  │
│  │ │ └─────────────────────────────────────────┘   │ │  │
│  │ │                                                 │ │  │
│  │ │ ┌─────────────────────────────────────────┐   │ │  │
│  │ │ │ #zoneValidationOutput (monospace)       │   │ │  │
│  │ │ │ Shows named-checkzone command output    │   │ │  │
│  │ │ └─────────────────────────────────────────┘   │ │  │
│  │ └─────────────────────────────────────────────────┘ │  │
│  │                                                       │  │
│  ├───────────────────────────────────────────────────────┤  │
│  │ Modal Footer                                          │  │
│  │                                                       │  │
│  │         [Fermer]          [📥 Télécharger]           │  │
│  │                                                       │  │
│  └───────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

## Flux d'exécution

```
Action utilisateur : Clic sur "Générer le fichier de zone"
                        ↓
    ┌──────────────────────────────────────────┐
    │ handleGenerateZoneFile()                 │
    └──────────────────────────────────────────┘
                        ↓
    ┌──────────────────────────────────────────┐
    │ openZonePreviewModalWithLoading()        │
    │ - Affiche la modale avec "Chargement…"  │
    │ - Définit z-index: 9999                  │
    └──────────────────────────────────────────┘
                        ↓
    ┌──────────────────────────────────────────┐
    │ fetch(generate_zone_file)                │
    │ - credentials: 'same-origin'             │
    │ - Accept: application/json               │
    └──────────────────────────────────────────┘
                        ↓
             ┌──────────┴──────────┐
             │                     │
          SUCCÈS                ERREUR
             │                     │
             ↓                     ↓
    ┌────────────────┐    ┌──────────────────┐
    │ Parse JSON     │    │ Affiche l'erreur │
    │ response       │    │ dans textarea    │
    └────────────────┘    │ Masque validation│
             ↓             └──────────────────┘
    ┌────────────────┐
    │ Stocke les     │
    │ données aperçu │
    └────────────────┘
             ↓
    ┌────────────────┐
    │ Met à jour     │
    │ le contenu     │
    └────────────────┘
             ↓
    ┌────────────────┐
    │ Attache le     │
    │ handler (Blob) │
    └────────────────┘
             ↓
    ┌──────────────────────────────────────────┐
    │ fetchAndDisplayValidation()              │
    └──────────────────────────────────────────┘
             ↓
    ┌──────────────────────────────────────────┐
    │ fetch(zone_validate?trigger=true)        │
    │ - credentials: 'same-origin'             │
    │ - Accept: application/json               │
    └──────────────────────────────────────────┘
             ↓
             ┌──────────┴──────────┐
             │                     │
          SUCCESS                ERROR
             │                     │
             ↓                     ↓
    ┌────────────────┐    ┌──────────────────┐
    │ Parse JSON     │    │ Show error in    │
    │ validation     │    │ validation area  │
    └────────────────┘    └──────────────────┘
             ↓
    ┌────────────────────────────────────────┐
    │ displayValidationResults()              │
    │ - Show validation section               │
    │ - Display status with icon/color        │
    │ - Display named-checkzone output        │
    └────────────────────────────────────────┘
             ↓
    ┌────────────────────────────────────────┐
    │ User sees complete preview with         │
    │ validation results                      │
    └────────────────────────────────────────┘
```

## Transitions d'État

### État Initial
- Modale : Masquée
- Textarea : Vide
- Section de validation : Masquée

### État de Chargement
```javascript
// After clicking "Générer le fichier de zone"
modal.classList.add('open')
textarea.value = 'Chargement…'
validation.style.display = 'none'
```

### État de Succès (Génération)
```javascript
// Après génération réussie
textarea.value = generatedContent
previewData = { content, filename }
// Bouton Télécharger prêt avec Blob
```

### État de Succès (Validation)
```javascript
// Après validation réussie
validation.style.display = 'block'
validationStatus.className = 'validation-status passed'
validationStatus.textContent = '✅ Validation réussie'
validationOutput.textContent = namedCheckzoneOutput
```

### État d'Erreur (Génération)
```javascript
// En cas d'erreur de génération
textarea.value = 'Erreur lors de la génération...'
validation.style.display = 'none'
```

### État d'Erreur (Validation)
```javascript
// En cas d'erreur de validation
validation.style.display = 'block'
validationStatus.className = 'validation-status failed'
validationStatus.textContent = '❌ Erreur lors de la récupération...'
validationOutput.textContent = errorDetails
```

## Classes CSS et Styles

### Couleurs de Statut de Validation

```css
.validation-status.passed {
  background-color: #d4edda;  /* Vert clair */
  color: #155724;              /* Vert foncé */
  border: 1px solid #c3e6cb;
}

.validation-status.failed {
  background-color: #f8d7da;  /* Rouge clair */
  color: #721c24;              /* Rouge foncé */
  border: 1px solid #f5c6cb;
}

.validation-status.pending {
  background-color: #fff3cd;  /* Jaune clair */
  color: #856404;              /* Jaune foncé */
  border: 1px solid #ffeaa7;
}
```

### Hiérarchie Z-Index
```
- Modales de base : z-index: 1000
- Modale de prévisualisation : z-index: 9999
```

Cela garantit que la modale de prévisualisation apparaît toujours au-dessus de la modale d'éditeur.

## Structures de Réponse API

### Réponse de Génération de Fichier de Zone
```json
{
  "success": true,
  "content": "...",
  "filename": "zone-file.conf"
}
```

### Réponse de Validation
```json
{
  "success": true,
  "validation": {
    "status": "passed",
    "output": "zone example.com/IN: loaded serial 2024...",
    "checked_at": "2024-10-22 12:34:56",
    "run_by_username": "admin"
  }
}
```

### Réponse d'Erreur
```json
{
  "error": "Message d'erreur en français"
}
```

## Interactions Utilisateur

1. **Générer** : Cliquer sur "Générer le fichier de zone"
   - La modale s'ouvre immédiatement
   - Affiche l'état de chargement
   - Récupère et affiche le contenu
   - Déclenche la validation automatiquement

2. **Télécharger** : Cliquer sur "Télécharger"
   - Crée un Blob depuis le contenu affiché
   - Télécharge le fichier avec le nom original
   - Affiche un message de succès

3. **Fermer** : Cliquer sur "Fermer" ou cliquer sur l'overlay
   - Ferme la modale de prévisualisation
   - NE ferme PAS la modale d'éditeur parente
   - Le z-index élevé garantit un comportement d'overlay approprié

## Messages d'Erreur (Français)

Tous les messages visibles par l'utilisateur sont en français :
- "Chargement…"
- "Erreur lors de la génération du fichier de zone"
- "Réponse JSON invalide du serveur"
- "Aucune zone sélectionnée"
- "✅ Validation réussie"
- "❌ Validation échouée"
- "⏳ Validation en cours"
- etc.
