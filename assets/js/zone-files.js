/**
 * Zone Files Management JavaScript - Paginated List View
 * Handles paginated table view for zone file management
 */

// --- BEGIN: local copy of combobox helpers (populateComboboxList, initCombobox) ---
function populateComboboxList(listElement, items, itemMapper, onSelect, showList = true) {
    if (!listElement) return;
    listElement.innerHTML = '';

    if (!Array.isArray(items) || items.length === 0) {
        const li = document.createElement('li');
        li.className = 'combobox-item combobox-empty';
        li.textContent = 'Aucun résultat';
        listElement.appendChild(li);
        if (showList) {
            listElement.style.display = 'block';
            listElement.setAttribute('aria-hidden', 'false');
        } else {
            listElement.style.display = 'none';
            listElement.setAttribute('aria-hidden', 'true');
        }
        return;
    }

    items.forEach(item => {
        const mapped = itemMapper(item);
        const li = document.createElement('li');
        li.className = 'combobox-item';
        li.textContent = mapped.text;
        li.dataset.id = mapped.id;
        li.addEventListener('click', () => {
            try { onSelect(item); } catch (e) { console.error('combobox onSelect error', e); }
        });
        listElement.appendChild(li);
    });

    if (showList) {
        listElement.style.display = 'block';
        listElement.setAttribute('aria-hidden', 'false');
    } else {
        listElement.style.display = 'none';
        listElement.setAttribute('aria-hidden', 'true');
    }
}

// Lightweight reusable combobox initializer with server search support
// opts: { inputEl, listEl, hiddenEl?, getItems?:fn, serverSearch?:fn, mapItem:fn, onSelectItem:fn, blurDelay, minCharsForServer }
function initCombobox(opts) {
    const input = opts.inputEl;
    const list = opts.listEl;
    const hidden = opts.hiddenEl || null;
    const blurDelay = opts.blurDelay || 150;
    const minCharsForServer = opts.minCharsForServer || 2; // Minimum chars to trigger server search
    if (!input || !list) return;

    async function showItems(items) {
        populateComboboxList(list, items, opts.mapItem, (it) => {
            if (hidden) hidden.value = opts.mapItem(it).id || '';
            if (typeof opts.onSelectItem === 'function') opts.onSelectItem(it);
        });
    }

    input.readOnly = false;

    input.addEventListener('input', async () => {
        const q = (input.value || '').toLowerCase().trim();
        
        // Server-first strategy: if query ≥ minCharsForServer and serverSearch available, use it
        if (q.length >= minCharsForServer && typeof opts.serverSearch === 'function') {
            console.debug('[initCombobox] Using server search for query:', q);
            try {
                const serverItems = await opts.serverSearch(q);
                showItems(serverItems);
                return;
            } catch (err) {
                console.warn('[initCombobox] Server search failed, fallback to client:', err);
                // Fall through to client filtering
            }
        }
        
        // Client filtering (for short queries or server search not available/failed)
        let items = (typeof opts.getItems === 'function') ? await opts.getItems() : (opts.items || []);
        if (q) {
            items = (items || []).filter(i => (opts.mapItem(i).text || '').toLowerCase().includes(q));
        }
        showItems(items);
    });

    input.addEventListener('focus', async () => {
        const items = (typeof opts.getItems === 'function') ? await opts.getItems() : (opts.items || []);
        showItems(items);
    });

    input.addEventListener('blur', () => {
        setTimeout(() => { list.style.display = 'none'; }, blurDelay);
    });

    input.addEventListener('keydown', (e) => {
        if (e.key === 'Escape') {
            list.style.display = 'none';
            input.blur();
        } else if (e.key === 'Enter') {
            const first = list.querySelector('.combobox-item');
            if (first) first.click();
            e.preventDefault();
        }
    });

    return { refresh: async () => {
        const items = (typeof opts.getItems === 'function') ? await opts.getItems() : (opts.items || []);
        showItems(items);
    }};
}
// --- END: local copy of combobox helpers ---

// =========================================================================
// Business helper functions (copied from dns-records.js for autonomy)
// =========================================================================

// Constants for zone hierarchy traversal
// MAX_PARENT_CHAIN_DEPTH: Safety limit to prevent infinite loops in malformed parent chains
// Typical zone hierarchies are 2-5 levels deep (master -> include -> nested include)
// 20 provides ample headroom for complex configurations while preventing runaway loops
const MAX_PARENT_CHAIN_DEPTH = 20;

/**
 * Sort zones alphabetically by name (case-insensitive)
 * Used to harmonize combobox behavior between DNS and Zones tabs
 * @param {Array} zones - Array of zone objects to sort
 * @returns {Array} - New array with zones sorted alphabetically by name (does not mutate original)
 * @example
 * const sorted = sortZonesAlphabetically([{name: 'zulu'}, {name: 'alpha'}]);
 * // Returns: [{name: 'alpha'}, {name: 'zulu'}]
 */
function sortZonesAlphabetically(zones) {
    return zones.slice().sort((a, b) => {
        const nameA = (a.name || '').toLowerCase();
        const nameB = (b.name || '').toLowerCase();
        return nameA.localeCompare(nameB);
    });
}

/**
 * Check if a zone is in a master's tree by traversing its parent chain
 * @param {Object} zone - The zone object to check
 * @param {number} masterId - The master zone ID to look for
 * @param {Array} zoneList - List of zones to search for parents
 * @returns {boolean} True if zone's parent chain contains masterId
 */
function isZoneInMasterTree(zone, masterId, zoneList) {
    if (!zone || !masterId) return false;
    
    const masterIdNum = parseInt(masterId, 10);
    if (parseInt(zone.id, 10) === masterIdNum) return true; // Zone is the master itself
    
    let currentZone = zone;
    let iterations = 0;
    
    while (currentZone && iterations < MAX_PARENT_CHAIN_DEPTH) {
        iterations++;
        
        const parentId = currentZone.parent_id ? parseInt(currentZone.parent_id, 10) : null;
        if (!parentId) break;
        
        if (parentId === masterIdNum) {
            return true; // Found master in parent chain
        }
        
        // Find parent in zoneList
        currentZone = zoneList.find(z => parseInt(z.id, 10) === parentId);
    }
    
    return false;
}

/**
 * Make an API call with fallback to zoneApiCall
 * This ensures zone-files page can call both dns_api and zone_api endpoints
 */
async function apiCall(action, params = {}, method = 'GET', body = null) {
    // Check if zoneApiCall exists globally (from zone_api.php context)
    if (typeof window.zoneApiCall === 'function') {
        return await window.zoneApiCall(action, { params, method, body });
    }
    
    // Fallback: construct API call manually
    try {
        const apiBase = window.API_BASE || window.BASE_URL || '/api/';
        const normalizedBase = apiBase.endsWith('/') ? apiBase : apiBase + '/';
        const url = new URL(normalizedBase + 'dns_api.php', window.location.origin);
        url.searchParams.append('action', action);
        
        Object.keys(params).forEach(key => {
            url.searchParams.append(key, params[key]);
        });

        const options = {
            method: method,
            headers: {
                'Content-Type': 'application/json',
            },
            credentials: 'same-origin'
        };

        if (body && method !== 'GET') {
            options.body = JSON.stringify(body);
        }

        const response = await fetch(url.toString(), options);
        const text = await response.text();
        
        let data;
        try {
            data = JSON.parse(text);
        } catch (jsonError) {
            console.error('[API Error] Failed to parse JSON response:', jsonError);
            throw new Error('Invalid JSON response from API');
        }

        if (!response.ok) {
            throw new Error(data.error || 'API request failed');
        }

        return data;
    } catch (error) {
        console.error('[API Error] Exception during API call:', error);
        throw error;
    }
}

/**
 * Initialize zones cache with all zones, domains, and masters
 * Sets up: ALL_ZONES, CURRENT_ZONE_LIST, allMasters, allDomains, ZONES_ALL
 */
function initZonesCache() {
    // Initialize cache arrays if not already initialized
    if (!window.ALL_ZONES) window.ALL_ZONES = [];
    if (!window.CURRENT_ZONE_LIST) window.CURRENT_ZONE_LIST = [];
    if (!window.ZONES_ALL) window.ZONES_ALL = [];
    if (typeof allMasters === 'undefined') window.allMasters = [];
    if (typeof allDomains === 'undefined') window.allDomains = [];
}

/**
 * Get master zone ID from any zone ID
 * If zone is an include, returns its parent_id; if master, returns itself
 */
async function getMasterIdFromZoneId(zoneId) {
    if (!zoneId) return null;
    
    const zoneIdNum = parseInt(zoneId, 10);
    if (isNaN(zoneIdNum) || zoneIdNum <= 0) return null;
    
    // Try to find zone in cached lists first
    let zone = null;
    const cachesToCheck = [
        window.ALL_ZONES,
        window.ZONES_ALL,
        window.CURRENT_ZONE_LIST,
        typeof allMasters !== 'undefined' ? allMasters : []
    ];
    
    for (const cache of cachesToCheck) {
        if (Array.isArray(cache) && cache.length > 0) {
            zone = cache.find(z => parseInt(z.id, 10) === zoneIdNum);
            if (zone) break;
        }
    }
    
    // Fallback: fetch from API
    if (!zone) {
        try {
            const result = await zoneApiCall('get_zone', { params: { id: zoneIdNum } });
            zone = result && result.data ? result.data : null;
        } catch (e) {
            console.warn('[getMasterIdFromZoneId] Failed to fetch zone:', e);
            return null;
        }
    }
    
    if (!zone) return null;
    
    // If it's an include, return parent_id; if master, return its own id
    if (zone.file_type === 'include' && zone.parent_id) {
        return parseInt(zone.parent_id, 10);
    } else {
        return zoneIdNum;
    }
}

/**
 * Get the top master (root) zone ID for any zone
 * Recursively traverses up the parent chain
 */
async function getTopMasterId(zoneId) {
    if (!zoneId) return null;
    
    const zoneIdNum = parseInt(zoneId, 10);
    if (isNaN(zoneIdNum) || zoneIdNum <= 0) return null;
    
    let currentZoneId = zoneIdNum;
    let iterations = 0;
    const maxIterations = 20;
    
    while (iterations < maxIterations) {
        iterations++;
        
        // Try to find current zone in caches first
        let zone = null;
        const cachesToCheck = [
            window.CURRENT_ZONE_LIST,
            window.ALL_ZONES,
            window.ZONES_ALL,
            typeof allMasters !== 'undefined' ? allMasters : []
        ];
        
        for (const cache of cachesToCheck) {
            if (Array.isArray(cache) && cache.length > 0) {
                zone = cache.find(z => parseInt(z.id, 10) === currentZoneId);
                if (zone) break;
            }
        }
        
        // Fallback: fetch from API
        if (!zone) {
            try {
                const result = await zoneApiCall('get_zone', { params: { id: currentZoneId } });
                zone = result && result.data ? result.data : null;
            } catch (e) {
                console.warn('[getTopMasterId] Failed to fetch zone:', currentZoneId, e);
                return null;
            }
        }
        
        if (!zone) return null;
        
        // Check if this is a top master (no parent)
        if (!zone.parent_id || zone.parent_id === null || zone.parent_id === 0) {
            return currentZoneId;
        }
        
        // Move up to parent
        const parentId = parseInt(zone.parent_id, 10);
        if (isNaN(parentId) || parentId <= 0) {
            return currentZoneId;
        }
        
        currentZoneId = parentId;
    }
    
    return currentZoneId;
}

/**
 * Fetch zones for a specific master using API with recursive flag
 */
async function fetchZonesForMaster(masterId) {
    if (!masterId) {
        console.warn('[fetchZonesForMaster] No masterId provided');
        return [];
    }
    
    const masterIdNum = parseInt(masterId, 10);
    if (isNaN(masterIdNum) || masterIdNum <= 0) {
        console.warn('[fetchZonesForMaster] Invalid masterId:', masterId);
        return [];
    }
    
    try {
        const result = await zoneApiCall('list_zones', { 
            params: {
                master_id: masterIdNum, 
                recursive: 1,
                per_page: 5000  // Increased to 5000 to support masters with many includes (up to ~5000)
            }
        });
        
        const zones = result && result.data ? result.data : [];
        return zones;
    } catch (e) {
        console.error('[fetchZonesForMaster] Failed to fetch zones for master:', masterIdNum, e);
        return [];
    }
}

/**
 * Populate zone combobox for a specific domain
 * Updates CURRENT_ZONE_LIST but does NOT open the list or auto-select a zone
 * Uses shared helper populateZoneListForDomain from zone-combobox.js with defensive fallback
 */
async function populateZoneComboboxForDomain(masterId) {
    try {
        let orderedZones = [];
        
        // Defensive: Try shared helper first (preferred)
        if (typeof window.populateZoneListForDomain === 'function') {
            console.debug('[populateZoneComboboxForDomain] Using shared helper populateZoneListForDomain');
            try {
                orderedZones = await window.populateZoneListForDomain(masterId);
                console.debug('[populateZoneComboboxForDomain] Shared helper returned', orderedZones.length, 'zones');
                
                // Update CURRENT_ZONE_LIST with ordered zones from helper
                window.CURRENT_ZONE_LIST = orderedZones;
                
                // Sync combobox instance state with updated CURRENT_ZONE_LIST
                if (window.ZONE_FILE_COMBOBOX_INSTANCE && typeof window.ZONE_FILE_COMBOBOX_INSTANCE.refresh === 'function') {
                    window.ZONE_FILE_COMBOBOX_INSTANCE.refresh();
                }
                
                // DO NOT populate or show the combobox list - user must click/focus to see it
                console.debug('[populateZoneComboboxForDomain] Updated CURRENT_ZONE_LIST, list will populate on user interaction');
                
                return;
            } catch (e) {
                console.warn('[populateZoneComboboxForDomain] Shared helper failed, falling back to direct API:', e);
            }
        } else {
            console.debug('[populateZoneComboboxForDomain] Shared helper not available, using fallback');
        }
        
        // Fallback: Use direct API call if shared helper unavailable or failed
        let result;
        try {
            result = await zoneApiCall('list_zone_files', { params: { domain_id: masterId } });
        } catch (e) {
            console.warn('[populateZoneComboboxForDomain] list_zone_files failed, falling back:', e);
            // Fallback to old API (list_zones_by_domain) if list_zone_files is not available
            try {
                result = await apiCall('list_zones_by_domain', { zone_id: masterId });
            } catch (e2) {
                result = await apiCall('list_zones_by_domain', { domain_id: masterId });
            }
        }
        
        const zones = result.data || [];
        
        // Find the master zone from the zones array
        const masterZone = zones.find(z => 
            (z.file_type || '').toLowerCase().trim() === 'master' && 
            parseInt(z.id, 10) === parseInt(masterId, 10)
        );
        
        // Use shared helper for consistent ordering: master first, then includes sorted A-Z
        const masterIdToUse = masterZone ? masterZone.id : masterId;
        if (typeof window.makeOrderedZoneList === 'function') {
            orderedZones = window.makeOrderedZoneList(zones, masterIdToUse);
        } else {
            // Final fallback: just use zones as-is
            orderedZones = zones;
        }
        
        // Update CURRENT_ZONE_LIST with ordered zones
        window.CURRENT_ZONE_LIST = orderedZones;
        
        // Sync combobox instance state with updated CURRENT_ZONE_LIST
        if (window.ZONE_FILE_COMBOBOX_INSTANCE && typeof window.ZONE_FILE_COMBOBOX_INSTANCE.refresh === 'function') {
            window.ZONE_FILE_COMBOBOX_INSTANCE.refresh();
        }
        
        // DO NOT populate or show the combobox list - user must click/focus to see it
        console.debug('[populateZoneComboboxForDomain] Updated CURRENT_ZONE_LIST, list will populate on user interaction');
        
    } catch (error) {
        console.error('Error populating zones for domain:', error);
        window.CURRENT_ZONE_LIST = [];
    }
}

/**
 * Set domain for a given zone (auto-complete domain based on zone)
 * Adapted for zone-files page context (zone-domain-input instead of dns-domain-input)
 */
async function setDomainForZone(zoneId) {
    try {
        const res = await zoneApiCall('get_zone', { params: { id: zoneId } });
        const zone = res && res.data ? res.data : null;
        if (!zone) {
            // Clear defensively
            const input = document.getElementById('zone-domain-input');
            if (input) input.value = '';
            const hiddenInput = document.getElementById('zone-master-id');
            if (hiddenInput) hiddenInput.value = '';
            
            // Disable zone file combobox
            if (typeof setZoneFileComboboxEnabled === 'function') {
                setZoneFileComboboxEnabled(false);
            }
            return;
        }

        // Calculate domain based on zone type
        let domainName = '';
        if (zone.file_type === 'master') {
            domainName = zone.domain || '';
        } else {
            domainName = zone.parent_domain || '';
            
            // Fallback: if parent_domain is empty, call get_domain_for_zone endpoint
            if (!domainName) {
                try {
                    const fallbackRes = await apiCall('get_domain_for_zone', { zone_id: zoneId });
                    if (fallbackRes && fallbackRes.success && fallbackRes.data && fallbackRes.data.domain) {
                        domainName = fallbackRes.data.domain;
                    }
                } catch (fallbackError) {
                    console.warn('Fallback get_domain_for_zone failed:', fallbackError);
                }
            }
        }

        const domainInput = document.getElementById('zone-domain-input');
        if (domainInput) domainInput.value = domainName;
        
        const hiddenInput = document.getElementById('zone-master-id');
        if (hiddenInput) hiddenInput.value = zone.id || '';

        // Update zone file input text display
        const zoneFileInput = document.getElementById('zone-file-input');
        if (zoneFileInput) {
            zoneFileInput.value = `${zone.name} (${zone.file_type})`;
        }

        // ALWAYS call populateZoneComboboxForDomain even if domainName is empty
        if (typeof populateZoneComboboxForDomain === 'function') {
            try { 
                await populateZoneComboboxForDomain(zone.id); 
            } catch (e) {
                console.warn('populateZoneComboboxForDomain failed:', e);
                // Fallback: filter ALL_ZONES by domain if available and apply ordering
                if (Array.isArray(window.ALL_ZONES)) {
                    let filteredZones;
                    if (domainName) {
                        filteredZones = window.ALL_ZONES.filter(z => (z.domain || '') === domainName);
                    } else {
                        filteredZones = window.ALL_ZONES.filter(z => z.id === zone.id);
                    }
                    // Apply consistent ordering using shared helper
                    window.CURRENT_ZONE_LIST = window.makeOrderedZoneList(filteredZones, zone.id);
                    
                    // Sync combobox instance state with updated CURRENT_ZONE_LIST
                    if (window.ZONE_FILE_COMBOBOX_INSTANCE && typeof window.ZONE_FILE_COMBOBOX_INSTANCE.refresh === 'function') {
                        window.ZONE_FILE_COMBOBOX_INSTANCE.refresh();
                    }
                }
            }
        }
        
        // Enable zone file combobox after population
        if (typeof setZoneFileComboboxEnabled === 'function') {
            setZoneFileComboboxEnabled(true);
        }

        if (typeof updateCreateBtnState === 'function') updateCreateBtnState();
    } catch (e) {
        console.error('setDomainForZone error', e);
    }
}

