# Technical Summary: Duplicate Request Deduplication

## Problem Statement

The Zones tab was making duplicate API requests on page load:
- Multiple `list_zones` calls with identical parameters (file_type, status, per_page)
- Multiple `list_zone_files` calls with the same domain_id
- Multiple initialization sequences from fallback timers (30ms, 800ms, 2500ms)

**Root Causes:**
1. Multiple fallback timers calling `initZonesWhenReady()` without checking if initialization was already in progress
2. `fetchZonesForMaster()` had no in-flight request caching
3. `initializeComboboxes()` was being called multiple times without idempotency protection
4. `loadZonesData()` was making redundant UI initialization calls

---

## Solutions Implemented

### 1. Request Memoization for `fetchZonesForMaster`

**File:** `assets/js/zone-files.js`

**Change:**
```javascript
// Added Map to cache in-flight requests by master_id
const _fetchZonesForMasterCache = new Map();

async function fetchZonesForMaster(masterId) {
    const masterIdNum = parseInt(masterId, 10);
    
    // Check if request already in-flight
    if (_fetchZonesForMasterCache.has(masterIdNum)) {
        return _fetchZonesForMasterCache.get(masterIdNum);
    }
    
    // Create and cache promise
    const requestPromise = (async () => {
        try {
            const result = await zoneApiCall('list_zones', {...});
            return result.data;
        } finally {
            // Clean up cache after completion
            _fetchZonesForMasterCache.delete(masterIdNum);
        }
    })();
    
    _fetchZonesForMasterCache.set(masterIdNum, requestPromise);
    return requestPromise;
}
```

**Benefit:**
- Multiple concurrent calls with same `master_id` reuse the same promise
- No duplicate `list_zones` API calls for the same master domain
- Automatic cleanup prevents memory leaks

---

### 2. Idempotent UI Initialization

**File:** `assets/js/zone-files.js`

**Change:**
```javascript
// Added flag to track initialization state
let _uiComponentsInitialized = false;

async function initializeComboboxes() {
    // Early exit if already initialized
    if (_uiComponentsInitialized) {
        console.debug('[initializeComboboxes] Already initialized, skipping');
        return;
    }
    
    // Perform initialization...
    await ensureZoneFilesInit();
    await populateZoneDomainSelect();
    await initZoneFileCombobox();
    // ... etc
    
    // Mark as initialized
    _uiComponentsInitialized = true;
}
```

**Benefit:**
- Function can be called safely from multiple code paths
- First call performs initialization, subsequent calls skip
- Prevents redundant API calls from recovery/fallback paths

**Important Note:**
This flag is for initial page setup. Individual functions like `populateZoneDomainSelect()` can still be called directly for updates after initialization (e.g., after saving a new zone).

---

### 3. Fallback Timer Deduplication

**File:** `assets/js/zone-files.js`

**Change:**
```javascript
// Before: Only checked _zonesInitRun
setTimeout(() => {
    if (!window._zonesInitRun && shouldInitZonesPage()) {
        initZonesWhenReady();
    }
}, 30);

// After: Also checks if initialization is in-flight
setTimeout(() => {
    if (!window._zonesInitRun && !window._initZonesWhenReadyPromise && shouldInitZonesPage()) {
        initZonesWhenReady();
    }
}, 30);
```

**Applied to:**
- 30ms fallback timer
- 800ms fallback timer  
- 2500ms fallback timer
- window.load event listener

**Benefit:**
- Prevents concurrent initialization attempts from multiple timers
- First timer that fires gets to initialize, others skip
- Respects existing `_initZonesWhenReadyPromise` guard in `initZonesWhenReady()`

---

### 4. Cleanup of Redundant Calls

**File:** `assets/js/zone-files.js`

**Change in `loadZonesData()`:**
```javascript
// Before: Called initializeComboboxes() then called individual functions again
await initializeComboboxes();
await populateZoneDomainSelect();  // ← REDUNDANT
await initZoneFileCombobox();       // ← REDUNDANT
syncZoneFileComboboxInstance();     // ← REDUNDANT

// After: Only call initializeComboboxes() (which is idempotent)
await initializeComboboxes();
```

**Benefit:**
- Eliminates redundant function calls
- `initializeComboboxes()` already calls these functions internally
- Idempotent flag ensures no work is duplicated

---

## Existing Deduplication (Verified)

These were already implemented correctly and continue to work:

