# Zone Search: Server-First Strategy

## Overview

This document explains the server-first search strategy implemented for zone searches and comboboxes in the Zones and DNS tabs. This approach was designed to handle large instances with many zones (~300+ includes) where client-side caching becomes impractical.

## Problem Statement

On large DNS3 instances (e.g., 1 master + ~300 includes + ~15k records), the UI exhibited inconsistent behavior:

- **Client cache limitations**: The `window.ZONES_ALL` cache was only partially populated (default 100 items) due to API pagination
- **Missing zones in searches**: Client-side searches couldn't find zones not in the cache (e.g., "fic001")
- **Combobox issues**: Zone selection dropdowns missed zones that were paginated out
- **Existing solution unused**: The API provides a `search_zones` endpoint for server-side autocomplete, but it wasn't used systematically

## Solution: Server-First Search

### Core Strategy

The implementation now follows a **server-first** approach for non-trivial queries:

1. **Empty query (0 characters)**: Reload full data via `loadZonesData()` to restore cache
2. **Short query (< 2 characters)**: Try client cache first; fallback to server if cache empty
3. **Query ≥ 2 characters**: **Always use server search** via `search_zones` endpoint

This ensures:
- ✅ All zones can be found regardless of pagination
- ✅ Server handles ACL filtering automatically
- ✅ Fast response for users (debounced, 250ms delay)
- ✅ Reduced client memory usage

### Affected Components

#### 1. Zone Files Page (zone-files.js)

**Main Search Input** (`#searchInput`)
- Function: `attachZoneSearchInput()`
- Debounce: 250ms
- Server search for queries ≥ 2 chars via `serverSearchZones()`
- Console debug traces: `[attachZoneSearchInput] server search q=...`

**Zone File Combobox** (`#zone-file-input`)
- Function: `initZoneFileCombobox()`
- Server search for queries ≥ 2 chars
- Filters results by selected master when applicable
- Console debug traces: `[initZoneFileCombobox] Using server search for query:...`

**Parent Combobox** (`#include-parent-input`)
- Function: `populateIncludeParentCombobox()`
- Server search for queries ≥ 2 chars
- Filters results to master's tree only
- Console debug traces: `[populateIncludeParentCombobox] Using server search for query:...`

#### 2. DNS Records Page (dns-records.js)

**Zone Selection Combobox** (`#dns-zone-input`)
- Function: `initZoneCombobox()`
- Reuses `window.serverSearchZones()` from zone-files.js
- Server search for queries ≥ 2 chars
- Console debug traces: `[DNS initZoneCombobox] Using server search for query:...`

#### 3. Zone File Detail Page (zone-file-detail.js)

**Include Search** (`#includeSearch`)
- Function: `handleIncludeSearch()`
- Already used server search correctly (verified)
- Only triggers for queries ≥ 2 chars
- Console debug traces: `[handleIncludeSearch] Server search for query:...`

### API Endpoint

**Endpoint**: `/api/zone_api.php?action=search_zones`

**Parameters**:
- `q` (required): Search query string
- `file_type` (optional): Filter by type ('master', 'include', or empty for all)
- `limit` (optional): Maximum results to return (default: 100)

**Response Format**:
```json
{
  "success": true,
  "data": [
    {
      "id": 123,
      "name": "fic001",
      "filename": "fic001.db",
      "file_type": "include",
      "parent_id": 456,
      "domain": "example.com",
      "status": "active"
    }
  ]
}
```

**ACL Filtering**: The endpoint automatically applies ACL filtering on the server side, so non-admin users only see zones they have access to.

## Implementation Details

### Helper Functions

**`serverSearchZones(query, options = {})`**
- Performs server-side zone search
- Options: `{ file_type: '', limit: 100 }`
- Returns: `Promise<Array>` of zone objects
- Exposed globally: `window.serverSearchZones`

**`clientFilterZones(query)`**
- Filters cached `window.ZONES_ALL` client-side
- Returns: `Array | null` (null if cache empty)
- Exposed globally: `window.clientFilterZones`

