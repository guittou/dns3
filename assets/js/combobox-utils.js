/**
 * Combobox Utilities - Shared helpers for DNS and ZONES pages
 * Provides reusable combobox functionality to unify behavior across pages
 */

(function() {
    'use strict';

    /**
     * Constants
     */
    const COMBOBOX_BLUR_DELAY = 200; // Delay in ms before hiding combobox list on blur

    /**
     * Populate a combobox list with items
     * Generic function used by both DNS and ZONES pages for consistent behavior
     * 
     * @param {HTMLElement} listElement - The <ul> element to populate
     * @param {Array} items - Array of items to display
     * @param {Function} itemMapper - Function that maps each item to {id, text}
     * @param {Function} onSelect - Function called when an item is selected
     */
    function populateComboboxList(listElement, items, itemMapper, onSelect) {
        if (!listElement) return;
        
        listElement.innerHTML = '';
        
        if (items.length === 0) {
            const li = document.createElement('li');
            li.className = 'combobox-item empty';
            li.textContent = 'Aucun résultat';
            listElement.appendChild(li);
            listElement.style.display = 'block';
            return;
        }
        
        items.forEach(item => {
            const mapped = itemMapper(item);
            const li = document.createElement('li');
            li.className = 'combobox-item';
            li.textContent = mapped.text;
            li.dataset.id = mapped.id;
            
            li.addEventListener('click', () => {
                onSelect(item);
            });
            
            listElement.appendChild(li);
        });
        
        listElement.style.display = 'block';
    }

    /**
     * Ensure zones cache is populated
     * Checks window.ZONES_ALL first, falls back to window.ALL_ZONES, then fetches from API if needed
     * Populates both ZONES_ALL and ALL_ZONES for compatibility
     * 
     * @returns {Promise<Array>} - Array of zones
     */
    async function ensureZonesCache() {
        try {
            // Check if already cached
            if (Array.isArray(window.ZONES_ALL) && window.ZONES_ALL.length > 0) {
                return window.ZONES_ALL;
            }
            if (Array.isArray(window.ALL_ZONES) && window.ALL_ZONES.length > 0) {
                window.ZONES_ALL = window.ALL_ZONES;
                return window.ZONES_ALL;
            }
            
            // Fetch from API if not cached
            let zones = [];
            if (typeof window.zoneApiCall === 'function') {
                const res = await window.zoneApiCall('list_zones', { params: { status: 'active', per_page: 1000 } });
                zones = (res && res.data) ? res.data : [];
            } else {
                // Fallback to fetch if zoneApiCall not available
                const apiBase = window.API_BASE || '/api/';
                const url = new URL(apiBase + 'zone_api.php', window.location.origin);
                url.searchParams.append('action', 'list_zones');
                url.searchParams.append('status', 'active');
                url.searchParams.append('per_page', '1000');
                
                const response = await fetch(url.toString(), {
                    method: 'GET',
                    headers: { 'Accept': 'application/json' },
                    credentials: 'same-origin'
                });
                
                const data = await response.json();
                if (data.success) {
                    zones = data.data || [];
                }
            }
            
            // Populate both caches for compatibility
            window.ZONES_ALL = zones;
            window.ALL_ZONES = zones;
            
            return zones;
        } catch (e) {
            console.warn('[ensureZonesCache] Failed to load zones:', e);
            // Initialize as empty array if not already set
            window.ZONES_ALL = window.ZONES_ALL || [];
            window.ALL_ZONES = window.ALL_ZONES || [];
            return window.ZONES_ALL;
        }
    }

    /**
     * Initialize a combobox with standard event handlers
     * Provides consistent behavior across all comboboxes
     * 
     * @param {Object} opts - Configuration options
     * @param {HTMLElement} opts.input - The input element
     * @param {HTMLElement} opts.list - The list element
     * @param {Function} opts.getItems - Function that returns items to display (can be async)
     * @param {Function} opts.filterItems - Function to filter items based on query
     * @param {Function} opts.mapItem - Function to map item to {id, text}
     * @param {Function} opts.onSelect - Function called when item is selected
     */
    function initCombobox(opts) {
        const { input, list, getItems, filterItems, mapItem, onSelect } = opts;
        
        if (!input || !list) {
            console.warn('[initCombobox] Missing required elements');
            return;
        }
        
        // Input event - filter and show list
        input.addEventListener('input', async () => {
            const query = input.value.toLowerCase().trim();
            let items = await getItems();
            
            if (filterItems) {
                items = filterItems(items, query);
            }
            
            populateComboboxList(list, items, mapItem, onSelect);
        });
        
        // Focus - show all items
        input.addEventListener('focus', async () => {
            const items = await getItems();
            populateComboboxList(list, items, mapItem, onSelect);
        });
        
        // Blur - hide list (with delay to allow click)
        input.addEventListener('blur', () => {
            setTimeout(() => {
                list.style.display = 'none';
            }, COMBOBOX_BLUR_DELAY);
        });
        
        // Escape key - close list
        input.addEventListener('keydown', (e) => {
            if (e.key === 'Escape') {
                list.style.display = 'none';
                input.blur();
            }
        });
    }

    // Expose functions globally for use by both DNS and ZONES pages
    window.populateComboboxList = populateComboboxList;
    window.ensureZonesCache = ensureZonesCache;
    window.initCombobox = initCombobox;
    
    // Export constant for consistent behavior
    window.COMBOBOX_BLUR_DELAY = COMBOBOX_BLUR_DELAY;
})();
