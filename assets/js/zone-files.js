/**
 * Zone Files Management JavaScript - Paginated List View
 * Handles paginated table view for zone file management
 */

// Global in-flight promise guard to prevent duplicate loadZonesData calls
window._loadZonesDataPromise = null;

// Global in-flight promise guard to prevent duplicate initZonesWhenReady calls
window._initZonesWhenReadyPromise = null;

// Map to track in-flight fetchZonesForMaster requests by master_id
// Key: master_id (number), Value: Promise
const _fetchZonesForMasterCache = new Map();

/**
 * Wait for a global variable to be defined (async polling)
 * Used to wait for shared helpers that may load asynchronously
 * 
 * @param {string} name - Name of the global variable to wait for
 * @param {number} timeout - Maximum time to wait in milliseconds (default: 1200ms)
 * @param {number} interval - Polling interval in milliseconds (default: 80ms)
 * @returns {Promise<any>} - Resolves with the global variable when found, rejects on timeout
 */
async function waitForGlobal(name, timeout = 1200, interval = 80) {
    const startTime = Date.now();
    let completed = false;
    
    return new Promise((resolve, reject) => {
        const checkInterval = setInterval(() => {
            // Prevent race condition - ensure only one completion path
            if (completed) {
                return;
            }
            
            // Check if global variable exists
            if (typeof window[name] !== 'undefined') {
                completed = true;
                clearInterval(checkInterval);
                resolve(window[name]);
                return;
            }
            
            // Check if timeout expired
            const elapsed = Date.now() - startTime;
            if (elapsed >= timeout) {
                completed = true;
                clearInterval(checkInterval);
                reject(new Error(`Timeout waiting for global variable: ${name}`));
            }
        }, interval);
    });
}

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
 * Parse and validate a zone ID
 * @param {*} value - Value to parse as zone ID
 * @returns {number|null} - Parsed zone ID if valid, null otherwise
 * @example
 * parseValidZoneId('123') // Returns: 123
 * parseValidZoneId('abc') // Returns: null
 * parseValidZoneId(-1)    // Returns: null
 */
function parseValidZoneId(value) {
    if (value === null || value === undefined) return null;
    const parsed = parseInt(value, 10);
    return (!isNaN(parsed) && parsed > 0) ? parsed : null;
}

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

// isZoneInMasterTree moved to zone-combobox-shared.js and exported as window.isZoneInMasterTree

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
    // Use Array.isArray checks to ensure they are proper arrays
    if (!Array.isArray(window.ALL_ZONES)) window.ALL_ZONES = [];
    if (!Array.isArray(window.CURRENT_ZONE_LIST)) window.CURRENT_ZONE_LIST = [];
    if (!Array.isArray(window.ZONES_ALL)) window.ZONES_ALL = [];
    if (typeof window.allMasters === 'undefined' || !Array.isArray(window.allMasters)) window.allMasters = [];
    if (typeof window.allDomains === 'undefined' || !Array.isArray(window.allDomains)) window.allDomains = [];
}

/**
 * Get default domain ID for combobox population
 * Falls back through multiple sources to find a suitable domain ID
 * @returns {number|null} Domain ID or null if none available
 */
function getDefaultDomainId() {
    return window.ZONES_SELECTED_MASTER_ID || 
           window.selectedDomainId || 
           (Array.isArray(allMasters) && allMasters.length ? allMasters[0].id : null);
}

// Flag to track if UI components have been initialized (for idempotency)
// This flag is set once during page lifecycle and prevents redundant initialization
// from multiple code paths (fallback timers, recovery, etc.)
// After initial setup, individual functions (populateZoneDomainSelect, etc.) can still be called directly
let _uiComponentsInitialized = false;

/**
 * Defensive combobox initialization to ensure UI components are populated
 * Calls initialization functions with error handling to prevent cascading failures
 * This is idempotent and safe to call multiple times - uses a flag to prevent redundant work
 * 
 * Note: This is for initial page setup. After initialization, individual functions like
 * populateZoneDomainSelect() can still be called directly for updates (e.g., after saving).
 */
async function initializeComboboxes() {
    // Early exit if already initialized in this page lifecycle
    if (_uiComponentsInitialized) {
        console.debug('[initializeComboboxes] UI components already initialized, skipping');
        return;
    }
    
    console.debug('[initializeComboboxes] Initializing UI components...');
    
    try {
        if (typeof ensureZoneFilesInit === 'function') await ensureZoneFilesInit();
    } catch (e) { console.warn('[zone-files] ensureZoneFilesInit failed during post-init:', e); }
    
    try {
        if (typeof populateZoneDomainSelect === 'function') await populateZoneDomainSelect();
    } catch (e) { console.warn('[zone-files] populateZoneDomainSelect failed during post-init:', e); }
    
    try {
        if (typeof initZoneFileCombobox === 'function') await initZoneFileCombobox();
    } catch (e) { console.warn('[zone-files] initZoneFileCombobox failed during post-init:', e); }
    
    // If populateZoneListForDomain expects a domain id, try to call with a sensible default
    try {
        if (typeof window.populateZoneListForDomain === 'function') {
            const domainId = getDefaultDomainId();
            if (domainId) await window.populateZoneListForDomain(domainId);
        }
    } catch (e) { console.warn('[zone-files] populateZoneListForDomain failed during post-init:', e); }
    
    // Sync combobox instance if helper exposed
    try {
        if (typeof syncZoneFileComboboxInstance === 'function') syncZoneFileComboboxInstance();
    } catch (e) { console.debug('[zone-files] syncZoneFileComboboxInstance failed:', e); }
    
    // Mark as initialized to prevent redundant calls
    _uiComponentsInitialized = true;
    console.debug('[initializeComboboxes] UI components initialization complete');
}

/**
 * Sync zone file combobox instance state after CURRENT_ZONE_LIST update
 * 
 * Calls refresh() on the combobox instance to update internal state without showing the dropdown.
 * The refresh() method internally calls showZones(zones, false, false), where:
 *   - showList=false prevents the dropdown from auto-displaying
 *   - updateCache=false prevents overwriting CURRENT_ZONE_LIST with derived zones
 * 
 * This prevents race conditions where refresh could overwrite the carefully constructed
 * domain-specific cache after it has been populated by populateZoneFileCombobox.
 * 
 * @see initServerSearchCombobox for the refresh() method implementation
 */
function syncZoneFileComboboxInstance() {
    if (!window.ZONE_FILE_COMBOBOX_INSTANCE) {
        console.debug('[syncZoneFileComboboxInstance] Combobox instance not available (not initialized yet)');
        return;
    }
    
    if (typeof window.ZONE_FILE_COMBOBOX_INSTANCE.refresh !== 'function') {
        console.warn('[syncZoneFileComboboxInstance] Combobox instance does not have a refresh method');
        return;
    }
    
    try {
        window.ZONE_FILE_COMBOBOX_INSTANCE.refresh();
        console.debug('[syncZoneFileComboboxInstance] Successfully synced combobox state');
    } catch (error) {
        console.debug('[syncZoneFileComboboxInstance] Error calling refresh (non-fatal):', error);
    }
}

// Constants for race-resistant hiding delays
// These delays are chosen to catch async operations that might occur after domain selection:
// - 50ms: catches immediate async callbacks (e.g., from refresh())
// - 150ms: catches slightly delayed operations (e.g., from setTimeout in other code)
// This setTimeout-based approach is necessary because we cannot control when external
// async operations (like combobox refresh) might try to show the list, and we need to
// ensure the list remains hidden regardless of these operations.
const ZONE_LIST_HIDE_RETRY_DELAY_SHORT = 50;  // ms
const ZONE_LIST_HIDE_RETRY_DELAY_LONG = 150;  // ms

/**
 * Ensure a value is a valid array, returning fallback if not
 * Note: Empty arrays are considered valid and will be returned as-is
 * @param {*} value - Value to check
 * @param {Array} fallback - Fallback value if not a valid array
 * @returns {Array} - Valid array (may be empty)
 */
function ensureValidArray(value, fallback = []) {
    return Array.isArray(value) ? value : fallback;
}

/**
 * Race-resistant hiding of zone file combobox list
 * 
 * Forcefully hides the #zone-file-list dropdown immediately and after delays
 * to catch any async operations that might try to show it (e.g., from refresh).
 * 
 * This prevents the UX "flash" where the list briefly appears after domain selection
 * due to race conditions with async refresh operations.
 * 
 * Note: This uses setTimeout-based retries because we cannot control when external
 * async operations (like combobox refresh) might try to show the list. Alternative
 * approaches like Promise.all or event-based coordination are not viable since we
 * don't have access to the Promise chain of the external operations.
 */
