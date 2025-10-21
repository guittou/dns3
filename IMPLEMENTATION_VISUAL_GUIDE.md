# Zone Files Management - Visual Implementation Guide

## UI Layout

```
┌─────────────────────────────────────────────────────────────────┐
│  [DNS3]  Home  Services  About  DNS Management  Zones  Admin    │
│                                                    [Logout]      │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│  Gestion des fichiers de zone         [+ Nouvelle zone]         │
└─────────────────────────────────────────────────────────────────┘

┌──────────────────┬──────────────────────────────────────────────┐
│ Left Pane        │ Right Pane                                   │
│ (350px)          │ (flex)                                       │
├──────────────────┼──────────────────────────────────────────────┤
│ ┌──────────────┐ │ ┌──────────────────────────────────────────┐ │
│ │ [Search...]  │ │ │  example.com                    [🔄] [🗑] │ │
│ │ [Type ▼]     │ │ └──────────────────────────────────────────┘ │
│ │ [Status ▼]   │ │                                              │
│ └──────────────┘ │ ┌──────────────────────────────────────────┐ │
│                  │ │ [Détails] [Éditeur] [Includes] [Historique]│
│ Masters          │ └──────────────────────────────────────────┘ │
│ ┌──────────────┐ │                                              │
│ │ example.com  │◄┼─ Selected                                    │
│ │ db.example   │ │ ┌──────────────────────────────────────────┐ │
│ │ active       │ │ │ Details Tab (Active)                     │ │
│ └──────────────┘ │ │                                          │ │
│ ┌──────────────┐ │ │ Nom: [example.com____________]           │ │
│ │ example.net  │ │ │ Fichier: [db.example.com_____]           │ │
│ │ db.example.n │ │ │ Type: [Master ▼]                         │ │
│ │ active       │ │ │ Statut: [Active ▼]                       │ │
│ └──────────────┘ │ │                                          │ │
│                  │ │ Créé par: admin (2025-10-21 10:00)       │ │
│ Includes         │ │ Modifié par: admin (2025-10-21 10:30)    │ │
│ ┌──────────────┐ │ │                                          │ │
│ │ common-ns    │ │ │ [Enregistrer] [Annuler]                  │ │
│ │ db.common-ns │ │ └──────────────────────────────────────────┘ │
│ │ active       │ │                                              │
│ └──────────────┘ │                                              │
│ ┌──────────────┐ │                                              │
│ │ app-web      │ │                                              │
│ │ db.app-web   │ │                                              │
│ │ active       │ │                                              │
│ └──────────────┘ │                                              │
└──────────────────┴──────────────────────────────────────────────┘
```

## Editor Tab

```
┌──────────────────────────────────────────────────────────────────┐
│ [⬇ Télécharger] [👁 Voir le contenu résolu]                      │
├──────────────────────────────────────────────────────────────────┤
│ ┌──────────────────────────────────────────────────────────────┐ │
│ │ ; Zone file for example.com                                  │ │
│ │ $TTL 3600                                                     │ │
│ │ @       IN SOA  ns1.example.com. admin.example.com. (        │ │
│ │                 2025102101 ; Serial                          │ │
│ │                 3600       ; Refresh                         │ │
│ │                 1800       ; Retry                           │ │
│ │                 604800     ; Expire                          │ │
│ │                 86400 )    ; Minimum TTL                     │ │
│ │                                                              │ │
│ │ ; Name servers                                               │ │
│ │ @       IN NS   ns1.example.com.                            │ │
│ │ @       IN NS   ns2.example.com.                            │ │
│ │                                                              │ │
│ │ ; A records                                                  │ │
│ │ @       IN A    192.168.1.1                                 │ │
│ │ www     IN A    192.168.1.2                                 │ │
│ │                                                              │ │
│ └──────────────────────────────────────────────────────────────┘ │
│                                                                  │
│                                      [Enregistrer le contenu]    │
└──────────────────────────────────────────────────────────────────┘
```

## Includes Tab - Tree View

```
┌──────────────────────────────────────────────────────────────────┐
│ Arborescence des includes              [+ Ajouter include]       │
├──────────────────────────────────────────────────────────────────┤
│ ┌──────────────────────────────────────────────────────────────┐ │
│ │ 📁 example.com [master]                                      │ │
│ │ ├── 📄 common-ns [include] [pos: 0] [❌]                     │ │
│ │ │   ├── 📄 ns-primary [include] [pos: 0] [❌]               │ │
│ │ │   └── 📄 ns-secondary [include] [pos: 1] [❌]             │ │
│ │ ├── 📄 common-mx [include] [pos: 1] [❌]                     │ │
│ │ │   └── 📄 mx-backup [include] [pos: 0] [❌]                │ │
│ │ └── 📄 app-web [include] [pos: 2] [❌]                       │ │
│ │     ├── 📄 web-frontend [include] [pos: 0] [❌]             │ │
│ │     └── 📄 web-backend [include] [pos: 1] [❌]              │ │
│ └──────────────────────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────────────────────┘
```

## History Tab

