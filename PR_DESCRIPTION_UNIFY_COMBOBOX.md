# PR: Unify Zone File Combobox Behavior Between Zones and DNS Tabs

## Summary

This PR harmonizes zone file combobox behavior between the Zones and DNS tabs to provide a consistent user experience on large instances (~300 includes, ~15k records).

## Problem

On large instances, the zone file combobox behavior was inconsistent:
- **DNS tab**: Used server-first search and could find files like "fic001"
- **Zones tab**: Relied on limited paginated cache and didn't display certain files
- **Both tabs**: Zone file combobox was always enabled, even without domain context

## Solution

### Changes Made

**Commit 1: Add setZoneFileComboboxEnabled helper (zone-files.js)**
- Implemented `setZoneFileComboboxEnabled(enabled)` utility to enable/disable zone file combobox based on domain selection
- Updated `initZoneFileCombobox()` to start with disabled state if no domain selected
- Updated `onZoneDomainSelected()` to enable combobox after population
- Updated `setDomainForZone()` to enable/disable combobox based on zone availability
- Exposed `setZoneFileComboboxEnabled` globally for cross-file access
- Updated documentation in `IMPLEMENTATION_SUMMARY_PAGINATION.md`

**Commit 2: Apply same behavior to DNS tab (dns-records.js)**
- Implemented `setDnsZoneComboboxEnabled(enabled)` utility for DNS zone combobox
- Updated `initZoneCombobox()` to start with disabled state if no domain selected
- Updated `selectDomain()` to enable combobox after domain selection or disable if cleared
- Updated `resetDomainZoneFilters()` to disable combobox when filters are reset
- Updated `setDomainForZone()` to enable/disable combobox based on zone availability
- Exposed `setDnsZoneComboboxEnabled` globally

### Key Features

1. **Server-First Search Strategy** (already implemented, now consistently applied)
   - For queries ≥2 characters: calls `search_zones` API endpoint
   - For short queries (<2 chars): uses client-side cache as fallback
   - Handles large datasets efficiently without preloading all zones

2. **Consistent UX** (NEW)
   - Zone file combobox is **disabled** (grayed out) when no domain is selected
   - Becomes **enabled** and populated after domain selection
   - Shows master first, then includes sorted alphabetically
   - Same behavior on both Zones and DNS tabs

3. **Preserves Existing Functionality**
   - `ensureParentOptionPresent` still works (fallback get_zone(parent_id))
   - Server-side ACL filtering respected
   - Backward compatible with existing code

## Manual Testing Checklist

### DNS Tab Testing
- [ ] Hard-refresh after deploying assets (Ctrl+F5 or Cmd+Shift+R)
- [ ] **Without domain selected**: 
  - Zone file combobox is disabled (grayed out) and empty
  - Placeholder shows "Sélectionnez d'abord un domaine"
- [ ] **After selecting domain**: 
  - Zone file combobox becomes enabled
  - Shows master first, then includes sorted alphabetically
- [ ] **Server-first search**: 
  - Typing "fic001" (≥2 chars) finds zones via server search
  - Search returns results even if zone is not in first 100 paginated results
- [ ] **Reset filters**: 
  - Zone file combobox becomes disabled again
  - Placeholder returns to "Sélectionnez d'abord un domaine"

### Zones Tab Testing
- [ ] **Without domain selected**: 
  - Zone file combobox is disabled (grayed out) and empty
  - Placeholder shows "Sélectionnez d'abord un domaine"
- [ ] **After selecting domain**: 
  - Zone file combobox becomes enabled and populated correctly
  - Shows master first, then includes sorted
- [ ] **Server-first search**: 
  - Typing zone names (≥2 chars) works and finds zones
  - Can find zones like "fic001" that weren't in cache
- [ ] **Reset/deselect domain**: 
  - Zone file combobox becomes disabled again

### Cross-Tab Verification
- [ ] Verify `ensureParentOptionPresent` still works in include edit modals
- [ ] Verify API continues to apply ACLs (non-admin sees fewer results)
- [ ] Check browser console for debug traces:
  - `[initServerSearchCombobox]` when initializing
  - `[setZoneFileComboboxEnabled]` when enabling/disabling (Zones tab)
  - `[setDnsZoneComboboxEnabled]` when enabling/disabling (DNS tab)

## Performance & Security Notes

⚠️ **Performance**: 
- `search_zones` endpoint is limited (default 20 results, max 100)
- No performance impact expected
- Reduces initial page load by not preloading all zones

⚠️ **Security/ACLs**: 
- All searches go through server-side filtering
- Non-admin users only see zones they have access to
- ACL enforcement is consistent across both tabs

## Documentation

Updated `docs/IMPLEMENTATION_SUMMARY_PAGINATION.md` with:
- Server-first search strategy details
- Combobox state management behavior
- Enable/disable functionality based on domain selection

## Files Changed

- `assets/js/zone-files.js` - Added `setZoneFileComboboxEnabled()` and wired it into domain selection flows
- `assets/js/dns-records.js` - Added `setDnsZoneComboboxEnabled()` and wired it into domain selection flows
- `docs/IMPLEMENTATION_SUMMARY_PAGINATION.md` - Updated documentation

## Branch Information

- **Source branch**: `feat/unify-zone-combobox-server-first`
- **Target branch**: `main` (or current default branch)
- **Commits**: 2 atomic commits as requested

## Related Issues

Fixes inconsistent zone file combobox behavior between Zones and DNS tabs on large instances (300+ masters, ~15k records).

## Screenshots

_To be added after deployment for visual verification of disabled/enabled states_

## Deployment Notes

- Hard refresh required after deployment (Ctrl+F5 or Cmd+Shift+R)
- No database changes required
- No configuration changes required
- Backward compatible with existing functionality
