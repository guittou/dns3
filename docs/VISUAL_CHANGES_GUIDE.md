# Visual Changes: Created At / Updated At UI

## Table View Changes

### Before
```
| Nom | TTL | Classe | Type | Valeur | Demandeur | Expire | Vu le | Statut | ID | Actions |
|-----|-----|--------|------|--------|-----------|--------|-------|--------|----|---------| 
```

### After
```
| Nom | TTL | Classe | Type | Valeur | Demandeur | Expire | Vu le | Créé le | Modifié le | Statut | ID | Actions |
|-----|-----|--------|------|--------|-----------|--------|-------|---------|------------|--------|----|---------| 
```

**New Columns:**
- **Créé le**: Displays record creation timestamp (DD/MM/YYYY HH:MM)
- **Modifié le**: Displays last modification timestamp (DD/MM/YYYY HH:MM)

### Example Data Display

```
| Nom                  | ... | Vu le              | Créé le            | Modifié le         | Statut | ... |
|----------------------|-----|--------------------|--------------------|--------------------| -------|-----|
| example.com          | ... | 20/10/2025 14:30   | 15/10/2025 09:15   | 18/10/2025 11:20   | active | ... |
| test.example.com     | ... | -                  | 20/10/2025 08:00   | 20/10/2025 08:00   | active | ... |
| old-record.com       | ... | 10/10/2025 16:45   | 01/10/2025 10:00   | 15/10/2025 14:30   | active | ... |
```

## Modal View Changes

### Create Mode (New Record)

**Fields Visible:**
- Type d'enregistrement
- Nom
- Adresse IPv4/IPv6/etc (depending on type)
- TTL
- Demandeur
- Date d'expiration
- Référence ticket
- Commentaire

**Fields NOT Visible:**
- ❌ Vu pour la dernière fois (hidden - not yet seen)
- ❌ Créé le (hidden - not yet created)
- ❌ Modifié le (hidden - not yet modified)

### Edit Mode (Existing Record)

**Additional Fields Visible:**
- ✓ Vu pour la dernière fois (read-only, if record has been seen)
- ✓ **Créé le** (read-only, shows creation timestamp)
- ✓ **Modifié le** (read-only, shows last modification timestamp)

**Example Modal Content (Edit Mode):**
```
═══════════════════════════════════════════
  Modifier l'enregistrement DNS
═══════════════════════════════════════════

Type d'enregistrement: [A ▼]

Nom: [example.com                        ]

Adresse IPv4: [192.168.1.100             ]

TTL (secondes): [3600]

Demandeur: [Jean Dupont                  ]

Date d'expiration: [2025-12-31T23:59     ]

Référence ticket: [JIRA-1234              ]

Commentaire: [Record for production...   ]

Vu pour la dernière fois: [20/10/2025 14:30]
                          (disabled, read-only)

Créé le: [15/10/2025 09:15]              ← NEW!
         (disabled, read-only)

Modifié le: [18/10/2025 11:20]           ← NEW!
            (disabled, read-only)

                    [Annuler] [Enregistrer]
═══════════════════════════════════════════
```

## Database Changes

### INSERT Statement

**Before:**
```sql
INSERT INTO dns_records (
    record_type, name, value, ..., status, created_by
)
VALUES (?, ?, ?, ..., 'active', ?)
```

**After:**
```sql
INSERT INTO dns_records (
    record_type, name, value, ..., status, created_by, created_at
)
VALUES (?, ?, ?, ..., 'active', ?, NOW())
```

### UPDATE Statement

**No changes required** - already uses `updated_at = NOW()`:
```sql
UPDATE dns_records 
SET record_type = ?, name = ?, value = ?, ..., 
    updated_by = ?, updated_at = NOW()
WHERE id = ?
```

## Security

### Client Request (CREATE)
```json
{
  "record_type": "A",
  "name": "example.com",
  "address_ipv4": "192.168.1.100",
  "ttl": 3600,
  "created_at": "2020-01-01 00:00:00"  ← Ignored by server!
}
```

Server will:
1. Unset `created_at` from payload
2. Use `NOW()` for `created_at` in SQL
3. Prevent client tampering

### Client Request (UPDATE)
```json
{
  "name": "example.com",
  "ttl": 7200,
  "created_at": "2020-01-01 00:00:00",  ← Ignored by server!
  "updated_at": "2020-01-01 00:00:00"   ← Ignored by server!
}
```

