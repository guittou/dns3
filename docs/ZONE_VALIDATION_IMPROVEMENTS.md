# Zone File Validation Improvements

## Overview

This document describes the improvements made to zone file validation, specifically for handling include files that are part of an include chain.

## Problem Statement

The previous implementation had limitations when validating include files:

1. **Only checked immediate parent**: If an include file had a parent that was also an include (not a master), validation would fail or behave incorrectly.
2. **Limited propagation**: Validation results were only propagated to direct children, not to deeply nested includes.
3. **No cycle detection**: No protection against circular dependencies in include chains.

## Solution

### 1. New Method: `findTopMaster($zoneId)`

**Purpose**: Traverse the entire parent chain to find the top-level master zone.

**Features**:
- Walks up the parent chain from any include file
- Handles multi-level include hierarchies (include → include → ... → master)
- Detects circular dependencies using a visited array
- Returns clear error messages for various failure cases

**Example**:
```
Zone Structure:
  master.example.com (master)
    ├─ common.include (include, parent_id=1)
    │   └─ specific.include (include, parent_id=2)
    └─ other.include (include, parent_id=1)

Calling findTopMaster(3) [specific.include]:
  Step 1: Check zone 3 (specific.include) - it's an include
  Step 2: Move to parent 2 (common.include) - it's an include
  Step 3: Move to parent 1 (master.example.com) - it's a master ✓
  Result: Returns master zone 1
```

### 2. Updated Method: `validateZoneFile($zoneId, $userId, $sync)`

**Changes**:
- Uses `findTopMaster()` to locate the top-level master
- Always validates the complete zone (the master)
- Propagates results to ALL includes in the tree

**Flow for Include Files**:
```
1. User requests validation of an include file
2. System calls findTopMaster() to traverse to master
3. System validates the master zone using named-checkzone
4. System stores validation result for the master
5. System propagates results to ALL descendant includes (BFS)
6. System returns result with context about which master was validated
```

**Flow for Master Files**:
```
1. User requests validation of a master file
2. System validates directly using named-checkzone
3. System stores validation result for the master
4. System propagates results to ALL descendant includes (BFS)
5. System returns result to user
```

### 3. Updated Method: `propagateValidationToIncludes($parentId, ...)`

**Changes**:
- Uses Breadth-First Search (BFS) to traverse ALL descendants
- Maintains cycle protection with visited array
- Updates validation status for every include in the entire tree

**Example**:
```
Zone Structure:
  master (id=1)
    ├─ include1 (id=2)
    │   └─ include3 (id=4)
    └─ include2 (id=3)

After validating master:
  1. Process master (id=1) - find children [2, 3]
  2. Store validation for include1 (id=2) - find children [4]
  3. Store validation for include2 (id=3) - no children
  4. Store validation for include3 (id=4) - no children

Result: ALL includes (2, 3, 4) have validation results
```

## Error Handling

The implementation provides specific error messages for each scenario:

### 1. Orphaned Include (No Master Parent)
```
Error: "Include file has no master parent; cannot validate standalone"
Status: failed
Return code: 1

This occurs when an include file has no parent_id set.
```

### 2. Circular Dependency
```
Error: "Circular dependency detected in include chain; cannot validate"
Status: failed
Return code: 1

This occurs when traversing the parent chain finds a cycle.
Note: Database constraints should prevent this, but the code protects against it.
```

### 3. Missing Zone in Chain
```
Error: "Zone file (ID: X) not found in parent chain"
Status: failed
Return code: 1

This occurs when a parent_id references a non-existent zone.
```

## Database Schema

The system relies on these tables:

### zone_files
```sql
CREATE TABLE zone_files (
  id INT PRIMARY KEY,
  name VARCHAR(255),
  file_type ENUM('master', 'include'),
  ...
);
```

### zone_file_includes
```sql
CREATE TABLE zone_file_includes (
  id INT PRIMARY KEY,
  parent_id INT,  -- References zone_files(id)
  include_id INT, -- References zone_files(id)
  UNIQUE KEY (include_id), -- Each include has ONE parent
  ...
);
```

