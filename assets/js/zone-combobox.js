/**
 * Zone Combobox Helpers - Shared utilities for consistent zone list ordering
 * 
 * This module provides reusable helpers to construct and render zone lists
 * with consistent ordering: master zone first, then all includes sorted alphabetically.
 * 
 * Used by:
 * - assets/js/zone-files.js (Zones tab)
 * - assets/js/dns-records.js (DNS Records tab)
 */

(function(window) {
    'use strict';

    /**
     * Sort zones alphabetically by name (or filename fallback), case-insensitive
     * @param {Array} zones - Array of zone objects to sort
     * @returns {Array} - New array with zones sorted alphabetically (does not mutate original)
     */
    function sortZonesAlphabetically(zones) {
        if (!Array.isArray(zones)) return [];
        
        return zones.slice().sort((a, b) => {
            const nameA = (a.name || a.filename || '').toLowerCase();
            const nameB = (b.name || b.filename || '').toLowerCase();
            return nameA.localeCompare(nameB);
        });
    }

    /**
     * Create ordered zone list: master first, then includes sorted alphabetically
     * 
     * @param {Array} zones - Array of all zone objects
     * @param {number|null} masterId - ID of the master zone (null if no domain selected)
     * @returns {Array} - Ordered array: [masterZone, ...includesSorted] or [all zones sorted by type+name]
     * 
     * Behavior:
     * - If masterId is null/0: returns all masters sorted, then all includes sorted
     * - If masterId is provided: returns the specific master + its includes sorted
     * - Deduplicates zones by ID
     * - Case-insensitive alphabetical sorting by name (or filename fallback)
     * 
     * @example
     * // With master selected
     * const ordered = makeOrderedZoneList(zones, 5);
     * // Returns: [masterZone5, includeA, includeB, includeC]
     * 
     * // Without master selected (all zones)
     * const ordered = makeOrderedZoneList(zones, null);
     * // Returns: [masterA, masterB, includeA, includeB, includeC]
     */
    function makeOrderedZoneList(zones, masterId) {
        if (!Array.isArray(zones)) return [];
        
        // Deduplicate zones by ID (keep first occurrence)
        const seen = new Set();
        const dedupedZones = zones.filter(zone => {
            const id = String(zone.id !== undefined && zone.id !== null ? zone.id : '');
            if (id === '' || seen.has(id)) return false;
            seen.add(id);
            return true;
        });
        
        // Normalize file_type to lowercase for consistent comparisons
        const normalizedZones = dedupedZones.map(z => ({
            ...z,
            _normalized_type: (z.file_type || '').toLowerCase().trim()
        }));
        
        // Case 1: No master selected - return all masters sorted, then all includes sorted
        if (!masterId || parseInt(masterId, 10) === 0) {
            const masters = normalizedZones.filter(z => z._normalized_type === 'master');
            const includes = normalizedZones.filter(z => z._normalized_type === 'include');
            
            const sortedMasters = sortZonesAlphabetically(masters);
            const sortedIncludes = sortZonesAlphabetically(includes);
            
            return [...sortedMasters, ...sortedIncludes];
        }
        
        // Case 2: Master selected - return master + its includes sorted
        const masterIdNum = parseInt(masterId, 10);
        const masterZone = normalizedZones.find(z => 
            parseInt(z.id, 10) === masterIdNum && z._normalized_type === 'master'
        );
        
        // Filter includes that belong to this master (direct or indirect via parent_id)
        const includeZones = normalizedZones.filter(z => {
            if (z._normalized_type !== 'include') return false;
            
            // Check if this zone's parent chain contains the master
            let currentZone = z;
            let iterations = 0;
            const maxIterations = 50; // Safety limit
            
            while (currentZone && iterations < maxIterations) {
                iterations++;
                const parentId = parseInt(currentZone.parent_id || 0, 10);
                
                if (parentId === masterIdNum) {
                    return true; // Found the master in the ancestor chain
                }
                
                if (parentId === 0 || !parentId) {
                    break; // No more parents
                }
                
                // Find the parent zone in the list
                currentZone = normalizedZones.find(parent => 
                    parseInt(parent.id, 10) === parentId
                );
            }
            
            return false;
        });
        
        const sortedIncludes = sortZonesAlphabetically(includeZones);
        
        return masterZone ? [masterZone, ...sortedIncludes] : sortedIncludes;
    }

    /**
     * Fill a select element with ordered zones
     * 
     * @param {HTMLSelectElement} selectEl - The select element to populate
     * @param {Array} orderedZones - Pre-ordered array of zones (from makeOrderedZoneList)
     * @param {number|string|null} selectedId - ID of zone to pre-select (optional)
     * @param {Object} options - Optional configuration
     * @param {Function} options.formatText - Custom formatter for option text (default: zone => `${zone.name} (${zone.file_type})`)
     * @param {boolean} options.includeEmpty - Whether to include an empty "Select..." option (default: false)
     * @param {string} options.emptyText - Text for empty option (default: "-- Sélectionner --")
     * 
     * @example
     * const select = document.getElementById('zone-select');
     * const ordered = makeOrderedZoneList(zones, masterId);
     * fillSelectWithOrderedZones(select, ordered, selectedId, {
     *   formatText: z => `${z.name} [${z.file_type}]`,
     *   includeEmpty: true
     * });
     */
    function fillSelectWithOrderedZones(selectEl, orderedZones, selectedId, options = {}) {
        if (!selectEl || !(selectEl instanceof HTMLSelectElement)) {
            console.warn('[fillSelectWithOrderedZones] Invalid select element');
            return;
        }
        
        const opts = {
            formatText: options.formatText || (zone => `${zone.name || zone.filename} (${zone.file_type})`),
            includeEmpty: options.includeEmpty || false,
            emptyText: options.emptyText || '-- Sélectionner --'
        };
        
        // Clear existing options
        selectEl.innerHTML = '';
        
        // Add empty option if requested
        if (opts.includeEmpty) {
            const emptyOption = document.createElement('option');
            emptyOption.value = '';
            emptyOption.textContent = opts.emptyText;
            selectEl.appendChild(emptyOption);
        }
        
        // Add zone options
        if (!Array.isArray(orderedZones) || orderedZones.length === 0) {
            // If no zones, optionally add a "no results" option
            if (!opts.includeEmpty) {
                const noResultOption = document.createElement('option');
                noResultOption.value = '';
                noResultOption.textContent = 'Aucune zone disponible';
                noResultOption.disabled = true;
                selectEl.appendChild(noResultOption);
            }
            return;
        }
        
        orderedZones.forEach(zone => {
            const option = document.createElement('option');
            option.value = zone.id || '';
            option.textContent = opts.formatText(zone);
            selectEl.appendChild(option);
        });
        
        // Set selected value after all options are added
        if (selectedId !== null && selectedId !== undefined && selectedId !== '') {
            selectEl.value = String(selectedId);
        }
    }

    /**
     * Populate a combobox list (ul element) with ordered zones
     * Used for custom combobox implementations (not standard select elements)
     * 
     * @param {HTMLElement} listElement - The ul element to populate
     * @param {Array} orderedZones - Pre-ordered array of zones (from makeOrderedZoneList)
     * @param {Function} onSelectCallback - Callback when a zone is clicked: (zone) => void
     * @param {Object} options - Optional configuration
     * @param {Function} options.formatText - Custom formatter for list item text
     * @param {boolean} options.showList - Whether to show the list after populating (default: true)
     * @param {string} options.emptyText - Text when no zones available (default: "Aucun résultat")
     * 
     * @example
     * const list = document.getElementById('zone-list');
     * const ordered = makeOrderedZoneList(zones, masterId);
     * populateComboboxListWithOrderedZones(list, ordered, (zone) => {
     *   console.log('Selected:', zone.name);
     * });
     */
    function populateComboboxListWithOrderedZones(listElement, orderedZones, onSelectCallback, options = {}) {
        if (!listElement) {
            console.warn('[populateComboboxListWithOrderedZones] Invalid list element');
            return;
        }
        
        const opts = {
            formatText: options.formatText || (zone => `${zone.name || zone.filename} (${zone.file_type})`),
            showList: options.showList !== undefined ? options.showList : true,
            emptyText: options.emptyText || 'Aucun résultat'
        };
        
        // Clear existing items
        listElement.innerHTML = '';
        
        // Handle empty list
        if (!Array.isArray(orderedZones) || orderedZones.length === 0) {
            const li = document.createElement('li');
            li.className = 'combobox-item combobox-empty';
            li.textContent = opts.emptyText;
            listElement.appendChild(li);
            
            if (opts.showList) {
                listElement.style.display = 'block';
                listElement.setAttribute('aria-hidden', 'false');
            } else {
                listElement.style.display = 'none';
                listElement.setAttribute('aria-hidden', 'true');
            }
            return;
        }
        
        // Add zone items
        orderedZones.forEach(zone => {
            const li = document.createElement('li');
            li.className = 'combobox-item';
            li.textContent = opts.formatText(zone);
            li.dataset.id = zone.id || '';
            
            if (typeof onSelectCallback === 'function') {
                li.addEventListener('click', () => {
                    try {
                        onSelectCallback(zone);
                    } catch (e) {
                        console.error('[populateComboboxListWithOrderedZones] onSelect error:', e);
                    }
                });
            }
            
            listElement.appendChild(li);
        });
        
        // Show/hide list
        if (opts.showList) {
            listElement.style.display = 'block';
            listElement.setAttribute('aria-hidden', 'false');
        } else {
            listElement.style.display = 'none';
            listElement.setAttribute('aria-hidden', 'true');
        }
    }
    
    /**
     * Populate zone list for a specific domain (master zone)
     * Fetches zones from API and returns ordered list
     * 
     * @param {number} domainId - Master zone ID (domain)
     * @returns {Promise<Array>} - Ordered array of zones (master first, then includes sorted A-Z)
     * 
     * @example
     * const ordered = await populateZoneListForDomain(5);
     * // Returns: [masterZone5, includeA, includeB, includeC]
     */
    async function populateZoneListForDomain(domainId) {
        if (!domainId) {
            console.warn('[populateZoneListForDomain] No domainId provided');
            return [];
        }
        
        const domainIdNum = parseInt(domainId, 10);
        if (isNaN(domainIdNum) || domainIdNum <= 0) {
            console.warn('[populateZoneListForDomain] Invalid domainId:', domainId);
            return [];
        }
        
        try {
            let result;
            
            // Try zoneApiCall if available (preferred)
            if (typeof window.zoneApiCall === 'function') {
                try {
                    // Note: zone-files.js zoneApiCall expects { params: {...} }
                    // dns-records.js zoneApiCall expects params directly as second argument
                    // Try both patterns for compatibility
                    result = await window.zoneApiCall('list_zone_files', { params: { domain_id: domainIdNum } });
                } catch (e) {
                    console.warn('[populateZoneListForDomain] list_zone_files failed, trying fallback:', e);
                    // Fallback to list_zones_by_domain API
                    // Note: Different API versions use different parameter names (zone_id vs domain_id)
                    // We try both for backward compatibility
                    if (typeof window.apiCall === 'function') {
                        try {
                            result = await window.apiCall('list_zones_by_domain', { zone_id: domainIdNum });
                        } catch (e2) {
                            result = await window.apiCall('list_zones_by_domain', { domain_id: domainIdNum });
                        }
                    } else {
                        throw new Error('No API call function available');
                    }
                }
            } else if (typeof window.apiCall === 'function') {
                // Use apiCall as fallback when zoneApiCall not available
                // Note: Different API versions use different parameter names (zone_id vs domain_id)
                // We try both for backward compatibility
                try {
                    result = await window.apiCall('list_zones_by_domain', { zone_id: domainIdNum });
                } catch (e) {
                    result = await window.apiCall('list_zones_by_domain', { domain_id: domainIdNum });
                }
            } else {
                throw new Error('No API call function available (zoneApiCall or apiCall)');
            }
            
            const zones = result.data || [];
            
            // Use makeOrderedZoneList for consistent ordering
            const orderedZones = makeOrderedZoneList(zones, domainIdNum);
            
            console.debug('[populateZoneListForDomain] Fetched and ordered', orderedZones.length, 'zones for domain', domainIdNum);
            
            return orderedZones;
            
        } catch (error) {
            console.error('[populateZoneListForDomain] Failed to populate zones for domain:', domainIdNum, error);
            return [];
        }
    }

    // Export functions to window for global access
    window.ZoneComboboxHelpers = {
        makeOrderedZoneList: makeOrderedZoneList,
        fillSelectWithOrderedZones: fillSelectWithOrderedZones,
        populateComboboxListWithOrderedZones: populateComboboxListWithOrderedZones,
        sortZonesAlphabetically: sortZonesAlphabetically,
        populateZoneListForDomain: populateZoneListForDomain
    };
    
    // Also export individual functions for backward compatibility
    window.makeOrderedZoneList = makeOrderedZoneList;
    window.fillSelectWithOrderedZones = fillSelectWithOrderedZones;
    window.populateComboboxListWithOrderedZones = populateComboboxListWithOrderedZones;
    window.populateZoneListForDomain = populateZoneListForDomain;
    
})(window);