```
┌──────────────────────────────────────────────────────────────────┐
│ ┌──────────────────────────────────────────────────────────────┐ │
│ │ STATUS_CHANGED                       2025-10-21 10:30:00     │ │
│ ├──────────────────────────────────────────────────────────────┤ │
│ │ Par: admin                                                   │ │
│ │ Ancien statut: inactive                                      │ │
│ │ Nouveau statut: active                                       │ │
│ │ Notes: Status changed from inactive to active                │ │
│ └──────────────────────────────────────────────────────────────┘ │
│                                                                  │
│ ┌──────────────────────────────────────────────────────────────┐ │
│ │ CONTENT_CHANGED                      2025-10-21 10:15:00     │ │
│ ├──────────────────────────────────────────────────────────────┤ │
│ │ Par: admin                                                   │ │
│ │ Ancien statut: active                                        │ │
│ │ Nouveau statut: active                                       │ │
│ │ Notes: Zone file updated                                     │ │
│ └──────────────────────────────────────────────────────────────┘ │
│                                                                  │
│ ┌──────────────────────────────────────────────────────────────┐ │
│ │ CREATED                              2025-10-21 10:00:00     │ │
│ ├──────────────────────────────────────────────────────────────┤ │
│ │ Par: admin                                                   │ │
│ │ Nouveau statut: active                                       │ │
│ │ Notes: Zone file created                                     │ │
│ └──────────────────────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────────────────────┘
```

## Modal: Create Zone

```
                    ┌────────────────────────┐
                    │ Créer une nouvelle zone │  [×]
                    ├────────────────────────┤
                    │                        │
                    │ Nom *                  │
                    │ [example.org_________] │
                    │                        │
                    │ Nom de fichier *       │
                    │ [db.example.org______] │
                    │                        │
                    │ Type *                 │
                    │ [Master ▼]             │
                    │                        │
                    │ Contenu                │
                    │ ┌────────────────────┐ │
                    │ │                    │ │
                    │ │                    │ │
                    │ │                    │ │
                    │ │                    │ │
                    │ └────────────────────┘ │
                    │                        │
                    │    [Annuler] [Créer]   │
                    └────────────────────────┘
```

## Modal: Add Include

```
                    ┌────────────────────────┐
                    │  Ajouter un include    │  [×]
                    ├────────────────────────┤
                    │                        │
                    │ Sélectionner un        │
                    │ fichier include *      │
                    │ [-- Choisir -- ▼]      │
                    │   common-ns            │
                    │   common-mx            │
                    │   app-web              │
                    │   ...                  │
                    │                        │
                    │ Position (ordre)       │
                    │ [0__________]          │
                    │                        │
                    │   [Annuler] [Ajouter]  │
                    └────────────────────────┘
```

## Modal: Resolved Content

```
    ┌──────────────────────────────────────────────────────┐
    │  Contenu résolu (avec includes)                 [×]  │
    ├──────────────────────────────────────────────────────┤
    │ ┌──────────────────────────────────────────────────┐ │
    │ │ ; Zone: example.com (db.example.com)             │ │
    │ │ ; Type: master                                   │ │
    │ │ ; Generated: 2025-10-21 10:45:00                 │ │
    │ │                                                  │ │
    │ │ $TTL 3600                                        │ │
    │ │ @  IN SOA ns1.example.com. admin.example.com. ( │ │
    │ │         2025102101 ; Serial                      │ │
    │ │         ...                                      │ │
    │ │                                                  │ │
    │ │ ; Including: common-ns (db.common-ns)           │ │
    │ │ ; Zone: common-ns (db.common-ns)                │ │
    │ │ ; Type: include                                 │ │
    │ │ ; Generated: 2025-10-21 10:45:00                │ │
    │ │                                                  │ │
    │ │ @  IN NS  ns1.example.com.                      │ │
    │ │ @  IN NS  ns2.example.com.                      │ │
    │ │                                                  │ │
    │ │ ; Including: ns-primary (db.ns-primary)         │ │
    │ │ ; Zone: ns-primary (db.ns-primary)              │ │
    │ │ ; Type: include                                 │ │
    │ │ ; Generated: 2025-10-21 10:45:00                │ │
    │ │                                                  │ │
    │ │ ns1  IN A  192.168.1.10                         │ │
    │ │                                                  │ │
    │ │ ...                                             │ │
    │ └──────────────────────────────────────────────────┘ │
    │                                                      │
    │                                      [Fermer]        │
    └──────────────────────────────────────────────────────┘
```

## Cycle Detection - Error Display

When attempting to create a cycle:

```
┌─────────────────────────────────────────────────────────┐
│  ⚠️ Erreur                                              │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  Erreur lors de l'ajout de l'include:                  │
│                                                         │
│  Cannot create circular dependency: this would create   │
│  a cycle in the include tree                           │
│                                                         │
│                                            [OK]         │
└─────────────────────────────────────────────────────────┘
```

## Flow Diagrams

### Creating a Zone with Includes

