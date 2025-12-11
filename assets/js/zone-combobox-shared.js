/**
 * Zone Combobox Shared Helpers
 * 
 * Centralized, robust combobox logic for zone file selection
 * Extracted from DNS tab implementation (proven to work correctly)
 * 
 * Provides:
 * - zoneApiCallShared: Robust fetch with response.clone() for retry-safe parsing
 * - initZoneComboboxShared: Server-first combobox initialization
 * - setZoneComboboxEnabledShared: Enable/disable combobox helper
 * 
 * Used by:
 * - assets/js/zone-files.js (Zones tab)
 * - assets/js/dns-records.js (DNS Records tab)
 */

(function(window) {
    'use strict';

    /**
     * Robust zone API call with response.clone() for error-resilient parsing
     * 
     * Handles cases where:
     * - Antivirus/proxy returns 499 or other error codes
     * - Response body stream is already read
     * - JSON parsing fails
     * 
     * @param {string} action - API action name (e.g., 'list_zones', 'search_zones')
     * @param {Object} params - Query parameters (e.g., { q: 'search', file_type: 'include' })
     * @param {string} method - HTTP method (default: 'GET')
     * @param {Object|null} body - Request body for POST/PUT (default: null)
     * @returns {Promise<Object>} - API response object
     * @throws {Error} - On API failure with clear error message
     * 
     * @example
     * const result = await zoneApiCallShared('search_zones', { q: 'example', limit: 100 });
     * console.log(result.data); // Array of zones
     */
    async function zoneApiCallShared(action, params = {}, method = 'GET', body = null) {
        const methodUpper = (method || 'GET').toUpperCase();
        
        // Build explicit URL to zone_api.php (API_BASE already ends with 'api/')
        let url = new URL(window.API_BASE + 'zone_api.php', window.location.origin);
        url.searchParams.append('action', action);

        // Always append params to URL for all methods (GET, POST, etc.)
        if (params && typeof params === 'object' && Object.keys(params).length > 0) {
            Object.keys(params).forEach(k => {
                if (params[k] !== undefined && params[k] !== null) {
                    url.searchParams.append(k, params[k]);
                }
            });
        }

        const fetchOptions = {
            method: methodUpper,
            headers: {
                'Accept': 'application/json'
            },
            credentials: 'same-origin' // important: send session cookie
        };

        if (body && (methodUpper === 'POST' || methodUpper === 'PUT' || methodUpper === 'PATCH')) {
            fetchOptions.headers['Content-Type'] = 'application/json';
            fetchOptions.body = JSON.stringify(body);
        }

        let response;
        try {
            response = await fetch(url.toString(), fetchOptions);
        } catch (networkError) {
            const errMsg = `[zoneApiCallShared] Network error: ${networkError.message}`;
            console.error(errMsg, networkError);
            throw new Error(`Erreur réseau: ${networkError.message}`);
        }

        // Clone response for retry-safe parsing (avoids "body stream already read" errors)
        const responseClone = response.clone();

        // Try parse JSON from clone
        let data;
        try {
            data = await responseClone.json();
        } catch (jsonErr) {
            // JSON parsing failed - try to get text for better error message
            let text = '';
            try {
                text = await response.text();
            } catch (textErr) {
                console.error('[zoneApiCallShared] Could not read response text:', textErr);
            }
            
            const errMsg = `[zoneApiCallShared] Invalid JSON response for action '${action}'`;
            console.error(errMsg, { 
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

        // Check HTTP status
        if (!response.ok) {
            const errMsg = data.error || data.message || `HTTP ${response.status}: ${response.statusText}`;
            console.error('[zoneApiCallShared] API error:', {
                action,
                status: response.status,
                error: errMsg
            });
            throw new Error(errMsg);
        }

        return data;
    }

    /**
     * Initialize zone combobox with server-first search
     * 
     * Provides consistent behavior:
     * - Server search for queries ≥ minCharsForServer
     * - Client filtering for short queries
     * - Dropdown only shows on user interaction (focus/input)
     * - Returns refresh() method to sync state without showing dropdown
     * 
     * @param {Object} opts - Configuration options
     * @param {HTMLInputElement} opts.inputEl - Visible input element
     * @param {HTMLUListElement} opts.listEl - Dropdown list element (UL)
     * @param {HTMLInputElement} opts.hiddenEl - Hidden input for storing selected ID
     * @param {Function} opts.onSelectItem - Callback when zone is selected
     * @param {string} opts.file_type - Filter by file type (e.g., 'include', 'master')
     * @param {number} opts.minCharsForServer - Minimum chars to trigger server search (default: 2)
     * @param {number} opts.blurDelay - Delay before hiding list on blur (default: 150ms)
     * @returns {Object} - Object with refresh() method
     * 
     * @example
     * const instance = initZoneComboboxShared({
     *   inputEl: document.getElementById('zone-file-input'),
     *   listEl: document.getElementById('zone-file-list'),
     *   hiddenEl: document.getElementById('zone-file-id'),
     *   onSelectItem: (zone) => { console.log('Selected:', zone.name); },
     *   file_type: 'include'
     * });
     * 
     * // Later: sync state without showing dropdown
     * instance.refresh();
     */
    function initZoneComboboxShared(opts) {
        const input = opts.inputEl;
        const list = opts.listEl;
        const hidden = opts.hiddenEl || null;
        const fileType = opts.file_type || '';
        const minCharsForServer = opts.minCharsForServer || 2;
        const blurDelay = opts.blurDelay || 150;
        
        if (!input || !list) {
            console.warn('[initZoneComboboxShared] Missing required elements (inputEl or listEl)');
            return { refresh: () => {} };
        }
        
        console.debug('[initZoneComboboxShared] Initializing with file_type:', fileType || 'all');
        
        // Map zone to combobox item format
        function mapZoneItem(zone) {
            return {
                id: zone.id,
                text: `${zone.name || zone.filename} (${zone.file_type})`
            };
        }
        
        // Populate list and attach click handlers
        // showList defaults to false to prevent auto-display on domain selection (aligned with DNS tab)
        // updateCache defaults to true to update CURRENT_ZONE_LIST, but should be false when zones are derived from it (e.g., refresh)
        function showZones(zones, showList = false, updateCache = true) {
            // Update CURRENT_ZONE_LIST to keep it in sync with displayed zones
            // Skip update when zones are already derived from CURRENT_ZONE_LIST (e.g., from refresh)
            // to prevent overwriting the carefully constructed domain-specific cache
            if (updateCache && !window.__ZONE_FILE_COMBOBOX_SUPPRESS_CACHE) {
                window.CURRENT_ZONE_LIST = zones;
            }
            
            // Use populateComboboxList helper if available
            if (typeof window.populateComboboxList === 'function') {
                window.populateComboboxList(list, zones, mapZoneItem, (zone) => {
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
                            console.error('[initZoneComboboxShared] onSelectItem callback error:', err);
                        }
                    }
                }, showList);
            } else {
                // Fallback: manual implementation
                console.warn('[initZoneComboboxShared] populateComboboxList not available, using fallback');
                list.innerHTML = '';
                
                if (!Array.isArray(zones) || zones.length === 0) {
                    const li = document.createElement('li');
                    li.className = 'combobox-item combobox-empty';
                    li.textContent = 'Aucun résultat';
                    list.appendChild(li);
                } else {
                    zones.forEach(zone => {
                        const li = document.createElement('li');
                        li.className = 'combobox-item';
                        li.textContent = mapZoneItem(zone).text;
                        li.dataset.id = zone.id;
                        li.addEventListener('click', () => {
                            if (hidden) hidden.value = zone.id || '';
                            input.value = mapZoneItem(zone).text;
                            if (typeof opts.onSelectItem === 'function') {
                                try {
                                    opts.onSelectItem(zone);
                                } catch (err) {
                                    console.error('[initZoneComboboxShared] onSelectItem error:', err);
                                }
                            }
                        });
                        list.appendChild(li);
                    });
                }
                
                if (showList) {
                    list.style.display = 'block';
                    list.setAttribute('aria-hidden', 'false');
                } else {
                    list.style.display = 'none';
                    list.setAttribute('aria-hidden', 'true');
                }
            }
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
                console.debug('[initZoneComboboxShared] server search for query:', query);
                
                try {
                    // Try to call serverSearchZones if available
                    let serverResults = [];
                    if (typeof window.serverSearchZones === 'function') {
                        serverResults = await window.serverSearchZones(query, { 
                            file_type: fileType,
                            limit: 100 
                        });
                    } else {
                        // Fallback: call zoneApiCallShared directly
                        console.debug('[initZoneComboboxShared] serverSearchZones not found, using zoneApiCallShared');
                        const params = { q: query, limit: 100 };
                        if (fileType) params.file_type = fileType;
                        const response = await zoneApiCallShared('search_zones', params);
                        serverResults = response.data || [];
                    }
                    
                    // Filter server results by selected domain if one is selected
                    const masterId = window.ZONES_SELECTED_MASTER_ID || null;
                    if (masterId && typeof window.isZoneInMasterTree === 'function') {
                        const unfilteredCount = serverResults.length;
                        serverResults = serverResults.filter(z => window.isZoneInMasterTree(z, masterId, serverResults));
                        console.debug('[initZoneComboboxShared] Filtered server results by domain:', unfilteredCount, '→', serverResults.length);
                    }
                    
                    // Apply ordering to server results: master first, then includes sorted A-Z
                    if (typeof window.makeOrderedZoneList === 'function') {
                        serverResults = window.makeOrderedZoneList(serverResults, masterId);
                    }
                    
                    console.debug('[initZoneComboboxShared] server returned', serverResults.length, 'results');
                    showZones(serverResults, true); // Show list when user is typing
                    return;
                } catch (err) {
                    console.warn('[initZoneComboboxShared] server search failed, fallback to client:', err);
                    // Fall through to client filtering
                }
            }
            
            // Client filtering for short queries or when server search fails
            console.debug('[initZoneComboboxShared] client filter for query:', query);
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
                // Prevent cache overwrite: zones derived from CURRENT_ZONE_LIST, preserves domain-specific cache
                showZones(zones, false, false);
            }
        };
    }

    /**
     * Enable or disable zone combobox inputs
     * 
     * @param {string} inputId - ID of visible input element
     * @param {string} hiddenId - ID of hidden input element
     * @param {boolean} enabled - True to enable, false to disable
     * 
     * @example
     * setZoneComboboxEnabledShared('zone-file-input', 'zone-file-id', true);
     */
    function setZoneComboboxEnabledShared(inputId, hiddenId, enabled) {
        const input = document.getElementById(inputId);
        const hidden = document.getElementById(hiddenId);
        
        if (input) {
            if (enabled) {
                input.disabled = false;
                input.readOnly = false;
            } else {
                input.disabled = true;
                input.readOnly = true;
            }
        }
        
        if (hidden) {
            hidden.disabled = !enabled;
        }
    }

    /**
     * Check if a zone is in a master's tree by traversing its parent chain
     * 
     * @param {Object} zone - The zone object to check
     * @param {number} masterId - The master zone ID to look for
     * @param {Array} zoneList - List of zones to search for parents
     * @returns {boolean} True if zone's parent chain contains masterId
     * 
     * @example
     * const inTree = isZoneInMasterTree(zone, 5, allZones);
     */
    function isZoneInMasterTree(zone, masterId, zoneList) {
        if (!zone || !masterId) return false;
        
        // Use global constant if available, otherwise default to 20
        const MAX_PARENT_CHAIN_DEPTH = window.MAX_PARENT_CHAIN_DEPTH || 20;
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
            currentZone = Array.isArray(zoneList) ? zoneList.find(z => parseInt(z.id, 10) === parentId) : null;
        }
        
        return false;
    }

    /**
     * Server-side zone search with optional file_type filtering
     * 
     * @param {string} query - Search query string
     * @param {Object} options - Search options
     * @param {string} options.file_type - Filter by file type (e.g., 'include', 'master')
     * @param {number} options.limit - Maximum number of results (default: 100)
     * @returns {Promise<Array>} - Array of matching zones
     * 
     * @example
     * const zones = await serverSearchZones('example', { file_type: 'include', limit: 50 });
     */
    async function serverSearchZones(query, options = {}) {
        const fileType = options.file_type || ''; // Empty = search all types
        const limit = options.limit || 100; // Default limit
        
        try {
            const params = { q: query, limit: limit };
            if (fileType) {
                params.file_type = fileType;
            }
            
            console.debug('[serverSearchZones] Searching with query:', query, 'file_type:', fileType || 'all', 'limit:', limit);
            
            const result = await zoneApiCallShared('search_zones', params);
            const zones = result.data || [];
            
            console.debug('[serverSearchZones] Found', zones.length, 'results');
            return zones;
        } catch (err) {
            console.warn('[serverSearchZones] Search failed:', err);
            return [];
        }
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
     * 
     * @example
     * const instance = initServerSearchCombobox({
     *   inputEl: document.getElementById('zone-input'),
     *   listEl: document.getElementById('zone-list'),
     *   hiddenEl: document.getElementById('zone-id'),
     *   file_type: 'include',
     *   onSelectItem: (zone) => { console.log('Selected:', zone.name); }
     * });
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
        // updateCache defaults to true to update CURRENT_ZONE_LIST, but should be false when zones are derived from it (e.g., refresh)
        function showZones(zones, showList = false, updateCache = true) {
            // Update CURRENT_ZONE_LIST to keep it in sync with displayed zones
            // Skip update when zones are already derived from CURRENT_ZONE_LIST (e.g., from refresh)
            // to prevent overwriting the carefully constructed domain-specific cache
            if (updateCache) {
                window.CURRENT_ZONE_LIST = zones;
            }
            
            // Use populateComboboxList helper if available
            if (typeof window.populateComboboxList === 'function') {
                window.populateComboboxList(list, zones, mapZoneItem, (zone) => {
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
            } else {
                // Fallback: manual implementation
                console.warn('[initServerSearchCombobox] populateComboboxList helper function not available. Ensure combobox-utils.js or zone-files.js is loaded before calling this function. Using fallback implementation.');
                list.innerHTML = '';
                
                if (!Array.isArray(zones) || zones.length === 0) {
                    const li = document.createElement('li');
                    li.className = 'combobox-item combobox-empty';
                    li.textContent = 'Aucun résultat';
                    list.appendChild(li);
                } else {
                    zones.forEach(zone => {
                        const li = document.createElement('li');
                        li.className = 'combobox-item';
                        li.textContent = mapZoneItem(zone).text;
                        li.dataset.id = zone.id;
                        li.addEventListener('click', () => {
                            if (hidden) hidden.value = zone.id || '';
                            input.value = mapZoneItem(zone).text;
                            if (typeof opts.onSelectItem === 'function') {
                                try {
                                    opts.onSelectItem(zone);
                                } catch (err) {
                                    console.error('[initServerSearchCombobox] onSelectItem error:', err);
                                }
                            }
                        });
                        list.appendChild(li);
                    });
                }
                
                if (showList) {
                    list.style.display = 'block';
                    list.setAttribute('aria-hidden', 'false');
                } else {
                    list.style.display = 'none';
                    list.setAttribute('aria-hidden', 'true');
                }
            }
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
                    // Use serverSearchZones function
                    const serverResults = await serverSearchZones(query, { 
                        file_type: fileType,
                        limit: 100 
                    });
                    
                    // Filter server results by selected domain if one is selected
                    let filtered = serverResults;
                    const masterId = window.ZONES_SELECTED_MASTER_ID || null;
                    if (masterId) {
                        const unfilteredCount = serverResults.length;
                        filtered = serverResults.filter(z => isZoneInMasterTree(z, masterId, serverResults));
                        console.debug('[initServerSearchCombobox] Filtered server results by domain:', unfilteredCount, '→', filtered.length);
                    }
                    
                    // Apply ordering to server results: master first, then includes sorted A-Z
                    if (typeof window.makeOrderedZoneList === 'function') {
                        filtered = window.makeOrderedZoneList(filtered, masterId);
                    }
                    
                    console.debug('[initServerSearchCombobox] server returned', filtered.length, 'results');
                    showZones(filtered, true); // Show list when user is typing
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
                // Prevent cache overwrite: zones derived from CURRENT_ZONE_LIST, preserves domain-specific cache
                showZones(zones, false, false);
            }
        };
    }

    // Export functions to window for global access
    window.zoneApiCallShared = zoneApiCallShared;
    window.initZoneComboboxShared = initZoneComboboxShared;
    window.setZoneComboboxEnabledShared = setZoneComboboxEnabledShared;
    window.isZoneInMasterTree = isZoneInMasterTree;
    window.serverSearchZones = serverSearchZones;
    window.initServerSearchCombobox = initServerSearchCombobox;
    
    console.debug('[zone-combobox-shared.js] Shared helpers loaded');

})(window);