function forceHideZoneFileList() {
    const listEl = document.getElementById('zone-file-list');
    if (!listEl) return;
    
    // Helper to hide the list (sets display, aria-hidden, and removes from tab order for accessibility)
    const hideList = (source = '') => {
        const wasVisible = listEl.style.display !== 'none';
        listEl.style.display = 'none';
        listEl.setAttribute('aria-hidden', 'true');
        listEl.setAttribute('tabindex', '-1');  // Remove from tab order for accessibility
        if (source) {
            const stateMsg = wasVisible ? ' (was visible, now hidden)' : ' (already hidden)';
            console.debug(`[forceHideZoneFileList] ${source}${stateMsg}`);
        }
    };
    
    // Hide immediately
    hideList('Applied initial hiding');
    
    // Hide again after short delays to catch any async operations
    setTimeout(() => hideList(`Re-applied hiding after ${ZONE_LIST_HIDE_RETRY_DELAY_SHORT}ms`), ZONE_LIST_HIDE_RETRY_DELAY_SHORT);
    setTimeout(() => hideList(`Re-applied hiding after ${ZONE_LIST_HIDE_RETRY_DELAY_LONG}ms`), ZONE_LIST_HIDE_RETRY_DELAY_LONG);
}

/**
 * Centralized helper to update the zone-file-input field display
 * Prevents concurrent writes and ensures consistent formatting
 * 
 * @param {Object|string} zoneOrText - Zone object with name/filename/file_type, or plain text string
 */
function setZoneFileDisplay(zoneOrText) {
    const input = document.getElementById('zone-file-input');
    if (!input) {
        console.warn('[setZoneFileDisplay] zone-file-input element not found');
        return;
    }
    
    // Prevent concurrent updates by checking if an update is in progress
    if (window.__ZONE_FILE_DISPLAY_UPDATING) {
        console.debug('[setZoneFileDisplay] Update already in progress, skipping');
        return;
    }
    
    try {
        window.__ZONE_FILE_DISPLAY_UPDATING = true;
        
        if (typeof zoneOrText === 'string') {
            // Plain text: set directly
            input.value = zoneOrText;
            console.debug('[setZoneFileDisplay] Set input to plain text:', zoneOrText);
        } else if (zoneOrText && typeof zoneOrText === 'object') {
            // Zone object: format as "name (filename)"
            const name = zoneOrText.name || zoneOrText.filename || 'Unknown';
            const filename = zoneOrText.filename || zoneOrText.file_type || '';
            const displayText = `${name} (${filename})`;
            input.value = displayText;
            console.debug('[setZoneFileDisplay] Set input to zone:', displayText);
        } else {
            // Fallback: clear input
            input.value = '';
            input.placeholder = 'Rechercher une zone...';
            console.debug('[setZoneFileDisplay] Cleared input (fallback)');
        }
    } finally {
        // Clear the flag after a short delay to allow the update to complete
        setTimeout(() => {
            window.__ZONE_FILE_DISPLAY_UPDATING = false;
        }, 10);
    }
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
    
    // Fallback: fetch from API and merge into cache
    if (!zone) {
        try {
            const result = await zoneApiCall('get_zone', { params: { id: zoneIdNum } });
            zone = result && result.data ? result.data : null;
            
            // Merge fetched zone into caches for future lookups
            if (zone) {
                mergeZonesIntoCache([zone]);
            }
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
        
        // Fallback: fetch from API and merge into cache
        if (!zone) {
            try {
                const result = await zoneApiCall('get_zone', { params: { id: currentZoneId } });
                zone = result && result.data ? result.data : null;
                
                // Merge fetched zone into caches for future lookups
                if (zone) {
                    mergeZonesIntoCache([zone]);
                }
            } catch (e) {
                console.warn('[getTopMasterId] Failed to fetch zone:', currentZoneId, e);
                return null;
            }
        }
        
        if (!zone) return null;
        
        // Check if this is a master zone (check file_type first, then parent_id as fallback)
        if (zone.file_type === 'master') {
            return currentZoneId;
        }
        
        // Fallback: check if no parent (for cases where file_type might not be set correctly)
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
    
    // Check if there's already an in-flight request for this master_id
    const cachedPromise = _fetchZonesForMasterCache.get(masterIdNum);
    if (cachedPromise) {
        console.debug('[fetchZonesForMaster] Request already in flight for master', masterIdNum, '- returning existing promise');
        return cachedPromise;
    }
    
    // Create and store the request promise
    const requestPromise = (async () => {
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
        } finally {
            // Remove from cache after completion to allow future requests
            _fetchZonesForMasterCache.delete(masterIdNum);
        }
    })();
    
    // Store the promise in the cache
    _fetchZonesForMasterCache.set(masterIdNum, requestPromise);
    
    return requestPromise;
}

/**
 * Populate zone combobox for a specific domain
 * Updates CURRENT_ZONE_LIST but does NOT open the list or auto-select a zone
 * Uses shared helper populateZoneListForDomain from zone-combobox.js with defensive fallback
 * 
 * DEFENSIVE: Always ensures CURRENT_ZONE_LIST is a valid array
 * FALLBACKS: Uses multiple strategies to populate the list if primary call fails or returns empty
 */
async function populateZoneComboboxForDomain(masterId) {
    try {
        console.debug('[populateZoneComboboxForDomain] Called with masterId:', masterId);
        
        // Normalize arrays before any operations
        if (!Array.isArray(window.ALL_ZONES)) {
            window.ALL_ZONES = [];
        }
        if (!Array.isArray(window.CURRENT_ZONE_LIST)) {
            window.CURRENT_ZONE_LIST = [];
        }
        
        let orderedZones = [];
        
        // Defensive: Try shared helper first (preferred)
        if (typeof window.populateZoneListForDomain === 'function') {
            console.debug('[populateZoneComboboxForDomain] Using shared helper populateZoneListForDomain');
            try {
                const result = await window.populateZoneListForDomain(masterId);
                orderedZones = Array.isArray(result) ? result : [];
                console.debug('[populateZoneComboboxForDomain] Shared helper returned', orderedZones.length, 'zones');
                
                // Update CURRENT_ZONE_LIST with ordered zones from helper
                if (orderedZones.length > 0) {
                    window.CURRENT_ZONE_LIST = orderedZones;
                    
                    // Merge into ALL_ZONES and ZONES_ALL caches using shared helper (with deduplication)
                    mergeZonesIntoCache(orderedZones);
                    console.debug('[populateZoneComboboxForDomain] Merged zones into ALL_ZONES and ZONES_ALL');
                    
                    // Sync combobox instance state with updated CURRENT_ZONE_LIST
                    if (typeof syncZoneFileComboboxInstance === 'function') {
                        try {
                            syncZoneFileComboboxInstance();
                            console.debug('[populateZoneComboboxForDomain] Synced combobox instance');
                        } catch (syncError) {
                            console.warn('[populateZoneComboboxForDomain] syncZoneFileComboboxInstance failed:', syncError);
                        }
                    }
                    
                    // DO NOT populate or show the combobox list - user must click/focus to see it
                    console.debug('[populateZoneComboboxForDomain] Updated CURRENT_ZONE_LIST, list will populate on user interaction');
                    return;
                } else {
                    console.warn('[populateZoneComboboxForDomain] Shared helper returned empty, trying fallback');
                }
            } catch (e) {
                console.warn('[populateZoneComboboxForDomain] Shared helper failed, falling back to direct API:', e);
            }
        } else {
            console.debug('[populateZoneComboboxForDomain] Shared helper not available, using fallback');
        }
        
        // Fallback: Use direct API call if shared helper unavailable or failed
        let result;
        let zones = [];
        
        try {
            result = await zoneApiCall('list_zone_files', { params: { domain_id: masterId } });
            zones = Array.isArray(result.data) ? result.data : [];
            console.debug('[populateZoneComboboxForDomain] list_zone_files by domain_id returned', zones.length, 'zones');
        } catch (e) {
            console.warn('[populateZoneComboboxForDomain] list_zone_files failed, falling back:', e);
            // Fallback to old API (list_zones_by_domain) if list_zone_files is not available
            try {
                result = await apiCall('list_zones_by_domain', { zone_id: masterId });
                zones = Array.isArray(result.data) ? result.data : [];
                console.debug('[populateZoneComboboxForDomain] list_zones_by_domain (zone_id) returned', zones.length, 'zones');
            } catch (e2) {
                try {
                    result = await apiCall('list_zones_by_domain', { domain_id: masterId });
                    zones = Array.isArray(result.data) ? result.data : [];
                    console.debug('[populateZoneComboboxForDomain] list_zones_by_domain (domain_id) returned', zones.length, 'zones');
                } catch (e3) {
                    console.warn('[populateZoneComboboxForDomain] All domain_id fallbacks failed:', e3);
                }
            }
        }
        
        // Filter zones to only include master and include types
        zones = zones.filter(z => {
            const fileType = (z.file_type || '').toLowerCase().trim();
            return fileType === 'master' || fileType === 'include';
        });
        
        // Find the master zone from the zones array
        const masterZone = zones.find(z => 
            (z.file_type || '').toLowerCase().trim() === 'master' && 
            parseInt(z.id, 10) === parseInt(masterId, 10)
        );
        
        // Use shared helper for consistent ordering: master first, then includes sorted A-Z
        const masterIdToUse = masterZone ? masterZone.id : masterId;
        
        // Always ensure makeOrderedZoneList returns an array
        if (typeof window.makeOrderedZoneList === 'function') {
            const result = window.makeOrderedZoneList(zones, masterIdToUse);
            orderedZones = Array.isArray(result) ? result : [];
            console.debug('[populateZoneComboboxForDomain] makeOrderedZoneList returned', orderedZones.length, 'zones');
        } else {
            console.warn('[populateZoneComboboxForDomain] makeOrderedZoneList not available, using unordered zones');
            orderedZones = zones;
        }
        
        // Update CURRENT_ZONE_LIST with ordered zones
        // DEFENSIVE: Only update if we have zones to avoid clearing cache unnecessarily
        if (orderedZones.length > 0) {
            window.CURRENT_ZONE_LIST = orderedZones;
            console.debug('[populateZoneComboboxForDomain] Updated CURRENT_ZONE_LIST with', orderedZones.length, 'zones');
            
            // Merge into ALL_ZONES and ZONES_ALL caches using shared helper (with deduplication)
            mergeZonesIntoCache(orderedZones);
            console.debug('[populateZoneComboboxForDomain] Merged zones into ALL_ZONES and ZONES_ALL');
            
            // Sync combobox instance state with updated CURRENT_ZONE_LIST
            if (typeof syncZoneFileComboboxInstance === 'function') {
                try {
                    syncZoneFileComboboxInstance();
                    console.debug('[populateZoneComboboxForDomain] Synced combobox instance');
                } catch (syncError) {
                    console.warn('[populateZoneComboboxForDomain] syncZoneFileComboboxInstance failed:', syncError);
                }
            }
        } else {
            console.warn('[populateZoneComboboxForDomain] No zones returned, preserving existing CURRENT_ZONE_LIST');
        }
        
        // DO NOT populate or show the combobox list - user must click/focus to see it
        console.debug('[populateZoneComboboxForDomain] Updated CURRENT_ZONE_LIST, list will populate on user interaction');
        
    } catch (error) {
        console.error('[populateZoneComboboxForDomain] Critical error:', error);
        // DEFENSIVE: Don't clear CURRENT_ZONE_LIST on error, preserve what we have
        if (!Array.isArray(window.CURRENT_ZONE_LIST) || window.CURRENT_ZONE_LIST.length === 0) {
            window.CURRENT_ZONE_LIST = [];
        }
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
            
            // Update edit domain button to hide it
            updateEditDomainButton(null);
            return;
        }

        // Calculate master ID based on zone type
        // For master: use zone.id
        // For include: ALWAYS use getTopMasterId to traverse the complete parent chain
        // This ensures we get the final master, not an intermediate include
        let masterId;
        if (zone.file_type === 'master') {
            masterId = zone.id;
        } else {
            // For includes: ALWAYS traverse to the top master to handle nested includes correctly
            // Even if master_id/parent_zone_id/parent_id fields exist, they might point to 
            // an intermediate include rather than the final master
            try {
                masterId = await getTopMasterId(zone.id);
                console.debug('[setDomainForZone] Traversed to top master using getTopMasterId:', masterId);
                if (!masterId) {
                    console.error('setDomainForZone: Cannot determine master ID for include zone:', zone.id);
                    // For includes, we cannot use zone.id as fallback since it would be wrong
                    // Clear the state and disable the edit button
                    updateEditDomainButton(null);
                    return;
                }
            } catch (fallbackError) {
                console.error('setDomainForZone: getTopMasterId failed for include zone:', zone.id, fallbackError);
                // For includes, we cannot use zone.id as fallback since it would be wrong
                updateEditDomainButton(null);
                return;
            }
        }

        // Calculate domain based on zone type
        let domainName = '';
        if (zone.file_type === 'master') {
            domainName = zone.domain || '';
        } else {
            // For includes: try to get domain from master zone
            domainName = zone.parent_domain || '';
            
            // If parent_domain is empty and we have a masterId, fetch domain from master
            if (!domainName && masterId) {
                try {
                    // First, try to get master zone from cache
                    // Use same order as getTopMasterId for consistency
                    let masterZone = null;
                    const cachesToCheck = [
                        window.CURRENT_ZONE_LIST,
                        window.ALL_ZONES,
                        window.ZONES_ALL,
                        (typeof allMasters !== 'undefined' && allMasters) ? allMasters : []
                    ];
                    const masterIdStr = String(masterId);
                    for (const cache of cachesToCheck) {
                        if (Array.isArray(cache) && cache.length > 0) {
                            masterZone = cache.find(z => String(z.id) === masterIdStr);
                            if (masterZone) break;
                        }
                    }
                    
                    // If not in cache, fetch from API
                    if (!masterZone) {
                        try {
                            const masterRes = await zoneApiCall('get_zone', { params: { id: masterId } });
                            masterZone = masterRes && masterRes.data ? masterRes.data : null;
                        } catch (apiError) {
                            console.warn('[setDomainForZone] Failed to fetch master zone:', apiError);
                        }
                    }
                    
                    // Use master's domain if available
                    if (masterZone && masterZone.domain) {
                        domainName = masterZone.domain;
                        console.debug('[setDomainForZone] Using domain from master zone:', domainName);
                    } else {
                        // Final fallback: call get_domain_for_zone endpoint
                        const fallbackRes = await apiCall('get_domain_for_zone', { zone_id: zoneId });
                        if (fallbackRes && fallbackRes.success && fallbackRes.data && fallbackRes.data.domain) {
                            domainName = fallbackRes.data.domain;
                        }
                    }
                } catch (fallbackError) {
                    console.warn('[setDomainForZone] Failed to resolve domain from master zone or API fallback:', fallbackError);
                }
            }
        }

        const domainInput = document.getElementById('zone-domain-input');
        if (domainInput) domainInput.value = domainName;
        
        // Store the master ID (not the selected zone ID)
        const hiddenInput = document.getElementById('zone-master-id');
        if (hiddenInput) hiddenInput.value = masterId || '';
        
        // Update global state with master ID
        window.selectedDomainId = masterId;
        window.ZONES_SELECTED_MASTER_ID = masterId;

        // Update zone file input text display
        const zoneFileInput = document.getElementById('zone-file-input');
        if (zoneFileInput) {
            zoneFileInput.value = `${zone.name} (${zone.file_type})`;
        }
        
        // Store the selected zone ID (include or master) in zone-file-id
        const zoneFileIdInput = document.getElementById('zone-file-id');
        if (zoneFileIdInput) {
            zoneFileIdInput.value = zoneId || '';
        }
        
        // Update global state with selected zone ID
        window.selectedZoneId = zoneId;
        window.ZONES_SELECTED_ZONEFILE_ID = zoneId;

        // ALWAYS call populateZoneComboboxForDomain with masterId
        if (typeof populateZoneComboboxForDomain === 'function') {
            try { 
                await populateZoneComboboxForDomain(masterId); 
            } catch (e) {
                console.warn('populateZoneComboboxForDomain failed:', e);
                // Fallback: filter ALL_ZONES by domain if available and apply ordering
                if (Array.isArray(window.ALL_ZONES)) {
                    let filteredZones;
                    if (domainName) {
                        filteredZones = window.ALL_ZONES.filter(z => (z.domain || '') === domainName);
                    } else {
                        filteredZones = window.ALL_ZONES.filter(z => z.id === masterId);
                    }
                    // Apply consistent ordering using shared helper
                    window.CURRENT_ZONE_LIST = window.makeOrderedZoneList(filteredZones, masterId);
                    
                    // Sync combobox instance state with updated CURRENT_ZONE_LIST
                    syncZoneFileComboboxInstance();
                }
            }
        }
        
        // Enable zone file combobox after population
        if (typeof setZoneFileComboboxEnabled === 'function') {
            setZoneFileComboboxEnabled(true);
        }
        
        // Update edit domain button with master ID
        updateEditDomainButton(masterId);

        if (typeof updateCreateBtnState === 'function') updateCreateBtnState();
    } catch (e) {
        console.error('setDomainForZone error', e);
    }
}

