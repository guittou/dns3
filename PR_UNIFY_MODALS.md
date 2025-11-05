# PR: Unify Modal System - 720px Fixed Height & Standardized UI

## Objectif

Cette PR unifie le système de modals de l'interface admin en :
- Implémentant une hauteur fixe de 720px avec fallback responsive
- Standardisant l'ordre et le style des boutons du footer
- Assurant une enveloppe `.dns-modal` cohérente pour tous les modals

## Contexte

L'interface admin avait plusieurs popups (Zones, Domaines, etc.) avec des comportements et styles incohérents. Cette PR standardise tous les modals selon le modèle de référence du modal Zones.

## Changements

### 1. Modal Utils - Hauteur Fixe 720px

**`assets/css/modal-utils.css`**
- Mise à jour de la variable CSS `--modal-fixed-height` de 730px → 720px
- Ajout de classes standalone pour les boutons : `.btn-success`, `.btn-secondary`, `.btn-danger`
- Mise à jour des commentaires pour refléter l'ordre standardisé des boutons

**`assets/js/modal-utils.js`**
- Refonte de `applyFixedModalHeight()` pour appliquer une hauteur fixe de 720px
- Ajout du fallback responsive : utilise `min(720px, viewportHeight - 80px)`
- Garantit que les modals s'adaptent aux petits écrans (< 720px)

### 2. Standardisation des Footers

Tous les modals suivent maintenant le même ordre de boutons :
1. **Enregistrer/Créer** (vert/btn-success) - à gauche
2. **Annuler** (gris/btn-cancel) - au centre
3. **Supprimer** (rouge/btn-danger) - à droite (seulement en mode édition)

**Fichiers modifiés :**
- `zone-files.php` - Modal création zone + modal édition zone
- `admin.php` - Modal utilisateur, modal mapping, modal domaine

### 3. Vérifications

✅ `includes/header.php` - Inclut déjà `modal-utils.css` et `modal-utils.js`  
✅ `zone-files.php` - Utilise l'enveloppe `.dns-modal` avec onglets Détails/Éditeur/Includes  
✅ `admin.php` - Tous les modals utilisent l'enveloppe `.dns-modal`  
✅ `assets/js/admin.js` - Les fonctions `openCreateDomainModal` et `editDomain` sont déjà en place

## Tests Effectués

### Desktop (720px viewport)
- ✅ Modal s'ouvre centré avec overlay sombre
- ✅ Hauteur fixe de 720px appliquée
- ✅ Contenu défilable à l'intérieur du modal
- ✅ Footer avec boutons centrés et stylés correctement

![Modal Desktop](https://github.com/user-attachments/assets/d5492eea-c1ab-4349-adee-734ff0843d94)

### Mobile Responsive (375x667px)
- ✅ Modal s'adapte à la hauteur du viewport (< 720px)
- ✅ Boutons empilés verticalement sur mobile
- ✅ Boutons pleine largeur sur mobile
- ✅ Contenu reste défilable

![Modal Mobile](https://github.com/user-attachments/assets/3de1d173-7941-4351-babe-e9e9441d030e)

### Fonctionnalités préservées
- ✅ Système d'onglets dans le modal Zones
- ✅ Éditeur de contenu de zone
- ✅ Liste des includes
- ✅ Bannières d'erreur
- ✅ Select searchable pour les zones dans le modal Domaine
- ✅ Logique métier existante intacte

## QA / Vérifications

**À tester après déploiement :**

1. **Admin → Zones** :
   - Ouvrir "Nouvelle zone" → modal centré, hauteur 720px, boutons stylés
   - Ouvrir une zone existante → onglets Détails/Éditeur/Includes fonctionnels
   - Vérifier que le contenu long scrolle correctement

2. **Admin → Domaines** :
   - Cliquer "Créer un domaine" → modal centré, zone select searchable
   - Modifier un domaine → bouton Supprimer visible
   - Vérifier que Save/Cancel/Delete sont centrés et stylés

3. **Responsive** :
   - Tester sur mobile (< 768px) → boutons empilés verticalement
   - Tester sur très petit écran (< 520px) → modal pleine largeur

4. **Navigation** :
   - Hard refresh (Ctrl+F5) pour vider le cache
   - Tester la fermeture par clic sur overlay
   - Tester la fermeture par bouton X ou Annuler

## Fichiers Modifiés

- ✅ `assets/css/modal-utils.css` - Hauteur fixe 720px + classes de boutons standalone
- ✅ `assets/js/modal-utils.js` - Logique de hauteur fixe avec fallback responsive
- ✅ `admin.php` - Footers standardisés pour User, Mapping, Domain modals
- ✅ `zone-files.php` - Footers standardisés pour Create/Edit Zone modals

## Notes

- **Type de changement** : UI only (CSS/JS/HTML) - aucun changement backend
- **Backward compatible** : Toutes les fonctions existantes préservées
- **Responsive** : Fallback automatique pour viewports < 720px
- **Accessibilité** : Maintien des attributs ARIA et rôles existants

## Branche

- **Source** : `feature/unify-modals`
- **Target** : `main`
- **Status** : DRAFT - En attente de revue

---

**Merci de tester et valider avant de merger ! 🚀**
