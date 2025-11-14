# Admin UI Overview

## Interface Layout

The admin interface (`admin.php`) provides a tabbed interface with four main sections:

```
┌─────────────────────────────────────────────────────────────────┐
│  DNS3 - Gestion du DNS                                [admin] [✕]│
├─────────────────────────────────────────────────────────────────┤
│  Accueil | DNS | Administration | Services | À propos           │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  Administration                                                   │
│  ┌────────────┬────────┬─────────────────┬─────┐                │
│  │ Utilisateurs│ Rôles │ Mappings AD/LDAP│ ACL │                │
│  └────────────┴────────┴─────────────────┴─────┘                │
│                                                                   │
│  [Active Tab Content]                                            │
│                                                                   │
└─────────────────────────────────────────────────────────────────┘
```

## Tab 1: Utilisateurs (Users)

### Layout
```
┌─────────────────────────────────────────────────────────────────┐
│ Gestion des Utilisateurs                    [+ Créer un utilisateur]│
├─────────────────────────────────────────────────────────────────┤
│ Filters:                                                         │
│ [Search username...] [Auth method ▼] [Status ▼] [Filtrer] [Réinitialiser]│
├─────────────────────────────────────────────────────────────────┤
│ ID │ Username │ Email │ Auth │ Rôles │ Statut │ Créé │ Actions │
├────┼──────────┼───────┼──────┼───────┼────────┼──────┼─────────┤
│ 1  │ admin    │ admin@│[DB]  │[admin]│[Actif] │ Jan 1│[Modifier]│
│ 2  │ jdoe     │ j@ex  │[AD]  │[user] │[Actif] │ Jan 2│[Modifier]│
│ 3  │ ldap_usr │ l@ex  │[LDAP]│[user] │[Inact] │ Jan 3│[Modifier]│
└────┴──────────┴───────┴──────┴───────┴────────┴──────┴─────────┘
```

### Features
- **Filter by:**
  - Username (text search)
  - Authentication method (database/AD/LDAP)
  - Status (active/inactive)
- **Badge colors:**
  - `[admin]` - Red badge
  - `[user]` - Blue badge
  - `[Actif]` - Green badge
  - `[Inactif]` - Gray badge
  - `[DB]` - Teal badge
  - `[AD]` - Purple badge
  - `[LDAP]` - Orange badge

### Create/Edit User Modal
```
┌────────────────────────────────────────┐
│ Créer un utilisateur              [×]  │
├────────────────────────────────────────┤
│                                        │
│ Nom d'utilisateur *                   │
│ [_________________________________]   │
│                                        │
│ Email *                                │
│ [_________________________________]   │
│                                        │
│ Méthode d'authentification *           │
│ [Base de données            ▼]        │
│                                        │
│ Mot de passe *                         │
│ [_________________________________]   │
│ Laissez vide pour ne pas modifier     │
│                                        │
│ Statut                                 │
│ [Actif                      ▼]        │
│                                        │
│ Rôles                                  │
│ ☐ admin - Administrator - full access │
│ ☑ user - Regular user - read only     │
│                                        │
├────────────────────────────────────────┤
│                    [Annuler] [Enregistrer]│
└────────────────────────────────────────┘
```

**Note:** Password field is hidden for AD/LDAP auth methods

## Tab 2: Rôles (Roles)

### Layout
```
┌─────────────────────────────────────────────────────────────┐
│ Rôles Disponibles                                           │
├─────────────────────────────────────────────────────────────┤
│ ID │ Nom     │ Description                    │ Créé le    │
├────┼─────────┼────────────────────────────────┼────────────┤
│ 1  │ [admin] │ Administrator - full access    │ Jan 1 2024 │
│ 2  │ [user]  │ Regular user - read only       │ Jan 1 2024 │
└────┴─────────┴────────────────────────────────┴────────────┘
```

### Features
- Read-only view of available roles
- Shows role name with badge
- Description and creation date

## Tab 3: Mappings AD/LDAP

### Layout
```
┌─────────────────────────────────────────────────────────────────┐
│ Mappings AD/LDAP                          [+ Créer un mapping]  │
├─────────────────────────────────────────────────────────────────┤
│ ℹ Mappings AD/LDAP permettent d'attribuer automatiquement des  │
│   rôles aux utilisateurs lors de l'authentification basée sur   │
│   leur groupe AD ou DN LDAP.                                    │
│   AD: CN=DNSAdmins,OU=Groups,DC=example,DC=com                 │
│   LDAP: ou=IT,dc=example,dc=com                                │
├─────────────────────────────────────────────────────────────────┤
│ ID │ Source │ DN/Groupe              │ Rôle    │ Créé par │ Notes│ Actions│
├────┼────────┼────────────────────────┼─────────┼──────────┼──────┼────────┤
│ 1  │ [AD]   │ CN=DNSAdmins,OU=...   │ [admin] │ admin    │ DNS  │[Supprimer]│
│ 2  │ [LDAP] │ ou=IT,dc=example...   │ [user]  │ admin    │ IT   │[Supprimer]│
└────┴────────┴────────────────────────┴─────────┴──────────┴──────┴────────┘
```

