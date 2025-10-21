# Visual UI Guide: Zone Files Management

## Before vs After

### BEFORE (Old UI)
```
┌─────────────────────────────────────────────────────────────────────┐
│ Gestion des fichiers de zone            [+ Nouvelle zone]           │
├─────────────────────────────────────────────────────────────────────┤
│                                                                       │
│ ┌────────────────────────────────────────────────────────────────┐  │
│ │ Zone    │ Type │ Fichier │ #Inc │ Proprio │ Statut │ Actions │  │
│ ├────────────────────────────────────────────────────────────────┤  │
│ │ example │ Mast │ ex.zone │   2  │  admin  │ Actif  │ 👁 ✏️   │  │
│ │ inc1    │ Inc  │ i1.conf │   0  │  admin  │ Actif  │ 👁 ✏️   │  │
│ └────────────────────────────────────────────────────────────────┘  │
│                                                                       │
│ • Clicking 👁 or ✏️ navigates to separate page                       │
│ • No parent information shown                                        │
│ • Multiple navigation steps required                                 │
└─────────────────────────────────────────────────────────────────────┘
```

### AFTER (New Modal UI)
```
┌─────────────────────────────────────────────────────────────────────┐
│ Gestion des fichiers de zone            [+ Nouvelle zone]           │
├─────────────────────────────────────────────────────────────────────┤
│                                                                       │
│ ┌────────────────────────────────────────────────────────────────┐  │
│ │ Zone    │ Type │ Fichier │ Parent  │ #Inc │ Proprio │ Statut │  │
│ ├────────────────────────────────────────────────────────────────┤  │
│ │ example │ Mast │ ex.zone │    -    │   2  │  admin  │ Actif  │←─┼─ Clickable!
│ │ inc1    │ Inc  │ i1.conf │ example │   0  │  admin  │ Actif  │←─┼─ Clickable!
│ └────────────────────────────────────────────────────────────────┘  │
│                                                                       │
│ • Click any row to open modal                                        │
│ • Parent column shows hierarchy                                      │
│ • No per-row action buttons                                          │
└─────────────────────────────────────────────────────────────────────┘
```

## New Modal Interface

### 1. Create Master Zone Modal (from "Nouvelle zone" button)

```
┌──────────────────────────────────────────────────────┐
│ Créer une nouvelle zone                           ✕ │
├──────────────────────────────────────────────────────┤
│                                                      │
│  Nom *                                              │
│  ┌────────────────────────────────────────────────┐ │
│  │ test-master                                     │ │
│  └────────────────────────────────────────────────┘ │
│                                                      │
│  Nom de fichier *                                   │
│  ┌────────────────────────────────────────────────┐ │
│  │ test-master.zone                                │ │
│  └────────────────────────────────────────────────┘ │
│                                                      │
│  Type *                                             │
│  ┌────────────────────────────────────────────────┐ │
│  │ Master                       [DISABLED]         │ │
│  └────────────────────────────────────────────────┘ │
│  ℹ️ Les zones master sont créées via "Nouvelle     │
│     zone". Les includes sont créés depuis le        │
│     modal d'édition d'une zone.                     │
│                                                      │
│  Contenu                                            │
│  ┌────────────────────────────────────────────────┐ │
│  │                                                 │ │
│  │  ; Zone content here...                        │ │
│  │                                                 │ │
│  └────────────────────────────────────────────────┘ │
│                                                      │
├──────────────────────────────────────────────────────┤
│                  [Annuler]  [Créer]                  │
└──────────────────────────────────────────────────────┘
```

### 2. Zone Edit Modal - Details Tab

```
┌────────────────────────────────────────────────────────────┐
│ example.com                                             ✕  │
├────────────────────────────────────────────────────────────┤
│ [Détails]  Éditeur  Includes                               │
├────────────────────────────────────────────────────────────┤
│                                                            │
│  Nom *                    │  Type                         │
│  ┌─────────────────────┐  │  ┌──────────────────┐        │
│  │ example.com         │  │  │ Master [DISABLED]│        │
│  └─────────────────────┘  │  └──────────────────┘        │
│                           │                               │
│  Nom de fichier *         │  Statut                       │
│  ┌─────────────────────┐  │  ┌──────────────────┐        │
│  │ example.com.zone    │  │  │ Actif      ▼    │        │
│  └─────────────────────┘  │  └──────────────────┘        │
│                                                            │
│  [Only for includes:]                                      │
│  Parent                                                    │
│  ┌──────────────────────────────────────────────┐         │
│  │ other-master (master)              ▼        │         │
│  └──────────────────────────────────────────────┘         │
│  ℹ️ Vous pouvez réassigner cet include à un autre parent │
│                                                            │
├────────────────────────────────────────────────────────────┤
│        [Supprimer]    [Annuler]    [Enregistrer]          │
└────────────────────────────────────────────────────────────┘
```

### 3. Zone Edit Modal - Editor Tab