### 1. `zone-combobox.js` - list_zone_files Deduplication
```javascript
const _zoneFileRequestsInFlight = new Map();

async function populateZoneListForDomain(domainId) {
    if (_zoneFileRequestsInFlight.has(domainIdNum)) {
        return _zoneFileRequestsInFlight.get(domainIdNum);
    }
    // ... fetch and cache promise
}
```

### 2. `combobox-utils.js` - list_zones Deduplication
```javascript
let _ensureZonesCachePromise = null;

async function ensureZonesCache() {
    if (_ensureZonesCachePromise) {
        return _ensureZonesCachePromise;
    }
    // ... fetch and cache promise
}
```

### 3. `zone-files.js` - loadZonesData Deduplication
```javascript
window._loadZonesDataPromise = null;

async function loadZonesData() {
    if (window._loadZonesDataPromise) {
        return window._loadZonesDataPromise;
    }
    // ... fetch and cache promise
}
```

### 4. `zone-files.js` - initZonesWhenReady Deduplication
```javascript
window._initZonesWhenReadyPromise = null;

async function initZonesWhenReady() {
    if (window._initZonesWhenReadyPromise) {
        return window._initZonesWhenReadyPromise;
    }
    // ... initialize and cache promise
}
```

---

## Deduplication Patterns Used

The codebase now consistently uses two patterns:

### Pattern 1: Single Promise Guard
For operations that should only happen once globally:
```javascript
let _operationPromise = null;

async function performOperation() {
    if (_operationPromise) {
        return _operationPromise;
    }
    
    _operationPromise = (async () => {
        // ... do work
    })();
    
    try {
        return await _operationPromise;
    } finally {
        _operationPromise = null;
    }
}
```

### Pattern 2: Map of Promises by ID
For operations that should be deduplicated per entity:
```javascript
const _operationCache = new Map();

async function performOperationForEntity(entityId) {
    if (_operationCache.has(entityId)) {
        return _operationCache.get(entityId);
    }
    
    const promise = (async () => {
        // ... do work
    })();
    
    _operationCache.set(entityId, promise);
    
    try {
        return await promise;
    } finally {
        _operationCache.delete(entityId);
    }
}
```

---

## Impact on Code Paths

### Page Load Sequence (Before)
```
1. DOMContentLoaded → initZonesWhenReady()
2. 30ms timer → initZonesWhenReady()  [DUPLICATE]
3. 800ms timer → initZonesWhenReady() [DUPLICATE]
4. window.load → initZonesWhenReady() [DUPLICATE]

Each call triggered:
- list_zones (file_type=include)
- list_zones (file_type=master)
- Multiple fetchZonesForMaster() calls
- Multiple UI initialization calls

Result: 6-12 duplicate API requests
```

### Page Load Sequence (After)
```
1. DOMContentLoaded → initZonesWhenReady() [executes]
2. 30ms timer → skipped (_initZonesWhenReadyPromise exists)
3. 800ms timer → skipped (_zonesInitRun = true)
4. window.load → skipped (_zonesInitRun = true)

First call triggers:
- list_zones (file_type=include) [once]
- list_zones (file_type=master) [once]
- fetchZonesForMaster() [once per domain]
- UI initialization [once, then idempotent flag set]

Result: 2-3 API requests (no duplicates)
```

---

## Testing Approach

See `docs/DUPLICATE_REQUEST_FIX_VALIDATION.md` for detailed test scenarios.

**Key verification points:**
1. Browser DevTools Network tab shows single request per unique API call
2. Console shows deduplication messages: "already in progress", "already initialized"
3. No regression in UI functionality
4. Page loads faster due to reduced network overhead

---

## Memory Management

All caches use proper cleanup:
- **Map-based caches**: Delete entry in `finally` block after promise resolves
- **Single promise guards**: Set to `null` in `finally` block
- **Idempotent flags**: Remain set for page lifecycle (reset on page reload)

No memory leaks introduced - all promises are cleaned up after resolution.

---

## Future Maintenance

When adding new initialization code:
1. Check if a similar operation already has deduplication
2. If calling API repeatedly with same params, add memoization
3. Use Pattern 1 (single guard) for global operations
4. Use Pattern 2 (Map by ID) for per-entity operations
5. Always clean up in `finally` block to prevent leaks

---

## References

**Modified Files:**
- `assets/js/zone-files.js` (main changes)

**Verified Files (no changes needed):**
- `assets/js/zone-combobox.js` (already has list_zone_files deduplication)
- `assets/js/combobox-utils.js` (already has ensureZonesCache deduplication)

**Related Memories:**
- Request memoization by ID (zone-combobox.js pattern)
- API request deduplication (shared promise guards)
- Fallback timer deduplication patterns