**`initCombobox(opts)`**
- Generic combobox initializer with server search support
- New option: `serverSearch: async (q) => Promise<Array>`
- New option: `minCharsForServer: 2` (default)
- Server search triggered when `q.length >= minCharsForServer`

### Fallback Behavior

The implementation includes defensive fallbacks:

1. **Server search fails**: Falls back to client cache filtering
2. **Client cache empty**: Uses server search even for short queries
3. **`serverSearchZones` not available**: Uses client cache only (graceful degradation)

### Parent Injection

The existing `ensureParentOptionPresent()` logic is preserved:
- When editing a zone whose parent is not in the cache, the parent is fetched via `get_zone(parent_id)`
- This ensures the parent appears in the combobox even if paginated out
- Works in conjunction with server search for a complete solution

## Testing

### Manual Testing Checklist

On a large instance (1 master + 300 includes + ~15k records):

- [ ] **Zones tab search**: Type "fic001" in `#searchInput` → Zone appears (server search invoked)
- [ ] **Parent combobox**: Edit an include whose parent is out of page 1 → Parent appears in combobox
- [ ] **DNS tab zone select**: Type zone name (2+ chars) → Zone found via server search
- [ ] **Console traces**: Verify `console.debug` traces appear confirming code paths
- [ ] **ACL respect**: As non-admin, verify only authorized zones appear (server-side filtering)

### Debug Traces

Search for these console messages to confirm behavior:

```javascript
// Zone Files search
[attachZoneSearchInput] Server search for query: fic001
[attachZoneSearchInput] Server search returned 1 results

// Zone File combobox
[initZoneFileCombobox] Using server search for query: fic
[serverSearchZones] Searching with query: fic file_type: all limit: 100
[serverSearchZones] Found 15 results

// Parent combobox
[populateIncludeParentCombobox] Using server search for query: master
[serverSearchZones] Found 3 results

// DNS zone combobox
[DNS initZoneCombobox] Using server search for query: test
```

## Performance Considerations

### Client Cache Still Used

The client cache (`window.ZONES_ALL`) is **not removed**:
- Used for initial page load (first 100 zones)
- Used for very short queries (< 2 chars)
- Used as fallback when server search fails
- Restored when search is cleared (empty query)

### Debouncing

All search inputs are debounced:
- Zone search: 250ms
- Zone comboboxes: Triggered on `input` event
- Include search: 300ms

This prevents excessive API calls while typing.

### Pagination

- Server search endpoint (`search_zones`) does not return pagination metadata
- Results are limited by `limit` parameter (default 100)
- For very large result sets, users should type more specific queries
- Client-side pagination is disabled when showing server search results

## Future Improvements

Potential enhancements (not in current scope):

1. **Typeahead UI**: Replace select dropdowns with full typeahead components
2. **Recent searches**: Cache recent successful searches client-side
3. **Fuzzy matching**: Add fuzzy search support on server side
4. **Result highlights**: Highlight matching text in search results
5. **Keyboard navigation**: Enhanced arrow key navigation in combobox lists

## Related Documentation

- **Pagination**: See `docs/archive/PR_SUMMARY_PAGINATION.md` for API pagination details
- **Zone Files**: See `docs/ZONE_FILES_QUICK_REFERENCE.md` (if exists) for zone management
- **API Reference**: See `api/zone_api.php` for endpoint documentation

## Rollback Plan

If issues arise, the changes can be reverted by:

1. Restore `attachZoneSearchInput()` to client-first strategy
2. Remove `serverSearch` option from `initCombobox()`
3. Restore original `initZoneFileCombobox()` and `initZoneCombobox()`
4. Remove server search calls from parent combobox

The implementation is backward-compatible and gracefully degrades if the server search endpoint is unavailable.

---

**Last Updated**: 2025-12-09  
**Author**: GitHub Copilot  
**Related PR**: feat/server-search-fallback-zones-dns