```
┌────────────────────────────────────────────────────────────┐
│ example.com                                             ✕  │
├────────────────────────────────────────────────────────────┤
│ Détails  [Éditeur]  Includes                               │
├────────────────────────────────────────────────────────────┤
│                                                            │
│  Contenu du fichier de zone                               │
│  ┌──────────────────────────────────────────────────────┐ │
│  │ $TTL 86400                                           │ │
│  │ @    IN    SOA    ns1.example.com. ...              │ │
│  │                                                      │ │
│  │      IN    NS     ns1.example.com.                  │ │
│  │      IN    NS     ns2.example.com.                  │ │
│  │                                                      │ │
│  │ ns1  IN    A      192.0.2.1                         │ │
│  │ ns2  IN    A      192.0.2.2                         │ │
│  │                                                      │ │
│  │ $INCLUDE /etc/bind/includes/common-records.conf     │ │
│  │                                                      │ │
│  └──────────────────────────────────────────────────────┘ │
│                                                            │
├────────────────────────────────────────────────────────────┤
│        [Supprimer]    [Annuler]    [Enregistrer]          │
└────────────────────────────────────────────────────────────┘
```

### 4. Zone Edit Modal - Includes Tab

```
┌────────────────────────────────────────────────────────────┐
│ example.com                                             ✕  │
├────────────────────────────────────────────────────────────┤
│ Détails  Éditeur  [Includes]                               │
├────────────────────────────────────────────────────────────┤
│                                                            │
│  Fichiers inclus dans cette zone    [+ Créer un include]  │
│                                                            │
│  ┌──────────────────────────────────────────────────────┐ │
│  │ common-records                           Position: 0 │ │
│  │ common-records.conf                               ✕  │ │
│  └──────────────────────────────────────────────────────┘ │
│                                                            │
│  ┌──────────────────────────────────────────────────────┐ │
│  │ additional-mx                                Position: 1│
│  │ additional-mx.conf                                 ✕  │ │
│  └──────────────────────────────────────────────────────┘ │
│                                                            │
│  [When "Créer un include" is clicked:]                    │
│  ┌────────────────────────────────────────────────────┐   │
│  │ Créer un nouvel include                            │   │
│  │                                                    │   │
│  │ Nom *                                              │   │
│  │ ┌──────────────────────────────────────────────┐  │   │
│  │ │ new-include                                   │  │   │
│  │ └──────────────────────────────────────────────┘  │   │
│  │                                                    │   │
│  │ Nom de fichier *                                   │   │
│  │ ┌──────────────────────────────────────────────┐  │   │
│  │ │ new-include.conf                              │  │   │
│  │ └──────────────────────────────────────────────┘  │   │
│  │                                                    │   │
│  │ Contenu                                            │   │
│  │ ┌──────────────────────────────────────────────┐  │   │
│  │ │ ; include content                             │  │   │
│  │ └──────────────────────────────────────────────┘  │   │
│  │                                                    │   │
│  │         [Annuler]  [Créer et assigner]            │   │
│  └────────────────────────────────────────────────────┘   │
│                                                            │
├────────────────────────────────────────────────────────────┤
│        [Supprimer]    [Annuler]    [Enregistrer]          │
└────────────────────────────────────────────────────────────┘
```

## User Flows

### Flow 1: Create New Master Zone
```
1. Click "Nouvelle zone" button
   ↓
2. Modal opens with Type=Master (disabled)
   ↓
3. Fill in Name and Filename
   ↓
4. Click "Créer"
   ↓
5. Zone created and modal switches to edit view
```

### Flow 2: Edit Existing Zone
```
1. Click any row in table
   ↓
2. Modal opens with zone data
   ↓
3. Switch between tabs to edit
   ↓
4. Click "Enregistrer" to save
   ↓
5. Modal closes, table refreshes
```

### Flow 3: Create Include from Parent
```
1. Open parent zone (click row)
   ↓
2. Switch to "Includes" tab
   ↓
3. Click "Créer un include"
   ↓
4. Form appears inline
   ↓
5. Fill in details and click "Créer et assigner"
   ↓
6. Include created and assigned to parent
   ↓
7. Includes list refreshes
```

### Flow 4: Reassign Include
```
1. Open include zone (click row)
   ↓
2. Details tab shows Parent dropdown
   ↓
3. Select different parent from dropdown
   ↓
4. Click "Enregistrer"
   ↓
5. Include reassigned, history created
   ↓
6. Modal closes, table refreshes
```

### Flow 5: Delete Zone (Soft)
```
1. Open zone (click row)
   ↓
2. Click "Supprimer" (red button)
   ↓
3. Confirmation dialog appears
   ↓
4. Click "OK"
   ↓
5. Status changed to "deleted"
   ↓
6. Zone removed from list, history created
```

## Key UI Improvements

### ✅ Better UX
- **No page navigation** - everything in modals
- **Faster interactions** - instant modal opening
- **Clear hierarchy** - Parent column shows relationships
- **One-click access** - click row to edit
- **Contextual actions** - only relevant options shown

### ✅ Cleaner Interface
- **No per-row buttons** - cleaner table
- **Grouped actions** - all actions in modal footer
- **Better organization** - tabs separate concerns
- **Inline forms** - create includes without new modal

### ✅ Enhanced Functionality
- **Parent reassignment** - easy to change relationships
- **Cycle prevention** - automatic validation
- **Unsaved changes** - prevents data loss
- **History tracking** - full audit trail
- **Single-parent enforcement** - data integrity

## Color Scheme

```
Primary:   #007bff (Blue) - Save, Create buttons
Secondary: #6c757d (Gray) - Cancel buttons  
Danger:    #dc3545 (Red)  - Delete button
Success:   #28a745 (Green) - Active status
Warning:   #ffc107 (Yellow) - Inactive status
Info:      #17a2b8 (Cyan) - Include badge
```

## Responsive Design

The modal and table are fully responsive:
- Desktop: Full modal width
- Tablet: Slightly narrower modal
- Mobile: Full-width modal, stacked form fields