### Create Mapping Modal
```
┌────────────────────────────────────────┐
│ Créer un mapping AD/LDAP          [×]  │
├────────────────────────────────────────┤
│                                        │
│ Source *                               │
│ [Active Directory           ▼]        │
│                                        │
│ DN/Groupe *                            │
│ [CN=DNSAdmins,OU=Groups,DC=ex...]     │
│ AD: DN complet du groupe               │
│ LDAP: DN ou chemin OU                  │
│                                        │
│ Rôle *                                 │
│ [admin - Administrator      ▼]        │
│                                        │
│ Notes                                  │
│ [________________________________]    │
│ [________________________________]    │
│ [________________________________]    │
│                                        │
├────────────────────────────────────────┤
│                    [Annuler] [Créer]   │
└────────────────────────────────────────┘
```

### Features
- Create mappings between AD groups/LDAP DNs and roles
- Delete existing mappings
- Add optional notes for documentation
- Validation prevents duplicate mappings

## Tab 4: ACL

### Layout
```
┌─────────────────────────────────────────────────────────────┐
│ Liste de Contrôle d'Accès (ACL)                             │
├─────────────────────────────────────────────────────────────┤
│ ℹ ACL permet de définir des permissions granulaires sur les │
│   ressources DNS.                                            │
│   Cette fonctionnalité sera implémentée dans une version    │
│   future.                                                    │
└─────────────────────────────────────────────────────────────┘
```

### Features
- Placeholder for future ACL management
- Reserved for granular DNS resource permissions

## Color Scheme

The interface uses a consistent color scheme:

```
Primary:    #3498db (Blue)    - Primary buttons, active tabs
Secondary:  #95a5a6 (Gray)    - Secondary buttons
Success:    #27ae60 (Green)   - Active status, success messages
Danger:     #e74c3c (Red)     - Delete buttons, admin badges, errors
Warning:    #f39c12 (Orange)  - Edit buttons, LDAP badges
Info:       #3498db (Blue)    - User badges, info boxes
Purple:     #9b59b6           - AD badges
Teal:       #16a085           - Database badges

Text:       #2c3e50 (Dark)    - Primary text
Light:      #ecf0f1           - Table borders, backgrounds
```

## Responsive Design

The interface is responsive and adapts to different screen sizes:

- **Desktop (> 1200px):** Full layout with all columns visible
- **Tablet (768px - 1200px):** Tables scroll horizontally if needed
- **Mobile (< 768px):** Stacked layout, single column forms

## User Experience Features

### Notifications
```
┌────────────────────────────────────┐
│ ✓ Utilisateur créé avec succès    │  (Green, auto-dismiss after 3s)
└────────────────────────────────────┘

┌────────────────────────────────────┐
│ ✗ Erreur: Username déjà existant  │  (Red, auto-dismiss after 3s)
└────────────────────────────────────┘
```

### Loading States
- Tables show "Chargement..." while fetching data
- Buttons disabled during form submission

### Validation
- Required fields marked with asterisk (*)
- Client-side validation before submission
- Server-side validation with meaningful error messages
- Real-time feedback for auth method changes

### Accessibility
- Proper ARIA labels
- Keyboard navigation support
- Focus management in modals
- Semantic HTML structure

## Keyboard Shortcuts

- **Escape:** Close active modal
- **Enter:** Submit active form (when in input field)
- **Tab:** Navigate between form fields

## API Integration

All UI actions call the secure API:

```
User Action                  → API Call
────────────────────────────────────────────────────────
Click "Créer un utilisateur" → Open modal (load roles)
Submit user form             → POST /api/admin_api.php?action=create_user
Click "Modifier"             → GET /api/admin_api.php?action=get_user&id=X
                              → Open modal with user data
Click "Filtrer"              → GET /api/admin_api.php?action=list_users&filters...
Switch to "Rôles" tab        → GET /api/admin_api.php?action=list_roles
Click "Créer un mapping"     → Open modal (load roles)
Submit mapping form          → POST /api/admin_api.php?action=create_mapping
Click "Supprimer" (mapping)  → Confirm → POST /api/admin_api.php?action=delete_mapping&id=X
```

## Browser Compatibility

Tested and compatible with:
- ✅ Chrome 90+
- ✅ Firefox 88+
- ✅ Safari 14+
- ✅ Edge 90+

Uses modern JavaScript (ES6+) features:
- Arrow functions
- Async/await
- Fetch API
- Template literals
- Destructuring

## Performance

- Lazy loading of data (only loads when tab is active)
- Efficient DOM updates
- Minimal HTTP requests
- Client-side filtering for quick search
- Cached role data to avoid redundant API calls

## Security Indicators

The interface provides visual security indicators:

- 🔒 Admin-only access enforced server-side
- 🔑 Password fields use type="password" (masked input)
- ⚠️ Confirmation dialog before deletion
- 📝 Audit trail shown (created by, created at)
- 🚫 Clear error messages without sensitive data exposure