```
┌──────────┐
│  Admin   │
│  User    │
└────┬─────┘
     │
     │ 1. Click "Nouvelle zone"
     ▼
┌──────────────────┐
│ Create Zone Modal│
└────┬─────────────┘
     │
     │ 2. Fill: name, filename, type, content
     │ 3. Click "Créer"
     ▼
┌─────────────┐        ┌──────────────┐
│  API POST   │───────▶│  zone_api.php│
│ create_zone │        │  create()    │
└─────────────┘        └──────┬───────┘
                              │
                              │ 4. Insert into zone_files
                              │ 5. Write to history
                              ▼
                       ┌──────────────┐
                       │  Database    │
                       └──────┬───────┘
                              │
                              │ 6. Return new ID
                              ▼
                       ┌──────────────┐
                       │ Refresh list │
                       │ Load details │
                       └──────────────┘
```

### Adding an Include (with Cycle Detection)

```
┌──────────┐
│  Admin   │
└────┬─────┘
     │
     │ 1. Select zone, go to Includes tab
     │ 2. Click "Ajouter include"
     ▼
┌────────────────────┐
│ Add Include Modal  │
└────┬───────────────┘
     │
     │ 3. Select include & position
     │ 4. Click "Ajouter"
     ▼
┌──────────────┐        ┌────────────────────┐
│  API POST    │───────▶│  zone_api.php      │
│assign_include│        │  assignInclude()   │
└──────────────┘        └─────┬──────────────┘
                              │
                              │ 5. Validate: not self-include
                              │ 6. Validate: is include type
                              │ 7. Check cycle: hasAncestor()
                              ▼
                       ┌────────────────┐
                       │ Cycle detected?│
                       └─────┬──────────┘
                             │
                    ┌────────┴────────┐
                    │                 │
                YES │                 │ NO
                    ▼                 ▼
            ┌───────────────┐  ┌──────────────┐
            │ Return HTTP   │  │ INSERT INTO  │
            │ 400 + error   │  │ zone_file_   │
            │ message       │  │ includes     │
            └───────────────┘  └──────┬───────┘
                    │                 │
                    │                 │
                    └────────┬────────┘
                             │
                             ▼
                    ┌─────────────────┐
                    │ Refresh tree    │
                    │ Show result     │
                    └─────────────────┘
```

### Viewing Resolved Content

```
┌──────────┐
│  Admin   │
└────┬─────┘
     │
     │ 1. Go to Editor tab
     │ 2. Click "Voir le contenu résolu"
     ▼
┌──────────────┐        ┌────────────────────┐
│  API GET     │───────▶│  zone_api.php      │
│render_resolved        │  renderResolved()  │
└──────────────┘        └─────┬──────────────┘
                              │
                              │ 3. Get zone info
                              │ 4. Get includes (ordered)
                              ▼
                       ┌────────────────┐
                       │ For each include│
                       │ (recursive):   │
                       └─────┬──────────┘
                             │
                             │ 5. Add comment header
                             │ 6. Add zone content
                             │ 7. Recurse into includes
                             │ 8. Detect cycles (visited array)
                             ▼
                       ┌────────────────┐
                       │ Return complete│
                       │ flattened text │
                       └─────┬──────────┘
                             │
                             ▼
                       ┌────────────────┐
                       │ Display in     │
                       │ modal popup    │
                       └────────────────┘
```

## Color Scheme

- **Active zones**: Green (#28a745)
- **Inactive zones**: Yellow/Orange (#ffc107)  
- **Deleted zones**: Red (#dc3545)
- **Primary actions**: Blue (#007bff)
- **Danger actions**: Red (#dc3545)
- **Info actions**: Cyan (#17a2b8)
- **Borders**: Light gray (#ddd)
- **Background**: White / Light gray (#f5f5f5)

## Responsive Behavior

### Desktop (>768px)
- Split pane side-by-side
- Left: 350px fixed width
- Right: Flexible width
- All features visible

### Mobile (<768px)
- Stacked layout (left above right)
- Full width for both panes
- Scrollable zones list
- Touch-friendly buttons
- Modals full-width with margins

## Key Interactions

1. **Click zone in list** → Load details in right pane
2. **Switch tabs** → Load tab-specific content
3. **Edit metadata** → Save button active
4. **Edit content** → Separate save button
5. **Add include** → Modal → Select → Position → Add
6. **Remove include** → Confirm → Remove from tree
7. **View resolved** → Modal with flattened content
8. **Create zone** → Modal → Form → Create
9. **Search/filter** → Real-time list updates

## Error Handling

- **API errors**: Alert with error message
- **Validation errors**: HTTP 400 with description
- **Cycle detection**: Clear message about circular dependency
- **Not found**: HTTP 404 with error
- **Unauthorized**: HTTP 403 with error
- **Server errors**: HTTP 500 with generic message

## Performance Considerations

- **Lazy loading**: Tree only loaded when Includes tab opened
- **Pagination**: Zone list limited to 1000 (configurable)
- **Caching**: Current zone cached in window.currentZoneId
- **Debouncing**: Search input debounced for filtering
- **Efficient queries**: Uses indexes on parent_id, include_id
- **Transaction safety**: All writes in transactions

This visual guide complements the technical documentation and provides a clear picture of the user interface and data flows.