/**
 * Update create button state based on zone selection
 * Adapted for zone-files page (btn-new-zone-file instead of dns-create-btn)
 */
function updateCreateBtnState() {
    const createBtn = document.getElementById('btn-new-zone-file');
    const zoneId = document.getElementById('zone-file-id');
    
    if (createBtn && zoneId) {
        // Enable if zone-file-id has a value OR if a master is selected
        createBtn.disabled = !((zoneId && zoneId.value) || (window.ZONES_SELECTED_MASTER_ID && String(window.ZONES_SELECTED_MASTER_ID) !== ''));
    }
}

/**
 * Sync selectedZoneId and selectedDomainId with window object
 * Ensures global state consistency across the page
 */
function syncSelectedIds() {
    // Sync zone file ID
    const zoneFileInput = document.getElementById('zone-file-id');
    if (zoneFileInput && zoneFileInput.value) {
        window.selectedZoneId = zoneFileInput.value;
        window.ZONES_SELECTED_ZONEFILE_ID = zoneFileInput.value;
    }
    
    // Sync master/domain ID
    const masterInput = document.getElementById('zone-master-id');
    if (masterInput && masterInput.value) {
        window.selectedDomainId = masterInput.value;
        window.ZONES_SELECTED_MASTER_ID = masterInput.value;
    }
}

/**
 * Build API path normalizing BASE_URL and avoiding double /api/
 * @param {string} endpoint - API endpoint (e.g., 'zone_api.php?action=search_zones')
 * @returns {string} - Properly normalized API URL
 */
function buildApiPath(endpoint) {
    const base = (typeof window.BASE_URL !== 'undefined' && window.BASE_URL) ? String(window.BASE_URL) : '/';
    const b = base.replace(/\/+$/, '');
    const e = String(endpoint).replace(/^\/+/, '');
    // If base already ends with /api or endpoint starts with api/, don't add /api/
    if (b.match(/\/api$/) || e.startsWith('api/')) {
        return b + '/' + e;
    }
    return b + '/api/' + e;
}

/**
 * Perform server-side search for zones
 * Uses search_zones endpoint which handles pagination and ACL filtering server-side
 * @param {string} query - Search query
 * @param {object} options - Optional parameters (file_type, limit)
 * @returns {Promise<Array>} - Array of zone objects
 */
async function serverSearchZones(query, options = {}) {
    const fileType = options.file_type || ''; // Empty = search all types
    const limit = options.limit || 100; // Increased default limit
    
    let url = buildApiPath(`zone_api.php?action=search_zones&q=${encodeURIComponent(query)}&limit=${limit}`);
    if (fileType) {
        url += `&file_type=${encodeURIComponent(fileType)}`;
    }
    
    console.debug('[serverSearchZones] Searching with query:', query, 'file_type:', fileType || 'all', 'limit:', limit);
    
    try {
        const res = await fetch(url, { 
            credentials: 'same-origin', 
            headers: { 'X-Requested-With': 'XMLHttpRequest' } 
        });
        if (!res.ok) {
            console.warn('[serverSearchZones] HTTP error:', res.status);
            return [];
        }
        const json = await res.json();
        console.debug('[serverSearchZones] Found', (json.data || []).length, 'results');
        return json.data || [];
    } catch (err) {
        console.warn('[serverSearchZones] Exception:', err);
        return [];
    }
}

/**
 * Filter zones client-side using cached ZONES_ALL
 * @param {string} query - Search query
 * @returns {Array|null} - Filtered array of zones, or null if cache is empty
 */
function clientFilterZones(query) {
    if (!window.ZONES_ALL || !Array.isArray(window.ZONES_ALL) || window.ZONES_ALL.length === 0) {
        return null;
    }
    const q = query.toLowerCase();
    return window.ZONES_ALL.filter(z => {
        const name = (z.name || '').toLowerCase();
        const filename = (z.filename || '').toLowerCase();
        return name.includes(q) || filename.includes(q);
    });
}

/**
 * Initialize server-first search combobox (unified helper for Zones and DNS tabs)
 * Server-first strategy: for queries ≥2 chars, calls serverSearchZones() to handle large datasets
 * Falls back to client filtering for short queries or if server search fails
 * 
 * @param {Object} opts - Configuration options
 * @param {HTMLElement} opts.inputEl - Text input element
 * @param {HTMLElement} opts.listEl - List element for dropdown
 * @param {HTMLElement} [opts.hiddenEl] - Optional hidden input for storing selected ID
 * @param {string} [opts.file_type] - Optional file_type filter ('master', 'include', or empty for all)
 * @param {Function} [opts.onSelectItem] - Optional callback when item is selected, receives (zone) => void
 * @param {number} [opts.minCharsForServer=2] - Minimum characters to trigger server search
 * @param {number} [opts.blurDelay=150] - Delay before hiding list on blur (ms)
 * @returns {Object} - Object with refresh() method
 */
function initServerSearchCombobox(opts) {
    const input = opts.inputEl;
    const list = opts.listEl;
    const hidden = opts.hiddenEl || null;
    const fileType = opts.file_type || '';
    const minCharsForServer = opts.minCharsForServer || 2;
    const blurDelay = opts.blurDelay || 150;
    
    if (!input || !list) {
        console.warn('[initServerSearchCombobox] Missing required elements (inputEl or listEl)');
        return { refresh: () => {} };
    }
    
    console.debug('[initServerSearchCombobox] Initializing with file_type:', fileType || 'all');
    
    // Map zone to combobox item format
    function mapZoneItem(zone) {
        return {
            id: zone.id,
            text: `${zone.name || zone.filename} (${zone.file_type})`
        };
    }
    
    // Populate list and attach click handlers
    // showList defaults to false to prevent auto-display on domain selection (aligned with DNS tab)
    function showZones(zones, showList = false) {
        // Update CURRENT_ZONE_LIST to keep it in sync with displayed zones
        window.CURRENT_ZONE_LIST = zones;
        
        populateComboboxList(list, zones, mapZoneItem, (zone) => {
            // Update hidden input if provided
            if (hidden) {
                hidden.value = zone.id || '';
            }
            // Update visible input
            input.value = `${zone.name || zone.filename} (${zone.file_type})`;
            // Call custom onSelectItem callback if provided
            if (typeof opts.onSelectItem === 'function') {
                try {
                    opts.onSelectItem(zone);
                } catch (err) {
                    console.error('[initServerSearchCombobox] onSelectItem callback error:', err);
                }
            }
        }, showList);
    }
    
    // Get client-filtered zones from cache
    function getClientZones(query) {
        const q = query.toLowerCase();
        // Prioritize CURRENT_ZONE_LIST (domain-specific zones) over ZONES_ALL (all zones)
        // This ensures domain-filtered zones are shown when a domain is selected
        let zones = window.CURRENT_ZONE_LIST || window.ZONES_ALL || [];
        
        if (!Array.isArray(zones)) {
            zones = [];
        }
        
        // Filter by file_type if specified
        if (fileType) {
            zones = zones.filter(z => (z.file_type || '').toLowerCase() === fileType.toLowerCase());
        }
        
        // Filter by query
        if (q) {
            zones = zones.filter(z => {
                const name = (z.name || '').toLowerCase();
                const filename = (z.filename || '').toLowerCase();
                return name.includes(q) || filename.includes(q);
            });
        }
        
        // Apply ordering: master first, then includes sorted A-Z
        const masterId = window.ZONES_SELECTED_MASTER_ID || null;
        if (typeof window.makeOrderedZoneList === 'function') {
            zones = window.makeOrderedZoneList(zones, masterId);
        }
        
        return zones;
    }
    
    // Input event: server-first for queries ≥minCharsForServer
    input.addEventListener('input', async () => {
        const query = input.value.trim();
        const q = query.toLowerCase();
        
        // Server-first strategy for queries ≥minCharsForServer chars
        if (query.length >= minCharsForServer) {
            console.debug('[initServerSearchCombobox] server search for query:', query);
            
            try {
                // Try to call serverSearchZones if available
                let serverResults = [];
                if (typeof window.serverSearchZones === 'function') {
                    serverResults = await window.serverSearchZones(query, { 
                        file_type: fileType,
                        limit: 100 
                    });
                } else if (typeof window.zoneApiCall === 'function') {
                    // Fallback: call zoneApiCall directly
                    console.debug('[initServerSearchCombobox] serverSearchZones not found, using zoneApiCall');
                    const params = { q: query, limit: 100 };
                    if (fileType) params.file_type = fileType;
                    const response = await window.zoneApiCall('search_zones', { params });
                    serverResults = response.data || [];
                } else {
                    console.warn('[initServerSearchCombobox] No server search function available, falling back to client');
                    throw new Error('No server search available');
                }
                
                // Filter server results by selected domain if one is selected
                const masterId = window.ZONES_SELECTED_MASTER_ID || null;
                if (masterId && typeof window.isZoneInMasterTree === 'function') {
                    const unfilteredCount = serverResults.length;
                    serverResults = serverResults.filter(z => window.isZoneInMasterTree(z, masterId, serverResults));
                    console.debug('[initServerSearchCombobox] Filtered server results by domain:', unfilteredCount, '→', serverResults.length);
                }
                
                // Apply ordering to server results: master first, then includes sorted A-Z
                if (typeof window.makeOrderedZoneList === 'function') {
                    serverResults = window.makeOrderedZoneList(serverResults, masterId);
                }
                
                console.debug('[initServerSearchCombobox] server returned', serverResults.length, 'results');
                showZones(serverResults, true); // Show list when user is typing
                return;
            } catch (err) {
                console.warn('[initServerSearchCombobox] server search failed, fallback to client:', err);
                // Fall through to client filtering
            }
        }
        
        // Client filtering for short queries or when server search fails
        console.debug('[initServerSearchCombobox] client filter for query:', query);
        const clientZones = getClientZones(query);
        showZones(clientZones, true); // Show list when user is typing
    });
    
    // Focus event: show all zones from cache
    input.addEventListener('focus', () => {
        const zones = getClientZones('');
        showZones(zones, true); // Show list when user focuses input
    });
    
    // Blur event: hide list after delay
    input.addEventListener('blur', () => {
        setTimeout(() => {
            list.style.display = 'none';
            list.setAttribute('aria-hidden', 'true');
        }, blurDelay);
    });
    
    // Keyboard navigation
    input.addEventListener('keydown', (e) => {
        if (e.key === 'Escape') {
            list.style.display = 'none';
            list.setAttribute('aria-hidden', 'true');
            input.blur();
        } else if (e.key === 'Enter') {
            const firstItem = list.querySelector('.combobox-item:not(.combobox-empty)');
            if (firstItem) {
                firstItem.click();
                e.preventDefault();
            }
        }
    });
    
    // Return object with refresh method
    // refresh() does NOT show the list by default (aligned with DNS tab - list only shown on user interaction)
    return {
        refresh: () => {
            const zones = getClientZones('');
            showZones(zones, false); // Do NOT show list on refresh - only update internal state
        }
    };
}

/**
 * Attach search handler to #searchInput with debouncing
 * Server-first approach: prefers server search for queries ≥2 chars to handle pagination
 * Updates the global searchQuery variable and re-renders the table
 */
function attachZoneSearchInput() {
    const DEBOUNCE_MS = 250;
    
    const input = document.getElementById('searchInput');
    if (!input) {
        console.log('[attachZoneSearchInput] #searchInput not found on this page');
        return;
    }
    
    // Check if already bound to prevent duplicate handlers (using data attribute for consistency)
    if (input.dataset.searchHandlerBound === 'true') {
        return;
    }
    input.dataset.searchHandlerBound = 'true';

    input.addEventListener('input', function(e) {
        clearTimeout(searchTimeout);
        const val = (e.target.value || '').trim();
        
        searchTimeout = setTimeout(async () => {
            // Update global searchQuery variable
            searchQuery = val;
            
            if (val.length === 0) {
                // Empty query: reset search and always reload full data to restore cache
                console.debug('[attachZoneSearchInput] Empty query, reloading full data');
                currentPage = 1;
                await loadZonesData();
                renderZonesTable();
                return;
            }
            
            if (val.length < 2) {
                // Short query (1 char): try client cache first, fallback to server if cache empty
                console.debug('[attachZoneSearchInput] Short query (<2 chars), trying client cache');
                const clientResults = clientFilterZones(val);
                if (clientResults !== null) {
                    console.debug('[attachZoneSearchInput] Using client cache,', clientResults.length, 'results');
                    // Client-side filtering available, just re-render table
                    currentPage = 1;
                    renderZonesTable();
                    return;
                }
                // Cache empty, fall through to server search
                console.debug('[attachZoneSearchInput] Client cache empty, using server search for short query');
            }
            
            // Query ≥2 chars or cache empty: prefer server search (handles pagination)
            console.debug('[attachZoneSearchInput] Server search for query:', val);
            try {
                const results = await serverSearchZones(val, { limit: 100 });
                console.debug('[attachZoneSearchInput] Server search returned', results.length, 'results');
                // Store server results in ZONES_ALL for rendering
                // Note: These are partial results; when search is cleared, loadZonesData() will restore full data
                window.ZONES_ALL = results;
                currentPage = 1;
                renderZonesTable();
            } catch (err) {
                console.warn('[attachZoneSearchInput] Server search failed:', err);
                // Fallback to client cache if server fails
                const clientResults = clientFilterZones(val);
                if (clientResults !== null) {
                    console.debug('[attachZoneSearchInput] Server failed, using client cache fallback');
                    currentPage = 1;
                    renderZonesTable();
                }
            }
        }, DEBOUNCE_MS);
    });
    
    console.log('[attachZoneSearchInput] Search handler attached to #searchInput with server-first strategy');
}

/**
 * Attach change handler to #filterStatus select
 * Updates the global filterStatus variable and reloads/re-renders the table
 */
function attachFilterStatusHandler() {
    const select = document.getElementById('filterStatus');
    if (!select) {
        console.log('[attachFilterStatusHandler] #filterStatus not found on this page');
        return;
    }
    
    // Check if already bound to prevent duplicate handlers (using data attribute for consistency)
    if (select.dataset.filterHandlerBound === 'true') {
        return;
    }
    select.dataset.filterHandlerBound = 'true';
    
    select.addEventListener('change', async function(e) {
        // Update global filterStatus variable
        filterStatus = e.target.value;
        currentPage = 1;
        
        // Reload data from server with new status filter
        await loadZonesData();
        renderZonesTable();
    });
    
    console.log('[attachFilterStatusHandler] Filter status handler attached to #filterStatus');
}

// Expose search functions globally
window.buildApiPath = buildApiPath;
window.attachZoneSearchInput = attachZoneSearchInput;
window.serverSearchZones = serverSearchZones;
window.clientFilterZones = clientFilterZones;
window.initServerSearchCombobox = initServerSearchCombobox;
window.isZoneInMasterTree = isZoneInMasterTree;
window.MAX_PARENT_CHAIN_DEPTH = MAX_PARENT_CHAIN_DEPTH;

/**
 * Ensure zone files initialization and expose helpers on window
 * Should be called before any combobox initialization
 * 
 * This function:
 * - Initializes zones cache and syncSelectedIds (preserves existing behavior)
 * - Exposes helper functions to window for global access
 * - Defensively binds click handler to "Nouveau fichier de zone" button if present
 * - Defensively binds click handler to "Réinitialiser" button with accent-neutralized search
 * - Attaches search handler to #searchInput for debounced zone search
 * - Uses data attributes to prevent duplicate bindings
 * - Wraps event wiring in try/catch to avoid breaking initialization
 */
function ensureZoneFilesInit() {
    // Initialize zones cache and sync selected IDs (existing behavior)
    initZonesCache();
    syncSelectedIds();
    
    // Expose helper functions on window for global access
    window.apiCall = apiCall;
    window.getMasterIdFromZoneId = getMasterIdFromZoneId;
    window.getTopMasterId = getTopMasterId;
    window.fetchZonesForMaster = fetchZonesForMaster;
    window.populateZoneComboboxForDomain = populateZoneComboboxForDomain;
    window.setDomainForZone = setDomainForZone;
    window.updateCreateBtnState = updateCreateBtnState;
    window.syncSelectedIds = syncSelectedIds;
    
    // Defensive event binding with try/catch to avoid breaking initialization
    try {
        // Bind "Nouveau fichier de zone" button if present (only once)
        const btnNewZoneFile = document.getElementById('btn-new-zone-file');
        if (btnNewZoneFile && !btnNewZoneFile.dataset.handlerBound) {
            btnNewZoneFile.addEventListener('click', function() {
                // Call openCreateIncludeModal if available
                if (typeof openCreateIncludeModal === 'function') {
                    openCreateIncludeModal();
                } else {
                    console.warn('openCreateIncludeModal function not available');
                }
            });
            // Mark as bound to prevent duplicate bindings
            btnNewZoneFile.dataset.handlerBound = 'true';
        }
        
        // Bind "Réinitialiser" button with accent-neutralized search (only once)
        // Search all button and anchor elements for text matching 'reinitialiser' or 'reset'
        const allButtons = Array.from(document.querySelectorAll('button, a'));
        const resetButton = allButtons.find(btn => {
            const text = (btn.textContent || '').toLowerCase().trim();
            // Normalize accents: remove diacritics for comparison
            const normalized = text.normalize('NFD').replace(/[\u0300-\u036f]/g, '');
            return normalized.includes('reinitialiser') || normalized.includes('reset');
        });
        
        if (resetButton && !resetButton.dataset.handlerBound) {
            resetButton.addEventListener('click', function(e) {
                e.preventDefault();
                e.stopPropagation();
                // Call resetZoneDomainSelection if available
                if (typeof resetZoneDomainSelection === 'function') {
                    resetZoneDomainSelection();
                } else {
                    console.warn('resetZoneDomainSelection function not available');
                }
            });
            // Mark as bound to prevent duplicate bindings
            resetButton.dataset.handlerBound = 'true';
        }
        
        // Attach search handler to #searchInput for debounced zone search
        attachZoneSearchInput();
        
        // Attach filter status handler for status dropdown
        attachFilterStatusHandler();
    } catch (error) {
        // Log warning but don't break initialization
        console.warn('ensureZoneFilesInit: Failed to bind event handlers:', error);
    }
}

