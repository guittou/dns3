# Zone File Selection Fallback Search Fix

## Problem Statement

On the **Zones** tab, when a user types or selects a zone file that is not in the first 100 preloaded entries, the domain field does not populate and the zone remains unfound. The zone file field relies on a paginated cache and does not perform server-side searches for zones outside the preloaded list.

## Root Cause

The zone file combobox uses a client-side cache (`CURRENT_ZONE_LIST` and `ZONES_ALL`) which is initially populated with the first 100 entries. When a user selects a zone that is not in this cache:

1. The `onZoneFileSelected` function was called with the zone ID
2. The zone was not found in the local caches (`ZONES_ALL`, `CURRENT_ZONE_LIST`, or `allMasters`)
3. Although there was an API fallback to fetch the zone, the fetched zone was only used for display purposes
4. The fetched zone was **not** added to the caches
5. Downstream operations (like `setDomainForZone` and `populateZoneComboboxForDomain`) could not find the zone in the cache
6. The domain field remained empty and the zone combobox was not properly enabled

## Solution

The fix adds proper cache management when zones are fetched from the API as a fallback:

### Changes in `zone-files.js`

Modified `onZoneFileSelected` function (lines 2111-2194):

1. **Added cache update after API fallback fetch**: When a zone is fetched from the API because it's not in the cache, it is now added to:
   - `window.ZONES_ALL` - global cache of all zones
   - `window.CURRENT_ZONE_LIST` - currently filtered/displayed zones
   - `allMasters` - if the zone is a master type

2. **Added explicit call to setDomainForZone**: After fetching and caching the zone, explicitly calls `setDomainForZone(zone.id)` to:
   - Populate the domain field
   - Populate the zone combobox for the selected domain
   - Enable the zone file combobox

### Changes in `dns-records.js`

Modified `setDomainForZone` function (lines 1069-1500):

1. **Added cache update after initial zone fetch**: When a zone is fetched from the API at the start of the function, it is now added to:
   - `window.ALL_ZONES` - global cache
   - `window.CURRENT_ZONE_LIST` - current zone list

This ensures consistency with the existing fallback logic that was already present for later fallback scenarios.

## Technical Details

### Caching Strategy

The solution maintains multiple caches for different purposes:

- **`ZONES_ALL` / `window.ZONES_ALL`**: Contains all zones seen by the user (grows over time as zones are accessed)
- **`CURRENT_ZONE_LIST` / `window.CURRENT_ZONE_LIST`**: Contains zones for the currently selected domain/master
- **`allMasters`**: Contains only master zones

When a zone is fetched from the API, it should be added to all relevant caches to ensure it's available for:
- Display in the combobox
- Domain field population
- Zone file combobox filtering
- Future operations without additional API calls

### API Calls

The solution uses existing API endpoints:
- `zone_api.php?action=get_zone&id=X` - Fetch a specific zone by ID
- `zone_api.php?action=search_zones&q=<text>&limit=100` - Server-side search (already used by the combobox)

No new API endpoints were required.

### Performance Considerations

The solution maintains good performance characteristics:

1. **Local cache first**: Always checks local caches (`ZONES_ALL`, `CURRENT_ZONE_LIST`) before making API calls
2. **Server search for queries ≥2 chars**: The existing `initServerSearchCombobox` already uses server-side search for queries with 2+ characters
3. **Fallback only when needed**: API calls are only made when a zone is not found in local caches
4. **Cache deduplication**: Before adding zones to caches, checks if they already exist to avoid duplicates

## Testing Checklist

- [ ] **Test 1: Zone in first 100 entries**
  - Select a zone that is in the preloaded cache
  - Verify domain field is populated
  - Verify zone combobox is enabled
  - Verify no additional API calls are made

- [ ] **Test 2: Zone outside first 100 entries**
  - Type the name of a zone that is NOT in the preloaded cache
  - Verify zone is found via server search
  - Verify domain field is populated
  - Verify zone combobox is enabled
  - Verify zone is added to caches for future use

- [ ] **Test 3: Non-existent zone**
  - Type the name of a zone that does not exist
  - Verify appropriate error handling
  - Verify UI remains stable

- [ ] **Test 4: Performance**
  - Verify no performance degradation for common use cases
  - Verify API calls are not duplicated
  - Verify cache grows appropriately but not excessively

## Expected Behavior

After this fix:

1. **Zone selection always works**: Users can select any zone, regardless of whether it's in the preloaded cache
2. **Domain field is populated**: When a zone is selected, the domain field is automatically filled
3. **Zone combobox is enabled**: After domain/zone selection, the zone file combobox is enabled for further operations
4. **No performance impact**: Zones in the preloaded cache are served from the client-side cache (no API call)
5. **Fallback for missing zones**: Zones not in the cache are fetched from the API and cached for future use

## Files Modified

1. `/home/runner/work/dns3/dns3/assets/js/zone-files.js`
   - Modified `onZoneFileSelected` function to add fetched zones to caches and call `setDomainForZone`

2. `/home/runner/work/dns3/dns3/assets/js/dns-records.js`
   - Modified `setDomainForZone` function to add fetched zones to caches immediately after fetching

## Related Files

The following files work together to provide the zone selection functionality:

- `assets/js/zone-combobox-shared.js` - Provides shared combobox initialization and server search
- `api/zone_api.php` - Provides API endpoints for zone operations
- `assets/js/zone-files.js` - Zone management page logic
- `assets/js/dns-records.js` - DNS records management page logic

## Validation

To validate this fix:

1. Create more than 100 zone files in the database
2. On the Zones tab, search for a zone file that is beyond the first 100 entries
3. Select that zone file
4. Verify the domain field is populated
5. Verify the zone file combobox is enabled
6. Verify subsequent operations (like creating DNS records) work correctly

## Conclusion

This fix ensures that the zone file selection works consistently regardless of the number of zones in the database. It maintains the existing performance characteristics while adding proper fallback handling for zones outside the preloaded cache.