**Important**: The `UNIQUE KEY (include_id)` constraint ensures each include can only have one parent, preventing most circular dependency scenarios at the database level.

## API Behavior

### Synchronous Validation (`sync=true`)
```php
$result = $zoneFile->validateZoneFile($zoneId, $userId, true);

// For include files, returns:
[
    'status' => 'passed' or 'failed',
    'output' => "Validation performed on top master zone 'example.com' (ID: 1):\n\n[named-checkzone output]",
    'return_code' => 0 or 1
]
```

### Asynchronous Validation (`sync=false`)
```php
$result = $zoneFile->validateZoneFile($zoneId, $userId, false);

// Returns true if queued successfully
// Stores 'pending' status in database
// Background worker will process the top master
```

## Validation Output

When validating an include file, users see context about which master was validated:

**Example Output**:
```
Validation performed on top master zone 'example.com' (ID: 1):

zone example.com/IN: loaded serial 2025102201
OK
```

This clarifies that:
1. The include was validated in the context of its master
2. The master zone is what was actually checked
3. The include is valid as part of that master zone

## Backward Compatibility

✅ **Fully backward compatible**:
- Existing validation of master files works identically
- API interface unchanged
- Database schema unchanged
- All existing functionality preserved

## Testing

Comprehensive tests verify the implementation:

1. ✓ Simple chain (master → include1)
2. ✓ Multi-level chain (master → include1 → include2)
3. ✓ Orphaned include detection
4. ✓ Circular dependency detection
5. ✓ Multi-branch tree propagation

All tests pass successfully.

## Performance Considerations

- **findTopMaster()**: O(n) where n = depth of include chain (typically 1-3 levels)
- **propagateValidationToIncludes()**: O(m) where m = total number of includes in tree
- Database queries are indexed on `parent_id` and `include_id`
- BFS uses a queue and visited array to prevent redundant processing

## Configuration

No new configuration required. The system respects existing settings:

```php
// In config.php (if defined)
define('NAMED_CHECKZONE_PATH', '/usr/sbin/named-checkzone');
define('ZONE_VALIDATE_SYNC', false);
```

## Files Modified

- `includes/models/ZoneFile.php`
  - Added: `findTopMaster()` method (~line 970)
  - Updated: `validateZoneFile()` method (~line 891)
  - Updated: `propagateValidationToIncludes()` method (~line 1067)

## Example Use Cases

### Use Case 1: Validating a Deeply Nested Include

```
Structure:
  master.zone (master)
    └─ level1.include (include)
        └─ level2.include (include)
            └─ level3.include (include)

User action: Validate level3.include
System behavior:
  1. Traverse: level3 → level2 → level1 → master
  2. Validate: master.zone (complete zone)
  3. Propagate: Results to level1, level2, level3
  4. Return: Success with master context
```

### Use Case 2: Validating a Master with Multiple Includes

```
Structure:
  master.zone (master)
    ├─ common.include (include)
    │   └─ specific.include (include)
    └─ other.include (include)

User action: Validate master.zone
System behavior:
  1. Validate: master.zone directly
  2. Propagate: Results to common, specific, and other
  3. Return: Success
  4. Result: All 3 includes now have validation status
```

## Future Enhancements

Potential improvements for future PRs:

1. **Caching**: Cache master lookups for includes to reduce traversal overhead
2. **Batch validation**: Validate multiple includes at once by grouping by master
3. **Partial validation**: Validate just the changed include without full zone validation
4. **Metrics**: Track validation performance and include chain depth statistics

## Troubleshooting

### Issue: Validation fails with "no master parent" error

**Cause**: Include file has no parent_id set
**Solution**: Assign the include to a parent zone using the UI or API

### Issue: Validation shows old results

**Cause**: Validation was propagated from a previous run
**Solution**: Trigger a new validation on the master zone

### Issue: Validation takes a long time

**Cause**: Large zone file or slow named-checkzone execution
**Solution**: Use async validation (`sync=false`) for large zones

## References

- Original issue: Improve validation of zone files when validating include files
- Related PR: #38 (work-in-progress)
- Named-checkzone documentation: BIND 9 Administrator Reference Manual