/**
 * Ensure zones are loaded in cache
 * This wrapper ensures cache is initialized before loading
 */
async function ensureZonesCache() {
    initZonesCache();
    if (!window.ZONES_ALL || window.ZONES_ALL.length === 0) {
        await loadZonesData();
    }
}

// =========================================================================
// End of business helper functions
// =========================================================================

// Global state
let currentPage = 1;
let perPage = 25;
let totalPages = 1;
let totalCount = 0;
let searchQuery = '';
let filterStatus = 'active';
let searchTimeout = null;
let allMasters = [];

// Add to window object for global access
window.ZONES_SELECTED_MASTER_ID = null;
window.ZONES_SELECTED_ZONEFILE_ID = null;
window.ZONES_ALL = [];

// Constants
const MAX_INCLUDES_PER_FETCH = 1000; // Maximum includes to fetch when filtering by domain
const COMBOBOX_BLUR_DELAY = 200; // Delay in ms before hiding combobox list on blur

// API base URL
const API_BASE = window.API_BASE || '/api/zone_api.php';

/**
 * Initialize zones page - load domains and zones
 */
async function initZonesPage() {
    // Initialize business helpers and cache before any combobox initialization
    ensureZoneFilesInit();
    await ensureZonesCache();
    await populateZoneDomainSelect();
    await initZoneFileCombobox();
    await loadZonesData();
    renderZonesTable();
}

/**
 * Validation helper: Validate domain label
 * Each label (separated by dots) must contain only letters [A-Za-z], digits [0-9], and hyphens '-'
 * No underscores or other characters allowed
 * @param {string} domain - The domain to validate
 * @returns {boolean} - True if valid, false otherwise
 */
function validateDomainLabel(domain) {
    if (!domain || typeof domain !== 'string') {
        return false;
    }
    
    const trimmed = domain.trim();
    if (trimmed === '') {
        return false;
    }
    
    // Split by dots and validate each label
    const labels = trimmed.split('.');
    
    // Each label must match: only letters, digits, and hyphens (no underscores)
    const labelRegex = /^[A-Za-z0-9-]+$/;
    
    for (const label of labels) {
        if (label === '' || !labelRegex.test(label)) {
            return false;
        }
        
        // Label cannot start or end with a hyphen
        if (label.startsWith('-') || label.endsWith('-')) {
            return false;
        }
    }
    
    return true;
}

/**
 * Validation helper: Validate zone name
 * Must contain only lowercase letters a-z and digits 0-9, no spaces
 * @param {string} name - The zone name to validate
 * @returns {object} - {valid: boolean, error: string|null}
 */
function validateZoneName(name) {
    if (!name || typeof name !== 'string') {
        return { valid: false, error: 'Le Nom de la zone est requis.' };
    }
    
    const trimmed = name.trim();
    if (trimmed === '') {
        return { valid: false, error: 'Le Nom de la zone est requis.' };
    }
    
    // Check for valid characters: only lowercase letters a-z and digits 0-9
    const validPattern = /^[a-z0-9]+$/;
    if (!validPattern.test(trimmed)) {
        return { valid: false, error: 'Le Nom doit contenir uniquement des lettres minuscules a–z et des chiffres, sans espaces.' };
    }
    
    return { valid: true, error: null };
}

/**
 * Validation helper: Validate master zone name as FQDN
 * Accepts valid FQDN with or without trailing dot
 * Each label must contain only [a-z0-9-], and cannot start/end with '-'
 * Total length 1..253 characters, each label 1..63 characters
 * @param {string} name - The zone name to validate (FQDN format)
 * @returns {object} - {valid: boolean, error: string|null}
 */
function validateMasterZoneName(name) {
    if (!name || typeof name !== 'string') {
        return { valid: false, error: 'Le Nom de la zone est requis.' };
    }
    
    // Normalize to lowercase and trim
    let normalized = name.trim().toLowerCase();
    if (normalized === '') {
        return { valid: false, error: 'Le Nom de la zone est requis.' };
    }
    
    // Remove trailing dot if present (FQDN format)
    if (normalized.endsWith('.')) {
        normalized = normalized.slice(0, -1);
    }
    
    // After removing trailing dot, check if empty
    if (normalized === '') {
        return { valid: false, error: 'Le Nom de la zone ne peut pas être seulement un point.' };
    }
    
    // Check total length (max 253 characters excluding trailing dot)
    if (normalized.length > 253) {
        return { valid: false, error: 'Le Nom de la zone dépasse la longueur maximale de 253 caractères.' };
    }
    
    // Split into labels
    const labels = normalized.split('.');
    
    // Validate each label
    for (const label of labels) {
        // Check label is not empty
        if (label === '') {
            return { valid: false, error: 'Le Nom de la zone contient un label vide (deux points consécutifs).' };
        }
        
        // Check label length (max 63 characters)
        if (label.length > 63) {
            return { valid: false, error: 'Chaque partie du nom de zone ne peut pas dépasser 63 caractères.' };
        }
        
        // Check valid characters: only lowercase letters a-z, digits 0-9, and hyphens
        const validPattern = /^[a-z0-9-]+$/;
        if (!validPattern.test(label)) {
            return { valid: false, error: 'Le Nom de la zone contient des caractères invalides. Seuls les lettres (a-z), chiffres (0-9) et tirets (-) sont autorisés.' };
        }
        
        // Cannot start with hyphen
        if (label.startsWith('-')) {
            return { valid: false, error: 'Chaque partie du nom de zone ne peut pas commencer par un tiret (-).' };
        }
        
        // Cannot end with hyphen
        if (label.endsWith('-')) {
            return { valid: false, error: 'Chaque partie du nom de zone ne peut pas se terminer par un tiret (-).' };
        }
    }
    
    return { valid: true, error: null };
}

/**
 * Validation helper: Validate filename
 * Must not contain spaces and must end with .db (case insensitive)
 * @param {string} filename - The filename to validate
 * @returns {object} - {valid: boolean, error: string|null}
 */
function validateFilename(filename) {
    if (!filename || typeof filename !== 'string') {
        return { valid: false, error: 'Le nom du fichier de zone est requis.' };
    }
    
    const trimmed = filename.trim();
    if (trimmed === '') {
        return { valid: false, error: 'Le nom du fichier de zone est requis.' };
    }
    
    // Check for spaces
    if (trimmed.includes(' ')) {
        return { valid: false, error: 'Le nom du fichier ne doit pas contenir d\'espaces.' };
    }
    
    // Check for .db extension (case insensitive)
    if (!trimmed.toLowerCase().endsWith('.db')) {
        return { valid: false, error: 'Le nom du fichier doit se terminer par .db.' };
    }
    
    return { valid: true, error: null };
}

/**
 * Show error banner in a modal (enhanced version)
 * @param {string} modalKey - Modal key (e.g., 'createZone' or 'includeCreate')
 * @param {string} message - Error message to display
 */
function showModalError(modalKey, message) {
    try {
        const banner = document.getElementById(modalKey + 'ErrorBanner');
        const msgEl = document.getElementById(modalKey + 'ErrorMessage');
        if (!banner || !msgEl) {
            console.warn('Banner elements not found for', modalKey);
            showError('Erreur : ' + (message || 'Une erreur est survenue'));
            return;
        }
        msgEl.textContent = message || "Erreur de validation : vérifiez les champs du formulaire.";
        banner.style.display = 'block';
        banner.focus();
    } catch (e) {
        console.error('showModalError failed', e);
    }
}

/**
 * Clear error banner in a modal (enhanced version)
 * @param {string} modalKey - Modal key (e.g., 'createZone' or 'includeCreate')
 */
function clearModalError(modalKey) {
    try {
        const banner = document.getElementById(modalKey + 'ErrorBanner');
        const msgEl = document.getElementById(modalKey + 'ErrorMessage');
        if (!banner) return;
        banner.style.display = 'none';
        if (msgEl) msgEl.textContent = '';
    } catch (e) {
        console.error('clearModalError failed', e);
    }
}

// Export validation helpers to window for reusability
window.__validateDomainLabel = validateDomainLabel;
window.__validateZoneName = validateZoneName;
window.__validateMasterZoneName = validateMasterZoneName;
window.__validateFilename = validateFilename;
window.__showModalError = showModalError;
window.__clearModalError = clearModalError;

/**
 * Populate domain combobox with all master zones that have a domain
 * Makes combobox searchable like DNS page
 */
async function populateZoneDomainSelect() {
    try {
        const response = await zoneApiCall('list_zones', {
            params: {
                file_type: 'master',
                status: 'active',
                per_page: 1000
            }
        });
        
        if (response.success) {
            // Filter masters that have a domain and sort by domain name
            allMasters = response.data
                .filter(zone => zone.domain && zone.domain.trim() !== '')
                .sort((a, b) => (a.domain || '').localeCompare(b.domain || ''));
            
            const input = document.getElementById('zone-domain-input');
            const list = document.getElementById('zone-domain-list');
            
            if (!input || !list) return;
            
            // Make input interactive (not readonly)
            input.readOnly = false;
            input.placeholder = 'Rechercher un domaine...';
            
            // Input event - filter domains and show list
            input.addEventListener('input', () => {
                const query = input.value.toLowerCase().trim();
                const filtered = allMasters.filter(d => 
                    d.domain.toLowerCase().includes(query)
                );
                
                populateComboboxList(list, filtered, (domain) => ({
                    id: domain.id,
                    text: domain.domain
                }), (domain) => {
                    onZoneDomainSelected(domain.id);
                });
            });
            
            // Focus - show all domains
            input.addEventListener('focus', () => {
                populateComboboxList(list, allMasters, (domain) => ({
                    id: domain.id,
                    text: domain.domain
                }), (domain) => {
                    onZoneDomainSelected(domain.id);
                });
            });
            
            // Blur - hide list (with delay to allow click)
            input.addEventListener('blur', () => {
                setTimeout(() => {
                    list.style.display = 'none';
                }, window.COMBOBOX_BLUR_DELAY || 200);
            });
            
            // Escape key - close list
            input.addEventListener('keydown', (e) => {
                if (e.key === 'Escape') {
                    list.style.display = 'none';
                    input.blur();
                }
            });
        }
    } catch (error) {
        console.error('Failed to populate domain select:', error);
        showError('Erreur lors du chargement des domaines: ' + error.message);
    }
}

/**
 * Handle domain selection - update UI and filter table
 */
async function onZoneDomainSelected(masterZoneId) {
    window.ZONES_SELECTED_MASTER_ID = masterZoneId;
    
    // Update input display
    const input = document.getElementById('zone-domain-input');
    const hiddenInput = document.getElementById('zone-master-id');
    if (input) {
        if (masterZoneId) {
            const master = allMasters.find(m => m.id === masterZoneId);
            if (master) {
                input.value = master.domain;
            }
        } else {
            input.value = '';
            input.placeholder = 'Rechercher un domaine...';
        }
    }
    if (hiddenInput) {
        hiddenInput.value = masterZoneId || '';
    }
    
    // Show/hide buttons based on selection
    const btnNewZoneFile = document.getElementById('btn-new-zone-file');
    const btnEditDomain = document.getElementById('btn-edit-domain');
    
    if (masterZoneId) {
        if (btnNewZoneFile) {
            btnNewZoneFile.disabled = false;
        }
        if (btnEditDomain) {
            btnEditDomain.style.display = 'inline-block';
            btnEditDomain.disabled = false;
        }
        
        // Populate zone file combobox for the selected domain (with auto-selection of master)
        await populateZoneFileCombobox(masterZoneId, null, true);
        
        // Enable zone file combobox after population
        if (typeof setZoneFileComboboxEnabled === 'function') {
            setZoneFileComboboxEnabled(true);
        }
    } else {
        if (btnNewZoneFile) {
            btnNewZoneFile.disabled = true;
        }
        if (btnEditDomain) {
            btnEditDomain.style.display = 'none';
            btnEditDomain.disabled = true;
        }
        
        // Disable zone file combobox when no domain selected
        if (typeof setZoneFileComboboxEnabled === 'function') {
            setZoneFileComboboxEnabled(false);
        }
        
        // Clear zone file combobox
        clearZoneFileSelection();
    }
    
    // Hide combobox list
    const list = document.getElementById('zone-domain-list');
    if (list) {
        list.style.display = 'none';
    }
    
    // Re-render table with filter after cache is updated
    currentPage = 1;
    await renderZonesTable();
}

/**
 * Enable or disable the zone file combobox
 * @param {boolean} enabled - Whether to enable the combobox
 */
function setZoneFileComboboxEnabled(enabled) {
    const inputEl = document.getElementById('zone-file-input');
    const hiddenEl = document.getElementById('zone-file-id');
    
    if (!inputEl) {
        console.warn('[setZoneFileComboboxEnabled] zone-file-input not found');
        return;
    }
    
    if (enabled) {
        inputEl.disabled = false;
        inputEl.placeholder = 'Rechercher une zone...';
        inputEl.title = 'Sélectionnez un fichier de zone';
    } else {
        inputEl.disabled = true;
        inputEl.value = '';
        inputEl.placeholder = 'Sélectionnez d\'abord un domaine';
        inputEl.title = 'Sélectionnez d\'abord un domaine';
        if (hiddenEl) {
            hiddenEl.value = '';
        }
        
        // Hide the dropdown list if it's open
        const listEl = document.getElementById('zone-file-list');
        if (listEl) {
            listEl.style.display = 'none';
        }
    }
    
    console.debug('[setZoneFileComboboxEnabled] Zone file combobox', enabled ? 'enabled' : 'disabled');
}

/**
 * Initialize zone file combobox using unified server-first helper
 * Wraps initServerSearchCombobox with zone-files-specific logic
 */
async function initZoneFileCombobox() {
    await ensureZonesCache();
    
    const inputEl = document.getElementById('zone-file-input');
    const listEl = document.getElementById('zone-file-list');
    const hiddenEl = document.getElementById('zone-file-id');
    
    if (!inputEl || !listEl || !hiddenEl) {
        console.warn('[initZoneFileCombobox] Required elements not found');
        return;
    }
    
    inputEl.readOnly = false;
    inputEl.placeholder = 'Rechercher une zone...';
    
    // Start with combobox disabled if no domain selected
    if (!window.ZONES_SELECTED_MASTER_ID) {
        setZoneFileComboboxEnabled(false);
    }
    
    // Use the unified initServerSearchCombobox helper
    // Custom onSelectItem to call onZoneFileSelected and update CURRENT_ZONE_LIST
    const comboboxInstance = initServerSearchCombobox({
        inputEl: inputEl,
        listEl: listEl,
        hiddenEl: hiddenEl,
        file_type: '', // No filter, show all types (master + include)
        onSelectItem: (zone) => {
            // Update CURRENT_ZONE_LIST for backward compatibility
            if (zone) {
                window.CURRENT_ZONE_LIST = [zone];
            }
            // Call existing onZoneFileSelected handler
            if (typeof onZoneFileSelected === 'function') {
                onZoneFileSelected(zone.id);
            }
        },
        minCharsForServer: 2,
        blurDelay: window.COMBOBOX_BLUR_DELAY || 200
    });
    
    // Store combobox instance globally so populateZoneComboboxForDomain can refresh it
    window.ZONE_FILE_COMBOBOX_INSTANCE = comboboxInstance;
    
    console.debug('[initZoneFileCombobox] Initialized using initServerSearchCombobox');
    
    return comboboxInstance;
}

/**
 * Get filtered zones for combobox based on selected domain
 * Uses recursive ancestor-based filtering to include all nested includes
 * Now uses shared makeOrderedZoneList helper for consistent ordering
 */
function getFilteredZonesForCombobox() {
    const zonesAll = Array.isArray(window.ZONES_ALL) && window.ZONES_ALL.length
        ? window.ZONES_ALL
        : (Array.isArray(window.ALL_ZONES) ? window.ALL_ZONES : []);

    // Merge allMasters into zonesAll for makeOrderedZoneList to work properly
    const allZones = [...zonesAll];
    if (Array.isArray(allMasters) && allMasters.length > 0) {
        allMasters.forEach(master => {
            if (!allZones.find(z => String(z.id) === String(master.id))) {
                allZones.push(master);
            }
        });
    }

    // Use shared helper for consistent ordering: master first, then includes sorted A-Z
    const masterId = window.ZONES_SELECTED_MASTER_ID || null;
    return window.makeOrderedZoneList(allZones, masterId);
}

/**
 * Populate zone file combobox for a specific domain
 * Fetches recursive includes from API and merges into cache
 * @param {number} masterZoneId - The master zone ID
 * @param {number|null} selectedZoneFileId - Optional zone file ID to pre-select
 * @param {boolean} autoSelect - Whether to auto-select a zone (default true)
 */
