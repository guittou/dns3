# Zone File Generation - UI Changes Visual Guide

## 📱 User Interface Changes

### 1. Zone List Table - BEFORE
```
┌─────────────────────────────────────────────────────────────────────────────┐
│ Zone      │ Type   │ Filename  │ Parent │ # Includes │ Owner │ Status │ ... │
├─────────────────────────────────────────────────────────────────────────────┤
│ example.com│ Master │ ex.zone   │   -    │     3      │ admin │ Active │ ... │
│ common.conf│ Include│ common.cf │ ex.com │     0      │ admin │ Active │ ... │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 1. Zone List Table - AFTER ✅
```
┌──────────────────────────────────────────────────────────────────────┐
│ Zone      │ Type   │ Filename  │ Parent │ Owner │ Status │ Modified │
├──────────────────────────────────────────────────────────────────────┤
│ example.com│ Master │ ex.zone   │   -    │ admin │ Active │ 10/21   │
│ common.conf│ Include│ common.cf │ ex.com │ admin │ Active │ 10/20   │
└──────────────────────────────────────────────────────────────────────┘
```
**Change**: Removed "# Includes" column ✓

---

### 2. Zone Edit Modal - Details Tab - BEFORE
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

### 2. Zone Edit Modal - Details Tab - AFTER ✅
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
**Change**: Added "Répertoire" field (only in modal, not in table) ✓

---

### 3. Zone Edit Modal - Editor Tab - BEFORE
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

### 3. Zone Edit Modal - Editor Tab - AFTER ✅
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
**Change**: Added "Générer le fichier de zone" button ✓

---

## 🎬 User Flow for Zone Generation

### Step 1: Open Zone
```
User clicks on zone row in table
    ↓
Modal opens showing zone details
```

### Step 2: Set Directory (Optional)
```
User goes to "Détails" tab
    ↓
Enters directory: /etc/bind/zones
    ↓
Clicks "Enregistrer"
```

### Step 3: Generate Zone File
```
User goes to "Éditeur" tab
    ↓
Clicks "Générer le fichier de zone" button
    ↓
Prompt: "Voulez-vous télécharger le fichier?"
    ├─ OUI → File downloads as "example.com.zone"
    └─ NON → Content shown in editor for preview
```

---

## 📄 Generated Zone File Example

### Input Configuration
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

## 🔄 Data Flow

```
┌─────────────────┐
│   User clicks   │
│  "Générer..."   │
└────────┬────────┘
         ↓
┌─────────────────┐
│   JavaScript    │
│ generates API   │
│      call       │
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
│  1. Get zone content                │
│  2. Get includes (with directory)   │
│  3. Get DNS records                 │
│  4. Format as BIND syntax           │
└────────┬────────────────────────────┘
         ↓
┌─────────────────┐
│   Return JSON   │
│   with content  │
└────────┬────────┘
         ↓
┌─────────────────┐
│   JavaScript    │
│  shows prompt   │
└────────┬────────┘
         ↓
    ┌────┴────┐
    ↓         ↓
[Download]  [Preview]
```

---

## ✅ Requirements Verification

| Requirement | Status | Notes |
|------------|--------|-------|
| Add directory column | ✅ | Via migration 010 |
| Directory in modal only | ✅ | Not in table view |
| Remove "# Includes" column | ✅ | From table view |
| Generate button | ✅ | In Editor tab |
| $INCLUDE directives | ✅ | Uses directory/filename |
| DNS records in BIND | ✅ | All types supported |
| Includes NOT inlined | ✅ | Uses $INCLUDE |
| Download/preview | ✅ | User choice |

---

## 🎨 Visual Elements Added

### New Field in Modal
- **Label**: "Répertoire"
- **Type**: Text input
- **Placeholder**: "Exemple: /etc/bind/zones"
- **Help text**: "Répertoire pour les directives $INCLUDE (optionnel)"

### New Button in Modal
- **Icon**: 📄 (file-code)
- **Text**: "Générer le fichier de zone"
- **Style**: btn btn-secondary
- **Help text**: "Génère le contenu complet avec les directives $INCLUDE et les enregistrements DNS"

---

## 📱 Responsive Design

All changes maintain the existing responsive design:
- Modal remains centered and scrollable
- Form fields stack properly on mobile
- Button is full-width on small screens
- Table columns adjust as before (minus one column)

---

**End of Visual Guide**
