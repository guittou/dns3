# Zone File Validation - Line Context Extraction

## Overview

This feature enhances the zone file validation output by automatically extracting and displaying the exact lines that caused validation errors when `named-checkzone` reports issues.

## Problem Statement

When `named-checkzone` validates zone files, it reports errors in the format:
```
filename:LINE: message
```

For example:
```
zone_1.db:13: ns1.example.com: bad owner name (check-names)
```

Previously, users would see these error messages but couldn't easily locate the problematic lines because:
1. The validation runs on temporary, inlined files (with includes expanded)
2. The temporary files are deleted after validation
3. Line numbers might not match the original zone file if includes are used

## Solution

The validation system now automatically:
1. **Parses error messages** - Detects lines matching the pattern `filename:line: message`
2. **Resolves file paths** - Locates the temporary files in the validation directory
3. **Extracts line context** - Gets the problematic line plus 2 lines before and after
4. **Formats the context** - Displays line numbers with a `>` marker for the error line
5. **Appends to output** - Adds the extracted context to the validation results stored in the database

## Example Output

### Before (original error only):
```
zone_1.db:13: bad..owner: bad owner name (check-names)
zone example.com/IN: has 1 errors
```

### After (with extracted context):
```
zone_1.db:13: bad..owner: bad owner name (check-names)
zone example.com/IN: has 1 errors

=== EXTRACTED LINES FROM INLINED FILE(S) ===

File: zone_1.db, Line: 13
Message: bad..owner: bad owner name (check-names)
    11: ns1     IN      A       192.0.2.2
    12: ns2     IN      A       192.0.2.3
>   13: bad..owner      IN      A       192.0.2.4
    14: www     IN      A       192.0.2.5
    15: mail    IN      A       192.0.2.6

=== END OF EXTRACTED LINES ===
```

## Implementation Details

### Modified Method: `runNamedCheckzone()`
- After executing `named-checkzone`, the output is enriched before storage
- Calls `enrichValidationOutput()` to add line context
- Stores and propagates the enriched output to child includes

### New Methods

#### `enrichValidationOutput($outputText, $tmpDir, $zoneFilename)`
- Main enrichment method
- Parses each line of output for error patterns
- Collects line contexts and appends them to the output
- Returns the enriched output text

#### `resolveValidationFilePath($reportedFile, $tmpDir, $zoneFilename)`
- Resolves file paths from error messages to actual files
- Uses multiple strategies:
  1. Absolute path in tmpDir
  2. Basename matches zone filename
  3. Basename exists in tmpDir
  4. Relative path from tmpDir
- Returns null if file cannot be located

#### `getFileLineContext($path, $lineNumber, $contextLines = 2)`
- Extracts lines from a file with context
- Parameters:
  - `$path`: File path
  - `$lineNumber`: Target line number (1-based)
  - `$contextLines`: Number of lines before/after to include (default: 2)
- Returns formatted block with line numbers
- Uses `>` prefix to mark the target line

## Configuration

### Debug Mode
To keep temporary files for manual inspection, define:
```php
define('DEBUG_KEEP_TMPDIR', true);
```

When enabled, temporary directories are not deleted and their paths are logged.

### Custom named-checkzone Path
If `named-checkzone` is not in the system PATH:
```php
define('NAMED_CHECKZONE_PATH', '/usr/local/bin/named-checkzone');
```

## Benefits

1. **Faster debugging** - Users can immediately see what's wrong
2. **Better UX** - No need to locate temporary files or count lines
3. **Include-friendly** - Works with inlined zone files that have includes expanded
4. **Clear visualization** - Line numbers and markers make errors obvious
5. **Preserved history** - Enriched output is stored in the database for future reference

## Testing

A test script is provided: `test-validation-enrich.php`

Run it with:
```bash
php test-validation-enrich.php
```

The test verifies:
- Pattern matching for error lines
- Line extraction with context
- Full enrichment flow with multiple errors
- Edge cases (missing files, invalid line numbers)

## Database Storage

The enriched output is stored in the `zone_file_validation` table:
- `output` column (TEXT) contains the full enriched validation output
- This output is also propagated to child includes via `propagateValidationToIncludes()`

## Future Enhancements

Possible improvements:
1. Configurable context lines (currently hardcoded to 2)
2. Syntax highlighting in the UI for displayed context
3. Direct links from error messages to specific lines in the zone file editor
4. Support for additional validation tools beyond `named-checkzone`