async function populateZoneFileCombobox(masterZoneId, selectedZoneFileId = null, autoSelect = true) {
    try {
        if (!masterZoneId) {
            clearZoneFileSelection();
            return;
        }

        const masterId = parseInt(masterZoneId, 10);
        const masterZone = allMasters.find(m => parseInt(m.id, 10) === masterId);

        console.debug('[populateZoneFileCombobox] masterZoneId:', masterId, 'masterZone:', masterZone ? masterZone.name : 'not found');

        // Defensive logic: Use shared helper if available, otherwise fallback
        let orderedZones = null;
        let sharedHelperSucceeded = false;
        
        if (typeof window.populateZoneListForDomain === 'function') {
            // Use shared helper from zone-combobox.js (preferred)
            console.debug('[populateZoneFileCombobox] Using shared helper populateZoneListForDomain');
            try {
                orderedZones = await window.populateZoneListForDomain(masterId);
                sharedHelperSucceeded = true;
                console.debug('[populateZoneFileCombobox] Shared helper returned', orderedZones.length, 'zones');
            } catch (e) {
                console.warn('[populateZoneFileCombobox] Shared helper failed, falling back to local implementation:', e);
                orderedZones = null;
            }
        } else {
            console.debug('[populateZoneFileCombobox] Shared helper not available, using fallback implementation');
        }
        
        // Fallback implementation if shared helper not available or failed
        if (!sharedHelperSucceeded) {
            // Try to get recursive includes from the cache first using ancestor-based filter
            let includeZones = (window.ZONES_ALL || []).filter(zone => {
                // Normalize file_type check to handle variations in case/whitespace
                const fileType = (zone.file_type || '').toLowerCase().trim();
                if (fileType !== 'include') return false;
                
                // Check if this zone's ancestor chain contains the master
                let currentZone = zone;
                let iterations = 0;
                const maxIterations = 50;
                
                while (currentZone && iterations < maxIterations) {
                    iterations++;
                    const parentId = parseInt(currentZone.parent_id || 0, 10);
                    
                    if (parentId === masterId) {
                        return true;
                    }
                    
                    if (parentId === 0 || !parentId) {
                        break;
                    }
                    
                    // Find parent in cache
                    currentZone = (window.ZONES_ALL || []).find(z => parseInt(z.id, 10) === parentId) ||
                                 allMasters.find(m => parseInt(m.id, 10) === parentId);
                }
                
                return false;
            });

            console.debug('[populateZoneFileCombobox] includeZones from cache:', includeZones.length);

            // If cache is empty or incomplete for this master, fetch from API
            if (!includeZones || includeZones.length === 0) {
                console.debug('[populateZoneFileCombobox] Cache empty, fetching from API...');
                try {
                    const fetched = await fetchZonesForMaster(masterId);
                    includeZones = fetched || [];
                    console.debug('[populateZoneFileCombobox] Fetched from API:', includeZones.length, 'zones');
                    
                    // Merge fetched includes into cache to keep it up-to-date (deduplicate using string comparison)
                    if (!Array.isArray(window.ZONES_ALL)) window.ZONES_ALL = [];
                    includeZones.forEach(z => {
                        if (!window.ZONES_ALL.find(x => String(x.id) === String(z.id))) {
                            window.ZONES_ALL.push(z);
                        }
                    });
                    console.debug('[populateZoneFileCombobox] Cache updated, total zones:', window.ZONES_ALL.length);
                } catch (e) {
                    console.warn('[populateZoneFileCombobox] fetchZonesForMaster failed, falling back to empty list:', e);
                    includeZones = includeZones || [];
                }
            } else {
                console.debug('[populateZoneFileCombobox] Using cached includeZones:', includeZones.length);
            }

            // Use shared helper for consistent ordering: master first, then includes sorted A-Z
            const allZones = masterZone ? [masterZone, ...includeZones] : includeZones;
            if (typeof window.makeOrderedZoneList === 'function') {
                orderedZones = window.makeOrderedZoneList(allZones, masterId);
                console.debug('[populateZoneFileCombobox] Used makeOrderedZoneList for ordering:', orderedZones.length, 'zones');
            } else {
                console.warn('[populateZoneFileCombobox] makeOrderedZoneList not available, using unordered list');
                orderedZones = allZones;
            }
        }

        const input = document.getElementById('zone-file-input');
        const hiddenInput = document.getElementById('zone-file-id');
        const listEl = document.getElementById('zone-file-list');
        if (!input) return;

        // Keep CURRENT_ZONE_LIST in sync with what's shown in combobox
        window.CURRENT_ZONE_LIST = orderedZones.slice();
        console.debug('[populateZoneFileCombobox] Final items for combobox:', orderedZones.length, '(master first, then includes sorted A-Z)');

        // Sync combobox instance state with updated CURRENT_ZONE_LIST
        // refresh() will update internal state without showing the list (showList=false)
        if (window.ZONE_FILE_COMBOBOX_INSTANCE && typeof window.ZONE_FILE_COMBOBOX_INSTANCE.refresh === 'function') {
            window.ZONE_FILE_COMBOBOX_INSTANCE.refresh();
            console.debug('[populateZoneFileCombobox] Called refresh() to sync combobox state');
        }

        // DO NOT populate or show the combobox list - user must click/focus to see it (aligned with DNS tab)
        // The list will be populated from CURRENT_ZONE_LIST when user interacts with the input

        // Handle auto-selection based on autoSelect parameter
        if (autoSelect) {
            // If selectedZoneFileId is provided, preselect it in the input/hidden value
            if (selectedZoneFileId) {
                const selectedId = parseInt(selectedZoneFileId, 10);
                const isMasterSelected = masterZone && selectedId === parseInt(masterZone.id, 10);
                if (isMasterSelected) {
                    input.value = `${masterZone.name} (${masterZone.filename || masterZone.file_type})`;
                    if (hiddenInput) hiddenInput.value = selectedZoneFileId;
                    window.ZONES_SELECTED_ZONEFILE_ID = selectedZoneFileId;
                } else {
                    const selectedZone = orderedZones.find(z => parseInt(z.id, 10) === selectedId);
                    if (selectedZone) {
                        input.value = `${selectedZone.name} (${selectedZone.filename || selectedZone.file_type})`;
                        if (hiddenInput) hiddenInput.value = selectedZoneFileId;
                        window.ZONES_SELECTED_ZONEFILE_ID = selectedZoneFileId;
                    }
                }
            } else {
                // Default: select the master zone itself if present
                if (masterZone) {
                    input.value = `${masterZone.name} (${masterZone.filename || masterZone.file_type})`;
                    if (hiddenInput) hiddenInput.value = masterId;
                    window.ZONES_SELECTED_ZONEFILE_ID = masterId;
                } else {
                    input.value = '';
                    input.placeholder = 'Rechercher une zone...';
                    if (hiddenInput) hiddenInput.value = '';
                    window.ZONES_SELECTED_ZONEFILE_ID = null;
                }
            }
        } else {
            // autoSelect is false: clear input and hidden value, but keep list populated
            input.value = '';
            input.placeholder = 'Rechercher une zone...';
            if (hiddenInput) hiddenInput.value = '';
            window.ZONES_SELECTED_ZONEFILE_ID = null;
        }
        
        // Always enable combobox after population (whether autoSelect is true or false)
        if (typeof window.setZoneFileComboboxEnabled === 'function') {
            window.setZoneFileComboboxEnabled(true);
        }
    } catch (error) {
        console.error('[populateZoneFileCombobox] Fatal error:', error);
    }
}

/**
 * Handle zone file selection
 * Sets ZONES_SELECTED_ZONEFILE_ID and window.selectedZoneId, 
 * updates ZONES_SELECTED_MASTER_ID if needed,
 * updates combobox texts, and re-renders the table
 */
async function onZoneFileSelected(zoneFileId) {
    const input = document.getElementById('zone-file-input');
    const hiddenInput = document.getElementById('zone-file-id');
    const list = document.getElementById('zone-file-list');
    const domainInput = document.getElementById('zone-domain-input');
    
    if (zoneFileId) {
        const zoneId = parseInt(zoneFileId, 10);
        
        // Set window.selectedZoneId for global state consistency
        window.selectedZoneId = zoneFileId;
        window.ZONES_SELECTED_ZONEFILE_ID = zoneFileId;
        
        // Update hidden input defensively
        if (hiddenInput) hiddenInput.value = zoneFileId;
        
        // Try to find zone in includes first
        let zone = (window.ZONES_ALL || []).find(z => parseInt(z.id, 10) === zoneId);
        
        // If not found, try to find in masters
        if (!zone) {
            zone = allMasters.find(m => parseInt(m.id, 10) === zoneId);
        }
        
        // If still not found, try to fetch from API for a nicer display value
        if (!zone) {
            try {
                const res = await zoneApiCall('get_zone', { params: { id: zoneFileId } });
                if (res && res.data) {
                    zone = res.data;
                }
            } catch (e) {
                console.warn('Failed to fetch zone for display:', e);
            }
        }
        
        if (zone) {
            // Update zone file input text with nicer display value
            if (input) input.value = `${zone.name} (${zone.filename})`;
            
            // Get the top master ID for this zone (recursively traverse to root)
            let topMasterId = await getTopMasterId(zone.id);
            
            // Fallback to getMasterIdFromZoneId if getTopMasterId fails
            if (!topMasterId) {
                topMasterId = await getMasterIdFromZoneId(zone.id);
            }
            
            // Set window.ZONES_SELECTED_MASTER_ID to the top master root
            if (topMasterId) {
                window.ZONES_SELECTED_MASTER_ID = String(topMasterId);
                window.selectedDomainId = String(topMasterId);
                
                // Update domain combobox text with master's domain
                const masterZone = allMasters.find(m => parseInt(m.id, 10) === topMasterId);
                if (masterZone && domainInput) {
                    domainInput.value = masterZone.domain;
                }
            }
        } else {
            // Fallback: just set the value even if we couldn't fetch display info
            if (input) input.value = `Zone ${zoneFileId}`;
        }
    } else {
        // Clear selection
        window.selectedZoneId = null;
        window.ZONES_SELECTED_ZONEFILE_ID = null;
        if (input) input.value = '';
        if (hiddenInput) hiddenInput.value = '';
    }
    
    // Hide combobox list
    if (list) list.style.display = 'none';
    
    // Update create button state
    updateCreateBtnState();
    
    // Refresh table with new filter by calling loadZonesData then renderZonesTable
    currentPage = 1;
    await loadZonesData();
    renderZonesTable();
}

/**
 * Clear zone file selection
 */
function clearZoneFileSelection() {
    const input = document.getElementById('zone-file-input');
    const hiddenInput = document.getElementById('zone-file-id');
    
    window.ZONES_SELECTED_ZONEFILE_ID = null;
    
    if (input) {
        input.value = '';
        input.placeholder = 'Rechercher une zone...';
    }
    if (hiddenInput) {
        hiddenInput.value = '';
    }
}

/**
 * Reset domain selection
 */
async function resetZoneDomainSelection() {
    await onZoneDomainSelected(null);
    clearZoneFileSelection();
    currentPage = 1;
    await renderZonesTable();
}

/**
 * Make API call to zone API (fixed)
 */
async function zoneApiCall(action, options = {}) {
    const method = (options.method || 'GET').toUpperCase();
    const params = options.params || {};
    const body = options.body || null;

    // Build explicit URL to zone_api.php (API_BASE already ends with 'api/')
    let url = new URL(window.API_BASE + 'zone_api.php', window.location.origin);
    url.searchParams.append('action', action);

    // Always append params to URL for all methods (GET, POST, etc.)
    if (Object.keys(params).length > 0) {
        Object.keys(params).forEach(k => url.searchParams.append(k, params[k]));
    }

    const fetchOptions = {
        method: method,
        headers: {
            'Accept': 'application/json'
        },
        credentials: 'same-origin' // important: send session cookie
    };

    if (body && (method === 'POST' || method === 'PUT' || method === 'PATCH')) {
        fetchOptions.headers['Content-Type'] = 'application/json';
        fetchOptions.body = JSON.stringify(body);
    }

    try {
        const response = await fetch(url.toString(), fetchOptions);

        // Try parse JSON
        let data;
        try {
            data = await response.json();
        } catch (jsonErr) {
            const text = await response.text();
            console.error('zoneApiCall: invalid JSON response', text);
            throw new Error('Invalid JSON response from server');
        }

        if (!response.ok) {
            // bubble up server error message if present
            throw new Error(data.error || `HTTP ${response.status}`);
        }

        return data;
    } catch (err) {
        console.error('zoneApiCall error:', err);
        throw err;
    }
}

/**
 * Load all zones data from API and cache it
 */
async function loadZonesData() {
    try {
        const params = {
            file_type: 'include',
            per_page: MAX_INCLUDES_PER_FETCH
        };

        if (filterStatus) {
            params.status = filterStatus;
        }

        const response = await zoneApiCall('list_zones', { params });

        if (response.success) {
            window.ZONES_ALL = response.data || [];
            totalCount = window.ZONES_ALL.length;
        }
    } catch (error) {
        console.error('Failed to load zones:', error);
        showError('Erreur lors du chargement des zones: ' + error.message);
        window.ZONES_ALL = [];
    }
}

/**
 * Ensure zones are loaded in cache
 * @returns {Promise<void>}
 */
async function ensureZonesLoaded() {
    if (!window.ZONES_ALL || window.ZONES_ALL.length === 0) {
        await loadZonesData();
    }
}

/**
 * Render zones table with filtering and pagination
 * Filtering precedence:
 * 1. If ZONES_SELECTED_ZONEFILE_ID => show rows with parent_id == zonefileId OR ancestor chain contains zonefileId
 * 2. Else if ZONES_SELECTED_MASTER_ID => show rows with parent_id == masterId OR ancestor chain contains masterId
 * 3. Else => show all includes
 */
async function renderZonesTable() {
    const tbody = document.getElementById('zones-table-body');
    if (!tbody) return;
    
    // Ensure data is loaded
    if (window.ZONES_ALL.length === 0 && filterStatus === 'active') {
        await loadZonesData();
    }
    
    let filteredZones = [...window.ZONES_ALL];
    
    // Helper: check whether a zone has `ancestorId` somewhere in its parent chain
    const zonesAll = Array.isArray(window.ZONES_ALL) ? window.ZONES_ALL : (Array.isArray(window.ALL_ZONES) ? window.ALL_ZONES : []);
    function hasAncestor(zone, ancestorId) {
        if (!zone || !ancestorId) return false;
        let currentZone = zone;
        let iterations = 0;
        const maxIterations = 50;
        const target = parseInt(ancestorId, 10);
        while (currentZone && iterations < maxIterations) {
            iterations++;
            const parentId = parseInt(currentZone.parent_id || 0, 10);
            if (!parentId) break;
            if (parentId === target) return true;
            currentZone = zonesAll.find(z => parseInt(z.id, 10) === parentId) || allMasters.find(m => parseInt(m.id, 10) === parentId);
        }
        return false;
    }
    
    // Filter by selection precedence with recursive ancestor-based matching
    if (window.ZONES_SELECTED_ZONEFILE_ID) {
        // Show includes whose ancestor chain contains the selected zone file (direct or indirect)
        const selectedZoneFileId = parseInt(window.ZONES_SELECTED_ZONEFILE_ID, 10);
        filteredZones = filteredZones.filter(zone => {
            const parentId = parseInt(zone.parent_id || 0, 10);
            return (!isNaN(parentId) && parentId === selectedZoneFileId) || hasAncestor(zone, selectedZoneFileId);
        });
    } else if (window.ZONES_SELECTED_MASTER_ID) {
        // Show includes whose ancestor chain contains the selected master (direct or indirect)
        const selectedMasterId = parseInt(window.ZONES_SELECTED_MASTER_ID, 10);
        filteredZones = filteredZones.filter(zone => {
            const parentId = parseInt(zone.parent_id || 0, 10);
            return (!isNaN(parentId) && parentId === selectedMasterId) || hasAncestor(zone, selectedMasterId);
        });
    }
    // else: show all includes (already in filteredZones)
    
    // Filter by search query
    if (searchQuery) {
        const query = searchQuery.toLowerCase();
        filteredZones = filteredZones.filter(zone => 
            (zone.name && zone.name.toLowerCase().includes(query)) ||
            (zone.filename && zone.filename.toLowerCase().includes(query))
        );
    }
    
    // Update counts
    totalCount = filteredZones.length;
    totalPages = Math.ceil(totalCount / perPage);
    
    // Paginate
    const startIndex = (currentPage - 1) * perPage;
    const endIndex = startIndex + perPage;
    const paginatedZones = filteredZones.slice(startIndex, endIndex);
    
    // Render
    const colspanValue = 6; // Always 6 columns including Actions

    if (paginatedZones.length === 0) {
        tbody.innerHTML = `
            <tr>
                <td colspan="${colspanValue}" class="empty-cell">
                    <div class="empty-state">
                        <i class="fas fa-inbox"></i>
                        <p>Aucune zone trouvée</p>
                    </div>
                </td>
            </tr>
        `;
        updatePaginationControls();
        updateResultsInfo();
        return;
    }

    tbody.innerHTML = paginatedZones.map(zone => {
        const statusBadge = getStatusBadge(zone.status);
        const parentDisplay = zone.parent_name ? escapeHtml(zone.parent_name) : '-';
        
        // Always render action buttons
        const actionsHtml = `
            <td class="actions-cell col-actions">
                <button class="btn-small btn-edit" onclick="event.stopPropagation(); openZoneModal(${zone.id})" title="Modifier">
                    <i class="fas fa-edit"></i> Modifier
                </button>
                <button class="btn-small btn-delete" onclick="event.stopPropagation(); deleteZone(${zone.id})" title="Supprimer">
                    <i class="fas fa-trash"></i> Supprimer
                </button>
            </td>
        `;
        
        return `
            <tr class="zone-row" data-zone-id="${zone.id}" data-file-type="${zone.file_type || 'include'}" data-parent-id="${zone.parent_id || ''}" onclick="handleZoneRowClick(${zone.id}, ${zone.parent_id || 'null'})" style="cursor: pointer;">
                <td><strong>${escapeHtml(zone.name)}</strong></td>
                <td><code>${escapeHtml(zone.filename)}</code></td>
                <td>${parentDisplay}</td>
                <td>${formatDate(zone.updated_at || zone.created_at)}</td>
                <td>${statusBadge}</td>
                ${actionsHtml}
            </tr>
        `;
    }).join('');
    
    updatePaginationControls();
    updateResultsInfo();
}

/**
 * Handle zone row click - select parent domain and zone file
 */
async function handleZoneRowClick(zoneId, parentId) {
    // Check if this zone has a parent (is an include)
    // parentId can be a number, null, or the string 'null' from onclick attribute
    const hasParent = parentId && parentId !== null && parentId !== 'null' && parentId !== '';
    
    if (hasParent) {
        // This is an include - select its parent domain first
        const parentIdNum = typeof parentId === 'number' ? parentId : parseInt(parentId, 10);
        if (!isNaN(parentIdNum)) {
            onZoneDomainSelected(parentIdNum);
        }
    }
    
    // Also select the zone file itself
    if (zoneId) {
        onZoneFileSelected(zoneId);
    }
}

/**
 * Delete zone - wrapper for confirmDeleteZone
 */
async function deleteZone(zoneId) {
    if (!confirm('Êtes-vous sûr de vouloir supprimer cette zone?')) {
        return;
    }
    
    try {
        await zoneApiCall('set_status_zone', {
            params: { id: zoneId, status: 'deleted' }
        });
        
        showSuccess('Zone supprimée avec succès');
        await loadZonesData();
        renderZonesTable();
    } catch (error) {
        console.error('Failed to delete zone:', error);
        showError('Erreur lors de la suppression: ' + error.message);
    }
}

/**
 * Update pagination controls
 */
function updatePaginationControls() {
    document.getElementById('currentPage').textContent = currentPage;
    document.getElementById('totalPages').textContent = totalPages;
    
    const prevBtn = document.getElementById('prevPage');
    const nextBtn = document.getElementById('nextPage');
    
    prevBtn.disabled = currentPage <= 1;
    nextBtn.disabled = currentPage >= totalPages;
}

