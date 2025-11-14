# Pull Request Summary - fix/include-parent-selection

## Branch Information
- **Source Branch:** fix/include-parent-selection
- **Target Branch:** main
- **Commit:** eddce87

## PR Title
Fix include-create modal: preselect selected zonefile and sync header/input

## PR Description

Ce PR corrige le modal "Nouveau fichier de zone" (include-create) pour respecter exactement deux exigences :

### 1. Header et domaine synchronisés ✅

- Le header affiche en haut, centré, le texte « Nouveau fichier de zone »
- Juste en dessous, centré également, s'affiche le nom du domaine (le domaine du master sélectionné)
- Le span `#include-modal-title` et `#include-modal-domain` existent déjà
- L'input disabled `#include-domain` affiche la même valeur (cohérence header input)
- **NOUVEAU:** Le texte du champ est centré visuellement avec `textAlign = 'center'`

### 2. Préselection du fichier parent ✅

- Le champ visible « Fichier de zone parent » (input `#include-parent-input`) est prérempli avec le fichier de zone sélectionné sur la page principale (c'est-à-dire le fichier de zone sélectionné, pas le domaine)
- Le champ caché `include-parent-zone-id` reçoit l'ID de ce fichier de zone
- La combobox continue à lister et permettre de rechercher tous les fichiers de zone liés au domaine (master + includes récursifs)
- `populateIncludeParentCombobox(masterId)` est appelé pour remplir la liste, puis la sélection visible est ré-appliquée au fichier sélectionné

## Modifications apportées

**Un seul fichier modifié :** `assets/js/zone-files.js`

La fonction `openCreateIncludeModal` a été remplacée par une implémentation minimale et défensive qui :

- Détermine `defaultParentId` en priorisant : `parentId` param → `window.ZONES_SELECTED_ZONEFILE_ID` → `window.selectedZoneId` → `#zone-file-id` input → `window.ZONES_SELECTED_MASTER_ID`
- Récupère la zone sélectionnée via `zoneApiCall('get_zone', {id: defaultParentId})` et la stocke en `selectedZone`
- Détermine `masterId` via `getMasterIdFromZoneId(selectedZone.id || defaultParentId)`
- Récupère le master zone pour obtenir `domain/name`
- Met à jour `#include-domain` (input disabled) et `#include-modal-domain` (span) avec la même valeur
- **Centre la valeur visible** avec `domainField.style.textAlign = 'center'`
- Met `include-domain-id = masterId` et `include-parent-zone-id = selectedZone.id`
- Vide les champs `include-name`, `include-filename`, `include-directory`
- Appelle `await populateIncludeParentCombobox(masterId)` pour remplir la liste master + includes
- Après populate, ré-applique la sélection visible : `include-parent-input.value = ${selectedZone.name} (${selectedZone.file_type})` et `include-parent-zone-id = selectedZone.id`
- Ouvre le modal (`modal.style.display='block'`, `modal.classList.add('open')`) et appelle `ensureModalCentered` si disponible
- Utilise `try/catch` et `console.warn` pour les appels API ratés

## Tests manuels attendus

1. Sélectionner un fichier de zone dans la page principale (master ou include)
2. Cliquer « Nouveau fichier de zone » :
   - ✅ Le modal s'ouvre ; le header affiche en haut centré « Nouveau fichier de zone »
   - ✅ Juste en dessous, centré, le nom du domaine (master)
   - ✅ L'input disabled `#include-domain` affiche la même valeur (centrée)
   - ✅ Le champ « Fichier de zone parent » (`#include-parent-input`) est pré-rempli avec le fichier de zone sélectionné sur la page principale
   - ✅ `include-parent-zone-id` contient son id
   - ✅ La combobox continue de lister et permettre de rechercher le master + includes récursifs
3. Créer un include et vérifier que l'affectation fonctionne et qu'il n'y a pas d'erreurs console

## Security Summary

✅ **CodeQL scan completed successfully with no alerts found in JavaScript code.**

## Files Changed

```
assets/js/zone-files.js | 36 insertions(+), 24 deletions(-)
1 file changed, 36 insertions(+), 24 deletions(-)
```

## Additional Notes

- Aucun autre fichier n'a été modifié
- La solution est minimale et défensive
- Tous les appels API utilisent try/catch avec console.warn pour les erreurs
- Le code est bien documenté avec des commentaires clairs
