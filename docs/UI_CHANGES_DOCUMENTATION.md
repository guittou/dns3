# UI Changes Documentation - Type-Specific Fields

## Overview
This document describes the visual and functional changes to the DNS management UI.

## Before (Old Implementation)
The old implementation used a single generic "value" field for all DNS record types:

```
[ Type d'enregistrement: A ▼ ]
[ Nom: example.com ]
[ Valeur: 192.168.1.1 ]  ← Single field for all types
[ TTL: 3600 ]
[ Priorité: 10 ]  ← Used only for MX/SRV
```

**Problems:**
- Same field used for IP addresses, hostnames, and text
- No type-specific validation hints
- Priority field shown for all types (confusing)
- Supported 9 different record types (MX, SRV, NS, SOA not fully functional)

## After (New Implementation)
The new implementation uses dedicated fields that show/hide based on record type:

### A Record (IPv4)
```
[ Type d'enregistrement: A ▼ ]
[ Nom: example.com ]
[ Adresse IPv4: 192.168.1.1 ]  ← Dedicated field with validation
  Example: 192.168.1.1
[ TTL: 3600 ]
```

### AAAA Record (IPv6)
```
[ Type d'enregistrement: AAAA ▼ ]
[ Nom: example.com ]
[ Adresse IPv6: 2001:db8::1 ]  ← Dedicated field with validation
  Example: 2001:db8::1
[ TTL: 3600 ]
```

### CNAME Record
```
[ Type d'enregistrement: CNAME ▼ ]
[ Nom: www.example.com ]
[ Cible CNAME: example.com ]  ← Dedicated field, no IP allowed
  Nom d'hôte cible (pas d'adresse IP)
[ TTL: 3600 ]
```

### PTR Record
```
[ Type d'enregistrement: PTR ▼ ]
[ Nom: example.com ]
[ Nom PTR (inversé): 1.1.168.192.in-addr.arpa ]  ← Requires reverse DNS name
  Nom DNS inversé requis
[ TTL: 3600 ]
```

### TXT Record
```
[ Type d'enregistrement: TXT ▼ ]
[ Nom: example.com ]
[ Texte: v=spf1 include:_spf.example.com ~all ]  ← Multi-line text area
  Example: v=spf1 include:_spf.example.com ~all
[ TTL: 3600 ]
```

## Key Changes

### 1. Type Selection
**Before:** 9 types (A, AAAA, CNAME, MX, TXT, NS, SOA, PTR, SRV)
**After:** 5 types (A, AAAA, CNAME, PTR, TXT)

The type dropdown now shows only supported types.

### 2. Dynamic Field Visibility
- Only ONE dedicated field is visible at a time
- Field automatically shows/hides when changing record type
- Each field has appropriate placeholder text and validation hints
- Required indicator (*) shown on active field

### 3. Field-Specific Validation
- **A Record**: Validates IPv4 format (e.g., 192.168.1.1)
- **AAAA Record**: Validates IPv6 format (e.g., 2001:db8::1)
- **CNAME Record**: Validates hostname format, rejects IP addresses
- **PTR Record**: Validates hostname format, expects reverse DNS name
- **TXT Record**: Accepts any non-empty text

### 4. Removed Fields
- **Priority field**: Removed (was only used for MX/SRV which are no longer supported)
- **Value field**: Replaced by type-specific fields

### 5. Enhanced User Experience
- Clear labeling with type-specific names
- Inline examples and hints below each field
- Visual highlighting of active field (green border)
- Better form validation with specific error messages

## Form Field Mapping

| Record Type | Field Name | Database Column | HTML Element | Validation |
|-------------|-----------|-----------------|--------------|------------|
| A | Adresse IPv4 | `address_ipv4` | `<input type="text">` | IPv4 format |
| AAAA | Adresse IPv6 | `address_ipv6` | `<input type="text">` | IPv6 format |
| CNAME | Cible CNAME | `cname_target` | `<input type="text">` | Hostname (no IP) |
| PTR | Nom PTR | `ptrdname` | `<input type="text">` | Hostname |
| TXT | Texte | `txt` | `<textarea>` | Non-empty |

## JavaScript Behavior

### Field Visibility Logic
```javascript
function updateFieldVisibility() {
    // Hide all dedicated field groups
    ipv4Group.style.display = 'none';
    ipv6Group.style.display = 'none';
    cnameGroup.style.display = 'none';
    ptrGroup.style.display = 'none';
    txtGroup.style.display = 'none';
    
    // Show only the relevant field based on selected type
    switch(recordType) {
        case 'A':
            ipv4Group.style.display = 'block';
            ipv4Input.setAttribute('required', 'required');
            break;
        // ... other types
    }
}
```

### Payload Construction
```javascript
// Build payload with both dedicated field AND value alias
const data = {
    record_type: 'A',
    name: 'example.com',
    address_ipv4: '192.168.1.1',  // Dedicated field
    value: '192.168.1.1',         // Alias for backward compatibility
    ttl: 3600
};
```

## Table Display

The records table continues to display a "Valeur" column, which is now computed from the dedicated fields by the backend:

```
| ID | Type  | Nom           | Valeur        | TTL  | ... |
|----|-------|---------------|---------------|------|-----|
| 1  | A     | example.com   | 192.168.1.1   | 3600 | ... |
| 2  | AAAA  | example.com   | 2001:db8::1   | 3600 | ... |
| 3  | CNAME | www.ex...com  | example.com   | 3600 | ... |
```

The `value` field in the API response is automatically computed from the appropriate dedicated column, ensuring backward compatibility with existing table rendering code.

## Error Messages

### Client-Side Validation
- "L'adresse doit être une adresse IPv4 valide pour le type A"
- "L'adresse doit être une adresse IPv6 valide pour le type AAAA"
- "La cible CNAME ne peut pas être une adresse IP (doit être un nom d'hôte)"
- "Le nom PTR doit être un nom d'hôte valide (nom DNS inversé requis)"
- "Le contenu du champ TXT ne peut pas être vide"

### Server-Side Validation
- "Invalid record type. Only A, AAAA, CNAME, PTR, and TXT are supported"
- "Address must be a valid IPv4 address for type A"
- "CNAME target cannot be an IP address (must be a hostname)"
- "Missing required field: address_ipv4 (or value) for type A"

## Accessibility Improvements

1. **Clear Labels**: Each field has a descriptive label specific to the record type
2. **Required Indicators**: Asterisks (*) indicate required fields
3. **Placeholder Text**: Examples show expected format
4. **Helper Text**: Small text below fields provides additional guidance
5. **Visual Feedback**: Active field is highlighted with green border

## Backward Compatibility

The implementation maintains backward compatibility in several ways:

1. **API accepts `value` as alias**: Old code can still send `value` instead of dedicated field
2. **API returns `value` field**: Response includes computed `value` for old clients
3. **Database keeps `value` column**: Can rollback if needed
4. **Gradual migration**: Existing records continue to work

## Migration Impact

When upgrading:
1. Existing records are automatically migrated (value → dedicated column)
2. UI immediately shows dedicated fields for new/edited records
3. API continues to accept both formats
4. No breaking changes for existing integrations
