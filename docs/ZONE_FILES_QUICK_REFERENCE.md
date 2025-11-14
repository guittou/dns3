# Zone Files Management - Quick Start Guide

## Overview

The Zone Files Management interface provides a complete solution for managing DNS zone files with support for recursive includes and automatic cycle detection.

## Accessing the Interface

1. Log in as an administrator
2. Click on the "Zones" tab in the navigation menu
3. You'll see the zone management interface with a split-pane layout

## Interface Layout

### Left Pane - Zone List
- **Search Bar**: Filter zones by name or filename
- **Type Filter**: Filter by Master or Include
- **Status Filter**: Show Active, Inactive, or Deleted zones
- **Master Zones**: List of master zone files
- **Include Zones**: List of include zone files
- Click any zone to view/edit its details

### Right Pane - Zone Details (4 Tabs)

#### 1. Details Tab
- Edit zone metadata: Name, Filename, Type, Status
- View creation and modification info
- Save changes with the "Enregistrer" button

#### 2. Editor Tab
- Edit zone file content in a large textarea
- **Download**: Download the zone file content
- **View Resolved Content**: See the complete content with all includes flattened
- **Save Content**: Save changes to the zone content

#### 3. Includes Tab
- View recursive tree of includes
- **Add Include**: Add a new include file to the current zone
  - Select from available include files
  - Set position for ordering
- **Remove**: Click the X button on any include to remove it
- Tree shows nested structure with indentation

#### 4. History Tab
- View audit trail of all changes
- Shows action type, user, timestamp, and notes
- Tracks content changes and status changes

## Creating a New Zone

1. Click **"Nouvelle zone"** button (top right)
2. Fill in the form:
   - **Name**: Zone name (e.g., example.com)
   - **Filename**: Zone file name (e.g., db.example.com)
   - **Type**: Select Master or Include
   - **Content**: Optional - add initial zone content
3. Click **"Créer"**

## Working with Recursive Includes

### Adding Includes to a Zone

1. Select a zone (master or include)
2. Go to the **Includes** tab
3. Click **"Ajouter include"**
4. Select an include file from the dropdown
5. Set position (0 = first, higher numbers = later)
6. Click **"Ajouter"**

### Include Tree Hierarchy

Includes can be nested to any depth:
```
Master Zone (example.com)
├── Include A (common-records)
│   ├── Include B (ns-records)
│   └── Include C (mx-records)
└── Include D (app-specific)
    └── Include E (service-records)
```

### Viewing Resolved Content

To see the complete zone file with all includes flattened:

1. Select a zone
2. Go to the **Editor** tab
3. Click **"Voir le contenu résolu"**
4. A modal will show the complete content with comments indicating each include

The resolved content will look like:
```
; Zone: example.com (db.example.com)
; Type: master
; Generated: 2025-10-21 12:00:00

[master zone content]

; Including: common-records (db.common)
[common-records content]

; Including: ns-records (db.ns)
[ns-records content]

...
```

## Cycle Detection

The system automatically prevents circular dependencies:

### What is a Cycle?

A cycle occurs when:
- A zone tries to include itself
- Zone A includes Zone B, and Zone B includes Zone A
- Any circular path: A → B → C → A

### How It Works

When you try to add an include that would create a cycle:
1. The system checks the entire include tree
2. If adding the include would create a cycle, it's rejected
3. You'll see an error: "Cannot create circular dependency"

### Example Scenarios

❌ **Rejected - Self Include:**
```
Zone A tries to include Zone A
→ Error: "Cannot include a zone file in itself"
```

❌ **Rejected - Simple Cycle:**
```
Master → Include A → Include B
Try to add: Master to Include B
→ Error: "Cannot create circular dependency"
```

❌ **Rejected - Complex Cycle:**
```
Zone A → Zone B → Zone C → Zone D
Try to add: Zone D to Zone A
→ Error: "Cannot create circular dependency"
```

✅ **Allowed - Tree Structure:**
```
Master
├── Include A
│   └── Include B
└── Include C
    └── Include D
```

## Position-Based Ordering

The `position` field controls the order of includes:

- Position 0 = First
- Position 1 = Second
- etc.

Includes with the same position are sorted alphabetically by name.

Example:
```
Include A (position 0)
Include B (position 0)  ← alphabetically after A
Include C (position 1)
Include D (position 2)
```

## API Endpoints

The system provides REST API endpoints for programmatic access:

### List Zones
```
GET /api/zone_api.php?action=list_zones&file_type=master&status=active
```

### Get Zone with Includes
```
GET /api/zone_api.php?action=get_zone&id=1
```

### Create Zone
```
POST /api/zone_api.php?action=create_zone
Body: {
  "name": "example.com",
  "filename": "db.example.com",
  "file_type": "master",
  "content": "..."
}
```

### Assign Include (with Cycle Detection)
```
POST /api/zone_api.php?action=assign_include
Body: {
  "parent_id": 1,
  "include_id": 2,
  "position": 0
}

Response on cycle:
{
  "error": "Cannot create circular dependency: this would create a cycle in the include tree"
}
```

### Get Recursive Tree
```
GET /api/zone_api.php?action=get_tree&id=1

Response: {
  "success": true,
  "data": {
    "id": 1,
    "name": "example.com",
    "includes": [
      {
        "id": 2,
        "name": "common-records",
        "position": 0,
        "includes": [...]
      }
    ]
  }
}
```

### Render Resolved Content
```
GET /api/zone_api.php?action=render_resolved&id=1

Response: {
  "success": true,
  "content": "; Zone: example.com\n..."
}
```

## Best Practices

### Zone Organization

1. **Master Zones**: One per domain
2. **Common Includes**: Reusable records (NS, SOA, MX)
3. **Service Includes**: Service-specific records
4. **Application Includes**: Application-specific records

Example structure:
```
Masters:
- example.com
- example.net

Includes:
- common-ns (NS records)
- common-mx (MX records)
- app-web (web server records)
- app-mail (mail server records)
```

### Include Strategy

- Keep includes focused on a single purpose
- Use position to control order (SOA/NS first, others later)
- Don't nest too deeply (3-4 levels max)
- Document the include structure in zone comments

### Content Management

- Use the Editor tab for quick edits
- Use "View Resolved Content" to verify the final zone
- Download zones before major changes
- Review history after changes to verify

## Troubleshooting

### "Cannot create circular dependency"
- Check the include tree to see existing relationships
- Remove conflicting includes before adding new ones
- Remember: includes can include other includes

### Zone Not Showing in DNS Records
- Verify zone status is "active"
- Check zone file_type (master or include)
- Refresh the zone list

### Content Not Saving
- Check that you have admin privileges
- Verify the zone status is not "deleted"
- Check browser console for errors

### Include Tree Not Loading
- Verify the zone has includes assigned
- Check for circular references (should be prevented but could exist from direct DB edits)
- Refresh the page

## Security Notes

- Only administrators can create, edit, or delete zones
- All changes are logged in the history
- Zone file content is stored securely in the database
- API endpoints require authentication
- Cycle detection prevents malicious or accidental loops

## Related Documentation

- `ZONE_FILES_RECURSIVE_IMPLEMENTATION.md` - Technical implementation details
- `ZONE_FILES_TESTING_GUIDE.md` - Comprehensive testing procedures
- `ZONE_FILES_IMPLEMENTATION_SUMMARY.md` - Original implementation summary

## Support

For issues or questions:
1. Check the History tab for recent changes
2. Verify zone status and relationships
3. Review the resolved content to see actual output
4. Check server logs for API errors
