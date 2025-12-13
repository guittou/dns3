# API Validation Implementation Summary

## Changes Made

### 1. Updated `api/zone_api.php`
- **Added import**: `require_once __DIR__ . '/../includes/lib/DnsValidator.php';`
- **Added validation** in the `create_zone` action (lines 221-230):
  ```php
  // Validate zone name using DnsValidator
  $nameValidation = DnsValidator::validateName(trim($input['name']));
  if (!$nameValidation['valid']) {
      http_response_code(422);
      echo json_encode([
          'success' => false,
          'error' => $nameValidation['error']
      ]);
      exit;
  }
  ```

### 2. Created Test Suite
- **New file**: `tests/unit/ZoneApiValidationTest.php`
- **Test coverage**: 10 test cases covering various validation scenarios
- **All tests pass**: ✓ 54 tests total (44 existing + 10 new)

## API Behavior

### Before Changes
- **Missing validation**: Zone names were not validated before creation
- **Generic errors**: Would fail later with database or zone file creation errors
- **No structured errors**: Error responses were not consistent

### After Changes
- **Early validation**: Zone names are validated immediately using `DnsValidator::validateName()`
- **HTTP 422 status**: Returns appropriate HTTP status for validation failures
- **Structured JSON response**: Consistent error format:
  ```json
  {
    "success": false,
    "error": "<descriptive error message>"
  }
  ```

## Example API Responses

### Valid Zone Name
**Request**: `POST /api/zone_api.php?action=create_zone`
```json
{
  "name": "example.com",
  "filename": "example.com.zone"
}
```
**Response**: HTTP 201
```json
{
  "success": true,
  "message": "Zone file created successfully",
  "id": 123
}
```

### Invalid Zone Name (Non-ASCII)
**Request**: `POST /api/zone_api.php?action=create_zone`
```json
{
  "name": "café.com",
  "filename": "cafe.com.zone"
}
```
**Response**: HTTP 422
```json
{
  "success": false,
  "error": "Label contains non-ASCII characters (IDN not supported)"
}
```

### Invalid Zone Name (Starts with Hyphen)
**Request**: `POST /api/zone_api.php?action=create_zone`
```json
{
  "name": "-example.com",
  "filename": "example.com.zone"
}
```
**Response**: HTTP 422
```json
{
  "success": false,
  "error": "Label cannot start with a hyphen"
}
```

### Invalid Zone Name (Contains Spaces)
**Request**: `POST /api/zone_api.php?action=create_zone`
```json
{
  "name": "my domain.com",
  "filename": "mydomain.com.zone"
}
```
**Response**: HTTP 422
```json
{
  "success": false,
  "error": "Label cannot contain spaces"
}
```

## Validation Rules Applied

The `DnsValidator::validateName()` method enforces strict DNS naming rules:
- ✓ Only ASCII characters (a-z, A-Z, 0-9, hyphen, dot)
- ✓ Labels cannot start or end with hyphen
- ✓ Labels max 63 characters each
- ✓ Total name max 253 characters
- ✓ No spaces allowed
- ✓ No special characters except hyphen
- ✓ Supports FQDN with trailing dot (example.com.)

## Testing

Run the test suite with:
```bash
vendor/bin/phpunit
```

Run validation tests specifically:
```bash
vendor/bin/phpunit tests/unit/ZoneApiValidationTest.php
```

All 54 tests pass successfully.
