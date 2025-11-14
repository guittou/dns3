# Zone Name Validation - Implementation Details

## Context

User requested that the "Nom de la zone" (zone name) field should have **NO format validation** on the client side. Previously, regex validation was blocking names like "test_uk" (with underscores) and preventing form submission.

## Solution

The client-side validation for zone name fields has been updated to perform **ONLY a required check** (non-empty validation). All format validation has been removed from zone name fields.

## Implementation

### Functions Modified

1. **`submitCreateInclude()`** (lines 1396-1439)
   - Creates include zones from the modal
   - Validates: `name` is required (non-empty)
   - No format validation on `name`

2. **`saveInclude()`** (lines 1672-1746)
   - Saves include zones in create modal
   - Validates: `name` is required (non-empty)
   - No format validation on `name`

3. **`createZone()`** (lines 1779-1850)
   - Creates master zones
   - Validates: `name` is required (non-empty)
   - No format validation on `name`

### Validation Rules

| Field | Required | Format Validation |
|-------|----------|-------------------|
| Zone Name (`name`) | ✅ Yes | ❌ No (removed) |
| Filename (`filename`) | ✅ Yes | ✅ Yes (no spaces, must end with .db) |
| Domain (`domain`) | ❌ Optional | ✅ Yes (if provided - no underscores in labels) |

### Code Example

```javascript
// Zone name validation - REQUIRED ONLY
const name = document.getElementById('master-zone-name').value?.trim() || '';

// Validate zone name: REQUIRED only (no format validation)
if (!name) {
    showModalError('createZone', 'Le Nom de la zone est requis.');
    return;
}
// Zone name accepted - no further validation
```

### Validation Functions Still Active

1. **`validateFilename(filename)`** (lines 71-92)
   - Validates filename has no spaces
   - Validates filename ends with `.db` (case insensitive)
   - Returns: `{valid: boolean, error: string|null}`

2. **`validateDomainLabel(domain)`** (lines 35-63)
   - Validates domain labels contain only `[A-Za-z0-9-]`
   - **No underscores allowed** in domain labels
   - Labels cannot start or end with hyphen
   - Returns: `boolean`

## Server-Side Validation

The server-side validator (`DnsValidator`) **remains unchanged**. The server may still reject zone names based on its own validation rules. This change only affects client-side validation.

## Testing

### Manual Test Scenarios

1. **Empty zone name**
   - Action: Leave "Nom de la zone" field empty
   - Expected: Error "Le Nom de la zone est requis."
   - Result: ✅ Works correctly

2. **Zone name with underscore (e.g., "test_uk")**
   - Action: Enter zone name with underscore
   - Expected: Accepted by client, API request sent
   - Result: ✅ Works correctly

3. **Filename with space**
   - Action: Enter filename with space (e.g., "test file.db")
   - Expected: Error "Le nom du fichier ne doit pas contenir d'espaces."
   - Result: ✅ Works correctly

4. **Filename without .db extension**
   - Action: Enter filename without .db (e.g., "testfile")
   - Expected: Error "Le nom du fichier doit se terminer par .db."
   - Result: ✅ Works correctly

5. **Domain with underscore**
   - Action: Enter domain with underscore (e.g., "test_uk.com")
   - Expected: Error about invalid domain characters
   - Result: ✅ Works correctly

### Automated Tests

All 20 automated tests pass:
- Zone name with underscore: ✅ Accepted
- Zone name with multiple underscores: ✅ Accepted
- Empty zone name: ✅ Rejected
- Domain with underscore: ✅ Rejected (format validation active)
- Filename validation: ✅ Active

## Modal Behavior

On successful zone creation:
1. Modal closes automatically
2. `populateZoneDomainSelect()` is called to refresh domain list
3. `renderZonesTable()` is called to refresh zones table
4. Success message displayed

On validation error:
1. Error banner displayed in modal via `showModalError()`
2. Modal remains open for user to correct input
3. Previous errors cleared via `clearModalError()`

## Error Messages

- Zone name required: `"Le Nom de la zone est requis."`
- Filename with spaces: `"Le nom du fichier ne doit pas contenir d'espaces."`
- Filename without .db: `"Le nom du fichier doit se terminer par .db."`
- Domain with invalid chars: `"Le domaine contient des caractères invalides (seules les lettres, chiffres et tirets sont autorisés dans chaque label ; pas d'underscore)."`

## Impact

- **Minimal**: Only affects client-side validation of zone name fields
- **Reversible**: Can be reverted by adding back format validation
- **No backend changes**: Server-side validation unchanged
- **Backward compatible**: Existing zone names continue to work

## References

- Problem statement: User repeatedly requested no format validation on zone name
- Files modified: `assets/js/zone-files.js`
- Branch: `fix/ui-no-validate-zone-name`
- Related issue: Zone names with underscores blocked by client validation