/**
 * Update results info
 */
function updateResultsInfo() {
    const start = (currentPage - 1) * perPage + 1;
    const end = Math.min(currentPage * perPage, totalCount);
    const info = totalCount > 0 
        ? `Affichage ${start}-${end} sur ${totalCount} zone(s)` 
        : 'Aucune zone trouvée';
    document.getElementById('resultsCount').textContent = info;
}

/**
 * Get status badge HTML
 */
function getStatusBadge(status) {
    const badges = {
        'active': '<span class="badge badge-success">Actif</span>',
        'inactive': '<span class="badge badge-warning">Inactif</span>',
        'deleted': '<span class="badge badge-danger">Supprimé</span>'
    };
    return badges[status] || status;
}

/**
 * Navigate to previous page
 */
function previousPage() {
    if (currentPage > 1) {
        currentPage--;
        renderZonesTable();
    }
}

/**
 * Navigate to next page
 */
function nextPage() {
    if (currentPage < totalPages) {
        currentPage++;
        renderZonesTable();
    }
}

// Modal state
let currentZone = null;
let currentTab = 'details';
let hasUnsavedChanges = false;
let originalZoneData = null;
let previewData = null;
let currentZoneId = null;

/**
 * Open zone modal and load zone data
 */
async function openZoneModal(zoneId) {
    try {
        const res = await zoneApiCall('get_zone', { params: { id: zoneId } });
        if (!res || !res.data) return;
        const zone = res.data;

        const zoneIdEl = document.getElementById('zoneId'); if (zoneIdEl) zoneIdEl.value = zone.id || '';
        const zoneNameEl = document.getElementById('zoneName'); if (zoneNameEl) zoneNameEl.value = zone.name || '';
        const zoneFilenameEl = document.getElementById('zoneFilename'); if (zoneFilenameEl) zoneFilenameEl.value = zone.filename || '';
        const zoneDirectoryEl = document.getElementById('zoneDirectory'); if (zoneDirectoryEl) zoneDirectoryEl.value = zone.directory || '';
        const zoneContentEl = document.getElementById('zoneContent') || document.getElementById('zoneContentTextarea'); if (zoneContentEl) zoneContentEl.value = zone.content || '';

        // populate domain
        const zoneDomainEl = document.getElementById('zoneDomain');
        if (zoneDomainEl) zoneDomainEl.value = zone.domain || '';

        // toggle visibility for domain group
        const group = document.getElementById('zoneDomainGroup') || document.getElementById('zone-domain-group');
        if (group) {
            group.style.display = ((zone.file_type || 'master') === 'master') ? 'block' : 'none';
        }
        
        // Populate SOA/TTL fields (only visible for master zones)
        const zoneSoaFieldset = document.getElementById('zoneSoaFieldset');
        if (zoneSoaFieldset) {
            zoneSoaFieldset.style.display = ((zone.file_type || 'master') === 'master') ? 'block' : 'none';
        }
        
        // Set SOA/TTL field values
        const zoneDefaultTtlEl = document.getElementById('zoneDefaultTtl');
        if (zoneDefaultTtlEl) zoneDefaultTtlEl.value = zone.default_ttl || '';
        const zoneMnameEl = document.getElementById('zoneMname');
        if (zoneMnameEl) zoneMnameEl.value = zone.mname || '';
        const zoneSoaRnameEl = document.getElementById('zoneSoaRname');
        if (zoneSoaRnameEl) zoneSoaRnameEl.value = zone.soa_rname || '';
        const zoneSoaRefreshEl = document.getElementById('zoneSoaRefresh');
        if (zoneSoaRefreshEl) zoneSoaRefreshEl.value = zone.soa_refresh || '';
        const zoneSoaRetryEl = document.getElementById('zoneSoaRetry');
        if (zoneSoaRetryEl) zoneSoaRetryEl.value = zone.soa_retry || '';
        const zoneSoaExpireEl = document.getElementById('zoneSoaExpire');
        if (zoneSoaExpireEl) zoneSoaExpireEl.value = zone.soa_expire || '';
        const zoneSoaMinimumEl = document.getElementById('zoneSoaMinimum');
        if (zoneSoaMinimumEl) zoneSoaMinimumEl.value = zone.soa_minimum || '';

        if (typeof populateZoneIncludes === 'function') try { await populateZoneIncludes(zone.id); } catch (e) {}
        
        // Store current zone ID and data (maintain existing functionality)
        // IMPORTANT: Set both local and global currentZone BEFORE calling loadParentOptions
        currentZoneId = zoneId;
        currentZone = zone;
        window.currentZone = zone; // Expose globally for helper functions
        originalZoneData = JSON.parse(JSON.stringify(zone));
        hasUnsavedChanges = false;
        
        // Clear any previous errors
        clearModalError('zoneModal');
        
        // Populate remaining fields that the new implementation doesn't cover
        const zoneModalTitle = document.getElementById('zoneModalTitle'); if (zoneModalTitle) zoneModalTitle.textContent = zone.name;
        const zoneFileTypeEl = document.getElementById('zoneFileType'); if (zoneFileTypeEl) zoneFileTypeEl.value = zone.file_type;
        const zoneStatusEl = document.getElementById('zoneStatus'); if (zoneStatusEl) zoneStatusEl.value = zone.status;
        
        // Show parent select only for includes
        const parentGroup = document.getElementById('parentGroup');
        if (zone.file_type === 'include') {
            if (parentGroup) parentGroup.style.display = 'block';
            await loadParentOptions(zone.parent_id);
        } else {
            if (parentGroup) parentGroup.style.display = 'none';
        }
        
        // Load includes list
        loadIncludesList(res.includes || []);
        
        // Load ACL entries if user can manage ACL
        if (window.CAN_MANAGE_ACL && typeof loadAclForZone === 'function') {
            await loadAclForZone(zoneId);
        }
        
        // Show modal
        document.getElementById('zoneModal').style.display = 'block';
        document.getElementById('zoneModal').classList.add('open');
        
        // Call centering helper if available
        const zoneModal = document.getElementById('zoneModal');
        if (typeof window.ensureModalCentered === 'function') {
            window.ensureModalCentered(zoneModal);
        }
        
        switchTab('details');
        
        // Setup change detection
        setupChangeDetection();
        
        // Apply fixed modal height after modal is displayed
        setTimeout(() => {
            applyFixedModalHeight();
        }, 150);
    } catch (err) {
        console.error('openZoneModal error', err);
    }
}



/**
 * Close zone modal
 */
function closeZoneModal() {
    if (hasUnsavedChanges) {
        if (!confirm('Vous avez des modifications non enregistrées. Êtes-vous sûr de vouloir fermer?')) {
            return;
        }
    }
    
    // Remove height lock to restore clean state for next open
    unlockZoneModalHeight();
    
    document.getElementById('zoneModal').classList.remove('open');
    document.getElementById('zoneModal').style.display = 'none';
    currentZone = null;
    currentZoneId = null;
    hasUnsavedChanges = false;
}

/**
 * Switch between tabs
 */
function switchTab(tabName) {
    currentTab = tabName;
    
    // Update tab buttons - more robust using data-zone-tab attribute
    document.querySelectorAll('.tab-btn').forEach(btn => {
        const isActive = btn.getAttribute('data-zone-tab') === tabName;
        btn.classList.toggle('active', isActive);
        btn.setAttribute('aria-selected', isActive);
    });
    
    // Update tab panes - toggle active class and aria-hidden for accessibility
    document.querySelectorAll('.tab-pane').forEach(pane => {
        const isActive = pane.id === tabName + 'Tab';
        pane.classList.toggle('active', isActive);
        pane.setAttribute('aria-hidden', !isActive);
    });
    
    // Initialize ACL tab when first shown
    if (tabName === 'acl' && window.CAN_MANAGE_ACL) {
        // Initialize subject type options to ensure correct field visibility
        updateAclSubjectOptions?.();
    }
    
    // Refresh editors if present (CodeMirror/ACE) after tab switch
    setTimeout(() => {
        try {
            document.querySelectorAll('.CodeMirror').forEach(cmEl => {
                const inst = cmEl.CodeMirror || cmEl.__cm;
                if (inst && typeof inst.refresh === 'function') inst.refresh();
            });
        } catch (e) {}
        try {
            if (typeof ace !== 'undefined') {
                document.querySelectorAll('.ace_editor').forEach(aceEl => {
                    try {
                        const ed = ace.edit(aceEl);
                        if (ed && typeof ed.resize === 'function') ed.resize();
                    } catch (err) {}
                });
            }
        } catch (e) {}
    }, 50);
    // Note: No height recalculation on tab switch - fixed 720px height is maintained
}

// Generic modal fixed-height helper using CSS variable + class
const MODAL_FIXED_CLASS = 'modal-fixed';
const DEFAULT_MODAL_HEIGHT = '730px';

function applyFixedModalHeight(height) {
  const modal = document.getElementById('zoneModal') || document.querySelector('.dns-modal') || document.querySelector('.zone-modal');
  if (!modal) return;

  // if a specific height is provided, set it as an inline CSS variable on the modal
  if (height) {
    modal.style.setProperty('--modal-fixed-height', height);
  } else {
    // ensure default exists
    if (!getComputedStyle(document.documentElement).getPropertyValue('--modal-fixed-height').trim()) {
      modal.style.setProperty('--modal-fixed-height', DEFAULT_MODAL_HEIGHT);
    }
  }

  modal.classList.add(MODAL_FIXED_CLASS);

  const mc = modal.querySelector('.dns-modal-content, .zone-modal-content');
  if (mc) {
    mc.dataset._computedModalHeight = modal.style.getPropertyValue('--modal-fixed-height') || getComputedStyle(document.documentElement).getPropertyValue('--modal-fixed-height').trim() || DEFAULT_MODAL_HEIGHT;
    mc.dataset._allowGrow = '0';
  }

  modal.querySelectorAll('.tab-pane, .zone-tab-content, .tab-content, .dns-modal-body').forEach(tc => {
    tc.style.overflow = 'auto';
  });

  setTimeout(() => {
    try { document.querySelectorAll('.CodeMirror').forEach(cmEl => (cmEl.CodeMirror || cmEl.__cm)?.refresh?.()); } catch (e) {}
    try { document.querySelectorAll('.ace_editor').forEach(aceEl => { try { const ed = (window.ace && ace.edit) ? ace.edit(aceEl) : null; if (ed && typeof ed.resize === 'function') ed.resize(); } catch (err) {} }); } catch (e) {}
  }, 80);
}

function adjustZoneModalTabHeights(force = false, allowGrowBeyondViewport = false) {
  applyFixedModalHeight();
}
window.adjustZoneModalTabHeights = adjustZoneModalTabHeights;

function lockZoneModalHeight() {
  applyFixedModalHeight();
}

function unlockZoneModalHeight() {
  const modal = document.getElementById('zoneModal') || document.querySelector('.dns-modal') || document.querySelector('.zone-modal');
  if (!modal) return;

  modal.classList.remove(MODAL_FIXED_CLASS);
  modal.style.removeProperty('--modal-fixed-height');

  const mc = modal.querySelector('.dns-modal-content, .zone-modal-content');
  if (mc) {
    delete mc.dataset._computedModalHeight;
    delete mc.dataset._allowGrow;
    mc.style.height = '';
    mc.style.maxHeight = '';
  }

  modal.querySelectorAll('.tab-pane, .zone-tab-content, .tab-content, .dns-modal-body').forEach(tc => {
    tc.style.overflow = '';
  });
}

function handleZoneModalResize() {
  // no-op; fixed height via CSS variable/class
}

/**
 * Legacy function name kept for backward compatibility
 */
function setZoneTabContentHeight() {
    adjustZoneModalTabHeights();
}

/**
 * Load parent options for includes
 */
async function loadParentOptions(currentParentId) {
    try {
        // Fallback: if currentZone is not set, try to get zone info from hidden field or currentZoneId
        if (!currentZone && !window.currentZone) {
            const zoneIdEl = document.getElementById('zoneId');
            const zoneIdValue = zoneIdEl ? zoneIdEl.value : currentZoneId;
            console.warn('[loadParentOptions] currentZone is not set, using fallback with zoneId:', zoneIdValue);
            
            // Try to fetch the current zone if we have an ID
            if (zoneIdValue) {
                try {
                    const res = await zoneApiCall('get_zone', { params: { id: zoneIdValue } });
                    if (res && res.data) {
                        currentZone = res.data;
                        window.currentZone = res.data;
                    }
                } catch (e) {
                    console.error('[loadParentOptions] Failed to fetch current zone:', e);
                }
            }
        }
        
        const response = await zoneApiCall('list_zones', { 
            params: { 
                status: 'active',
                recursive: 1,
                per_page: 5000  // Increased to 5000 with recursive=1 to support instances with many zones (~300+)
            } 
        });
        
        if (response.success) {
            const select = document.getElementById('zoneParent');
            if (!select) {
                console.warn('[loadParentOptions] zoneParent select element not found');
                return;
            }
            
            select.innerHTML = '<option value="">Aucun parent</option>';
            
            // Filter out the current zone itself (use both currentZone and window.currentZone)
            const currentZoneObj = currentZone || window.currentZone;
            const currentZoneIdValue = currentZoneObj ? currentZoneObj.id : (currentZoneId || null);
            const zones = response.data.filter(z => z.id != currentZoneIdValue);
            
            zones.forEach(zone => {
                const option = document.createElement('option');
                option.value = zone.id;
                option.textContent = `${zone.name} (${zone.file_type})`;
                select.appendChild(option);
            });
            
            // Set the select element's value directly after all options are added
            // This is more reliable than setting option.selected on individual options
            if (currentParentId) {
                select.value = String(currentParentId);
                
                // Verify the selection was successful
                if (select.value === String(currentParentId)) {
                    const selectedOption = select.options[select.selectedIndex];
                    console.debug('[loadParentOptions] Selected parent:', selectedOption?.textContent, 'id:', currentParentId);
                } else {
                    console.warn('[loadParentOptions] Parent ID provided but not found in options:', currentParentId);
                }
            }
        }
    } catch (error) {
        console.error('[loadParentOptions] Failed to load parent options:', error);
    }
}

/**
 * Load includes list
 */
function loadIncludesList(includes) {
    const container = document.getElementById('includesList');
    
    if (includes.length === 0) {
        container.innerHTML = '<p class="empty-list">Aucun include associé à cette zone.</p>';
        return;
    }
    
    container.innerHTML = includes.map(inc => `
        <div class="include-item" style="padding: 0.75rem; margin-bottom: 0.5rem; border: 1px solid #ddd; border-radius: 4px; background: white;">
            <div style="display: flex; justify-content: space-between; align-items: center;">
                <div>
                    <strong>${escapeHtml(inc.name)}</strong>
                    <br>
                    <small><code>${escapeHtml(inc.filename)}</code></small>
                    <span class="badge badge-position" style="margin-left: 0.5rem;">Position: ${inc.position}</span>
                </div>
                <button class="btn btn-xs btn-secondary" onclick="removeIncludeFromZone(${inc.id})" title="Retirer">
                    <i class="fas fa-times"></i>
                </button>
            </div>
        </div>
    `).join('');
}

/**
 * Setup change detection
 */
function setupChangeDetection() {
    const inputs = [
        'zoneName', 'zoneFilename', 'zoneDirectory', 'zoneStatus', 'zoneContent', 'zoneParent', 'zoneDomain',
        'zoneDefaultTtl', 'zoneSoaRname', 'zoneSoaRefresh', 'zoneSoaRetry', 'zoneSoaExpire', 'zoneSoaMinimum'
    ];
    inputs.forEach(id => {
        const elem = document.getElementById(id);
        if (elem) {
            elem.addEventListener('input', () => {
                hasUnsavedChanges = true;
            });
        }
    });
}

/**
 * Save zone changes
 */
async function saveZone() {
    try {
        // Clear any previous errors
        clearModalError('zoneModal');
        
        const zoneId = document.getElementById('zoneId').value;
        
        // Get content directly from textarea (no CodeMirror)
        const content = document.getElementById('zoneContent').value;
        
        const data = {
            name: document.getElementById('zoneName').value,
            filename: document.getElementById('zoneFilename').value,
            directory: document.getElementById('zoneDirectory').value || null,
            content: content
        };
        
        // Add domain and SOA/TTL fields only for master zones
        if (currentZone.file_type === 'master') {
            data.domain = document.getElementById('zoneDomain').value || null;
            
            // Get SOA/TTL fields
            const defaultTtl = document.getElementById('zoneDefaultTtl')?.value?.trim();
            const mname = document.getElementById('zoneMname')?.value?.trim();
            const soaRname = document.getElementById('zoneSoaRname')?.value?.trim();
            const soaRefresh = document.getElementById('zoneSoaRefresh')?.value?.trim();
            const soaRetry = document.getElementById('zoneSoaRetry')?.value?.trim();
            const soaExpire = document.getElementById('zoneSoaExpire')?.value?.trim();
            const soaMinimum = document.getElementById('zoneSoaMinimum')?.value?.trim();
            
            // Validate SOA/TTL numeric fields using helper function
            const soaFields = [
                { value: defaultTtl, name: 'Le $TTL par défaut' },
                { value: soaRefresh, name: 'Le refresh SOA' },
                { value: soaRetry, name: 'Le retry SOA' },
                { value: soaExpire, name: 'L\'expire SOA' },
                { value: soaMinimum, name: 'Le minimum SOA' }
            ];
            
            for (const field of soaFields) {
                const validation = validatePositiveInteger(field.value, field.name);
                if (!validation.valid) {
                    showModalError('zoneModal', validation.error);
                    return;
                }
            }
            
            data.default_ttl = defaultTtl || null;
            // Normalize MNAME with trailing dot if provided
            data.mname = mname ? normalizeFqdn(mname) : null;
            data.soa_rname = soaRname || null;
            data.soa_refresh = soaRefresh || null;
            data.soa_retry = soaRetry || null;
            data.soa_expire = soaExpire || null;
            data.soa_minimum = soaMinimum || null;
        }
        
        // Handle status change separately if needed
        const newStatus = document.getElementById('zoneStatus').value;
        if (newStatus !== originalZoneData.status) {
            await zoneApiCall('set_status_zone', {
                params: { id: zoneId, status: newStatus }
            });
        }
        
        // Handle parent reassignment for includes
        if (currentZone.file_type === 'include') {
            const newParentId = document.getElementById('zoneParent').value;
            if (newParentId && newParentId != currentZone.parent_id) {
                await zoneApiCall('assign_include', {
                    method: 'POST',
                    body: {
                        parent_id: parseInt(newParentId),
                        include_id: parseInt(zoneId),
                        position: 0
                    }
                });
            }
        }
        
        // Update zone
        await zoneApiCall('update_zone', {
            method: 'POST',
            params: { id: zoneId },
            body: data
        });
        
        showSuccess('Zone mise à jour avec succès');
        hasUnsavedChanges = false;
        
        // Refresh domain list if this is a master zone
        if (currentZone.file_type === 'master') {
            await populateDomainSelect();
        }
        
        closeZoneModal();
        await loadZonesData();
        await renderZonesTable();
    } catch (error) {
        console.error('Failed to save zone:', error);
        
        // Show error in modal banner instead of global error
        const errorMessage = error.message || 'Erreur lors de la sauvegarde de la zone';
        showModalError('zoneModal', errorMessage);
    }
}