/**
 * Update "Modifier le domaine" button visibility and state
 * Extracted helper to ensure consistency between onZoneDomainSelected and onZoneFileSelected flows
 * @param {number|null} masterId - Master zone ID, or null to hide the button
 */
function updateEditDomainButton(masterId) {
    const btnEditDomain = document.getElementById('btn-edit-domain');
    if (!btnEditDomain) return;
    
    if (masterId) {
        btnEditDomain.style.display = 'inline-block';
        btnEditDomain.disabled = false;
        console.debug('[updateEditDomainButton] Enabled button for masterId:', masterId);
    } else {
        btnEditDomain.style.display = 'none';
        btnEditDomain.disabled = true;
        console.debug('[updateEditDomainButton] Disabled button (no masterId)');
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

// serverSearchZones moved to zone-combobox-shared.js and exported as window.serverSearchZones

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

// initServerSearchCombobox moved to zone-combobox-shared.js and exported as window.initServerSearchCombobox

/**
 * Merge zones into global caches (ALL_ZONES, ZONES_ALL)
 * Used after search or fetch to ensure parent resolution and master lookup work properly
 * Note: Does not modify CURRENT_ZONE_LIST as that is domain-specific and managed by populateZoneComboboxForDomain
 * @param {Array} zones - Array of zone objects to merge into caches
 */
function mergeZonesIntoCache(zones) {
    if (!Array.isArray(zones) || zones.length === 0) {
        return;
    }
    
    // Ensure caches are initialized
    if (!Array.isArray(window.ALL_ZONES)) window.ALL_ZONES = [];
    if (!Array.isArray(window.ZONES_ALL)) window.ZONES_ALL = [];
    
    // Create sets of existing IDs for O(1) lookup
    const allZonesIds = new Set(window.ALL_ZONES.map(z => parseInt(z.id, 10)));
    const zonesAllIds = new Set(window.ZONES_ALL.map(z => parseInt(z.id, 10)));
    
    // Merge zones into caches (deduplicated)
    zones.forEach(zone => {
        const zoneId = parseInt(zone.id, 10);
        
        // Add to ALL_ZONES if not already present
        if (!allZonesIds.has(zoneId)) {
            window.ALL_ZONES.push(zone);
            allZonesIds.add(zoneId);
        }
        
        // Add to ZONES_ALL if not already present
        if (!zonesAllIds.has(zoneId)) {
            window.ZONES_ALL.push(zone);
            zonesAllIds.add(zoneId);
        }
    });
    
    console.debug('[mergeZonesIntoCache] Merged', zones.length, 'zones into ALL_ZONES and ZONES_ALL');
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
                const results = await serverSearchZones(val, { limit: 1000 });
                console.debug('[attachZoneSearchInput] Server search returned', results.length, 'results');
                
                // Merge search results into caches for proper parent resolution and master lookup
                // This ensures renderZonesTable can resolve parent names and setDomainForZone can find masters
                mergeZonesIntoCache(results);
                
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
    
    console.debug('[attachZoneSearchInput] Search handler attached to #searchInput with server-first strategy');
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
    
    console.debug('[attachFilterStatusHandler] Filter status handler attached to #filterStatus');
}

/**
 * Attach change handler to #perPageSelect select
 * Updates the global perPage variable and re-renders the table
 */
function attachPerPageHandler() {
    const select = document.getElementById('perPageSelect');
    if (!select) {
        console.debug('[attachPerPageHandler] #perPageSelect not found on this page');
        return;
    }
    
    // Check if already bound to prevent duplicate handlers (using data attribute for consistency)
    if (select.dataset.perPageHandlerBound === 'true') {
        return;
    }
    select.dataset.perPageHandlerBound = 'true';
    
    select.addEventListener('change', async function(e) {
        // Update global perPage variable with validation
        const newPerPage = parseInt(e.target.value, 10);
        
        // Validate parsed value is a positive number
        if (isNaN(newPerPage) || newPerPage <= 0) {
            console.error('[attachPerPageHandler] Invalid perPage value:', e.target.value);
            return;
        }
        
        perPage = newPerPage;
        
        // Reset to page 1 when changing perPage
        currentPage = 1;
        
        // Re-render the table with new pagination
        await renderZonesTable();
        
        console.debug('[attachPerPageHandler] perPage changed to:', perPage);
    });
    
    console.debug('[attachPerPageHandler] perPage handler attached to #perPageSelect');
}

// Expose search functions globally
window.buildApiPath = buildApiPath;
window.attachZoneSearchInput = attachZoneSearchInput;
// serverSearchZones, initServerSearchCombobox, isZoneInMasterTree are now in zone-combobox-shared.js
window.clientFilterZones = clientFilterZones;
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
        
        // Attach perPage handler for pagination
        attachPerPageHandler();
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
const API_STANDARD_PER_PAGE_LIMIT = 100; // API caps per_page at 100 for standard requests
const COMBOBOX_BLUR_DELAY = 200; // Delay in ms before hiding combobox list on blur

// API base URL
const API_BASE = window.API_BASE || '/api/zone_api.php';

/**
 * Initialize zones page - load domains and zones
 */
/**
 * Check if the Zones page elements are present in the DOM
 * @returns {boolean} True if zones page elements exist
 */
function shouldInitZonesPage() {
    const zonesTable = document.getElementById('zonesTable');
    const zoneDomainSelect = document.getElementById('zone-domain-select');
    
    if (!zonesTable && !zoneDomainSelect) {
        console.debug('[shouldInitZonesPage] Zones page elements not found, skipping init');
        return false;
    }
    
    return true;
}

async function initZonesPage() {
    // Guard: Only initialize if zones page elements exist
    if (!shouldInitZonesPage()) {
        console.debug('[initZonesPage] Not on zones page, skipping initialization');
        return;
    }
    
    // Initialize business helpers and cache before any combobox initialization
    ensureZoneFilesInit();
    await ensureZonesCache();
    await populateZoneDomainSelect();
    await initZoneFileCombobox();
    await loadZonesData();
    renderZonesTable();
}

/**
 * Initialize zones page when ready, waiting for shared helpers
 * 
 * Waits briefly for initServerSearchCombobox to be available before initializing.
 * This prevents race conditions when zone-combobox-shared.js loads slightly after zone-files.js.
 * Falls back gracefully if helper is not found within timeout period.
 * 
 * This function is idempotent and can be called multiple times safely.
 * Uses a shared promise to deduplicate concurrent initialization calls.
 */
async function initZonesWhenReady() {
    // Initialize attempt tracking flags if not present
    if (typeof window._zonesInitAttempts === 'undefined') {
        window._zonesInitAttempts = 0;
    }
    
    // Idempotency guard: only initialize once successfully
    if (window._zonesInitRun) {
        console.debug('[initZonesWhenReady] Already initialized successfully, skipping');
        return;
    }
    
    // Deduplication guard: return existing promise if initialization is in progress
    if (window._initZonesWhenReadyPromise) {
        console.debug('[initZonesWhenReady] Initialization already in progress, returning existing promise');
        return window._initZonesWhenReadyPromise;
    }
    
    // Guard: Maximum retry attempts (3 total attempts)
    const MAX_ATTEMPTS = 3;
    if (window._zonesInitAttempts >= MAX_ATTEMPTS) {
        console.debug('[initZonesWhenReady] Maximum retry attempts reached, aborting');
        return;
    }
    
    // Create and store the initialization promise
    window._initZonesWhenReadyPromise = (async () => {
        // Increment attempt counter
        window._zonesInitAttempts++;
        console.debug(`[initZonesWhenReady] Starting initialization attempt ${window._zonesInitAttempts}/${MAX_ATTEMPTS}`);
        
        // Helper to safely call setupNameFilenameAutofill
        const callSetupAutofill = () => {
            try {
                setupNameFilenameAutofill();
            } catch (err) {
                console.debug('[initZonesWhenReady] setupNameFilenameAutofill not available or failed:', err);
            }
        };
        
        try {
            // Wait for shared helper to be available (with timeout)
            try {
                await waitForGlobal('initServerSearchCombobox', 1200, 80);
                console.debug('[initZonesWhenReady] initServerSearchCombobox found — continuing init');
            } catch (err) {
                console.debug('[initZonesWhenReady] initServerSearchCombobox not found after wait — continuing with fallback');
            }
            
            // Enhanced Zones page detection (fallback URL/DOM if shouldInitZonesPage returns false)
            let shouldInit = true;
            if (typeof shouldInitZonesPage === 'function') {
                try {
                    shouldInit = !!shouldInitZonesPage();
                } catch (e) {
                    console.debug('[initZonesWhenReady] shouldInitZonesPage threw:', e);
                    shouldInit = false;
                }
            }
            
            if (!shouldInit) {
                // Fallback heuristics: URL pathname matches zone-files page OR multiple zone-specific DOM markers present
                const urlLooksLikeZones = /\/zone-files(?:\.php)?(?:$|[/?#])/i.test(window.location.pathname);
                const zoneFileInput = !!document.getElementById('zone-file-input');
                const zonesTableBody = !!document.getElementById('zones-table-body');
                const domLooksLikeZones = zoneFileInput && zonesTableBody;
                if (urlLooksLikeZones || domLooksLikeZones) {
                    console.debug('[initZonesWhenReady] shouldInitZonesPage returned false but URL/DOM indicate Zones page — forcing init');
                    shouldInit = true;
                } else {
                    console.debug('[initZonesWhenReady] shouldInitZonesPage false and URL/DOM do not indicate Zones page — skipping init');
                }
            }
            
            if (!shouldInit) {
                // preserve prior behavior
                callSetupAutofill();
                return;
            }
            
            // Ensure cache is initialized before any operations
            initZonesCache();
            
            // Initialize zones page
            await initZonesPage();
            
            // Defensive rendering: ensure UI is updated after initialization
            if (typeof renderZonesTable === 'function') {
                try {
                    renderZonesTable();
                } catch (renderErr) {
                    console.debug('[initZonesWhenReady] renderZonesTable failed after init:', renderErr);
                }
            }
            
            // Sync combobox state if available
            if (typeof syncZoneFileComboboxInstance === 'function') {
                try {
                    syncZoneFileComboboxInstance();
                } catch (syncErr) {
                    console.debug('[initZonesWhenReady] syncZoneFileComboboxInstance failed:', syncErr);
                }
            }
            
            // Verify that data was actually loaded
            if (!window.ZONES_ALL || window.ZONES_ALL.length === 0) {
                console.debug('[initZonesWhenReady] ZONES_ALL is empty after init, will use loadZonesData for recovery');
                
                // Use loadZonesData which already has deduplication
                await loadZonesData();
                
                // Re-render with new data
                try {
                    if (typeof renderZonesTable === 'function') {
                        renderZonesTable();
                    }
                } catch (renderErr) {
                    console.debug('[initZonesWhenReady] renderZonesTable failed after loadZonesData:', renderErr);
                }
                
                // Sync comboboxes after successful recovery
                try {
                    await initializeComboboxes();
                } catch (comboErr) {
                    console.debug('[initZonesWhenReady] initializeComboboxes failed after recovery:', comboErr);
                }
            }
            
            // Mark successful initialization only if we have data and rendered
            if (window.ZONES_ALL && window.ZONES_ALL.length > 0) {
                window._zonesInitRun = true;
                console.debug('[initZonesWhenReady] Zones page initialized successfully with', window.ZONES_ALL.length, 'zones');
                
                // Defensive combobox initialization to ensure UI components are populated
                try {
                    await initializeComboboxes();
                } catch (comboErr) {
                    console.debug('[initZonesWhenReady] Final initializeComboboxes failed:', comboErr);
                }
            } else {
                console.debug('[initZonesWhenReady] Initialization completed but no zones loaded (non-fatal)');
            }
            
        } catch (err) {
            console.debug('[initZonesWhenReady] Failed to initialize zones page (attempt', window._zonesInitAttempts, '):', err);
            
            // Defensive recovery: try minimal functions to populate page
            console.debug('[initZonesWhenReady] Attempting defensive recovery...');
            try {
                await ensureZonesCache();
                
                // If cache is still empty after ensureZonesCache, force loadZonesData
                if (!window.ZONES_ALL || window.ZONES_ALL.length === 0) {
                    await loadZonesData();
                }
                
                await populateZoneDomainSelect();
                await initZoneFileCombobox();
                
                // Defensive render
                if (typeof renderZonesTable === 'function') {
                    renderZonesTable();
                }
                
                // Check if recovery succeeded
                if (window.ZONES_ALL && window.ZONES_ALL.length > 0) {
                    window._zonesInitRun = true;
                    console.debug('[initZonesWhenReady] Defensive recovery succeeded with', window.ZONES_ALL.length, 'zones');
                } else {
                    console.debug('[initZonesWhenReady] Defensive recovery completed but no zones loaded (non-fatal)');
                }
            } catch (recoveryErr) {
                console.debug('[initZonesWhenReady] Defensive recovery also failed (non-fatal):', recoveryErr);
            }
        } finally {
            // Always try to setup autofill (safe even if not on zones page)
            callSetupAutofill();
            
            // Clear the promise guard after completion
            window._initZonesWhenReadyPromise = null;
        }
    })();
    
    return window._initZonesWhenReadyPromise;
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
    
    if (masterZoneId) {
        if (btnNewZoneFile) {
            btnNewZoneFile.disabled = false;
        }
        updateEditDomainButton(masterZoneId);
        
        // Populate zone file combobox for the selected domain WITHOUT auto-selection
        // This keeps the visible input empty and ready for search (aligned with problem statement)
        await populateZoneFileCombobox(masterZoneId, null, false);
        
        // Race-resistant hiding: ensure zone file list is hidden after domain selection
        forceHideZoneFileList();
        
        // Enable zone file combobox after population using shared helper
        if (typeof window.setZoneComboboxEnabledShared === 'function') {
            window.setZoneComboboxEnabledShared('zone-file-input', 'zone-file-id', true);
        } else if (typeof setZoneFileComboboxEnabled === 'function') {
            setZoneFileComboboxEnabled(true);
        }
    } else {
        if (btnNewZoneFile) {
            btnNewZoneFile.disabled = true;
        }
        updateEditDomainButton(null);
        
        // Disable zone file combobox when no domain selected using shared helper
        if (typeof window.setZoneComboboxEnabledShared === 'function') {
            window.setZoneComboboxEnabledShared('zone-file-input', 'zone-file-id', false);
        } else if (typeof setZoneFileComboboxEnabled === 'function') {
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
    // Guard: Only initialize if zone file combobox elements exist
    const inputEl = document.getElementById('zone-file-input');
    const listEl = document.getElementById('zone-file-list');
    const hiddenEl = document.getElementById('zone-file-id');
    
    if (!inputEl || !listEl || !hiddenEl) {
        console.debug('[initZoneFileCombobox] Zone file combobox elements not found, skipping init');
        return;
    }
    
    await ensureZonesCache();
    
    inputEl.readOnly = false;
    inputEl.placeholder = 'Rechercher une zone...';
    
    // Start with combobox disabled if no domain selected
    if (!window.ZONES_SELECTED_MASTER_ID) {
        setZoneFileComboboxEnabled(false);
    }
    
    // Use the unified initServerSearchCombobox helper
    // Custom onSelectItem to update state and call business logic handler
    const comboboxInstance = initServerSearchCombobox({
        inputEl: inputEl,
        listEl: listEl,
        hiddenEl: hiddenEl,
        file_type: '', // No filter, show all types (master + include)
        onSelectItem: async (zone) => {
            try {
                if (!zone) return;
                
                // Update global state variables
                // DO NOT update window.CURRENT_ZONE_LIST - preserve the full zone list for the domain
                window.ZONES_SELECTED_ZONEFILE_ID = zone.id;
                window.selectedZoneId = zone.id;
                
                // Update hidden input
                if (hiddenEl) {
                    hiddenEl.value = zone.id;
                }
                
                // Call existing onZoneFileSelected handler for business logic
                if (typeof onZoneFileSelected === 'function') {
                    await onZoneFileSelected(zone.id);
                }
            } finally {
                // Centralized display update to ensure consistent final display
                // This runs after all other updates to prevent race conditions
                if (zone) {
                    setZoneFileDisplay(zone);
                }
                
                // Hide the list after selection to prevent flickers
                forceHideZoneFileList();
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
                const result = window.makeOrderedZoneList(allZones, masterId);
                const isValidResult = Array.isArray(result);
                orderedZones = isValidResult ? result : allZones;
                if (isValidResult) {
                    console.debug('[populateZoneFileCombobox] Used makeOrderedZoneList for ordering:', orderedZones.length, 'zones');
                } else {
                    console.warn('[populateZoneFileCombobox] makeOrderedZoneList returned invalid result, defaulting to allZones');
                }
            } else {
                console.warn('[populateZoneFileCombobox] makeOrderedZoneList not available, using unordered list');
                orderedZones = allZones;
            }
        }

        // Ensure orderedZones is always an array (final safeguard for all error paths)
        orderedZones = ensureValidArray(orderedZones, []);
        
        const input = document.getElementById('zone-file-input');
        const hiddenInput = document.getElementById('zone-file-id');
        const listEl = document.getElementById('zone-file-list');
        if (!input) return;

        // Keep CURRENT_ZONE_LIST in sync with what's shown in combobox
        // DEFENSIVE: Only update cache if orderedZones is non-empty to prevent clearing cache on API errors
        if (orderedZones.length > 0) {
            window.CURRENT_ZONE_LIST = orderedZones.slice();
            console.debug('[populateZoneFileCombobox] Updated CURRENT_ZONE_LIST with', orderedZones.length, 'zones (master first, then includes sorted A-Z)');
            
            // Merge into ZONES_ALL cache so renderZonesTable can display these zones
            // This ensures child includes of a selected include appear in the table
            mergeZonesIntoCache(orderedZones);
            console.debug('[populateZoneFileCombobox] Merged zones into ZONES_ALL for table rendering');
        } else {
            console.warn('[populateZoneFileCombobox] orderedZones is empty, preserving existing CURRENT_ZONE_LIST');
        }

        // Sync combobox instance state with updated CURRENT_ZONE_LIST
        // Use suppress flag to prevent refresh() from overwriting cache
        try {
            window.__ZONE_FILE_COMBOBOX_SUPPRESS_CACHE = true;
            syncZoneFileComboboxInstance();
        } finally {
            window.__ZONE_FILE_COMBOBOX_SUPPRESS_CACHE = false;
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
            // autoSelect is false: clear visible input but pre-fill hidden field with master zone ID
            // This allows user to search while having the master zone pre-selected in the hidden field
            input.value = '';
            input.placeholder = 'Rechercher une zone...';
            
            // Pre-fill hidden field with master zone ID (or selectedZoneFileId if provided)
            if (selectedZoneFileId) {
                if (hiddenInput) hiddenInput.value = selectedZoneFileId;
                window.ZONES_SELECTED_ZONEFILE_ID = selectedZoneFileId;
            } else if (masterZone) {
                if (hiddenInput) hiddenInput.value = masterId;
                window.ZONES_SELECTED_ZONEFILE_ID = masterId;
            } else {
                if (hiddenInput) hiddenInput.value = '';
                window.ZONES_SELECTED_ZONEFILE_ID = null;
            }
        }
        
        // Always enable combobox after population (whether autoSelect is true or false)
        // Use shared helper if available for consistency
        if (typeof window.setZoneComboboxEnabledShared === 'function') {
            window.setZoneComboboxEnabledShared('zone-file-input', 'zone-file-id', true);
        } else if (typeof window.setZoneFileComboboxEnabled === 'function') {
            window.setZoneFileComboboxEnabled(true);
        }
        
        // Race-resistant hiding: forcefully hide the list to prevent it from appearing
        // due to async refresh operations or other side effects
        forceHideZoneFileList();
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
        
        // If still not found, try to fetch from API (fallback for zones not in preloaded cache)
        if (!zone) {
            console.info('[onZoneFileSelected] Zone not found in cache, fetching from API:', zoneFileId);
            try {
                const res = await zoneApiCall('get_zone', { params: { id: zoneFileId } });
                if (res && res.data) {
                    zone = res.data;
                    
                    // Add fetched zone to caches so it's available for downstream operations
                    if (!Array.isArray(window.ZONES_ALL)) {
                        window.ZONES_ALL = [];
                    }
                    if (!Array.isArray(window.CURRENT_ZONE_LIST)) {
                        window.CURRENT_ZONE_LIST = [];
                    }
                    
                    // Add to ZONES_ALL if not already present
                    const existsInZonesAll = window.ZONES_ALL.some(z => parseInt(z.id, 10) === zoneId);
                    if (!existsInZonesAll) {
                        window.ZONES_ALL.push(zone);
                        console.debug('[onZoneFileSelected] Added zone to ZONES_ALL cache:', zone.name);
                    }
                    
                    // Add to CURRENT_ZONE_LIST if not already present
                    const existsInCurrent = window.CURRENT_ZONE_LIST.some(z => parseInt(z.id, 10) === zoneId);
                    if (!existsInCurrent) {
                        window.CURRENT_ZONE_LIST.push(zone);
                        console.debug('[onZoneFileSelected] Added zone to CURRENT_ZONE_LIST cache:', zone.name);
                    }
                    
                    // Also check if this is a master and add to allMasters if needed
                    if (zone.file_type === 'master') {
                        const existsInMasters = allMasters.some(m => parseInt(m.id, 10) === zoneId);
                        if (!existsInMasters) {
                            allMasters.push(zone);
                            console.debug('[onZoneFileSelected] Added master to allMasters cache:', zone.name);
                        }
                    }
                }
            } catch (e) {
                console.warn('[onZoneFileSelected] Failed to fetch zone from API:', e);
            }
        }
        
        if (zone) {
            // Update zone file input text with nicer display value using centralized helper
            // Note: This will be called again by the onSelectItem callback's finally block,
            // but by then enough time will have passed (due to async operations) for the flag to clear
            setZoneFileDisplay(zone);
            
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
            
            // Call setDomainForZone to populate the domain field and enable the combobox
            // This ensures the domain field is properly filled even for zones outside the preloaded cache
            if (typeof setDomainForZone === 'function') {
                try {
                    await setDomainForZone(zone.id);
                    console.debug('[onZoneFileSelected] Domain populated via setDomainForZone');
                } catch (e) {
                    console.warn('[onZoneFileSelected] setDomainForZone failed:', e);
                }
            }
            
            // After setDomainForZone, ensure "Modifier le domaine" button is visible
            // This is needed for fallback zones (outside initial cache) where onZoneDomainSelected wasn't called
            updateEditDomainButton(topMasterId);
        } else {
            // Fallback: just set the value even if we couldn't fetch display info
            setZoneFileDisplay(`Zone ${zoneFileId}`);
        }
    } else {
        // Clear selection
        window.selectedZoneId = null;
        window.ZONES_SELECTED_ZONEFILE_ID = null;
        setZoneFileDisplay('');
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
    const hiddenInput = document.getElementById('zone-file-id');
    
    window.ZONES_SELECTED_ZONEFILE_ID = null;
    
    // Use centralized helper to clear the input
    setZoneFileDisplay('');
    
    if (hiddenInput) {
        hiddenInput.value = '';
    }
}

/**
 * Reset domain selection
 */
async function resetZoneDomainSelection() {
    // Clear search input and global search query
    const searchInput = document.getElementById('searchInput');
    if (searchInput) {
        searchInput.value = '';
    }
    searchQuery = '';
    
    // Clear domain and zone selection
    await onZoneDomainSelected(null);
    clearZoneFileSelection();
    
    // Reset pagination to page 1
    currentPage = 1;
    
    // Reload full table data (loadZonesData calls renderZonesTable internally)
    await loadZonesData();
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

        // Clone response for retry-safe parsing (avoids "body stream already read" errors)
        // This is critical when antivirus/proxy returns 499 or other error codes
        const responseClone = response.clone();

        // Try parse JSON from clone
        let data;
        try {
            data = await responseClone.json();
        } catch (jsonErr) {
            // JSON parsing failed - try to get text from original response for better error message
            let text = '';
            try {
                text = await response.text();
            } catch (textErr) {
                console.error('[zoneApiCall] Could not read response text:', textErr);
            }
            
            console.error('[zoneApiCall] Invalid JSON response for action:', action, {
                status: response.status,
                statusText: response.statusText,
                responseText: text ? text.substring(0, 200) : '(empty)',
                jsonError: jsonErr.message
            });
            
            // Provide user-friendly error message based on status code
            if (response.status === 499) {
                throw new Error('Erreur de connexion (499): Veuillez réessayer');
            } else if (response.status >= 500) {
                throw new Error(`Erreur serveur (${response.status}): ${response.statusText}`);
            } else if (response.status >= 400) {
                throw new Error(`Erreur client (${response.status}): ${response.statusText}`);
            } else {
                throw new Error('Réponse invalide du serveur');
            }
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
 * Deduplicates in-flight requests to prevent duplicate API calls
 */
async function loadZonesData() {
    // If a load is already in progress, return the existing promise
    if (window._loadZonesDataPromise) {
        console.debug('[loadZonesData] Load already in progress, returning existing promise');
        return window._loadZonesDataPromise;
    }
    
    // Create and store the promise
    window._loadZonesDataPromise = (async () => {
        try {
            // Use API standard limit per page and loop to fetch all pages
            const perPage = API_STANDARD_PER_PAGE_LIMIT;
            let allZones = [];
            let total = 0;
            let totalPages = 1;
            
            // Build base params
            const baseParams = {
                file_type: 'include',
                per_page: perPage
            };

            if (filterStatus) {
                baseParams.status = filterStatus;
            }

            // Fetch first page to get total count
            console.debug(`[loadZonesData] Fetching page 1 with per_page=${perPage}`);
            const firstResponse = await zoneApiCall('list_zones', { 
                params: { ...baseParams, page: 1 } 
            });

            if (firstResponse.success) {
                allZones = firstResponse.data || [];
                total = firstResponse.total || allZones.length;
                totalPages = firstResponse.total_pages || 1;
                
                console.debug('[loadZonesData] First page returned', allZones.length, 'zones, total:', total, 'total_pages:', totalPages);
                
                // Log warning if total exceeds first page results (indicating pagination is needed)
                if (total > perPage) {
                    console.log(`[loadZonesData] Total zones (${total}) exceeds page size (${perPage}), fetching remaining pages...`);
                }
                
                // Fetch remaining pages if needed
                if (totalPages > 1) {
                    for (let page = 2; page <= totalPages; page++) {
                        console.debug('[loadZonesData] Fetching page', page, 'of', totalPages);
                        const response = await zoneApiCall('list_zones', { 
                            params: { ...baseParams, page: page } 
                        });
                        
                        if (response.success && response.data) {
                            allZones = allZones.concat(response.data);
                            console.debug('[loadZonesData] Page', page, 'returned', response.data.length, 'zones, cumulative:', allZones.length);
                        } else {
                            console.warn('[loadZonesData] Page', page, 'failed or returned no data');
                        }
                    }
                    
                    console.log('[loadZonesData] Fetched all', totalPages, 'pages, total zones:', allZones.length);
                }
                
                // Store all zones and total count
                window.ZONES_ALL = allZones;
                totalCount = total; // Use total from API, not array length (more reliable)
                
                console.debug(`[loadZonesData] Loaded ${allZones.length} zones (total from API: ${total})`);
                
                // Defensive combobox initialization to ensure UI components are populated
                // This covers cases where loadZonesData is called outside initZonesWhenReady (e.g., manual refresh)
                // Note: initializeComboboxes is now idempotent and will skip if already initialized
                try {
                    await initializeComboboxes();
                } catch (e) {
                    console.debug('[loadZonesData] initializeComboboxes failed:', e);
                }
                
                // Re-render table after successful data load to ensure UI updates
                // Use flag to prevent recursion: when renderZonesTable calls loadZonesData
                // (because data is empty), we don't want that loadZonesData to call
                // renderZonesTable again, which would create an infinite loop.
                if (typeof renderZonesTable === 'function' && !window.__LOADING_ZONES_DATA) {
                    try {
                        window.__LOADING_ZONES_DATA = true;
                        renderZonesTable();
                    } catch (e) {
                        console.debug('[loadZonesData] renderZonesTable failed:', e);
                    } finally {
                        window.__LOADING_ZONES_DATA = false;
                    }
                }
            }
        } catch (error) {
            console.debug('[loadZonesData] Failed to load zones (non-fatal):', error);
            window.ZONES_ALL = [];
        } finally {
            // Clear the promise guard after completion
            window._loadZonesDataPromise = null;
        }
    })();
    
    return window._loadZonesDataPromise;
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
    
    // Build filteredZones from union of ZONES_ALL and CURRENT_ZONE_LIST
    // This ensures zones present only in CURRENT_ZONE_LIST (e.g., children of selected include) are rendered
    // Deduplicate by zone ID using a Map for O(1) lookup
    let filteredZones = [];
    const zonesMap = new Map();
    
    // Add zones from ZONES_ALL first (primary cache)
    if (Array.isArray(window.ZONES_ALL) && window.ZONES_ALL.length > 0) {
        window.ZONES_ALL.forEach(zone => {
            if (zone && zone.id) {
                zonesMap.set(String(zone.id), zone);
            }
        });
    }
    
    // Add zones from CURRENT_ZONE_LIST (domain/zone-specific cache)
    if (Array.isArray(window.CURRENT_ZONE_LIST) && window.CURRENT_ZONE_LIST.length > 0) {
        window.CURRENT_ZONE_LIST.forEach(zone => {
            if (zone && zone.id) {
                zonesMap.set(String(zone.id), zone);
            }
        });
    }
    
    // Convert map values to array
    filteredZones = Array.from(zonesMap.values());
    console.debug('[renderZonesTable] Built filteredZones from union of ZONES_ALL (', 
        (Array.isArray(window.ZONES_ALL) ? window.ZONES_ALL.length : 0), 
        ') and CURRENT_ZONE_LIST (', 
        (Array.isArray(window.CURRENT_ZONE_LIST) ? window.CURRENT_ZONE_LIST.length : 0), 
        ') = ', filteredZones.length, 'unique zones');
    
    // Helper: check whether a zone has `ancestorId` somewhere in its parent chain
    // Use the merged filteredZones (union of all caches) for robust parent resolution
    const zonesAll = filteredZones;
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
        // Fallback for status: try status, then state, then default to empty string (never undefined)
        const statusValue = zone.status || zone.state || '';
        const statusBadge = getStatusBadge(statusValue);
        
        // Fallback for date: try updated_at, then modified_at, then created_at, then null
        const dateValue = zone.updated_at || zone.modified_at || zone.created_at || null;
        
        // Display parent name: try parent_name from API, then parent_domain, then lookup in cache via parent_id
        // Handle string literals 'null', 'undefined', null, and undefined as missing values
        let parentDisplay = '-';
        const hasValidParentName = zone.parent_name && 
                                   zone.parent_name !== 'null' && 
                                   zone.parent_name !== 'undefined' && 
                                   zone.parent_name.trim() !== '';
        const hasValidParentDomain = zone.parent_domain && 
                                     zone.parent_domain !== 'null' && 
                                     zone.parent_domain !== 'undefined' && 
                                     zone.parent_domain.trim() !== '';
        
        if (hasValidParentName) {
            parentDisplay = escapeHtml(zone.parent_name);
        } else if (hasValidParentDomain) {
            // Fallback: use parent_domain if parent_name is not available
            parentDisplay = escapeHtml(zone.parent_domain);
        } else if (zone.parent_id) {
            // Look up parent in caches to get the name
            const parentId = parseValidZoneId(zone.parent_id);
            if (parentId) {
                const cachesToCheck = [
                    window.ALL_ZONES,
                    window.ZONES_ALL,
                    window.CURRENT_ZONE_LIST,
                    (typeof allMasters !== 'undefined' && allMasters) ? allMasters : []
                ];
                
                let parentZone = null;
                for (const cache of cachesToCheck) {
                    if (Array.isArray(cache) && cache.length > 0) {
                        parentZone = cache.find(z => parseInt(z.id, 10) === parentId);
                        if (parentZone) break;
                    }
                }
                
                if (parentZone && parentZone.name) {
                    parentDisplay = escapeHtml(parentZone.name);
                } else if (parentZone && parentZone.domain) {
                    // If name is not available, try domain
                    parentDisplay = escapeHtml(parentZone.domain);
                }
                // If still not found, fetch on-demand and show fallback meanwhile
                else if (!parentZone) {
                    // Store parent ID in data attribute for async fetch
                    parentDisplay = `<span class="parent-fallback" data-parent-id="${parentId}" title="Chargement...">Parent #${parentId}</span>`;
                    // Queue async fetch for this parent using microtask queue for predictable scheduling
                    queueMicrotask(() => fetchAndDisplayParent(zone.id, parentId));
                }
            }
        }
        
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
                <td class="col-name"><strong>${escapeHtml(zone.name)}</strong></td>
                <td class="col-filename"><code>${escapeHtml(zone.filename)}</code></td>
                <td class="col-parent">${parentDisplay}</td>
                <td class="col-date">${formatDate(dateValue)}</td>
                <td class="col-status">${statusBadge}</td>
                ${actionsHtml}
            </tr>
        `;
    }).join('');
    
    updatePaginationControls();
    updateResultsInfo();
}

/**
 * Handle zone row click - select parent domain and zone file
 * Ensures zone and parent data are loaded into caches before processing
 */
async function handleZoneRowClick(zoneId, parentId) {
    // Fetch and cache zone if not already cached (for search results)
    if (zoneId) {
        const zoneIdNum = parseInt(zoneId, 10);
        if (!isNaN(zoneIdNum) && zoneIdNum > 0) {
            // Check if zone is in cache
            const cachesToCheck = [window.ALL_ZONES, window.ZONES_ALL, window.CURRENT_ZONE_LIST];
            let zoneInCache = false;
            
            for (const cache of cachesToCheck) {
                if (Array.isArray(cache) && cache.some(z => parseInt(z.id, 10) === zoneIdNum)) {
                    zoneInCache = true;
                    break;
                }
            }
            
            // Fetch and cache zone if missing
            if (!zoneInCache) {
                try {
                    const result = await zoneApiCall('get_zone', { params: { id: zoneIdNum } });
                    if (result && result.data) {
                        mergeZonesIntoCache([result.data]);
                        console.debug('[handleZoneRowClick] Fetched and cached zone:', result.data.name);
                    }
                } catch (e) {
                    console.warn('[handleZoneRowClick] Failed to fetch zone:', e);
                }
            }
        }
    }
    
    const hasParent = parentId && parentId !== null && parentId !== 'null' && parentId !== '';

    if (hasParent) {
        const parentIdNum = typeof parentId === 'number' ? parentId : parseInt(parentId, 10);
        if (!isNaN(parentIdNum)) {
            try { await onZoneDomainSelected(parentIdNum); } catch (e) { console.warn('[handleZoneRowClick] onZoneDomainSelected failed:', e); }
        }
    }

    if (zoneId) {
        try { await onZoneFileSelected(zoneId); } catch (e) { console.warn('[handleZoneRowClick] onZoneFileSelected failed:', e); }
    }
}

/**
 * Delete zone - wrapper for confirmDeleteZone
 */
async function deleteZone(zoneId) {
    showConfirm(
        'Êtes-vous sûr de vouloir supprimer cette zone?',
        async () => {
            try {
                await zoneApiCall('set_status_zone', {
                    params: { id: zoneId, status: 'deleted' }
                });
                
                showSuccess('Zone supprimée avec succès');
                await loadZonesData();
                renderZonesTable();
            } catch (error) {
                console.error('Failed to delete zone:', error);
                showError('Échec de la suppression: ' + error.message);
            }
        },
        null,
        { type: 'danger', confirmText: 'Supprimer', cancelText: 'Annuler' }
    );
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
    
    // Sync the perPage select value with the current perPage variable
    const perPageSelect = document.getElementById('perPageSelect');
    if (perPageSelect && perPageSelect.value !== String(perPage)) {
        perPageSelect.value = String(perPage);
    }
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
 * Fetch parent zone on-demand and update display in table
 * Used when parent is not in cache after search
 * @param {number} zoneId - Zone ID whose parent cell needs updating
 * @param {number} parentId - Parent zone ID to fetch
 */
async function fetchAndDisplayParent(zoneId, parentId) {
    // Get parent cell once to avoid duplication
    const row = document.querySelector(`tr.zone-row[data-zone-id="${zoneId}"]`);
    if (!row) {
        console.debug('[fetchAndDisplayParent] Row not found for zone:', zoneId);
        return;
    }
    
    const parentCell = row.querySelector('td.col-parent');
    if (!parentCell) {
        console.debug('[fetchAndDisplayParent] Parent cell not found for zone:', zoneId);
        return;
    }
    
    try {
        // Fetch parent zone via API
        const result = await zoneApiCall('get_zone', { params: { id: parentId } });
        if (result && result.data) {
            const parentZone = result.data;
            
            // Merge into cache for future lookups
            mergeZonesIntoCache([parentZone]);
            
            // Update the display in the table row
            const parentName = parentZone.name || parentZone.domain || `Parent #${parentId}`;
            parentCell.innerHTML = escapeHtml(parentName);
            
            console.debug('[fetchAndDisplayParent] Fetched and displayed parent:', parentZone.name || parentId);
        }
    } catch (e) {
        console.warn('[fetchAndDisplayParent] Failed to fetch parent:', parentId, e);
        // Update fallback display with error indication
        parentCell.innerHTML = `<span class="parent-fallback" title="Parent introuvable">Parent #${parentId}</span>`;
    }
}

/**
 * Get status badge HTML
 */
function getStatusBadge(status) {
    // Handle empty/falsy status gracefully
    if (!status || status === '') {
        return '<span class="badge badge-secondary">-</span>';
    }
    
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
        
        // Populate DNSSEC fields (only visible for master zones)
        const zoneDnssecFieldset = document.getElementById('zoneDnssecFieldset');
        if (zoneDnssecFieldset) {
            zoneDnssecFieldset.style.display = ((zone.file_type || 'master') === 'master') ? 'block' : 'none';
        }
        
        // Set DNSSEC field values
        const zoneDnssecKskEl = document.getElementById('zoneDnssecKsk');
        if (zoneDnssecKskEl) zoneDnssecKskEl.value = zone.dnssec_include_ksk || '';
        const zoneDnssecZskEl = document.getElementById('zoneDnssecZsk');
        if (zoneDnssecZskEl) zoneDnssecZskEl.value = zone.dnssec_include_zsk || '';
        
        // Populate Metadata fields (only visible for include zones)
        const zoneMetadataFieldset = document.getElementById('zoneMetadataFieldset');
        if (zoneMetadataFieldset) {
            zoneMetadataFieldset.style.display = (zone.file_type === 'include') ? 'block' : 'none';
        }
        
        // Set Metadata field values
        const zoneApplicationEl = document.getElementById('zoneApplication');
        if (zoneApplicationEl) zoneApplicationEl.value = zone.application || '';
        const zoneTrigrammeEl = document.getElementById('zoneTrigramme');
        if (zoneTrigrammeEl) zoneTrigrammeEl.value = zone.trigramme || '';

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
        showConfirm(
            'Vous avez des modifications non enregistrées. Êtes-vous sûr de vouloir fermer?',
            () => {
                // Remove height lock to restore clean state for next open
                unlockZoneModalHeight();
                
                document.getElementById('zoneModal').classList.remove('open');
                document.getElementById('zoneModal').style.display = 'none';
                currentZone = null;
                currentZoneId = null;
                hasUnsavedChanges = false;
            },
            null,
            { type: 'warning', confirmText: 'Fermer sans enregistrer', cancelText: 'Annuler' }
        );
    } else {
        // Remove height lock to restore clean state for next open
        unlockZoneModalHeight();
        
        document.getElementById('zoneModal').classList.remove('open');
        document.getElementById('zoneModal').style.display = 'none';
        currentZone = null;
        currentZoneId = null;
        hasUnsavedChanges = false;
    }
}

/**
 * Switch between tabs
 */
function switchTab(tabName) {
    // Skip if trying to switch to removed includes tab
    if (tabName === 'includes') {
        console.warn('[switchTab] Includes tab has been removed, ignoring switch request');
        return;
    }
    
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
            
            // Get DNSSEC fields
            const dnssecKsk = document.getElementById('zoneDnssecKsk')?.value?.trim();
            const dnssecZsk = document.getElementById('zoneDnssecZsk')?.value?.trim();
            
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
            data.dnssec_include_ksk = dnssecKsk || null;
            data.dnssec_include_zsk = dnssecZsk || null;
        }
        
        // Add metadata fields only for include zones
        if (currentZone.file_type === 'include') {
            const application = document.getElementById('zoneApplication')?.value?.trim();
            const trigramme = document.getElementById('zoneTrigramme')?.value?.trim();
            
            data.application = application || null;
            data.trigramme = trigramme || null;
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
    showConfirm(
        'Êtes-vous sûr de vouloir supprimer cette zone? Cette action peut être annulée en restaurant la zone.',
        async () => {
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
        },
        null,
        { type: 'danger', confirmText: 'Supprimer', cancelText: 'Annuler' }
    );
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
    showConfirm(
        'Êtes-vous sûr de vouloir retirer cet include de cette zone?',
        async () => {
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
        },
        null,
        { type: 'danger', confirmText: 'Retirer', cancelText: 'Annuler' }
    );
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
                    const serverResults = await serverSearchZones(query, { limit: 1000 });
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
        
        // Get metadata fields
        const application = document.getElementById('include-application')?.value?.trim() || null;
        const trigramme = document.getElementById('include-trigramme')?.value?.trim() || null;
        
        // Create the include zone
        const data = {
            name: name,
            filename: filename,
            file_type: 'include',
            directory: directory,
            application: application,
            trigramme: trigramme,
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
        
        // Get DNSSEC fields
        const dnssecKsk = document.getElementById('master-dnssec-ksk').value?.trim() || '';
        const dnssecZsk = document.getElementById('master-dnssec-zsk').value?.trim() || '';
        
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
            soa_minimum: soaMinimum || null,
            dnssec_include_ksk: dnssecKsk || null,
            dnssec_include_zsk: dnssecZsk || null
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
    showAlert(message, 'success');
}

function showError(message) {
    showAlert(message, 'error');
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
                            <button class="btn-small btn-delete" onclick="deleteAclEntry(${entry.id})" title="Supprimer">
                                <i class="fas fa-trash"></i> Supprimer
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
 * For 'user' type: show text input for sAMAccountName (AD) or uid (LDAP) entry (pre-authorization support)
 * For 'role' type: show select with existing roles
 * For 'ad_group' type: show text input for AD group DN (Distinguished Name)
 */
async function updateAclSubjectOptions() {
    const typeSelect = document.getElementById('aclSubjectType');
    const selectEl = document.getElementById('aclSubjectIdentifierSelect');
    const inputEl = document.getElementById('aclSubjectIdentifierInput');
    
    if (!typeSelect || !selectEl || !inputEl) return;
    
    const type = typeSelect.value;
    
    if (type === 'user') {
        // Show text input for free sAMAccountName/uid entry (allows pre-authorization of users not yet in DB)
        selectEl.style.display = 'none';
        inputEl.style.display = 'block';
        inputEl.value = '';
        inputEl.placeholder = 'sAMAccountName (AD) ou uid (LDAP) — ex: jdupont';
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
            option.textContent = user.username;
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
    showConfirm(
        'Êtes-vous sûr de vouloir supprimer cette entrée ACL ?',
        async () => {
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
        },
        null,
        { type: 'danger', confirmText: 'Supprimer', cancelText: 'Annuler' }
    );
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
window.fetchAndDisplayParent = fetchAndDisplayParent;
window.setZoneFileComboboxEnabled = setZoneFileComboboxEnabled;
window.initZonesWhenReady = initZonesWhenReady; // Expose for manual testing and fallback retry

// Initialize on DOM ready
if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', () => {
        initZonesWhenReady();
    });
} else {
    // DOM already loaded, init immediately
    initZonesWhenReady();
}

// Fallback orchestration: ensure initialization happens with bounded retries
// This handles cases where scripts load in unexpected order or async timing issues
// Maximum 3 attempts total with exponential backoff (30ms, 800ms, 2500ms)

// Attempt 1: Quick async call (30ms delay)
setTimeout(() => {
    // Skip if already initialized or if an initialization is currently in progress
    if (!window._zonesInitRun && !window._initZonesWhenReadyPromise && shouldInitZonesPage()) {
        console.debug('[Fallback 30ms] Attempting initialization (retry available)');
        initZonesWhenReady().catch(err => {
            console.debug('[Fallback 30ms] Init attempt failed or incomplete:', err);
        });
    }
}, 30);

// Attempt 2: Medium delay retry (800ms)
setTimeout(() => {
    // Skip if already initialized or if an initialization is currently in progress
    if (!window._zonesInitRun && !window._initZonesWhenReadyPromise && shouldInitZonesPage()) {
        console.debug('[Fallback 800ms] Zones not initialized, retrying...');
        initZonesWhenReady().catch(err => {
            console.error('[Fallback 800ms] Init attempt failed:', err);
        });
    }
}, 800);

// Attempt 3: Extended delay final retry (2500ms)
setTimeout(() => {
    // Skip if already initialized or if an initialization is currently in progress
    if (!window._zonesInitRun && !window._initZonesWhenReadyPromise && shouldInitZonesPage()) {
        console.debug('[Fallback 2500ms] Final initialization retry...');
        initZonesWhenReady().catch(err => {
            console.error('[Fallback 2500ms] Final retry failed:', err);
            console.info('[Fallback 2500ms] Manual recovery: call window.initZonesWhenReady() in console');
        });
    }
}, 2500);

// Window load listener: additional fallback for atypical script loading order
// This ensures initZonesWhenReady is called when window.load event fires
// Safe due to attempt counter and idempotency guards
window.addEventListener('load', () => {
    // Skip if already initialized or if an initialization is currently in progress
    if (!window._zonesInitRun && !window._initZonesWhenReadyPromise && shouldInitZonesPage()) {
        console.debug('[window.load] Triggering initialization fallback');
        try {
            window.initZonesWhenReady();
        } catch (e) {
            console.error('[window.load] initZonesWhenReady failed', e);
        }
    }
});
