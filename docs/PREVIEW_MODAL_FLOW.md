# Zone Preview Modal Flow - Visual Documentation

## Modal Structure

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

## Execution Flow

```
User Action: Click "Générer le fichier de zone"
                        ↓
    ┌──────────────────────────────────────────┐
    │ handleGenerateZoneFile()                 │
    └──────────────────────────────────────────┘
                        ↓
    ┌──────────────────────────────────────────┐
    │ openZonePreviewModalWithLoading()        │
    │ - Show modal with "Chargement…"         │
    │ - Set z-index: 9999                      │
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
          SUCCESS                ERROR
             │                     │
             ↓                     ↓
    ┌────────────────┐    ┌──────────────────┐
    │ Parse JSON     │    │ Show error in    │
    │ response       │    │ textarea         │
    └────────────────┘    │ Hide validation  │
             ↓             └──────────────────┘
    ┌────────────────┐
    │ Store preview  │
    │ data           │
    └────────────────┘
             ↓
    ┌────────────────┐
    │ Update preview │
    │ content        │
    └────────────────┘
             ↓
    ┌────────────────┐
    │ Attach download│
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

## State Transitions

### Initial State
- Modal: Hidden
- Textarea: Empty
- Validation section: Hidden

### Loading State
```javascript
// After clicking "Générer le fichier de zone"
modal.classList.add('open')
textarea.value = 'Chargement…'
validation.style.display = 'none'
```

### Success State (Generation)
```javascript
// After successful generation
textarea.value = generatedContent
previewData = { content, filename }
// Download button ready with Blob
```

### Success State (Validation)
```javascript
// After successful validation
validation.style.display = 'block'
validationStatus.className = 'validation-status passed'
validationStatus.textContent = '✅ Validation réussie'
validationOutput.textContent = namedCheckzoneOutput
```

### Error State (Generation)
```javascript
// On generation error
textarea.value = 'Erreur lors de la génération...'
validation.style.display = 'none'
```

### Error State (Validation)
```javascript
// On validation error
validation.style.display = 'block'
validationStatus.className = 'validation-status failed'
validationStatus.textContent = '❌ Erreur lors de la récupération...'
validationOutput.textContent = errorDetails
```

## CSS Classes and Styling

### Validation Status Colors

```css
.validation-status.passed {
  background-color: #d4edda;  /* Light green */
  color: #155724;              /* Dark green */
  border: 1px solid #c3e6cb;
}

.validation-status.failed {
  background-color: #f8d7da;  /* Light red */
  color: #721c24;              /* Dark red */
  border: 1px solid #f5c6cb;
}

.validation-status.pending {
  background-color: #fff3cd;  /* Light yellow */
  color: #856404;              /* Dark yellow */
  border: 1px solid #ffeaa7;
}
```

### Z-Index Hierarchy
```
- Base modals: z-index: 1000
- Preview modal: z-index: 9999
```

This ensures the preview modal always appears above the editor modal.

## API Response Structures

### Generate Zone File Response
```json
{
  "success": true,
  "content": "...",
  "filename": "zone-file.conf"
}
```

### Validation Response
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

### Error Response
```json
{
  "error": "Error message in French"
}
```

## User Interactions

1. **Generate**: Click "Générer le fichier de zone"
   - Modal opens immediately
   - Shows loading state
   - Fetches and displays content
   - Triggers validation automatically

2. **Download**: Click "Télécharger"
   - Creates Blob from displayed content
   - Downloads file with original filename
   - Shows success message

3. **Close**: Click "Fermer" or click overlay
   - Closes preview modal
   - Does NOT close parent editor modal
   - High z-index ensures proper overlay behavior

## Error Messages (French)

All user-facing messages are in French:
- "Chargement…"
- "Erreur lors de la génération du fichier de zone"
- "Réponse JSON invalide du serveur"
- "Aucune zone sélectionnée"
- "✅ Validation réussie"
- "❌ Validation échouée"
- "⏳ Validation en cours"
- etc.