/**
 * Delete zone (soft delete)
 */
async function deleteZone() {
    if (!confirm('Êtes-vous sûr de vouloir supprimer cette zone? Cette action peut être annulée en restaurant la zone.')) {
        return;
    }
    
    try {
        const zoneId = document.getElementById('zoneId').value;
        
        await zoneApiCall('set_status_zone', {
            params: { id: zoneId, status: 'deleted' }
        });
        
        showSuccess('Zone supprimée avec succès');
        closeZoneModal();
        await loadZonesData();
        await renderZonesTable();
    } catch (error) {
        console.error('Failed to delete zone:', error);
        showError('Erreur lors de la suppression: ' + error.message);
    }
}

/**
 * Open create include form
 */
function openCreateIncludeForm() {
    document.getElementById('createIncludeForm').style.display = 'block';
    document.getElementById('includeNameInput').value = '';
    document.getElementById('includeFilenameInput').value = '';
    document.getElementById('includeContentInput').value = '';
}

/**
 * Cancel create include
 */
function cancelCreateInclude() {
    document.getElementById('createIncludeForm').style.display = 'none';
}

/**
 * Submit create include (DEPRECATED - aliased to saveInclude for backward compatibility)
 */
async function submitCreateInclude() {
    // Alias to saveInclude() which is the single source of truth
    return await saveInclude();
}

/**
 * Remove include from zone
 */
async function removeIncludeFromZone(includeId) {
    if (!confirm('Êtes-vous sûr de vouloir retirer cet include de cette zone?')) {
        return;
    }
    
    try {
        await zoneApiCall('remove_include', {
            params: {
                parent_id: currentZone.id,
                include_id: includeId
            }
        });
        
        showSuccess('Include retiré avec succès');
        
        // Reload zone data
        await openZoneModal(currentZone.id);
    } catch (error) {
        console.error('Failed to remove include:', error);
        showError('Erreur lors du retrait de l\'include: ' + error.message);
    }
}

/**
 * Open create master modal (new domain)
 */
function openCreateMasterModal() {
    openCreateZoneModal();
}

/**
 * Open edit master modal for selected domain
 */
async function openEditMasterModal() {
    if (!window.ZONES_SELECTED_MASTER_ID) {
        showError('Aucun domaine sélectionné');
        return;
    }
    
    try {
        await openZoneModal(window.ZONES_SELECTED_MASTER_ID);
    } catch (error) {
        console.error('Failed to open edit modal:', error);
        showError('Erreur lors de l\'ouverture du modal: ' + error.message);
    }
}

/**
 * Open create include modal for selected domain
 * Minimal defensive implementation that preselects the selected zonefile as parent
 * and synchronizes header/input display
 * @param {number} parentId - Optional parent zone ID (defaults to currently selected)
 */
async function openCreateIncludeModal(parentId) {
    try {
        // Determine defaultParentId with priority chain:
        // parentId param -> window.ZONES_SELECTED_ZONEFILE_ID -> window.selectedZoneId -> #zone-file-id input -> window.ZONES_SELECTED_MASTER_ID
        const defaultParentId = parentId || 
            window.ZONES_SELECTED_ZONEFILE_ID || 
            window.selectedZoneId ||
            (document.getElementById('zone-file-id') ? document.getElementById('zone-file-id').value : '') ||
            window.ZONES_SELECTED_MASTER_ID;

        if (!defaultParentId) {
            showError('Veuillez sélectionner un fichier de zone ou un domaine d\'abord');
            return;
        }

        // Fetch the selected zone (this will be the visible preselected parent in the combobox)
        let selectedZone = null;
        try {
            const selResp = await zoneApiCall('get_zone', { params: { id: defaultParentId } });
            if (selResp && selResp.data) selectedZone = selResp.data;
        } catch (e) {
            console.warn('openCreateIncludeModal: failed to fetch selected zone', e);
        }

        // Determine master id for domain display with page-priority:
        // Prefer window.ZONES_SELECTED_MASTER_ID or #zone-master-id; only fall back to getMasterIdFromZoneId if not present
        let masterId = null;
        const zoneMasterIdEl = document.getElementById('zone-master-id');
        if (window.ZONES_SELECTED_MASTER_ID) {
            masterId = window.ZONES_SELECTED_MASTER_ID;
        } else if (zoneMasterIdEl && zoneMasterIdEl.value) {
            masterId = zoneMasterIdEl.value;
        } else {
            // Fall back to resolving master from selected zone
            try {
                masterId = await getMasterIdFromZoneId(selectedZone ? selectedZone.id : defaultParentId);
            } catch (e) {
                console.warn('openCreateIncludeModal: getMasterIdFromZoneId failed', e);
                // Final fallback to defaultParentId
                masterId = defaultParentId;
            }
        }

        // Fetch master zone to get domain/name for display
        let masterZone = null;
        try {
            const mResp = await zoneApiCall('get_zone', { params: { id: masterId } });
            if (mResp && mResp.data) masterZone = mResp.data;
        } catch (e) {
            console.warn('openCreateIncludeModal: failed to fetch master zone', e);
        }

        // Prepare domain display value - priority: page combobox (#zone-domain-input) > masterZone.domain > masterZone.name
        let domainDisplay = '-';
        const pageDomainInput = document.getElementById('zone-domain-input');
        if (pageDomainInput && pageDomainInput.value && pageDomainInput.value.trim() !== '') {
            domainDisplay = pageDomainInput.value.trim();
        } else if (masterZone) {
            domainDisplay = masterZone.domain || masterZone.name || '-';
        }

        // Update #include-domain (disabled input) and #include-modal-domain (span) with same value
        const domainField = document.getElementById('include-domain');
        const domainTitle = document.getElementById('include-modal-domain');
        const fileTitle = document.getElementById('include-modal-title');
        
        if (domainField) {
            domainField.value = domainDisplay;
            domainField.disabled = true; // Ensure field is non-editable
            domainField.readOnly = true; // Also set readOnly for extra safety
            domainField.style.textAlign = 'center'; // Center the text
        }
        if (domainTitle) domainTitle.textContent = domainDisplay;
        if (fileTitle) fileTitle.textContent = 'Nouveau fichier de zone';

        // Set hidden IDs: include-domain-id = masterId
        const includeDomainIdEl = document.getElementById('include-domain-id');
        if (includeDomainIdEl) includeDomainIdEl.value = masterId || '';

        // Clear creation input fields
        const nameEl = document.getElementById('include-name');
        const filenameEl = document.getElementById('include-filename');
        const dirEl = document.getElementById('include-directory');
        if (nameEl) nameEl.value = '';
        if (filenameEl) {
            filenameEl.value = '';
            filenameEl.dataset.userEdited = ''; // Reset user-edited flag
        }
        if (dirEl) dirEl.value = '';

        // Prefill the visible combobox include-parent-input with the selected zonefile text
        // and include-parent-zone-id with selectedZone.id (if selectedZone present)
        const includeInput = document.getElementById('include-parent-input');
        const includeHidden = document.getElementById('include-parent-zone-id');
        if (selectedZone && includeInput && includeHidden) {
            includeInput.value = `${selectedZone.name} (${selectedZone.file_type})`;
            includeHidden.value = selectedZone.id;
        }

        // Populate the parent combobox with master + recursive includes
        // This call will overwrite the combobox list but we'll reapply the visible selection after
        await populateIncludeParentCombobox(masterId);

        // Re-apply visible selection to show the originally selected zonefile in the combobox
        // (populateIncludeParentCombobox may have reset these values)
        if (selectedZone && includeInput && includeHidden) {
            includeInput.value = `${selectedZone.name} (${selectedZone.file_type})`;
            includeHidden.value = selectedZone.id;
        }

        // Open the modal
        const modal = document.getElementById('include-create-modal');
        if (modal) {
            modal.style.display = 'block';
            modal.classList.add('open');
            // Center modal if helper is available
            if (typeof window.ensureModalCentered === 'function') {
                window.ensureModalCentered(modal);
            }
        }
    } catch (error) {
        console.warn('openCreateIncludeModal: unexpected error', error);
        showError('Erreur lors de l\'ouverture du modal');
    }
}

/**
 * Populate parent combobox with master + recursive includes
 * @param {number} masterId - Master zone ID (may be an include id; will be resolved to real master)
 */
async function populateIncludeParentCombobox(masterId) {
    try {
        if (!masterId) {
            console.warn('[populateIncludeParentCombobox] No masterId provided');
            return;
        }
        
        let masterIdNum = parseInt(masterId, 10);
        if (isNaN(masterIdNum) || masterIdNum <= 0) {
            console.warn('[populateIncludeParentCombobox] Invalid masterId:', masterId);
            return;
        }
        
        console.debug('[populateIncludeParentCombobox] Starting with masterId:', masterIdNum);
        
        // If a non-master id is passed, resolve the real master by calling getMasterIdFromZoneId
        let zoneToCheck = null;
        try {
            const checkResp = await zoneApiCall('get_zone', { params: { id: masterIdNum } });
            if (checkResp && checkResp.data) {
                zoneToCheck = checkResp.data;
            }
        } catch (e) {
            console.warn('[populateIncludeParentCombobox] Failed to fetch zone to check type:', e);
        }
        
        // If the zone is an include, resolve to its master (normalize file_type check)
        if (zoneToCheck) {
            const fileType = (zoneToCheck.file_type || '').toLowerCase().trim();
            if (fileType === 'include') {
                try {
                    const resolvedMasterId = await getMasterIdFromZoneId(masterIdNum);
                    if (resolvedMasterId) {
                        masterIdNum = parseInt(resolvedMasterId, 10);
                        console.debug('[populateIncludeParentCombobox] Resolved include to master:', masterIdNum);
                    }
                } catch (e) {
                    console.warn('[populateIncludeParentCombobox] Failed to resolve include to master:', e);
                }
            }
        }
        
        // Fetch recursive includes using fetchZonesForMaster with fallback to ancestor-chain filtering
        let zones = [];
        try {
            zones = await fetchZonesForMaster(masterIdNum);
            console.debug('[populateIncludeParentCombobox] Fetched zones:', zones.length);
        } catch (e) {
            console.warn('[populateIncludeParentCombobox] fetchZonesForMaster failed, falling back to ancestor-chain filtering:', e);
            
            // Fallback: use zoneApiCall('list_zones') and filter by ancestor chain
            try {
                const response = await zoneApiCall('list_zones', {
                    params: {
                        status: 'active',
                        per_page: 1000
                    }
                });
                
                if (response.success) {
                    const allZones = response.data || [];
                    
                    // Filter zones whose ancestor chain contains masterId (normalize file_type)
                    zones = allZones.filter(zone => {
                        const fileType = (zone.file_type || '').toLowerCase().trim();
                        if (fileType !== 'include') return false;
                        
                        // Check if this zone's ancestor chain contains the master
                        let currentZone = zone;
                        let iterations = 0;
                        const maxIterations = 50;
                        
                        while (currentZone && iterations < maxIterations) {
                            iterations++;
                            const parentId = parseInt(currentZone.parent_id || 0, 10);
                            
                            if (parentId === masterIdNum) {
                                return true;
                            }
                            
                            if (parentId === 0 || !parentId) {
                                break;
                            }
                            
                            // Find parent in allZones
                            currentZone = allZones.find(z => parseInt(z.id, 10) === parentId);
                        }
                        
                        return false;
                    });
                    console.debug('[populateIncludeParentCombobox] Fallback filtered zones:', zones.length);
                }
            } catch (fallbackErr) {
                console.error('[populateIncludeParentCombobox] Fallback also failed:', fallbackErr);
                zones = [];
            }
        }
        
        console.debug('[populateIncludeParentCombobox] Total zones to populate:', zones.length);
        
        // Try to fetch the master via zoneApiCall('get_zone'); if that returns nothing,
        // search caches; if still missing, create a minimal placeholder master object
        let masterZone = null;
        try {
            const masterResponse = await zoneApiCall('get_zone', { params: { id: masterIdNum } });
            if (masterResponse && masterResponse.data) {
                masterZone = masterResponse.data;
                console.debug('[populateIncludeParentCombobox] Master zone fetched:', masterZone.name);
            }
        } catch (e) {
            console.warn('[populateIncludeParentCombobox] Failed to fetch master zone, searching caches:', e);
        }
        
        // If not found via API, search caches
        if (!masterZone) {
            const cachesToSearch = [
                window.ALL_ZONES,
                window.ZONES_ALL,
                window.CURRENT_ZONE_LIST,
                allMasters
            ];
            
            for (const cache of cachesToSearch) {
                if (Array.isArray(cache) && cache.length > 0) {
                    masterZone = cache.find(z => parseInt(z.id, 10) === masterIdNum);
                    if (masterZone) {
                        console.log('[populateIncludeParentCombobox] Found master in cache');
                        break;
                    }
                }
            }
        }
        
        // If still not found, create a minimal placeholder so the UI displays an entry
        if (!masterZone) {
            console.warn('[populateIncludeParentCombobox] Master not found anywhere, creating minimal placeholder');
            masterZone = {
                id: masterIdNum,
                name: `Master ${masterIdNum}`,
                filename: `master-${masterIdNum}.db`,
                file_type: 'master',
                domain: '',
                status: 'active',
                parent_id: null,
                created_at: new Date().toISOString(),
                updated_at: new Date().toISOString()
            };
        }
        
        // Compose final list with master first then includes sorted alphabetically (deduplicated)
        const composedList = [];
        const seenIds = new Set();
        
        // Always add master first
        if (masterZone) {
            composedList.push(masterZone);
            seenIds.add(String(masterZone.id));
        }
        
        // Sort includes alphabetically by name before adding to list
        const sortedZones = sortZonesAlphabetically(zones || []);
        
        // Then add sorted includes (deduplicated)
        sortedZones.forEach(z => {
            if (!seenIds.has(String(z.id))) {
                composedList.push(z);
                seenIds.add(String(z.id));
            }
        });
        
        // Set window.CURRENT_INCLUDE_PARENT_LIST to composed list
        window.CURRENT_INCLUDE_PARENT_LIST = composedList;
        
        // Setup combobox elements
        const input = document.getElementById('include-parent-input');
        const list = document.getElementById('include-parent-list');
        const hiddenField = document.getElementById('include-parent-zone-id');
        
        if (!input || !list || !hiddenField) {
            console.warn('[populateIncludeParentCombobox] Combobox elements not found');
            return;
        }
        
        // Check if include-parent-zone-id has a pre-existing value to preserve
        const existingParentId = hiddenField.value ? parseInt(hiddenField.value, 10) : null;
        
        // Wire the combobox UI: preserve behavior of preselecting include-parent-zone-id if present,
        // otherwise preselect the master
        if (existingParentId && composedList.find(z => parseInt(z.id, 10) === existingParentId)) {
            // Keep existing selection (don't overwrite)
            const existingZone = composedList.find(z => parseInt(z.id, 10) === existingParentId);
            if (existingZone) {
                input.value = `${existingZone.name} (${existingZone.file_type})`;
                hiddenField.value = existingParentId;
            }
        } else {
            // Preselect the master zone by default
            if (masterZone) {
                input.value = `${masterZone.name} (${masterZone.file_type})`;
                hiddenField.value = masterIdNum;
            } else {
                input.value = '';
                hiddenField.value = '';
            }
        }
        
        // Remove old event listeners by cloning the input element
        const newInput = input.cloneNode(true);
        input.parentNode.replaceChild(newInput, input);
        const inputEl = document.getElementById('include-parent-input');
        
        // Input event - filter zones with server search for queries ≥2 chars
        inputEl.addEventListener('input', async () => {
            const query = inputEl.value.toLowerCase().trim();
            
            // Server-first strategy for queries ≥2 chars
            if (query.length >= 2) {
                console.debug('[populateIncludeParentCombobox] Using server search for query:', query);
                try {
                    const serverResults = await serverSearchZones(query, { limit: 100 });
                    // Filter to only include zones in the master's tree
                    // Use Set for O(1) lookup performance
                    const composedIds = new Set(composedList.map(cz => parseInt(cz.id, 10)));
                    const filtered = serverResults.filter(z => composedIds.has(parseInt(z.id, 10)));
                    
                    populateComboboxList(list, filtered, (zone) => ({
                        id: zone.id,
                        text: `${zone.name} (${zone.file_type})`
                    }), (zone) => {
                        inputEl.value = `${zone.name} (${zone.file_type})`;
                        hiddenField.value = zone.id;
                        list.style.display = 'none';
                    });
                    return;
                } catch (err) {
                    console.warn('[populateIncludeParentCombobox] Server search failed, fallback to client:', err);
                    // Fall through to client filtering
                }
            }
            
            // Client filtering for short queries or when server fails
            const filtered = composedList.filter(z => 
                (z.name || '').toLowerCase().includes(query) || 
                (z.filename || '').toLowerCase().includes(query)
            );
            
            populateComboboxList(list, filtered, (zone) => ({
                id: zone.id,
                text: `${zone.name} (${zone.file_type})`
            }), (zone) => {
                inputEl.value = `${zone.name} (${zone.file_type})`;
                hiddenField.value = zone.id;
                list.style.display = 'none';
            });
        });
        
        // Focus - show all zones
        inputEl.addEventListener('focus', () => {
            populateComboboxList(list, composedList, (zone) => ({
                id: zone.id,
                text: `${zone.name} (${zone.file_type})`
            }), (zone) => {
                inputEl.value = `${zone.name} (${zone.file_type})`;
                hiddenField.value = zone.id;
                list.style.display = 'none';
            });
        });
        
        // Blur - hide list (with delay to allow click)
        inputEl.addEventListener('blur', () => {
            setTimeout(() => {
                list.style.display = 'none';
            }, window.COMBOBOX_BLUR_DELAY || 200);
        });
        
        // Escape key - close list
        inputEl.addEventListener('keydown', (e) => {
            if (e.key === 'Escape') {
                list.style.display = 'none';
                inputEl.blur();
            } else if (e.key === 'Enter') {
                const first = list.querySelector('.combobox-item');
                if (first) first.click();
                e.preventDefault();
            }
        });
        
    } catch (error) {
        console.error('[populateIncludeParentCombobox] Fatal error:', error);
    }
}