Server will:
1. Unset both `created_at` and `updated_at` from payload
2. Use `NOW()` for `updated_at` in SQL
3. Never modify `created_at` (preserve original)
4. Prevent client tampering

## API Response

### GET /api/dns_api.php?action=get&id=123

**Response includes timestamps:**
```json
{
  "success": true,
  "data": {
    "id": 123,
    "record_type": "A",
    "name": "example.com",
    "address_ipv4": "192.168.1.100",
    "ttl": 3600,
    "created_at": "2025-10-15 09:15:00",    ← Returned
    "updated_at": "2025-10-18 11:20:00",    ← Returned
    "last_seen": "2025-10-20 14:30:00",
    "status": "active",
    ...
  }
}
```

### GET /api/dns_api.php?action=list

**Each record in array includes timestamps:**
```json
{
  "success": true,
  "data": [
    {
      "id": 123,
      "name": "example.com",
      "created_at": "2025-10-15 09:15:00",  ← Returned
      "updated_at": "2025-10-18 11:20:00",  ← Returned
      ...
    },
    ...
  ]
}
```

## User Experience Flow

### Creating a New Record
1. User clicks "+ Créer un enregistrement"
2. Modal opens with empty form
3. Timestamp fields are hidden (not applicable yet)
4. User fills in required fields
5. User clicks "Enregistrer"
6. Server creates record with `created_at = NOW()`
7. Table refreshes
8. New record appears with "Créé le" and "Modifié le" populated

### Editing an Existing Record
1. User clicks "Modifier" on a record
2. Modal opens with populated form
3. Timestamp fields are visible and readonly:
   - "Créé le" shows original creation time
   - "Modifié le" shows last modification time
   - "Vu pour la dernière fois" shows last view time
4. User modifies a field
5. User clicks "Enregistrer"
6. Server updates record with `updated_at = NOW()`
7. Table refreshes
8. Record shows updated "Modifié le" timestamp
9. "Créé le" remains unchanged

### Viewing the Table
1. User navigates to DNS Management page
2. Table loads with all records
3. Each row shows formatted timestamps:
   - "Créé le": Always shows creation time
   - "Modifié le": Shows last modification time
   - If null: displays "-"
4. User can filter/search records
5. Timestamps remain visible and formatted

## Technical Implementation

### JavaScript Date Formatting

Function used: `formatDateTime(datetime)`
```javascript
function formatDateTime(datetime) {
    if (!datetime) return '';
    try {
        const date = new Date(datetime.replace(' ', 'T'));
        return date.toLocaleString('fr-FR', {
            year: 'numeric',
            month: '2-digit',
            day: '2-digit',
            hour: '2-digit',
            minute: '2-digit'
        });
    } catch (e) {
        return datetime;
    }
}
```

**Input:** `"2025-10-15 09:15:00"` (SQL format)
**Output:** `"15/10/2025 09:15"` (French locale)

### Table Row Generation

```javascript
// Generate table rows with semantic classes
currentRecords.forEach(record => {
    const row = document.createElement('tr');
    row.innerHTML = `
        <td class="col-name">${escapeHtml(record.name)}</td>
        <td class="col-ttl">${escapeHtml(record.ttl)}</td>
        <td class="col-class">${escapeHtml(record.class || 'IN')}</td>
        <td class="col-type">${escapeHtml(record.record_type)}</td>
        <td class="col-value">${escapeHtml(record.value)}</td>
        <td class="col-requester">${escapeHtml(record.requester || '-')}</td>
        <td class="col-expires">${record.expires_at ? formatDateTime(record.expires_at) : '-'}</td>
        <td class="col-lastseen">${record.last_seen ? formatDateTime(record.last_seen) : '-'}</td>
        <td class="col-created">${record.created_at ? formatDateTime(record.created_at) : '-'}</td>
        <td class="col-updated">${record.updated_at ? formatDateTime(record.updated_at) : '-'}</td>
        <td class="col-status"><span class="status-badge status-${record.status}">${escapeHtml(record.status)}</span></td>
        <td class="col-id">${escapeHtml(record.id)}</td>
        <td class="col-actions">...</td>
    `;
    tbody.appendChild(row);
});
```

## Summary

This implementation adds full visibility of temporal metadata to DNS records while maintaining:
- ✓ Security (server-managed timestamps)
- ✓ User experience (appropriate field visibility)
- ✓ Data integrity (explicit NOW() in SQL)
- ✓ Backward compatibility (works with existing data)
- ✓ Clean code (minimal changes)
