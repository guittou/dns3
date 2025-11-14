# Manual PR Instructions - Zone Name Validation Fix

## Current Status
All code changes have been completed and committed to the local branch `fix/ui-no-validate-zone-name`.

## Branch Information
- **Local branch**: `fix/ui-no-validate-zone-name`
- **Base branch**: Merge commit `e0f12e8` from PR #150
- **Commits**:
  1. `5f33c10` - Remove duplicated submitCreateInclude function, alias to saveInclude
  2. `958498f` - Fix(ui): remove zone name format validation (required only) + unify include modal IDs/handlers

## Manual Steps to Complete

### 1. Push the Branch
From the repository root, run:
```bash
git push -u origin fix/ui-no-validate-zone-name
```

### 2. Create Pull Request
After pushing, create a PR with the following details:

**Title:**
```
Fix: skip zone name format validation on create (name required only) and fix include modal handlers
```

**Description:**
```markdown
## Objectifs

Retirer la validation de format côté client sur le champ "Nom de la zone" (ne garder que la validation required) et corriger les incohérences du modal d'include.

## Changements implémentés

### 1. Unification des fonctions du modal include ✅
- Supprimé la duplication de `submitCreateInclude()`
- `submitCreateInclude()` est maintenant un alias de `saveInclude()` pour compatibilité
- `saveInclude()` est la seule source de vérité pour la création d'includes

### 2. Validation du nom de zone - Required seulement ✅

**Création d'include (saveInclude)**
```javascript
// Validate name field (required only, no format validation)
if (!name) {
    showModalError('includeCreate', 'Le Nom de la zone est requis.');
    return;
}
```

**Création de master (createZone)**
```javascript
// Validate zone name: REQUIRED only (no format validation)
if (!name) {
    showModalError('createZone', 'Le Nom de la zone est requis.');
    return;
}
```

### 3. Autres validations intactes ✅
- **Champ domaine**: Utilise `validateDomainLabel()` (lettres, chiffres, tirets uniquement - pas d'underscores)
- **Champ nom de fichier**: Utilise `validateFilename()` (pas d'espaces, doit se terminer par .db)

### 4. IDs des modaux cohérents ✅
- Modal include: `include-create-modal`, modalKey: `includeCreate`
- Modal master: `master-create-modal`, modalKey: `createZone`
- Tous les champs cachés et IDs d'input correspondent entre HTML et JavaScript

## Fichiers modifiés
- `assets/js/zone-files.js` - Simplifié submitCreateInclude, vérifié validation

## Comportement attendu
✅ Nom de zone avec underscores (ex: `test_uk`) accepté côté client
✅ Nom de zone vide bloqué avec message d'erreur
✅ Champ domaine valide toujours le format (correct - champ différent)
✅ Nom de fichier valide toujours le format (correct - requis)
✅ Bannières d'erreur s'affichent correctement dans les deux modaux
✅ Toutes les fonctions de modal utilisent des IDs cohérents

## Tests manuels requis
- Ouvrir "Nouveau domaine": laisser nom vide → bloqué
- Saisir nom de zone avec underscore → accepté (serveur peut refuser)
- Ouvrir "Nouveau fichier de zone": saisir nom avec underscore → accepté
- Nom de fichier avec espace ou sans .db → bloqué

Voir ZONE_NAME_VALIDATION_FIX.md pour la checklist complète de tests.
```

## Verification

After creating the PR, verify:
- [ ] Branch `fix/ui-no-validate-zone-name` appears on GitHub
- [ ] PR is created with correct title and description
- [ ] All commits are included
- [ ] PR can be merged without conflicts

## Alternative: Use GitHub Web Interface

If command-line push fails:
1. Go to https://github.com/guittou/dns3
2. Click "Branches"
3. Find `fix/ui-no-validate-zone-name` (if it exists remotely)
4. Click "New pull request"
5. Use the title and description above

## Files Changed
- `assets/js/zone-files.js` - 46 lines modified (43 additions, 3 deletions)
- `ZONE_NAME_VALIDATION_FIX.md` - 87 lines added (new file)

Total: 2 files changed, 43 insertions(+), 90 deletions(-)