/**
 * Close include create modal
 */
function closeIncludeCreateModal() {
    const modal = document.getElementById('include-create-modal');
    modal.classList.remove('open');
    modal.style.display = 'none';
}

/**
 * Save include from create modal
 */
async function saveInclude() {
    try {
        // Clear any previous errors
        clearModalError('includeCreate');
        
        // Get form values
        const name = document.getElementById('include-name').value?.trim() || '';
        const filename = document.getElementById('include-filename').value?.trim() || '';
        const parentId = document.getElementById('include-parent-zone-id').value;
        const directory = document.getElementById('include-directory').value?.trim() || null;
        
        // Validate name field with strict validation
        const nameValidation = validateZoneName(name);
        if (!nameValidation.valid) {
            showModalError('includeCreate', nameValidation.error);
            return;
        }
        
        // Validate filename (required, no spaces, must end with .db)
        const filenameValidation = validateFilename(filename);
        if (!filenameValidation.valid) {
            showModalError('includeCreate', filenameValidation.error);
            return;
        }
        
        // Validate parent selection
        if (!parentId) {
            showModalError('includeCreate', 'Veuillez sélectionner un fichier de zone parent');
            return;
        }
        
        // Create the include zone
        const data = {
            name: name,
            filename: filename,
            file_type: 'include',
            directory: directory,
            content: '' // Empty content for new include
        };
        
        const response = await zoneApiCall('create_zone', {
            method: 'POST',
            body: data
        });
        
        if (!response.success) {
            throw new Error(response.error || 'Erreur lors de la création de l\'include');
        }
        
        const includeId = response.id;
        
        // Assign the include to the parent zone
        await zoneApiCall('assign_include', {
            method: 'POST',
            body: {
                parent_id: parseInt(parentId),
                include_id: parseInt(includeId),
                position: 0 // Default position
            }
        });
        
        showSuccess('Fichier de zone créé et assigné avec succès');
        closeIncludeCreateModal();
        
        // Refresh domain list and zones table
        await populateZoneDomainSelect();
        await loadZonesData();
        await renderZonesTable();
    } catch (error) {
        console.error('Failed to save include:', error);
        
        // Show error in modal banner
        const errorMessage = error.message || 'Erreur lors de la création du fichier de zone';
        showModalError('includeCreate', errorMessage);
    }
}

/**
 * Open create zone modal
 */
function openCreateZoneModal() {
    // Clear any previous errors
    clearModalError('createZone');
    
    document.getElementById('createZoneForm').reset();
    
    // Reset user-edited flags for filename fields
    const masterFilenameEl = document.getElementById('master-filename');
    if (masterFilenameEl) {
        masterFilenameEl.dataset.userEdited = '';
    }
    
    const modal = document.getElementById('master-create-modal');
    modal.style.display = 'block';
    modal.classList.add('open');
    
    // Call centering helper if available
    if (typeof window.ensureModalCentered === 'function') {
        window.ensureModalCentered(modal);
    }
}

/**
 * Close create zone modal
 */
function closeCreateZoneModal() {
    const modal = document.getElementById('master-create-modal');
    modal.classList.remove('open');
    modal.style.display = 'none';
}

/**
 * Create zone
 */
async function createZone() {
    try {
        // Clear any previous errors
        clearModalError('createZone');
        
        // Get field values
        const domain = document.getElementById('master-domain').value?.trim() || '';
        const name = document.getElementById('master-zone-name').value?.trim() || '';
        const filename = document.getElementById('master-filename').value?.trim() || '';
        const directory = document.getElementById('master-directory').value?.trim() || null;
        
        // Get SOA/TTL fields
        const defaultTtl = document.getElementById('master-default-ttl').value?.trim() || '';
        const mname = document.getElementById('master-mname').value?.trim() || '';
        const soaRname = document.getElementById('master-soa-rname').value?.trim() || '';
        const soaRefresh = document.getElementById('master-soa-refresh').value?.trim() || '';
        const soaRetry = document.getElementById('master-soa-retry').value?.trim() || '';
        const soaExpire = document.getElementById('master-soa-expire').value?.trim() || '';
        const soaMinimum = document.getElementById('master-soa-minimum').value?.trim() || '';
        
        // Validate zone name as FQDN for master zones
        const nameValidation = validateMasterZoneName(name);
        if (!nameValidation.valid) {
            showModalError('createZone', nameValidation.error);
            return;
        }
        
        // Validate domain field (strict validation on labels only if not empty)
        if (domain && !validateDomainLabel(domain)) {
            showModalError('createZone', 'Le domaine contient des caractères invalides (seules les lettres, chiffres et tirets sont autorisés dans chaque label ; pas d\'underscore).');
            return;
        }
        
        // Validate filename (required, no spaces, must end with .db)
        const filenameValidation = validateFilename(filename);
        if (!filenameValidation.valid) {
            showModalError('createZone', filenameValidation.error);
            return;
        }
        
        // Validate SOA/TTL numeric fields using helper function
        const soaFields = [
            { value: defaultTtl, name: 'Le $TTL par défaut' },
            { value: soaRefresh, name: 'Le refresh SOA' },
            { value: soaRetry, name: 'Le retry SOA' },
            { value: soaExpire, name: 'L\'expire SOA' },
            { value: soaMinimum, name: 'Le minimum SOA' }
        ];
        
        for (const field of soaFields) {
            const validation = validatePositiveInteger(field.value, field.name);
            if (!validation.valid) {
                showModalError('createZone', validation.error);
                return;
            }
        }
        
        // Normalize MNAME with trailing dot if provided
        const normalizedMname = mname ? normalizeFqdn(mname) : null;
        
        // Prepare data for API call
        // Normalize zone name to lowercase for consistency (FQDN standard)
        const normalizedName = name.toLowerCase();
        const data = {
            name: normalizedName,
            filename: filename,
            file_type: 'master', // Always create as master from "Nouveau domaine" button
            content: '', // Empty content for new master zones - content omitted
            domain: domain || null,
            directory: directory,
            default_ttl: defaultTtl || null,
            mname: normalizedMname,
            soa_rname: soaRname || null,
            soa_refresh: soaRefresh || null,
            soa_retry: soaRetry || null,
            soa_expire: soaExpire || null,
            soa_minimum: soaMinimum || null
        };

        const response = await zoneApiCall('create_zone', {
            method: 'POST',
            body: data
        });

        showSuccess('Zone créée avec succès');
        closeCreateZoneModal();
        
        // Refresh domain list if a domain was set
        if (data.domain) {
            await populateZoneDomainSelect();
            // Optionally select the newly created domain
            if (response.id) {
                onZoneDomainSelected(response.id);
            }
        }
        
        await loadZonesData();
        await renderZonesTable();
        
        // Open the new zone in the modal instead of navigating
        if (response.id) {
            await openZoneModal(response.id);
        }
    } catch (error) {
        console.error('Failed to create zone:', error);
        
        // Show error in modal banner instead of global error
        const errorMessage = error.message || 'Erreur lors de la création du domaine';
        showModalError('createZone', errorMessage);
    }
}

/**
 * Utility functions
 */

/**
 * Validate that a value is a positive integer
 * @param {string} value - The value to validate
 * @param {string} fieldName - The field name for error message
 * @returns {{valid: boolean, error: string|null}}
 */
function validatePositiveInteger(value, fieldName) {
    if (!value || value === '') {
        return { valid: true, error: null }; // Empty is valid (optional field)
    }
    const parsed = parseInt(value, 10);
    if (!Number.isInteger(parsed) || parsed < 1) {
        return { valid: false, error: `${fieldName} doit être un entier positif.` };
    }
    return { valid: true, error: null };
}

/**
 * Normalize a hostname to FQDN format (with trailing dot)
 * @param {string} hostname - The hostname to normalize
 * @returns {string} Hostname with trailing dot
 */
function normalizeFqdn(hostname) {
    if (!hostname || typeof hostname !== 'string') {
        return '';
    }
    
    hostname = hostname.trim();
    
    // Ensure trailing dot for FQDN
    if (hostname && !hostname.endsWith('.')) {
        hostname += '.';
    }
    
    return hostname;
}

function escapeHtml(text) {
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
}

function formatDate(dateString) {
    if (!dateString) return 'N/A';
    const date = new Date(dateString);
    return date.toLocaleString('fr-FR');
}

function showSuccess(message) {
    // Simple alert for now - can be enhanced with toast notifications
    alert(message);
}

function showError(message) {
    // Simple alert for now - can be enhanced with toast notifications
    alert('Erreur: ' + message);
}

/**
 * Normalize an ACL subject identifier based on its type
 * For 'user' type, converts username to lowercase for consistency
 * @param {string} identifier - The subject identifier
 * @param {string} subjectType - The type of subject ('user', 'role', 'ad_group')
 * @returns {string} - The normalized identifier
 */
function normalizeAclSubjectIdentifier(identifier, subjectType) {
    if (!identifier || typeof identifier !== 'string') {
        return identifier;
    }
    // Only normalize usernames to lowercase
    if (subjectType === 'user') {
        return identifier.toLowerCase();
    }
    return identifier;
}

/**
 * Handle generate zone file button click (delegated handler)
 */
async function handleGenerateZoneFile() {
    try {
        const zoneId = currentZoneId || document.getElementById('zoneId').value;
        
        if (!zoneId) {
            showError('Aucune zone sélectionnée');
            return;
        }
        
        // Immediately open preview modal with loading state
        openZonePreviewModalWithLoading();
        
        // Build URL for the API request
        const url = new URL(window.API_BASE + 'zone_api.php', window.location.origin);
        url.searchParams.append('action', 'generate_zone_file');
        url.searchParams.append('id', zoneId);
        
        // Fetch the generated content with credentials
        const response = await fetch(url.toString(), {
            method: 'GET',
            headers: {
                'Accept': 'application/json'
            },
            credentials: 'same-origin'
        });
        
        // Handle response
        let data;
        const contentType = response.headers.get('content-type');
        
        if (contentType && contentType.includes('application/json')) {
            try {
                data = await response.json();
            } catch (jsonErr) {
                console.error('Failed to parse JSON response:', jsonErr);
                const textContent = await response.text();
                console.error('Response text:', textContent);
                throw new Error('Réponse JSON invalide du serveur');
            }
        } else {
            // Non-JSON response
            const textContent = await response.text();
            console.error('Non-JSON response received:', textContent);
            throw new Error('Le serveur a retourné une réponse non-JSON');
        }
        
        if (!response.ok) {
            // Handle HTTP error
            console.error('HTTP error:', response.status, data);
            throw new Error(data.error || `Erreur HTTP ${response.status}`);
        }
        
        if (!data.success) {
            console.error('API error:', data);
            throw new Error(data.error || 'La génération du fichier a échoué');
        }
        
        // Success - store preview data
        previewData = {
            content: data.content || '',
            filename: data.filename || 'zone-file.conf'
        };
        
        // Update preview content
        updateZonePreviewContent();
        
        // Now trigger validation and display results
        await fetchAndDisplayValidation(zoneId);
        
    } catch (error) {
        console.error('Failed to generate zone file:', error);
        
        // Show error in preview textarea
        const textarea = document.getElementById('zoneGeneratedPreview');
        textarea.value = `Erreur lors de la génération du fichier de zone:\n\n${error.message}\n\nVeuillez consulter la console pour plus de détails.`;
        
        // Hide validation results on error
        const validationResults = document.getElementById('zoneValidationResults');
        if (validationResults) {
            validationResults.style.display = 'none';
        }
        
        // Don't close the modal - let user see the error
    }
}

/**
 * Generate zone file content with includes and DNS records - Show preview
 * (Legacy function name kept for backward compatibility)
 */
async function generateZoneFileContent(e) {
    // Prevent event propagation
    if (e) {
        e.preventDefault();
        e.stopPropagation();
    }
    
    // Call the new handler
    await handleGenerateZoneFile();
}

/**
 * Open zone preview modal with loading state
 */
function openZonePreviewModalWithLoading() {
    const modal = document.getElementById('zonePreviewModal');
    const textarea = document.getElementById('zoneGeneratedPreview');
    
    // Set loading message
    textarea.value = 'Chargement…';
    
    // Show modal using open class for better control and ensure high z-index
    modal.classList.add('open');
    modal.style.zIndex = '9999';
    
    // Call centering helper if available
    if (typeof window.ensureModalCentered === 'function') {
        window.ensureModalCentered(modal);
    }
}

/**
 * Legacy function name for backward compatibility
 */
function openZonePreviewModal() {
    openZonePreviewModalWithLoading();
}

/**
 * Update zone preview content after fetch
 */
function updateZonePreviewContent() {
    if (!previewData) {
        return;
    }
    
    const textarea = document.getElementById('zoneGeneratedPreview');
    textarea.value = previewData.content;
    
    // Setup download button handler
    const downloadBtn = document.getElementById('downloadZoneFile');
    
    // Remove old event listeners by cloning
    const newDownloadBtn = downloadBtn.cloneNode(true);
    downloadBtn.parentNode.replaceChild(newDownloadBtn, downloadBtn);
    
    // Add new event listener
    newDownloadBtn.addEventListener('click', function(e) {
        e.preventDefault();
        e.stopPropagation();
        downloadZoneFileFromPreview();
    });
}

/**
 * Close zone preview modal without closing editor modal
 */
function closeZonePreviewModal() {
    const modal = document.getElementById('zonePreviewModal');
    modal.classList.remove('open');
    // Don't close zoneModal - it should stay open
}

/**
 * Download file from zone preview
 */
function downloadZoneFileFromPreview() {
    if (!previewData) {
        showError('Aucun contenu à télécharger');
        return;
    }
    
    // Create a blob and download the file
    const blob = new Blob([previewData.content], { type: 'text/plain' });
    const url = window.URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = previewData.filename;
    document.body.appendChild(a);
    a.click();
    window.URL.revokeObjectURL(url);
    document.body.removeChild(a);
    showSuccess('Fichier de zone téléchargé avec succès');
}

/**
 * Fetch and display validation results for a zone
 */
async function fetchAndDisplayValidation(zoneId) {
    try {
        // Build URL for validation API request
        const url = new URL(window.API_BASE + 'zone_api.php', window.location.origin);
        url.searchParams.append('action', 'zone_validate');
        url.searchParams.append('id', zoneId);
        url.searchParams.append('trigger', 'true');
        
        // Fetch validation result with credentials
        const response = await fetch(url.toString(), {
            method: 'GET',
            headers: {
                'Accept': 'application/json'
            },
            credentials: 'same-origin'
        });
        
        // Handle response
        let data;
        const contentType = response.headers.get('content-type');
        
        if (contentType && contentType.includes('application/json')) {
            try {
                data = await response.json();
            } catch (jsonErr) {
                console.error('Failed to parse validation JSON response:', jsonErr);
                const textContent = await response.text();
                console.error('Response text:', textContent);
                throw new Error('Réponse JSON invalide du serveur pour la validation');
            }
        } else {
            const textContent = await response.text();
            console.error('Non-JSON validation response received:', textContent);
            throw new Error('Le serveur a retourné une réponse non-JSON pour la validation');
        }
        
        if (!response.ok) {
            console.error('Validation HTTP error:', response.status, data);
            throw new Error(data.error || `Erreur HTTP ${response.status} lors de la validation`);
        }
        
        if (!data.success) {
            console.error('Validation API error:', data);
            throw new Error(data.error || 'La validation a échoué');
        }
        
        // Display initial validation results (may be latest known or new result)
        displayValidationResults(data.validation);
        
        // Check if validation was queued and is pending
        const isQueued = data.message && data.message.includes('queued');
        const isPending = data.validation && data.validation.status === 'pending';
        
        if (isQueued || isPending) {
            console.log('Validation queued or pending, starting polling...');
            
            // Start polling for the final result
            try {
                const finalValidation = await pollValidationResult(zoneId, {
                    interval: 2000,  // Poll every 2 seconds
                    timeout: 60000   // Timeout after 60 seconds
                });
                
                // Update UI with final validation result
                displayValidationResults(finalValidation);
                console.log('Validation polling completed:', finalValidation.status);
            } catch (pollError) {
                console.error('Polling failed:', pollError);
                
                // Show polling error in validation section
                const validationStatus = document.getElementById('zoneValidationStatus');
                const validationOutput = document.getElementById('zoneValidationOutput');
                
                if (validationStatus && validationOutput) {
                    validationStatus.className = 'validation-status failed';
                    validationStatus.textContent = '❌ Timeout lors de l\'attente du résultat';
                    validationOutput.textContent = `Erreur: ${pollError.message}\n\nLa validation peut toujours être en cours. Rafraîchissez la page pour voir le résultat final.`;
                }
            }
        }
        
    } catch (error) {
        console.error('Failed to fetch validation:', error);
        
        // Show error in validation section
        const validationResults = document.getElementById('zoneValidationResults');
        const validationStatus = document.getElementById('zoneValidationStatus');
        const validationOutput = document.getElementById('zoneValidationOutput');
        
        if (validationResults && validationStatus && validationOutput) {
            validationResults.style.display = 'block';
            validationStatus.className = 'validation-status failed';
            validationStatus.textContent = '❌ Erreur lors de la récupération de la validation';
            validationOutput.textContent = `Erreur: ${error.message}\n\nLa validation n'a pas pu être effectuée. Veuillez consulter la console pour plus de détails.`;
        }
    }
}

/**
 * Poll for validation result until status is not pending or timeout
 * @param {number} zoneId - Zone file ID
 * @param {object} options - Polling options {interval: ms, timeout: ms}
 * @returns {Promise<object>} Final validation result
 */
