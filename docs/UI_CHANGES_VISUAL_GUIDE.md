# Génération de fichiers de zone - Guide visuel des modifications UI

## 📱 Modifications de l'interface utilisateur

### 1. Tableau de la liste des zones - AVANT
```
┌─────────────────────────────────────────────────────────────────────────────┐
│ Zone      │ Type   │ Filename  │ Parent │ # Includes │ Owner │ Status │ ... │
├─────────────────────────────────────────────────────────────────────────────┤
│ example.com│ Master │ ex.zone   │   -    │     3      │ admin │ Active │ ... │
│ common.conf│ Include│ common.cf │ ex.com │     0      │ admin │ Active │ ... │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 1. Tableau de la liste des zones - APRÈS ✅
```
┌──────────────────────────────────────────────────────────────────────┐
│ Zone      │ Type   │ Filename  │ Parent │ Owner │ Status │ Modified │
├──────────────────────────────────────────────────────────────────────┤
│ example.com│ Master │ ex.zone   │   -    │ admin │ Active │ 10/21   │
│ common.conf│ Include│ common.cf │ ex.com │ admin │ Active │ 10/20   │
└──────────────────────────────────────────────────────────────────────┘
```
**Modification** : Colonne "# Includes" supprimée ✓

---

### 2. Modal d'édition de zone - Onglet Détails - AVANT
```
┌────────────────────────────────────────┐
│  Zone: example.com              [X]    │
├────────────────────────────────────────┤
│ Détails │ Éditeur │ Includes │         │
├────────────────────────────────────────┤
│                                        │
│  Nom: [example.com              ]     │
│                                        │
│  Nom de fichier: [example.com.zone]   │
│                                        │
│  Type: [Master ▼] (disabled)          │
│                                        │
│  Statut: [Actif ▼]                    │
│                                        │
└────────────────────────────────────────┘
```

### 2. Modal d'édition de zone - Onglet Détails - APRÈS ✅
```
┌────────────────────────────────────────┐
│  Zone: example.com              [X]    │
├────────────────────────────────────────┤
│ Détails │ Éditeur │ Includes │         │
├────────────────────────────────────────┤
│                                        │
│  Nom: [example.com              ]     │
│                                        │
│  Nom de fichier: [example.com.zone]   │
│                                        │
│  Répertoire: [/etc/bind/zones   ]     │ ← NEW!
│  ℹ️ Répertoire pour les directives    │
│     $INCLUDE (optionnel)               │
│                                        │
│  Type: [Master ▼] (disabled)          │
│                                        │
│  Statut: [Actif ▼]                    │
│                                        │
└────────────────────────────────────────┘
```
**Modification** : Champ "Répertoire" ajouté (uniquement dans le modal, pas dans le tableau) ✓

---

### 3. Modal d'édition de zone - Onglet Éditeur - AVANT
```
┌────────────────────────────────────────┐
│  Zone: example.com              [X]    │
├────────────────────────────────────────┤
│ Détails │ Éditeur │ Includes │         │
├────────────────────────────────────────┤
│                                        │
│  Contenu du fichier de zone:          │
│  ┌──────────────────────────────────┐ │
│  │$ORIGIN example.com.              │ │
│  │$TTL 3600                         │ │
│  │@  IN  SOA ns1 admin (2024...)    │ │
│  │                                  │ │
│  │                                  │ │
│  └──────────────────────────────────┘ │
│                                        │
└────────────────────────────────────────┘
   [Annuler]            [Enregistrer]
```

### 3. Modal d'édition de zone - Onglet Éditeur - APRÈS ✅
```
┌────────────────────────────────────────┐
│  Zone: example.com              [X]    │
├────────────────────────────────────────┤
│ Détails │ Éditeur │ Includes │         │
├────────────────────────────────────────┤
│                                        │
│  Contenu du fichier de zone:          │
│  ┌──────────────────────────────────┐ │
│  │$ORIGIN example.com.              │ │
│  │$TTL 3600                         │ │
│  │@  IN  SOA ns1 admin (2024...)    │ │
│  │                                  │ │
│  │                                  │ │
│  └──────────────────────────────────┘ │
│                                        │
│  [📄 Générer le fichier de zone]      │ ← NEW!
│  ℹ️ Génère le contenu complet avec... │
│                                        │
└────────────────────────────────────────┘
   [Annuler]            [Enregistrer]
```
**Modification** : Bouton "Générer le fichier de zone" ajouté ✓

---

## 🎬 Flux utilisateur pour la génération de zone

### Étape 1 : Ouvrir la zone
```
L'utilisateur clique sur une ligne de zone dans le tableau
    ↓
