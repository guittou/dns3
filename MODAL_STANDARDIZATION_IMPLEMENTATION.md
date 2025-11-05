# Modal Standardization Implementation

## Objectif
Uniformiser tous les modals de l'interface d'administration en utilisant le modèle des Zones comme référence standard.

## Changements effectués

### 1. Création de `assets/css/modal-utils.css`
Nouvelle feuille de styles réutilisable contenant :
- **Classes de base** : `.dns-modal`, `.dns-modal-content`
- **Variantes de taille** : `.modal-small` (400px), `.modal-medium` (600px), `.modal-large` (900px)
- **Structure** : `.dns-modal-header`, `.dns-modal-body`, `.dns-modal-footer`
- **Boutons d'action** : `.modal-action-button` avec variantes `.btn-delete`, `.btn-cancel`, `.btn-submit`
- **Styles de formulaire** : Cohérents pour tous les modals
- **Responsive** : Adaptations pour mobile et tablette
- **Comportement fixe** : Support pour hauteur verrouillée avec classe `.modal-fixed`

### 2. Amélioration de `assets/js/modal-utils.js`
Nouvelles fonctions utilitaires :
- **`openModalById(modalId)`** : Ouvre un modal, ajoute la classe `open`, applique le centrage et la gestion de hauteur
- **`closeModalById(modalId)`** : Ferme un modal, nettoie les classes et styles
- **`applyFixedModalHeight(modalEl)`** : Verrouille la hauteur du modal (utile pour les onglets)
- **`unlockModalHeight(modalEl)`** : Déverrouille la hauteur
- **`ensureModalCentered(modalEl)`** : Garantit le centrage correct (fonction existante)
- **Click overlay** : Fermeture au clic sur l'overlay (sauf si `data-no-overlay-close="true"`)

### 3. Inclusion dans `includes/header.php`
Ajout des lignes suivantes dans le `<head>` :
```html
<link rel="stylesheet" href="<?php echo $basePath; ?>assets/css/modal-utils.css">
<script src="<?php echo $basePath; ?>assets/js/modal-utils.js" defer></script>
```

### 4. Mise à jour des modals dans `admin.php`
Trois modals mis à jour avec la structure standardisée :

#### Modal Domaines
```html
<div id="modal-domain" class="dns-modal">
    <div class="dns-modal-content modal-medium">
        <div class="dns-modal-header">...</div>
        <div class="dns-modal-body">...</div>
        <div class="dns-modal-footer">
            <div class="modal-action-bar">
                <button class="btn-delete modal-action-button">Supprimer</button>
                <button class="btn-cancel modal-action-button">Annuler</button>
                <button class="btn-success modal-action-button">Enregistrer</button>
            </div>
        </div>
    </div>
</div>
```

#### Modal Utilisateurs
Structure identique avec `id="modal-user"`, sans bouton Supprimer.

#### Modal Mappings
Structure identique avec `id="modal-mapping"`, sans bouton Supprimer.

**Suppression** : Ancien CSS inline (150+ lignes) retiré de `admin.php`.

### 5. Mise à jour de `assets/js/admin.js`
Toutes les fonctions d'ouverture/fermeture de modals mises à jour :

#### Avant
```javascript
document.getElementById('modal-domain').classList.add('show');
document.getElementById('modal-domain').classList.remove('show');
```

#### Après
```javascript
window.openModalById('modal-domain');
window.closeModalById('modal-domain');
```

Fonctions mises à jour :
- `openCreateUserModal()` et `closeUserModal()`
- `editUser()` 
- `openCreateMappingModal()` et `closeMappingModal()`
- `openCreateDomainModal()`, `editDomain()` et `closeDomainModal()`
- Code défensif en bas du fichier

## Ordre des boutons dans le footer
Conformément aux spécifications, l'ordre est :
1. **Supprimer** (rouge, `.btn-delete`) - À gauche
2. **Annuler** (gris, `.btn-cancel`) - Au centre
3. **Enregistrer/Créer** (vert, `.btn-submit` ou `.btn-success`) - À droite

## Comportement modal

### Centrage
- Modal centré verticalement et horizontalement avec flexbox
- Recalcul automatique lors du redimensionnement de la fenêtre

### Hauteur
- Hauteur maximale : `calc(100vh - 80px)` par défaut
- Option de hauteur fixe avec la classe `.modal-fixed`
- Défilement interne dans `.dns-modal-body` si contenu trop grand

### Fermeture
- Clic sur le bouton `×` (close)
- Clic sur l'overlay (peut être désactivé avec `data-no-overlay-close="true"`)
- Bouton "Annuler"
- Touche Escape (à implémenter si nécessaire)

## Responsive
- **Desktop** : Tailles modal-small/medium/large respectées
- **Tablette** : Modals s'adaptent à la largeur disponible (90%)
- **Mobile** : 
  - Modals prennent 95% de la largeur
  - Boutons empilés verticalement
  - Padding réduit pour maximiser l'espace

## Compatibilité
- Compatibilité avec les modals existants (Zones) maintenue
- Support des classes `.zone-modal-content` pour rétrocompatibilité
- Fallback pour navigateurs sans flexbox

## Tests recommandés
1. Ouvrir chaque modal (Domaines, Utilisateurs, Mappings)
2. Vérifier le centrage sur différentes tailles d'écran
3. Tester la fermeture par clic overlay
4. Vérifier l'ordre des boutons
5. Tester sur mobile/tablette
6. Vérifier que les formulaires fonctionnent correctement

## Fichiers modifiés
- `assets/css/modal-utils.css` (nouveau)
- `assets/js/modal-utils.js` (amélioré)
- `includes/header.php` (inclusions ajoutées)
- `admin.php` (modals restructurés, CSS inline supprimé)
- `assets/js/admin.js` (fonctions mises à jour)

## Résultat
Tous les modals de l'interface admin suivent maintenant le même modèle visuel et comportemental que les Zones, avec une base CSS/JS réutilisable pour les futurs modals.