async function pollValidationResult(zoneId, options = {}) {
    const interval = options.interval || 2000; // Poll every 2 seconds by default
    const timeout = options.timeout || 60000;  // Timeout after 60 seconds by default
    const startTime = Date.now();
    
    while (true) {
        // Check if timeout exceeded
        if (Date.now() - startTime > timeout) {
            throw new Error('Timeout attendu lors de la récupération du résultat de validation');
        }
        
        try {
            // Build URL for validation API request (without trigger)
            const url = new URL(window.API_BASE + 'zone_api.php', window.location.origin);
            url.searchParams.append('action', 'zone_validate');
            url.searchParams.append('id', zoneId);
            // No trigger parameter - just retrieve latest validation
            
            // Fetch validation result with credentials
            const response = await fetch(url.toString(), {
                method: 'GET',
                headers: {
                    'Accept': 'application/json'
                },
                credentials: 'same-origin'
            });
            
            // Handle response
            let data;
            const contentType = response.headers.get('content-type');
            
            if (contentType && contentType.includes('application/json')) {
                try {
                    data = await response.json();
                } catch (jsonErr) {
                    console.error('Failed to parse validation JSON during polling:', jsonErr);
                    throw new Error('Réponse JSON invalide du serveur');
                }
            } else {
                const textContent = await response.text();
                console.error('Non-JSON validation response during polling:', textContent);
                throw new Error('Le serveur a retourné une réponse non-JSON');
            }
            
            if (!response.ok) {
                console.error('Validation HTTP error during polling:', response.status, data);
                throw new Error(data.error || `Erreur HTTP ${response.status}`);
            }
            
            if (!data.success) {
                console.error('Validation API error during polling:', data);
                throw new Error(data.error || 'Erreur lors de la récupération de la validation');
            }
            
            const validation = data.validation;
            
            // Check if validation is complete (not pending)
            if (validation && validation.status !== 'pending') {
                return validation;
            }
            
            // Wait before next poll
            await new Promise(resolve => setTimeout(resolve, interval));
            
        } catch (error) {
            console.error('Error during validation polling:', error);
            throw error;
        }
    }
}

/**
 * Display validation results in the modal
 */
function displayValidationResults(validation) {
    const validationResults = document.getElementById('zoneValidationResults');
    const validationStatus = document.getElementById('zoneValidationStatus');
    const validationOutput = document.getElementById('zoneValidationOutput');
    
    if (!validationResults || !validationStatus || !validationOutput) {
        console.error('Validation result elements not found in DOM');
        return;
    }
    
    // Show validation section
    validationResults.style.display = 'block';
    
    // Handle case where validation is null or queued
    if (!validation) {
        validationStatus.className = 'validation-status pending';
        validationStatus.textContent = '⏳ En attente';
        validationOutput.textContent = 'La validation n\'a pas encore été effectuée pour cette zone.';
        return;
    }
    
    // Display validation status
    const status = validation.status || 'pending';
    validationStatus.className = `validation-status ${status}`;
    
    if (status === 'passed') {
        validationStatus.textContent = '✅ Validation réussie';
    } else if (status === 'failed') {
        validationStatus.textContent = '❌ Validation échouée';
    } else if (status === 'pending') {
        validationStatus.textContent = '⏳ Validation en cours';
    } else {
        validationStatus.textContent = `Statut: ${status}`;
    }
    
    // Display validation output
    const output = validation.output || 'Aucune sortie disponible';
    validationOutput.textContent = output;
}

/**
 * Setup name to filename autofill for zone creation forms
 * Monitors name fields and auto-fills corresponding filename fields with {name}.db
 * Tracks manual edits via dataset.userEdited flag to avoid overwriting user input
 */
function setupNameFilenameAutofill() {
    // Define field pairs: name input ID → filename input ID
    const fieldPairs = [
        { nameId: 'include-name', filenameId: 'include-filename' },
        { nameId: 'master-zone-name', filenameId: 'master-filename' },
        { nameId: 'includeNameInput', filenameId: 'includeFilenameInput' }
    ];
    
    fieldPairs.forEach(pair => {
        const nameInput = document.getElementById(pair.nameId);
        const filenameInput = document.getElementById(pair.filenameId);
        
        // Skip if either field doesn't exist (defensive)
        if (!nameInput || !filenameInput) {
            return;
        }
        
        // Monitor name input changes
        nameInput.addEventListener('input', () => {
            try {
                // Only autofill if filename hasn't been manually edited
                if (filenameInput.dataset.userEdited !== 'true') {
                    const nameValue = nameInput.value.trim();
                    if (nameValue) {
                        filenameInput.value = `${nameValue}.db`;
                    } else {
                        filenameInput.value = '';
                    }
                }
            } catch (e) {
                console.warn('setupNameFilenameAutofill: error during autofill', e);
            }
        });
        
        // Monitor filename input for manual edits
        filenameInput.addEventListener('input', () => {
            try {
                // Mark as user-edited when user types in filename field
                filenameInput.dataset.userEdited = 'true';
            } catch (e) {
                console.warn('setupNameFilenameAutofill: error marking user edit', e);
            }
        });
    });
}

// =========================================================================
// ACL Management Functions
// =========================================================================

// Cache for users and roles lists
let aclUsersCache = [];
let aclRolesCache = [];

/**
 * Load ACL entries for the current zone
 */
async function loadAclForZone(zoneId) {
    if (!window.CAN_MANAGE_ACL) return;
    
    const aclList = document.getElementById('aclList');
    if (!aclList) return;
    
    aclList.innerHTML = '<div class="loading">Chargement des ACL...</div>';
    
    try {
        const apiBase = window.API_BASE || '/api/';
        const normalizedBase = apiBase.endsWith('/') ? apiBase : apiBase + '/';
        const url = new URL(normalizedBase + 'admin_api.php', window.location.origin);
        url.searchParams.append('action', 'list_acl');
        url.searchParams.append('zone_id', zoneId);
        
        const response = await fetch(url.toString(), {
            method: 'GET',
            headers: {
                'Accept': 'application/json'
            },
            credentials: 'same-origin'
        });
        
        const data = await response.json();
        
        if (!response.ok) {
            throw new Error(data.error || 'Failed to load ACL entries');
        }
        
        renderAclList(data.data || []);
    } catch (error) {
        console.error('Failed to load ACL:', error);
        aclList.innerHTML = `<div class="error-state" style="color: #e74c3c; padding: 1rem;">
            <i class="fas fa-exclamation-triangle"></i> Erreur lors du chargement des ACL: ${escapeHtml(error.message)}
        </div>`;
    }
}

/**
 * Render ACL entries list
 */
function renderAclList(entries) {
    const aclList = document.getElementById('aclList');
    if (!aclList) return;
    
    if (!entries || entries.length === 0) {
        aclList.innerHTML = `<div class="empty-state" style="text-align: center; padding: 2rem; color: #666;">
            <i class="fas fa-lock-open" style="font-size: 2rem; margin-bottom: 1rem;"></i>
            <p>Aucune entrée ACL pour cette zone.</p>
            <small>Ajoutez des entrées ACL pour contrôler l'accès des utilisateurs non-admin à cette zone.</small>
        </div>`;
        return;
    }
    
    const getPermissionBadge = (permission) => {
        switch (permission) {
            case 'admin': return '<span class="badge badge-admin" style="background: #e74c3c;">Admin</span>';
            case 'write': return '<span class="badge badge-write" style="background: #f39c12;">Écriture</span>';
            case 'read': return '<span class="badge badge-read" style="background: #3498db;">Lecture</span>';
            default: return `<span class="badge">${escapeHtml(permission)}</span>`;
        }
    };
    
    const getTypeBadge = (type) => {
        switch (type) {
            case 'user': return '<span class="badge" style="background: #27ae60;">Utilisateur</span>';
            case 'role': return '<span class="badge" style="background: #9b59b6;">Rôle</span>';
            case 'ad_group': return '<span class="badge" style="background: #e67e22;">Groupe AD</span>';
            default: return `<span class="badge">${escapeHtml(type)}</span>`;
        }
    };
    
    aclList.innerHTML = `
        <table class="acl-table" style="width: 100%; border-collapse: collapse;">
            <thead>
                <tr style="background: #f8f9fa;">
                    <th style="padding: 0.75rem; text-align: left; border-bottom: 2px solid #ddd;">Type</th>
                    <th style="padding: 0.75rem; text-align: left; border-bottom: 2px solid #ddd;">Sujet</th>
                    <th style="padding: 0.75rem; text-align: left; border-bottom: 2px solid #ddd;">Permission</th>
                    <th style="padding: 0.75rem; text-align: left; border-bottom: 2px solid #ddd;">Créé par</th>
                    <th style="padding: 0.75rem; text-align: left; border-bottom: 2px solid #ddd;">Date</th>
                    <th style="padding: 0.75rem; text-align: center; border-bottom: 2px solid #ddd;">Actions</th>
                </tr>
            </thead>
            <tbody>
                ${entries.map(entry => `
                    <tr data-acl-id="${entry.id}" style="border-bottom: 1px solid #eee;">
                        <td style="padding: 0.75rem;">${getTypeBadge(entry.subject_type)}</td>
                        <td style="padding: 0.75rem;">
                            <strong>${escapeHtml(entry.subject_name || entry.subject_identifier)}</strong>
                            ${entry.subject_type === 'ad_group' ? `<br><small style="color: #666;">${escapeHtml(entry.subject_identifier)}</small>` : ''}
                        </td>
                        <td style="padding: 0.75rem;">${getPermissionBadge(entry.permission)}</td>
                        <td style="padding: 0.75rem;">${escapeHtml(entry.created_by_username || 'N/A')}</td>
                        <td style="padding: 0.75rem;">${formatDate(entry.created_at)}</td>
                        <td style="padding: 0.75rem; text-align: center;">
                            <button class="btn btn-danger btn-sm" onclick="deleteAclEntry(${entry.id})" title="Supprimer">
                                <i class="fas fa-trash"></i>
                            </button>
                        </td>
                    </tr>
                `).join('')}
            </tbody>
        </table>
    `;
}

/**
 * Update subject identifier options based on selected type
 * For 'user' type: show text input for free CN/UID entry (pre-authorization support)
 * For 'role' type: show select with existing roles
 * For 'ad_group' type: show text input for AD group DN
 */
async function updateAclSubjectOptions() {
    const typeSelect = document.getElementById('aclSubjectType');
    const selectEl = document.getElementById('aclSubjectIdentifierSelect');
    const inputEl = document.getElementById('aclSubjectIdentifierInput');
    
    if (!typeSelect || !selectEl || !inputEl) return;
    
    const type = typeSelect.value;
    
    if (type === 'user') {
        // Show text input for free CN/UID entry (allows pre-authorization of users not yet in DB)
        selectEl.style.display = 'none';
        inputEl.style.display = 'block';
        inputEl.value = '';
        inputEl.placeholder = 'CN ou UID de l\'utilisateur (ex: jdupont, john.doe)';
    } else if (type === 'role') {
        // Show select with roles list
        selectEl.style.display = 'block';
        inputEl.style.display = 'none';
        await populateAclRolesSelect();
    } else {
        // Show text input for AD group DN
        selectEl.style.display = 'none';
        inputEl.style.display = 'block';
        inputEl.value = '';
        inputEl.placeholder = 'DN du groupe AD (ex: CN=DNSAdmins,OU=Groups,DC=example,DC=com)';
    }
}

/**
 * Populate users select dropdown
 */
async function populateAclUsersSelect() {
    const selectEl = document.getElementById('aclSubjectIdentifierSelect');
    if (!selectEl) return;
    
    selectEl.innerHTML = '<option value="">Chargement...</option>';
    
    try {
        // Use cached data if available
        if (aclUsersCache.length === 0) {
            const apiBase = window.API_BASE || '/api/';
            const normalizedBase = apiBase.endsWith('/') ? apiBase : apiBase + '/';
            const url = new URL(normalizedBase + 'admin_api.php', window.location.origin);
            url.searchParams.append('action', 'list_users');
            
            const response = await fetch(url.toString(), {
                method: 'GET',
                headers: { 'Accept': 'application/json' },
                credentials: 'same-origin'
            });
            
            const data = await response.json();
            if (response.ok && data.data) {
                aclUsersCache = data.data.filter(u => u.is_active == 1 || u.is_active === '1');
            }
        }
        
        selectEl.innerHTML = '<option value="">Sélectionner un utilisateur...</option>';
        aclUsersCache.forEach(user => {
            const option = document.createElement('option');
            option.value = user.id;
            option.textContent = `${user.username} (${user.email})`;
            selectEl.appendChild(option);
        });
    } catch (error) {
        console.error('Failed to load users for ACL:', error);
        selectEl.innerHTML = '<option value="">Erreur de chargement</option>';
    }
}

/**
 * Populate roles select dropdown
 */
async function populateAclRolesSelect() {
    const selectEl = document.getElementById('aclSubjectIdentifierSelect');
    if (!selectEl) return;
    
    selectEl.innerHTML = '<option value="">Chargement...</option>';
    
    try {
        // Use cached data if available
        if (aclRolesCache.length === 0) {
            const apiBase = window.API_BASE || '/api/';
            const normalizedBase = apiBase.endsWith('/') ? apiBase : apiBase + '/';
            const url = new URL(normalizedBase + 'admin_api.php', window.location.origin);
            url.searchParams.append('action', 'list_roles');
            
            const response = await fetch(url.toString(), {
                method: 'GET',
                headers: { 'Accept': 'application/json' },
                credentials: 'same-origin'
            });
            
            const data = await response.json();
            if (response.ok && data.data) {
                aclRolesCache = data.data;
            }
        }
        
        selectEl.innerHTML = '<option value="">Sélectionner un rôle...</option>';
        aclRolesCache.forEach(role => {
            const option = document.createElement('option');
            option.value = role.name; // Use role name as identifier
            option.textContent = `${role.name} - ${role.description || ''}`;
            selectEl.appendChild(option);
        });
    } catch (error) {
        console.error('Failed to load roles for ACL:', error);
        selectEl.innerHTML = '<option value="">Erreur de chargement</option>';
    }
}

/**
 * Add new ACL entry
 */
async function addAclEntry() {
    // Support both #zoneId input and window.currentZoneId as fallback
    let zoneId = document.getElementById('zoneId')?.value;
    if (!zoneId && window.currentZoneId) {
        zoneId = window.currentZoneId;
    }
    if (!zoneId) {
        showError('Aucune zone sélectionnée');
        return;
    }
    
    const typeSelect = document.getElementById('aclSubjectType');
    const selectEl = document.getElementById('aclSubjectIdentifierSelect');
    const inputEl = document.getElementById('aclSubjectIdentifierInput');
    const permissionSelect = document.getElementById('aclPermission');
    
    const subjectType = typeSelect?.value;
    let subjectIdentifier = '';
    
    if (subjectType === 'role') {
        // Role uses the select dropdown
        subjectIdentifier = selectEl?.value;
    } else {
        // User and AD group use the text input
        subjectIdentifier = inputEl?.value?.trim();
    }
    
    const permission = permissionSelect?.value;
    
    // Validate inputs
    if (!subjectType) {
        showError('Veuillez sélectionner un type de sujet');
        return;
    }
    if (!subjectIdentifier) {
        showError('Veuillez spécifier un identifiant');
        return;
    }
    if (!permission) {
        showError('Veuillez sélectionner une permission');
        return;
    }
    
    // Normalize subject identifier based on type (username to lowercase for 'user')
    const normalizedIdentifier = normalizeAclSubjectIdentifier(subjectIdentifier, subjectType);
    
    try {
        const apiBase = window.API_BASE || '/api/';
        const normalizedBase = apiBase.endsWith('/') ? apiBase : apiBase + '/';
        const url = new URL(normalizedBase + 'admin_api.php', window.location.origin);
        url.searchParams.append('action', 'create_acl');
        
        const response = await fetch(url.toString(), {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json'
            },
            credentials: 'same-origin',
            body: JSON.stringify({
                zone_id: parseInt(zoneId, 10),
                subject_type: subjectType,
                subject_identifier: normalizedIdentifier,
                permission: permission
            })
        });
        
        const data = await response.json();
        
        if (!response.ok) {
            throw new Error(data.error || 'Failed to create ACL entry');
        }
        
        showSuccess('Entrée ACL créée avec succès');
        
        // Clear form and reload ACL list
        if (selectEl) selectEl.value = '';
        if (inputEl) inputEl.value = '';
        
        await loadAclForZone(zoneId);
    } catch (error) {
        console.error('Failed to add ACL entry:', error);
        showError('Erreur lors de la création de l\'entrée ACL: ' + error.message);
    }
}

/**
 * Delete ACL entry
 */
async function deleteAclEntry(aclId) {
    if (!confirm('Êtes-vous sûr de vouloir supprimer cette entrée ACL ?')) {
        return;
    }
    
    const zoneId = document.getElementById('zoneId')?.value;
    
    try {
        const apiBase = window.API_BASE || '/api/';
        const normalizedBase = apiBase.endsWith('/') ? apiBase : apiBase + '/';
        const url = new URL(normalizedBase + 'admin_api.php', window.location.origin);
        url.searchParams.append('action', 'delete_acl');
        url.searchParams.append('id', aclId);
        
        const response = await fetch(url.toString(), {
            method: 'POST',
            headers: {
                'Accept': 'application/json'
            },
            credentials: 'same-origin'
        });
        
        const data = await response.json();
        
        if (!response.ok) {
            throw new Error(data.error || 'Failed to delete ACL entry');
        }
        
        showSuccess('Entrée ACL supprimée avec succès');
        
        // Reload ACL list
        if (zoneId) {
            await loadAclForZone(zoneId);
        }
    } catch (error) {
        console.error('Failed to delete ACL entry:', error);
        showError('Erreur lors de la suppression de l\'entrée ACL: ' + error.message);
    }
}

// Expose ACL functions globally
window.loadAclForZone = loadAclForZone;
window.updateAclSubjectOptions = updateAclSubjectOptions;
window.addAclEntry = addAclEntry;
window.deleteAclEntry = deleteAclEntry;

// Expose functions globally for inline event handlers and external access
window.openZoneModal = openZoneModal;
window.populateZoneDomainSelect = populateZoneDomainSelect;
window.populateZoneFileCombobox = populateZoneFileCombobox;
window.onZoneDomainSelected = onZoneDomainSelected;
window.onZoneFileSelected = onZoneFileSelected;
window.resetZoneDomainSelection = resetZoneDomainSelection;
window.handleZoneRowClick = handleZoneRowClick;
window.deleteZone = deleteZone;
window.openCreateMasterModal = openCreateMasterModal;
window.openEditMasterModal = openEditMasterModal;
window.openCreateIncludeModal = openCreateIncludeModal;
window.closeIncludeCreateModal = closeIncludeCreateModal;
window.saveInclude = saveInclude;
window.renderZonesTable = renderZonesTable;
window.setZoneFileComboboxEnabled = setZoneFileComboboxEnabled;

// Initialize on DOM ready
if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', () => {
        initZonesPage();
        setupNameFilenameAutofill();
    });
} else {
    // DOM already loaded, init immediately
    initZonesPage();
    setupNameFilenameAutofill();
}