Le modal s'ouvre et affiche les détails de la zone
```

### Étape 2 : Définir le répertoire (optionnel)
```
L'utilisateur va dans l'onglet "Détails"
    ↓
Saisit le répertoire : /etc/bind/zones
    ↓
Clique sur "Enregistrer"
```

### Étape 3 : Générer le fichier de zone
```
L'utilisateur va dans l'onglet "Éditeur"
    ↓
Clique sur le bouton "Générer le fichier de zone"
    ↓
Message : "Voulez-vous télécharger le fichier ?"
    ├─ OUI → Le fichier est téléchargé sous le nom "example.com.zone"
    └─ NON → Le contenu est affiché dans l'éditeur pour prévisualisation
```

---

## 📄 Exemple de fichier de zone généré

### Configuration d'entrée
- **Zone Content**: 
  ```
  $ORIGIN example.com.
  $TTL 3600
  ```
- **Includes**:
  - ID 5: common.conf (directory: /etc/bind/zones)
  - ID 7: special.conf (directory: null)
- **DNS Records**:
  - www.example.com → 192.168.1.10 (A)
  - mail.example.com → 192.168.1.20 (A)
  - example.com → 10 mail.example.com (MX)

### Generated Output ✅
```
$ORIGIN example.com.
$TTL 3600

$INCLUDE "/etc/bind/zones/common.conf"
$INCLUDE "special.conf"

; DNS Records
www.example.com        3600 IN A      192.168.1.10
mail.example.com       3600 IN A      192.168.1.20
example.com            3600 IN MX     10 mail.example.com
```

---

## 🔄 Flux de données

```
┌─────────────────┐
│ L'utilisateur   │
│ clique sur      │
│  "Générer..."   │
└────────┬────────┘
         ↓
┌─────────────────┐
│   JavaScript    │
│   génère un     │
│   appel API     │
└────────┬────────┘
         ↓
┌─────────────────────────────────────┐
│   API: /api/zone_api.php            │
│   action=generate_zone_file&id=X    │
└────────┬────────────────────────────┘
         ↓
┌─────────────────────────────────────┐
│   ZoneFile::generateZoneFile($id)   │
├─────────────────────────────────────┤
│  1. Récupérer le contenu de zone    │
│  2. Récupérer les includes          │
│     (avec répertoire)               │
│  3. Récupérer les enregistrements   │
│     DNS                             │
│  4. Formater en syntaxe BIND        │
└────────┬────────────────────────────┘
         ↓
┌─────────────────┐
│  Retourner un   │
│  JSON avec le   │
│    contenu      │
└────────┬────────┘
         ↓
┌─────────────────┐
│   JavaScript    │
│  affiche une    │
│   invite        │
└────────┬────────┘
         ↓
    ┌────┴────┐
    ↓         ↓
[Télécharger] [Prévisualiser]
```

---

## ✅ Vérification des exigences

| Exigence | Statut | Notes |
|----------|--------|-------|
| Ajouter colonne directory | ✅ | Via migration 010 |
| Directory uniquement dans modal | ✅ | Pas dans la vue tableau |
| Supprimer colonne "# Includes" | ✅ | De la vue tableau |
| Bouton Générer | ✅ | Dans l'onglet Éditeur |
| Directives $INCLUDE | ✅ | Utilise répertoire/nom de fichier |
| Enregistrements DNS en BIND | ✅ | Tous types supportés |
| Includes NON inlinés | ✅ | Utilise $INCLUDE |
| Télécharger/prévisualiser | ✅ | Choix utilisateur |

---

## 🎨 Éléments visuels ajoutés

### Nouveau champ dans le modal
- **Label** : "Répertoire"
- **Type** : Saisie de texte
- **Placeholder** : "Exemple: /etc/bind/zones"
- **Texte d'aide** : "Répertoire pour les directives $INCLUDE (optionnel)"

### Nouveau bouton dans le modal
- **Icône** : 📄 (file-code)
- **Texte** : "Générer le fichier de zone"
- **Style** : btn btn-secondary
- **Texte d'aide** : "Génère le contenu complet avec les directives $INCLUDE et les enregistrements DNS"

---

## 📱 Design responsive

Toutes les modifications conservent le design responsive existant :
- Le modal reste centré et défilable
- Les champs de formulaire s'empilent correctement sur mobile
- Le bouton est en pleine largeur sur les petits écrans
- Les colonnes du tableau s'ajustent comme auparavant (moins une colonne)

---

**Fin du guide visuel**
