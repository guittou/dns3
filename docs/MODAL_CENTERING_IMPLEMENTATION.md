# Centrage vertical des modales - Guide d'implémentation

## Résumé
Cette implémentation ajoute le centrage vertical et horizontal à toutes les fenêtres modales de l'application DNS3. Les modales apparaissent maintenant centrées dans la fenêtre avec un défilement de contenu approprié et un comportement responsive.

## Changements effectués

### Fichiers CSS
**assets/css/style.css**
- Ajout du centrage flexbox à `.dns-modal.open`
- Ajout de padding (20px) et box-sizing pour un espacement approprié
- Ajout d'un fallback responsive pour les écrans < 768px (padding réduit à 10px)
- Hauteur max du contenu : `calc(100vh - 80px)` avec défilement interne

**assets/css/zone-files.css**
- Ajout du centrage flexbox à `.modal.open` (modale de prévisualisation de zone)
- Ajout d'un fallback responsive pour les petits écrans
- Même approche que dns-modal pour la cohérence

### Fichiers JavaScript
**assets/js/zone-files.js**
- `openCreateZoneModal()` : ajoute la classe 'open', appelle ensureModalCentered
- `closeCreateZoneModal()` : retire la classe 'open'
- `openZonePreviewModalWithLoading()` : appelle ensureModalCentered

**Déjà en place (depuis la PR #69) :**
- `assets/js/modal-utils.js` : Helper pour l'ajustement de hauteur dynamique
- `assets/js/dns-records.js` : Intégration modale DNS
- `assets/js/zone-files.js` : Intégration modale d'édition de zone

## Comment ça fonctionne

1. **Ouverture d'une modale**
   - JavaScript définit `modal.style.display = 'block'`
   - JavaScript ajoute `modal.classList.add('open')`
   - Le CSS `.modal.open` applique le centrage flexbox
   - `ensureModalCentered()` ajuste dynamiquement la hauteur max du contenu

2. **Débordement du contenu**
   - Contenu de la modale limité à la hauteur `calc(100vh - 80px)`
   - Le débordement défile à l'intérieur de la modale avec `overflow: auto`
   - Le corps de la page ne défile pas, seulement le contenu de la modale

3. **Fermeture d'une modale**
   - JavaScript retire `modal.classList.remove('open')`
   - JavaScript définit `modal.style.display = 'none'`
   - État propre pour la prochaine ouverture

4. **Comportement responsive**
   - Sur les écrans < 768px : padding réduit (10px vs 20px)
   - Hauteur max ajustée : `calc(100vh - 40px)`
   - Meilleur ajustement pour les appareils mobiles

## Guide de test

### Tests manuels
1. **Modales d'enregistrement DNS**
   - Créer un nouvel enregistrement : Devrait être centré
   - Éditer un enregistrement existant : Devrait être centré
   - Contenu long : Devrait défiler à l'intérieur de la modale

2. **Modales de zone**
   - Créer une zone : Devrait être centrée
   - Éditer une zone : Devrait être centrée
   - Changement d'onglets : La position reste stable
   - Générer une prévisualisation : Modale de prévisualisation centrée

3. **Responsive**
   - Redimensionner vers mobile : Padding réduit, centrage approprié
   - Vérifier le défilement du contenu sur petits écrans

4. **Régression**
   - Toutes les opérations CRUD fonctionnent
   - Les boutons de fermeture de modale fonctionnent
   - Le clic à l'extérieur ferme la modale
   - Aucune erreur JavaScript

### Test des navigateurs
- ✅ Chrome/Chromium
- ✅ Firefox
- ✅ Safari
- ✅ Edge
- ✅ Navigateurs mobiles

## Instructions de rollback
Si nécessaire, revenir à cette PR pour retrouver le comportement de modale précédent. Les changements sont minimes et réversibles :
1. Les ajouts CSS peuvent être supprimés
2. Les ajouts de classe JavaScript sont rétrocompatibles
3. Aucun changement cassant dans le HTML ou la base de données

## Notes techniques
- Utilise le flexbox CSS pour un centrage fiable
- `!important` assure l'override des styles inline
- Aucun changement aux IDs de modale ou à la structure HTML
- Maintient `modal.style.display` pour la rétrocompatibilité
- Tout le JavaScript passe la validation de syntaxe
- Aucune nouvelle dépendance ajoutée

## Fichiers modifiés
- `assets/css/style.css` (+15 lignes)
- `assets/css/zone-files.css` (+25 lignes)
- `assets/js/zone-files.js` (+19 lignes modifiées)

Total : 54 lignes ajoutées/modifiées sur 3 fichiers
