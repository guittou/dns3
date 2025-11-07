/**
 * DNS Records Management JavaScript
 * Handles client-side interactions for DNS record management
 */

(function() {
    'use strict';

    let currentRecords = [];
    
    /**
     * Constants
     */
    const COMBOBOX_BLUR_DELAY = 200; // Delay in ms before hiding combobox list on blur
    const FOCUS_TRANSITION_DELAY = 50; // Delay in ms between sequential focus calls for visual feedback
    const AUTOFILL_HIGHLIGHT_COLOR = '#fffacd'; // Light yellow color for autofill visual feedback
    const AUTOFILL_HIGHLIGHT_DURATION = 900; // Duration in ms for autofill highlight

    /**
     * Required fields by DNS record type
     */
    const REQUIRED_BY_TYPE = {
        'A': ['name', 'address_ipv4'],
        'AAAA': ['name', 'address_ipv6'],
        'CNAME': ['name', 'cname_target'],
        'PTR': ['name', 'ptrdname'],
        'TXT': ['name', 'txt']
    };

    /**
     * Check if a string is a valid IPv4 address
     */
    function isIPv4(str) {
        const ipv4Regex = /^(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$/;
        return ipv4Regex.test(str);
    }

    /**
     * Check if a string is a valid IPv6 address
     */
    function isIPv6(str) {
        // Simplified IPv6 regex - covers most common cases
        const ipv6Regex = /^(([0-9a-fA-F]{1,4}:){7}[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,7}:|([0-9a-fA-F]{1,4}:){1,6}:[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,5}(:[0-9a-fA-F]{1,4}){1,2}|([0-9a-fA-F]{1,4}:){1,4}(:[0-9a-fA-F]{1,4}){1,3}|([0-9a-fA-F]{1,4}:){1,3}(:[0-9a-fA-F]{1,4}){1,4}|([0-9a-fA-F]{1,4}:){1,2}(:[0-9a-fA-F]{1,4}){1,5}|[0-9a-fA-F]{1,4}:((:[0-9a-fA-F]{1,4}){1,6})|:((:[0-9a-fA-F]{1,4}){1,7}|:)|fe80:(:[0-9a-fA-F]{0,4}){0,4}%[0-9a-zA-Z]{1,}|::(ffff(:0{1,4}){0,1}:){0,1}((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])|([0-9a-fA-F]{1,4}:){1,4}:((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9]))$/;
        return ipv6Regex.test(str);
    }

    /**
     * Validate payload data for a specific record type
     * @param {string} recordType - The DNS record type
     * @param {Object} data - The payload data to validate
     * @returns {Object} { valid: boolean, error: string|null }
     */
    function validatePayloadForType(recordType, data) {
        const requiredFields = REQUIRED_BY_TYPE[recordType] || ['name'];
        
        // Check required fields
        for (const field of requiredFields) {
            if (!data[field] || String(data[field]).trim() === '') {
                return { valid: false, error: `Le champ "${field}" est requis pour le type ${recordType}` };
            }
        }
        
        // Type-specific semantic validation
        switch(recordType) {
            case 'A':
                if (!isIPv4(data.address_ipv4)) {
                    return { valid: false, error: 'L\'adresse doit être une adresse IPv4 valide pour le type A' };
                }
                break;
                
            case 'AAAA':
                if (!isIPv6(data.address_ipv6)) {
                    return { valid: false, error: 'L\'adresse doit être une adresse IPv6 valide pour le type AAAA' };
                }
                break;
                
            case 'CNAME':
                // CNAME should not be an IP address
                if (isIPv4(data.cname_target) || isIPv6(data.cname_target)) {
                    return { valid: false, error: 'La cible CNAME ne peut pas être une adresse IP (doit être un nom d\'hôte)' };
                }
                // Basic FQDN validation
                if (!data.cname_target.match(/^[a-zA-Z0-9]([a-zA-Z0-9\-\.]*[a-zA-Z0-9])?(\.[a-zA-Z]{2,})?$/)) {
                    return { valid: false, error: 'La cible CNAME doit être un nom d\'hôte valide' };
                }
                break;
                
            case 'PTR':
                // PTR requires reverse DNS name from user
                if (!data.ptrdname.match(/^[a-zA-Z0-9]([a-zA-Z0-9\-\.]*[a-zA-Z0-9])?(\.[a-zA-Z]{2,})?$/)) {
                    return { valid: false, error: 'Le nom PTR doit être un nom d\'hôte valide (nom DNS inversé requis)' };
                }
                break;
                
            case 'TXT':
                if (data.txt.trim().length === 0) {
                    return { valid: false, error: 'Le contenu du champ TXT ne peut pas être vide' };
                }
                break;
        }
        
        return { valid: true, error: null };
    }

    /**
     * Construct API URL using window.API_BASE with fallbacks
     */
    function getApiUrl(action, params = {}) {
        // Use window.API_BASE or fallback to window.BASE_URL or current origin
        const apiBase = window.API_BASE || window.BASE_URL || '/api/';
        
        // Normalize apiBase to ensure it ends with /
        const normalizedBase = apiBase.endsWith('/') ? apiBase : apiBase + '/';
        
        const url = new URL(normalizedBase + 'dns_api.php', window.location.origin);
        url.searchParams.append('action', action);
        
        Object.keys(params).forEach(key => {
            url.searchParams.append(key, params[key]);
        });

        const finalUrl = url.toString();
        console.debug('[API Request] Constructed URL:', finalUrl);
        return finalUrl;
    }

    /**
     * Construct Zone API URL with fallbacks
     */
    function getZoneApiUrl(action, params = {}) {
        // Use window.API_BASE or fallback to window.BASE_URL or current origin
        const apiBase = window.API_BASE || window.BASE_URL || '/api/';
        
        // Normalize apiBase to ensure it ends with /
        const normalizedBase = apiBase.endsWith('/') ? apiBase : apiBase + '/';
        
        const url = new URL(normalizedBase + 'zone_api.php', window.location.origin);
        url.searchParams.append('action', action);
        
        Object.keys(params).forEach(key => {
            url.searchParams.append(key, params[key]);
        });

        const finalUrl = url.toString();
        console.debug('[Zone API Request] Constructed URL:', finalUrl);
        return finalUrl;
    }

    /**
     * Make an API call
     */
    async function apiCall(action, params = {}, method = 'GET', body = null) {
        try {
            const url = getApiUrl(action, params);

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

            console.debug('[API Request] Fetching:', method, url);
            const response = await fetch(url, options);
            
            // Try to parse JSON, fallback to text for debugging
            let data;
            try {
                data = await response.json();
            } catch (jsonError) {
                const text = await response.text();
                console.error('[API Error] Failed to parse JSON response:', jsonError);
                console.error('[API Error] Response status:', response.status, response.statusText);
                console.error('[API Error] Response body:', text);
                throw new Error('Invalid JSON response from API');
            }

            if (!response.ok) {
                console.error('[API Error] Request failed:', response.status, response.statusText);
                console.error('[API Error] Response data:', data);
                throw new Error(data.error || 'API request failed');
            }

            console.debug('[API Response] Success:', data);
            return data;
        } catch (error) {
            console.error('[API Error] Exception during API call:', error);
            throw error;
        }
    }

    /**
     * Make a Zone API call
     */
    async function zoneApiCall(action, params = {}, method = 'GET', body = null) {
        try {
            const url = getZoneApiUrl(action, params);

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

            const response = await fetch(url, options);
            
            let data;
            try {
                data = await response.json();
            } catch (jsonError) {
                const text = await response.text();
                console.error('Failed to parse JSON response:', jsonError);
                console.error('Response body:', text);
                throw new Error('Invalid JSON response from API');
            }

            if (!response.ok) {
                throw new Error(data.error || 'API request failed');
            }

            return data;
        } catch (error) {
            console.error('Zone API call error:', error);
            throw error;
        }
    }

    // =========================================================================
    // Combobox Component State
    // =========================================================================
    
    let allDomains = [];
    let allZones = [];
    let ALL_ZONES = [];  // Complete list of all zones
    let CURRENT_ZONE_LIST = [];  // Currently filtered zones (by domain or all)
    let selectedDomainId = null;
    let selectedZoneId = null;

    /**
     * Initialize domain combobox
     */
    async function initDomainCombobox() {
        try {
            // Load all domains
            const result = await apiCall('list_domains');
            allDomains = result.data || [];
            
            const input = document.getElementById('dns-domain-input');
            const hiddenInput = document.getElementById('dns-domain-id');
            const list = document.getElementById('dns-domain-list');
            
            if (!input || !hiddenInput || !list) return;
            
            // Input event - filter and show list
            input.addEventListener('input', () => {
                const query = input.value.toLowerCase().trim();
                const filtered = allDomains.filter(d => 
                    d.domain.toLowerCase().includes(query)
                );
                
                populateComboboxList(list, filtered, (domain) => ({
                    id: domain.id,
                    text: domain.domain
                }), (domain) => {
                    selectDomain(domain.id, domain.domain);
                });
            });
            
            // Focus - show full list
            input.addEventListener('focus', () => {
                populateComboboxList(list, allDomains, (domain) => ({
                    id: domain.id,
                    text: domain.domain
                }), (domain) => {
                    selectDomain(domain.id, domain.domain);
                });
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
        } catch (error) {
            console.error('Error initializing domain combobox:', error);
        }
    }

    /**
     * Initialize zone combobox
     */
    async function initZoneCombobox() {
        try {
            // Load all active zones
            const result = await zoneApiCall('list_zones', { status: 'active' });
            allZones = (result.data || []).filter(z => z.file_type === 'master' || z.file_type === 'include');
            ALL_ZONES = [...allZones];  // Keep a copy of all zones
            CURRENT_ZONE_LIST = [...allZones];  // Initialize current list
            
            const input = document.getElementById('dns-zone-input');
            const hiddenInput = document.getElementById('dns-zone-id');
            const list = document.getElementById('dns-zone-list');
            
            if (!input || !hiddenInput || !list) return;
            
            // Input event - filter CURRENT_ZONE_LIST and show list
            input.addEventListener('input', () => {
                const query = input.value.toLowerCase().trim();
                const filtered = CURRENT_ZONE_LIST.filter(z => 
                    z.name.toLowerCase().includes(query) || 
                    z.filename.toLowerCase().includes(query)
                );
                
                populateComboboxList(list, filtered, (zone) => ({
                    id: zone.id,
                    text: `${zone.name} (${zone.file_type})`
                }), (zone) => {
                    selectZone(zone.id, zone.name, zone.file_type);
                });
            });
            
            // Focus - show CURRENT_ZONE_LIST (filtered by domain if domain selected)
            input.addEventListener('focus', () => {
                populateComboboxList(list, CURRENT_ZONE_LIST, (zone) => ({
                    id: zone.id,
                    text: `${zone.name} (${zone.file_type})`
                }), (zone) => {
                    selectZone(zone.id, zone.name, zone.file_type);
                });
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
        } catch (error) {
            console.error('Error initializing zone combobox:', error);
        }
    }

    /**
     * Generic function to populate combobox list
     */
    function populateComboboxList(listElement, items, mapFn, onClickFn) {
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
            const mapped = mapFn(item);
            const li = document.createElement('li');
            li.className = 'combobox-item';
            li.textContent = mapped.text;
            li.dataset.id = mapped.id;
            
            li.addEventListener('click', () => {
                onClickFn(item);
            });
            
            listElement.appendChild(li);
        });
        
        listElement.style.display = 'block';
    }

    /**
     * Select a domain
     */
    function selectDomain(domainId, domainName) {
        selectedDomainId = domainId;
        
        const input = document.getElementById('dns-domain-input');
        const hiddenInput = document.getElementById('dns-domain-id');
        const list = document.getElementById('dns-domain-list');
        
        if (input) input.value = domainName;
        if (hiddenInput) hiddenInput.value = domainId;
        if (list) list.style.display = 'none';
        
        // When domain is selected, filter zones
        populateZoneComboboxForDomain(domainId);
        
        // Clear zone selection (user must re-select)
        clearZoneSelection();
        
        // Reload table with domain filter
        loadDnsTable();
    }

    /**
     * Select a zone
     */
    async function selectZone(zoneId, zoneName, zoneType) {
        selectedZoneId = zoneId;
        
        const input = document.getElementById('dns-zone-input');
        const hiddenInput = document.getElementById('dns-zone-id');
        const list = document.getElementById('dns-zone-list');
        
        if (input) input.value = `${zoneName} (${zoneType})`;
        if (hiddenInput) hiddenInput.value = zoneId;
        if (list) list.style.display = 'none';
        
        // Enable create button
        updateCreateBtnState();
        
        // When zone is selected, auto-select the associated domain
        await setDomainForZone(zoneId);
        
        // Reload table with zone filter
        loadDnsTable();
    }

    /**
     * Clear zone selection
     */
    function clearZoneSelection() {
        selectedZoneId = null;
        
        const input = document.getElementById('dns-zone-input');
        const hiddenInput = document.getElementById('dns-zone-id');
        
        if (input) input.value = '';
        if (hiddenInput) hiddenInput.value = '';
        
        // Update create button state
        updateCreateBtnState();
    }

    /**
     * Populate zone combobox for a specific domain
     * This updates CURRENT_ZONE_LIST but does NOT open the list or auto-select a zone
     */
    async function populateZoneComboboxForDomain(domainId) {
        try {
            const result = await apiCall('list_zones_by_domain', { domain_id: domainId });
            const zones = result.data || [];
            
            // Update CURRENT_ZONE_LIST with filtered zones
            CURRENT_ZONE_LIST = zones;
            
            // DO NOT open the combobox list - user must click/focus to see it
            // DO NOT auto-select a zone - zone selection must be explicit
        } catch (error) {
            console.error('Error populating zones for domain:', error);
            CURRENT_ZONE_LIST = [];
        }
    }

    /**
     * Set domain for a given zone (auto-complete domain based on zone)
     */
    async function setDomainForZone(zoneId) {
        try {
            const result = await apiCall('get_domain_for_zone', { zone_id: zoneId });
            const domain = result.data;
            
            if (domain) {
                selectedDomainId = domain.id;
                
                const input = document.getElementById('dns-domain-input');
                const hiddenInput = document.getElementById('dns-domain-id');
                
                if (input) input.value = domain.domain;
                if (hiddenInput) hiddenInput.value = domain.id;
                
                // Update CURRENT_ZONE_LIST to show zones for this domain
                // but do NOT auto-open the list
                await populateZoneComboboxForDomain(domain.id);
            }
        } catch (error) {
            console.error('Error setting domain for zone:', error);
        }
    }

    /**
     * Update create button state based on zone selection
     */
    function updateCreateBtnState() {
        const createBtn = document.getElementById('dns-create-btn');
        const zoneId = document.getElementById('dns-zone-id');
        
        if (createBtn && zoneId) {
            // Enable only if zone is selected (has non-empty value)
            createBtn.disabled = !zoneId.value || zoneId.value === '';
        }
    }

    /**
     * Reset domain and zone filters
     */
    function resetDomainZoneFilters() {
        // Clear domain selection
        selectedDomainId = null;
        const domainInput = document.getElementById('dns-domain-input');
        const domainHidden = document.getElementById('dns-domain-id');
        if (domainInput) domainInput.value = '';
        if (domainHidden) domainHidden.value = '';
        
        // Clear zone selection
        clearZoneSelection();
        
        // Restore CURRENT_ZONE_LIST to ALL_ZONES
        CURRENT_ZONE_LIST = [...ALL_ZONES];
        
        // Close any open lists
        const domainList = document.getElementById('dns-domain-list');
        const zoneList = document.getElementById('dns-zone-list');
        if (domainList) domainList.style.display = 'none';
        if (zoneList) zoneList.style.display = 'none';
        
        // Disable create button
        updateCreateBtnState();
        
        // Reload table with no filters
        loadDnsTable();
    }

    /**
     * Initialize modal zone file select
     * Note: This function is now a no-op since we're using a simple select element.
     * The select element is populated dynamically when the modal opens.
     * Kept for compatibility with existing initialization code.
     */
    async function initModalZoneCombobox() {
        // No initialization needed for select element
    }

    /**
     * Helper function to populate zone file select and set selected value
     * Ensures the select is populated before attempting to set the value
     * If a specific zone_file_id is provided, fetches that zone and ensures it's in the list
     * @param {number|string|null} selectedZoneFileId - The zone file ID to select after populating
     * @param {number|string|null} domainId - Optional domain ID to filter zones by domain (legacy param, use modal field or selectedDomainId)
     */
    async function populateZoneFileCombobox(selectedZoneFileId, domainId = null) {
        try {
            const modalDomainIdEl = document.getElementById('dns-modal-domain-id');
            let modalDomainId = modalDomainIdEl && modalDomainIdEl.value ? modalDomainIdEl.value : null;
            if (!modalDomainId && typeof selectedDomainId !== 'undefined' && selectedDomainId) modalDomainId = selectedDomainId;
            let zones = [];
            if (modalDomainId) {
                if (Array.isArray(CURRENT_ZONE_LIST) && CURRENT_ZONE_LIST.length > 0) {
                    zones = CURRENT_ZONE_LIST;
                } else {
                    const res = await apiCall('list_zones_by_domain', { domain_id: modalDomainId });
                    zones = (res && res.data ? res.data : []).filter(z => z.file_type === 'master' || z.file_type === 'include');
                    CURRENT_ZONE_LIST = zones;
                }
            } else {
                const res = await zoneApiCall('list_zones', { status: 'active' });
                zones = (res && res.data ? res.data : []).filter(z => z.file_type === 'master' || z.file_type === 'include');
                ALL_ZONES = zones;
                CURRENT_ZONE_LIST = [...ALL_ZONES];
            }
            
            const selectElement = document.getElementById('record-zone-file');
            
            if (!selectElement) {
                console.error('[populateZoneFileSelect] Zone file select not found');
                return;
            }
            
            // If a specific zone_file_id is provided, ensure it's in the list
            if (selectedZoneFileId) {
                const zoneIdNum = parseInt(selectedZoneFileId, 10);
                
                // Validate parsed zone ID before attempting to fetch
                if (!isNaN(zoneIdNum) && zoneIdNum > 0) {
                    // Convert zone.id to number for strict comparison since API may return string or number
                    const zoneExists = zones.some(z => parseInt(z.id, 10) === zoneIdNum);
                    
                    // If the zone isn't in the list (due to pagination/filtering), fetch it specifically
                    if (!zoneExists) {
                        console.debug('[populateZoneFileSelect] Zone', zoneIdNum, 'not in list, fetching specifically');
                        try {
                            const specificZoneResult = await zoneApiCall('get_zone', { id: zoneIdNum });
                            // API throws on error, but verify data exists before using
                            if (specificZoneResult && specificZoneResult.data) {
                                // Add the specific zone to our list
                                zones.push(specificZoneResult.data);
                                // Update CURRENT_ZONE_LIST and ALL_ZONES
                                CURRENT_ZONE_LIST.push(specificZoneResult.data);
                                if (!ALL_ZONES.some(z => parseInt(z.id, 10) === zoneIdNum)) {
                                    ALL_ZONES.push(specificZoneResult.data);
                                }
                                console.debug('[populateZoneFileSelect] Added zone', specificZoneResult.data.name, 'to select');
                            }
                        } catch (fetchError) {
                            console.warn('[populateZoneFileSelect] Failed to fetch specific zone:', fetchError);
                        }
                    }
                } else {
                    console.warn('[populateZoneFileSelect] Invalid zone_file_id:', selectedZoneFileId);
                }
            }
            
            // Filter to show only master and include types
            const filteredZones = zones.filter(z => z.file_type === 'master' || z.file_type === 'include');
            
            // Clear and populate the select element
            selectElement.innerHTML = '<option value="">Sélectionner une zone...</option>';
            
            filteredZones.forEach(zone => {
                const option = document.createElement('option');
                option.value = zone.id;
                option.textContent = `${zone.name} (${zone.file_type})`;
                selectElement.appendChild(option);
            });
            
            // Set the selected value if provided
            if (selectedZoneFileId) {
                const zoneIdNum = parseInt(selectedZoneFileId, 10);
                const selectedZone = filteredZones.find(z => parseInt(z.id, 10) === zoneIdNum);
                
                if (selectedZone) {
                    selectElement.value = selectedZone.id;
                    console.debug('[populateZoneFileSelect] Successfully set zone_file_id:', selectedZone.id);
                } else {
                    console.warn('[populateZoneFileSelect] zone_file_id', selectedZoneFileId, 'not found after fetch attempt');
                    selectElement.value = '';
                }
            } else {
                // Clear the selection
                selectElement.value = '';
            }
            
            // Hide zone combobox list to prevent it from opening automatically after programmatic set
            const listEl = document.getElementById('record-zone-list') || document.getElementById('dns-zone-list');
            if (listEl) setTimeout(() => { listEl.style.display = 'none'; }, FOCUS_TRANSITION_DELAY);
        } catch (error) {
            console.error('[populateZoneFileSelect] Error:', error);
            // Don't show message to user, just log it
        }
    }

    /**
     * Load available domains for domain filter
     */
    async function populateDomainSelect() {
        try {
            const result = await apiCall('list_domains');
            const domains = result.data || [];
            
            const selector = document.getElementById('dns-domain-filter');
            if (!selector) return;
            
            // Clear existing options except the first placeholder
            selector.innerHTML = '<option value="">Tous les domaines</option>';
            
            // Add domains to selector
            domains.forEach(domain => {
                const option = document.createElement('option');
                option.value = domain.id;
                option.textContent = domain.domain;
                selector.appendChild(option);
            });
        } catch (error) {
            console.error('Error loading domains:', error);
            // Don't show message to user, just log it
        }
    }

    /**
     * Load and display DNS records table
     */
    async function loadDnsTable(filters = {}) {
        try {
            const searchInput = document.getElementById('dns-search');
            if (searchInput && searchInput.value) {
                filters.name = searchInput.value;
            }

            const typeFilter = document.getElementById('dns-type-filter');
            if (typeFilter && typeFilter.value) {
                filters.type = typeFilter.value;
            }

            const statusFilter = document.getElementById('dns-status-filter');
            if (statusFilter && statusFilter.value) {
                filters.status = statusFilter.value;
            }

            // Priority: zone filter takes precedence over domain filter
            if (selectedZoneId) {
                filters.zone_file_id = selectedZoneId;
            } else if (selectedDomainId) {
                filters.domain_id = selectedDomainId;
            }

            const result = await apiCall('list', filters);
            currentRecords = result.data || [];

            const tbody = document.getElementById('dns-table-body');
            if (!tbody) return;

            tbody.innerHTML = '';

            if (currentRecords.length === 0) {
                tbody.innerHTML = '<tr><td colspan="11" style="text-align: center; padding: 20px;">Aucun enregistrement trouvé</td></tr>';
                return;
            }

            // Generate table rows with semantic classes matching the new header order
            currentRecords.forEach(record => {
                const row = document.createElement('tr');
                row.dataset.recordId = record.id;
                if (record.zone_file_id) row.dataset.zoneFileId = record.zone_file_id;

                const domainDisplay = escapeHtml(record.domain_name || '-');
                const zoneDisplay = escapeHtml(record.zone_name || '-');

                row.innerHTML = `
                    <td class="col-domain">${domainDisplay}</td>
                    <td class="col-zonefile">${zoneDisplay}</td>
                    <td class="col-name">${escapeHtml(record.name)}</td>
                    <td class="col-ttl">${escapeHtml(record.ttl)}</td>
                    <td class="col-class">${escapeHtml(record.class || 'IN')}</td>
                    <td class="col-type">${escapeHtml(record.record_type)}</td>
                    <td class="col-value">${escapeHtml(record.value)}</td>
                    <td class="col-updated">${record.updated_at ? formatDateTime(record.updated_at) : (record.created_at ? formatDateTime(record.created_at) : '-')}</td>
                    <td class="col-lastseen">${record.last_seen ? formatDateTime(record.last_seen) : '-'}</td>
                    <td class="col-status"><span class="status-badge status-${record.status}">${escapeHtml(record.status)}</span></td>
                    <td class="col-actions">
                        <button class="btn-small btn-edit" onclick="dnsRecords.openEditModal(${record.id})">Modifier</button>
                        ${record.status !== 'deleted' ? `<button class="btn-small btn-delete" onclick="dnsRecords.deleteRecord(${record.id})">Supprimer</button>` : ''}
                        ${record.status === 'deleted' ? `<button class="btn-small btn-restore" onclick="dnsRecords.restoreRecord(${record.id})">Restaurer</button>` : ''}
                    </td>
                `;

                // Au clic sur la ligne : autocomplete domain + zone (ignorer clics sur actions)
                row.addEventListener('click', async (e) => {
                    // Ignore clicks sur la colonne d'actions / boutons
                    if (e.target.closest('.col-actions') || e.target.tagName === 'BUTTON' || e.target.closest('button')) return;

                    const zoneFileId = record.zone_file_id || row.dataset.zoneFileId;
                    if (!zoneFileId) return;

                    try {
                        // 1) remplir la combobox Domaine en fonction de la zone (met selectedDomainId)
                        if (typeof setDomainForZone === 'function') {
                            await setDomainForZone(zoneFileId);
                        }

                        // 2) s'assurer que CURRENT_ZONE_LIST est filtré pour le domaine (important)
                        try {
                            if (typeof populateZoneComboboxForDomain === 'function' && (selectedDomainId || document.getElementById('dns-modal-domain-id')?.value)) {
                                const domainToUse = selectedDomainId || document.getElementById('dns-modal-domain-id')?.value;
                                if (domainToUse) await populateZoneComboboxForDomain(domainToUse);
                            }
                        } catch (ee) {
                            console.warn('populateZoneComboboxForDomain failed (click row):', ee);
                        }

                        // 3) Remplir la combobox de la PAGE (dns-zone-input / dns-zone-id) si elle existe
                        const pageZoneInput = document.getElementById('dns-zone-input');
                        const pageZoneHidden = document.getElementById('dns-zone-id');
                        if (pageZoneInput && pageZoneHidden) {
                            // Rechercher la zone dans CURRENT_ZONE_LIST
                            let zone = (CURRENT_ZONE_LIST || []).find(z => String(z.id) === String(zoneFileId));

                            // Si pas trouvée, tenter de la récupérer via l'API
                            if (!zone) {
                                try {
                                    const res = await zoneApiCall('get_zone', { id: zoneFileId });
                                    if (res && res.data) zone = res.data;
                                } catch (e) {
                                    console.warn('get_zone fallback failed:', e);
                                }
                            }

                            if (zone) {
                                pageZoneInput.value = `${zone.name} (${zone.file_type})`;
                                pageZoneHidden.value = zone.id;
                                selectedZoneId = zone.id;
                                if (typeof updateCreateBtnState === 'function') updateCreateBtnState();
                                // reload table if you want the table to reflect the zone filter
                                if (typeof loadDnsTable === 'function') loadDnsTable();
                            } else {
                                // Clear if not found
                                pageZoneInput.value = '';
                                pageZoneHidden.value = '';
                            }
                        }

                        // 4) Si tu veux aussi remplir le modal (si ouvert), appelle populateZoneFileCombobox
                        const modalDomainIdEl = document.getElementById('dns-modal-domain-id');
                        if (modalDomainIdEl) modalDomainIdEl.value = selectedDomainId || (document.getElementById('dns-domain-id')?.value || '');

                        if (typeof populateZoneFileCombobox === 'function') {
                            await populateZoneFileCombobox(zoneFileId);
                        } else if (typeof populateZoneFileSelect === 'function') {
                            await populateZoneFileSelect(zoneFileId);
                        }

                        // 5) Provide visual feedback without focusing - prevent lists from opening
                        const domainInput = document.getElementById('dns-domain-input');
                        const zoneInput = document.getElementById('record-zone-input') || document.getElementById('dns-zone-input');
                        
                        // Explicitly hide both combobox lists to prevent auto-opening
                        setTimeout(() => {
                            const domainList = document.getElementById('dns-domain-list');
                            const zoneList = document.getElementById('record-zone-list') || document.getElementById('dns-zone-list');
                            if (domainList) domainList.style.display = 'none';
                            if (zoneList) zoneList.style.display = 'none';
                        }, FOCUS_TRANSITION_DELAY);
                        
                        // Blur zone input if currently focused to prevent list opening
                        if (zoneInput && document.activeElement === zoneInput) zoneInput.blur();
                        
                        // Provide temporary visual highlight on domain input (no focus)
                        if (domainInput) {
                            // Save original inline style (empty string if no inline style is set)
                            // Note: This captures inline styles only, not CSS-defined backgrounds
                            const originalInlineStyle = domainInput.style.backgroundColor;
                            // Apply highlight
                            domainInput.style.backgroundColor = AUTOFILL_HIGHLIGHT_COLOR;
                            setTimeout(() => {
                                // Restore original inline style (empty string removes the inline style)
                                domainInput.style.backgroundColor = originalInlineStyle;
                            }, AUTOFILL_HIGHLIGHT_DURATION);
                        }
                    } catch (err) {
                        console.error('Erreur autocomplétion domaine/zone depuis ligne:', err);
                    }
                });

                tbody.appendChild(row);
            });
        } catch (error) {
            console.error('Error loading DNS table:', error);
            showMessage('Erreur lors du chargement des enregistrements: ' + error.message, 'error');
        }
    }

    /**
     * Update form field visibility and required attributes based on record type
     */
    function updateFieldVisibility() {
        const recordType = document.getElementById('record-type').value;
        
        // Get all dedicated field groups
        const ipv4Group = document.getElementById('record-address-ipv4-group');
        const ipv6Group = document.getElementById('record-address-ipv6-group');
        const cnameGroup = document.getElementById('record-cname-target-group');
        const ptrGroup = document.getElementById('record-ptrdname-group');
        const txtGroup = document.getElementById('record-txt-group');
        
        // Get all dedicated field inputs
        const ipv4Input = document.getElementById('record-address-ipv4');
        const ipv6Input = document.getElementById('record-address-ipv6');
        const cnameInput = document.getElementById('record-cname-target');
        const ptrInput = document.getElementById('record-ptrdname');
        const txtInput = document.getElementById('record-txt');
        
        // Hide all dedicated fields first
        if (ipv4Group) ipv4Group.style.display = 'none';
        if (ipv6Group) ipv6Group.style.display = 'none';
        if (cnameGroup) cnameGroup.style.display = 'none';
        if (ptrGroup) ptrGroup.style.display = 'none';
        if (txtGroup) txtGroup.style.display = 'none';
        
        // Remove required attribute from all
        if (ipv4Input) ipv4Input.removeAttribute('required');
        if (ipv6Input) ipv6Input.removeAttribute('required');
        if (cnameInput) cnameInput.removeAttribute('required');
        if (ptrInput) ptrInput.removeAttribute('required');
        if (txtInput) txtInput.removeAttribute('required');
        
        // Show and set required for the appropriate field based on record type
        switch(recordType) {
            case 'A':
                if (ipv4Group) ipv4Group.style.display = 'block';
                if (ipv4Input) ipv4Input.setAttribute('required', 'required');
                break;
            case 'AAAA':
                if (ipv6Group) ipv6Group.style.display = 'block';
                if (ipv6Input) ipv6Input.setAttribute('required', 'required');
                break;
            case 'CNAME':
                if (cnameGroup) cnameGroup.style.display = 'block';
                if (cnameInput) cnameInput.setAttribute('required', 'required');
                break;
            case 'PTR':
                if (ptrGroup) ptrGroup.style.display = 'block';
                if (ptrInput) ptrInput.setAttribute('required', 'required');
                break;
            case 'TXT':
                if (txtGroup) txtGroup.style.display = 'block';
                if (txtInput) txtInput.setAttribute('required', 'required');
                break;
        }
    }

    /**
     * Open modal to create a new record (with prefilled zone)
     */
    async function openCreateModalPrefilled() {
        const modal = document.getElementById('dns-modal');
        const form = document.getElementById('dns-form');
        const title = document.getElementById('dns-modal-title');
        const lastSeenGroup = document.getElementById('record-last-seen-group');
        const deleteBtn = document.getElementById('record-delete-btn');
        const domainDiv = document.getElementById('dns-modal-domain');
        
        if (!modal || !form || !title) return;

        // Set fixed title without domain
        title.textContent = 'Créer un enregistrement DNS';
        
        // Populate domain name from combobox if selected
        if (domainDiv) {
            try {
                const domainInput = document.getElementById('dns-domain-input');
                const domainValue = domainInput ? domainInput.value.trim() : '';
                
                if (domainValue) {
                    domainDiv.textContent = domainValue;
                    domainDiv.style.display = 'block';
                } else {
                    domainDiv.style.display = 'none';
                }
            } catch (error) {
                // Silently handle error, don't block modal opening
                console.error('Error populating domain in modal:', error);
                domainDiv.style.display = 'none';
            }
        }
        
        form.reset();
        form.dataset.mode = 'create';
        delete form.dataset.recordId;
        
        // Hide last_seen field for new records (server-managed)
        if (lastSeenGroup) {
            lastSeenGroup.style.display = 'none';
        }
        
        // Hide delete button for create mode
        if (deleteBtn) {
            deleteBtn.style.display = 'none';
        }
        
        // Load zone files and preselect the selected zone, filtered by domain if selected
        await populateZoneFileCombobox(selectedZoneId, selectedDomainId);

        // Update field visibility based on default record type
        updateFieldVisibility();

        modal.style.display = 'block';
        modal.classList.add('open');
        
        // Call centering helper if available
        if (typeof window.ensureModalCentered === 'function') {
            window.ensureModalCentered(modal);
        }
    }

    /**
     * Open modal to create a new record
     */
    async function openCreateModal() {
        const modal = document.getElementById('dns-modal');
        const form = document.getElementById('dns-form');
        const title = document.getElementById('dns-modal-title');
        const lastSeenGroup = document.getElementById('record-last-seen-group');
        const deleteBtn = document.getElementById('record-delete-btn');
        const domainDiv = document.getElementById('dns-modal-domain');
        
        if (!modal || !form || !title) return;

        title.textContent = 'Créer un enregistrement DNS';
        form.reset();
        form.dataset.mode = 'create';
        delete form.dataset.recordId;
        
        // Hide last_seen field for new records (server-managed)
        if (lastSeenGroup) {
            lastSeenGroup.style.display = 'none';
        }
        
        // Hide delete button for create mode
        if (deleteBtn) {
            deleteBtn.style.display = 'none';
        }
        
        // Populate domain name from combobox if selected
        if (domainDiv) {
            try {
                const domainInput = document.getElementById('dns-domain-input');
                const domainValue = domainInput ? domainInput.value.trim() : '';
                
                if (domainValue) {
                    domainDiv.textContent = domainValue;
                    domainDiv.style.display = 'block';
                } else {
                    domainDiv.style.display = 'none';
                }
            } catch (error) {
                // Silently handle error, don't block modal opening
                console.error('Error populating domain in modal:', error);
                domainDiv.style.display = 'none';
            }
        }
        
        // Load zone files for combobox (no selection for new records), filtered by domain if selected
        await populateZoneFileCombobox(null, selectedDomainId);

        // Update field visibility based on default record type
        updateFieldVisibility();

        modal.style.display = 'block';
        modal.classList.add('open');
        
        // Call centering helper if available
        if (typeof window.ensureModalCentered === 'function') {
            window.ensureModalCentered(modal);
        }
    }

    /**
     * Open modal to edit an existing record
     */
    async function openEditModal(recordId) {
        try {
            const result = await apiCall('get', { id: recordId });
            const record = result.data;

            const modal = document.getElementById('dns-modal');
            const form = document.getElementById('dns-form');
            const title = document.getElementById('dns-modal-title');
            const lastSeenGroup = document.getElementById('record-last-seen-group');
            const domainDiv = document.getElementById('dns-modal-domain');
            
            if (!modal || !form || !title) return;

            // Set fixed title without domain
            title.textContent = 'Modifier l\'enregistrement DNS';
            
            // Populate domain name in separate line - only use record.domain_name (strict)
            if (domainDiv) {
                try {
                    const displayDomain = record.domain_name || '';
                    
                    if (displayDomain) {
                        domainDiv.textContent = displayDomain;
                        domainDiv.style.display = 'block';
                    } else {
                        domainDiv.style.display = 'none';
                    }
                } catch (error) {
                    // Silently handle error, don't block modal opening
                    console.error('Error populating domain in modal:', error);
                    domainDiv.style.display = 'none';
                }
            }
            
            form.dataset.mode = 'edit';
            form.dataset.recordId = recordId;
            
            // Populate zone files combobox and set the selected zone_file_id, filtered by domain if available
            await populateZoneFileCombobox(record.zone_file_id, record.domain_id);

            document.getElementById('record-type').value = record.record_type;
            document.getElementById('record-name').value = record.name;
            document.getElementById('record-ttl').value = record.ttl;
            document.getElementById('record-requester').value = record.requester || '';
            document.getElementById('record-ticket-ref').value = record.ticket_ref || '';
            document.getElementById('record-comment').value = record.comment || '';
            
            // Set dedicated field values based on record type
            const ipv4Input = document.getElementById('record-address-ipv4');
            const ipv6Input = document.getElementById('record-address-ipv6');
            const cnameInput = document.getElementById('record-cname-target');
            const ptrInput = document.getElementById('record-ptrdname');
            const txtInput = document.getElementById('record-txt');
            
            // Clear all dedicated fields first
            if (ipv4Input) ipv4Input.value = '';
            if (ipv6Input) ipv6Input.value = '';
            if (cnameInput) cnameInput.value = '';
            if (ptrInput) ptrInput.value = '';
            if (txtInput) txtInput.value = '';
            
            // Set the appropriate dedicated field
            switch(record.record_type) {
                case 'A':
                    if (ipv4Input) ipv4Input.value = record.address_ipv4 || record.value || '';
                    break;
                case 'AAAA':
                    if (ipv6Input) ipv6Input.value = record.address_ipv6 || record.value || '';
                    break;
                case 'CNAME':
                    if (cnameInput) cnameInput.value = record.cname_target || record.value || '';
                    break;
                case 'PTR':
                    if (ptrInput) ptrInput.value = record.ptrdname || record.value || '';
                    break;
                case 'TXT':
                    if (txtInput) txtInput.value = record.txt || record.value || '';
                    break;
            }
            
            // Convert SQL datetime to datetime-local format
            if (record.expires_at) {
                document.getElementById('record-expires-at').value = sqlToDatetimeLocal(record.expires_at);
            } else {
                document.getElementById('record-expires-at').value = '';
            }
            
            // Show last_seen field (read-only) if it has a value
            if (record.last_seen && lastSeenGroup) {
                document.getElementById('record-last-seen').value = formatDateTime(record.last_seen);
                lastSeenGroup.style.display = 'block';
            } else if (lastSeenGroup) {
                lastSeenGroup.style.display = 'none';
            }

            // Update field visibility based on record type
            updateFieldVisibility();

            // Show and bind delete button for edit mode
            const deleteBtn = document.getElementById('record-delete-btn');
            if (deleteBtn) {
                deleteBtn.style.display = 'block';
                // Remove any previous click listeners and add new one
                deleteBtn.onclick = function() {
                    dnsRecords.deleteRecord(recordId);
                };
            }

            modal.style.display = 'block';
            modal.classList.add('open');
            
            // Call centering helper if available
            if (typeof window.ensureModalCentered === 'function') {
                window.ensureModalCentered(modal);
            }
        } catch (error) {
            console.error('Error opening edit modal:', error);
            showMessage('Erreur lors du chargement de l\'enregistrement: ' + error.message, 'error');
        }
    }

    /**
     * Close modal
     */
    function closeModal() {
        const modal = document.getElementById('dns-modal');
        if (modal) {
            modal.classList.remove('open');
            modal.style.display = 'none';
        }
    }

    /**
     * Submit DNS form (create or update)
     */
    async function submitDnsForm(event) {
        event.preventDefault();

        const form = document.getElementById('dns-form');
        const mode = form.dataset.mode;
        const recordId = form.dataset.recordId;

        const recordType = document.getElementById('record-type').value;
        const zoneFileId = document.getElementById('record-zone-file').value;
        
        // Validate zone_file_id is selected
        if (!zoneFileId || zoneFileId === '') {
            showMessage('Veuillez sélectionner un fichier de zone', 'error');
            return;
        }

        const data = {
            zone_file_id: parseInt(zoneFileId),
            record_type: recordType,
            name: document.getElementById('record-name').value,
            ttl: parseInt(document.getElementById('record-ttl').value),
            requester: document.getElementById('record-requester').value || null,
            ticket_ref: document.getElementById('record-ticket-ref').value || null,
            comment: document.getElementById('record-comment').value || null
        };
        
        // Add the appropriate dedicated field based on record type
        let dedicatedValue = null;
        switch(recordType) {
            case 'A':
                dedicatedValue = document.getElementById('record-address-ipv4').value;
                data.address_ipv4 = dedicatedValue;
                break;
            case 'AAAA':
                dedicatedValue = document.getElementById('record-address-ipv6').value;
                data.address_ipv6 = dedicatedValue;
                break;
            case 'CNAME':
                dedicatedValue = document.getElementById('record-cname-target').value;
                data.cname_target = dedicatedValue;
                break;
            case 'PTR':
                dedicatedValue = document.getElementById('record-ptrdname').value;
                data.ptrdname = dedicatedValue;
                break;
            case 'TXT':
                dedicatedValue = document.getElementById('record-txt').value;
                data.txt = dedicatedValue;
                break;
        }
        
        // Also include 'value' as alias for backward compatibility
        data.value = dedicatedValue;
        
        // Convert datetime-local to SQL format for expires_at
        const expiresAtValue = document.getElementById('record-expires-at').value;
        if (expiresAtValue) {
            data.expires_at = datetimeLocalToSql(expiresAtValue);
        } else {
            data.expires_at = null;
        }
        
        // IMPORTANT: Never send last_seen from client - it's server-managed only
        // (already handled by not including it in data object)

        // Validate payload before sending
        const validation = validatePayloadForType(recordType, data);
        if (!validation.valid) {
            showMessage(validation.error, 'error');
            return;
        }

        try {
            if (mode === 'create') {
                await apiCall('create', {}, 'POST', data);
                showMessage('Enregistrement créé avec succès', 'success');
            } else if (mode === 'edit' && recordId) {
                await apiCall('update', { id: recordId }, 'POST', data);
                showMessage('Enregistrement mis à jour avec succès', 'success');
            }

            closeModal();
            await loadDnsTable();
        } catch (error) {
            console.error('Error submitting form:', error);
            showMessage('Erreur: ' + error.message, 'error');
        }
    }

    /**
     * Delete record (soft delete)
     */
    async function deleteRecord(recordId) {
        if (!confirm('Êtes-vous sûr de vouloir supprimer cet enregistrement ?')) {
            return;
        }

        try {
            await apiCall('set_status', { id: recordId, status: 'deleted' });
            showMessage('Enregistrement supprimé', 'success');
            await loadDnsTable();
        } catch (error) {
            console.error('Error deleting record:', error);
            showMessage('Erreur lors de la suppression: ' + error.message, 'error');
        }
    }

    /**
     * Restore a deleted record
     */
    async function restoreRecord(recordId) {
        if (!confirm('Êtes-vous sûr de vouloir restaurer cet enregistrement ?')) {
            return;
        }

        try {
            await apiCall('set_status', { id: recordId, status: 'active' });
            showMessage('Enregistrement restauré', 'success');
            await loadDnsTable();
        } catch (error) {
            console.error('Error restoring record:', error);
            showMessage('Erreur lors de la restauration: ' + error.message, 'error');
        }
    }

    /**
     * Show message to user
     */
    function showMessage(message, type = 'info') {
        const messageContainer = document.getElementById('dns-message');
        if (!messageContainer) {
            alert(message);
            return;
        }

        messageContainer.textContent = message;
        messageContainer.className = `dns-message dns-message-${type}`;
        messageContainer.style.display = 'block';

        setTimeout(() => {
            messageContainer.style.display = 'none';
        }, 5000);
    }

    /**
     * Escape HTML to prevent XSS
     */
    function escapeHtml(text) {
        if (text === null || text === undefined) return '';
        const map = {
            '&': '&amp;',
            '<': '&lt;',
            '>': '&gt;',
            '"': '&quot;',
            "'": '&#039;'
        };
        return String(text).replace(/[&<>"']/g, m => map[m]);
    }

    /**
     * Convert SQL datetime format to datetime-local input format
     * SQL: "2024-10-20 14:30:00" -> HTML5: "2024-10-20T14:30"
     */
    function sqlToDatetimeLocal(sqlDatetime) {
        if (!sqlDatetime) return '';
        // Remove seconds if present and replace space with T
        return sqlDatetime.substring(0, 16).replace(' ', 'T');
    }

    /**
     * Convert datetime-local input format to SQL datetime format
     * HTML5: "2024-10-20T14:30" -> SQL: "2024-10-20 14:30:00"
     */
    function datetimeLocalToSql(datetimeLocal) {
        if (!datetimeLocal) return null;
        // Replace T with space and add :00 for seconds
        return datetimeLocal.replace('T', ' ') + ':00';
    }

    /**
     * Format datetime for display
     * Converts "2024-10-20 14:30:00" or "2024-10-20T14:30:00" to localized format
     */
    function formatDateTime(datetime) {
        if (!datetime) return '';
        try {
            const date = new Date(datetime.replace(' ', 'T'));
            return date.toLocaleString('fr-FR', {
                year: 'numeric',
                month: '2-digit',
                day: '2-digit',
                hour: '2-digit',
                minute: '2-digit'
            });
        } catch (e) {
            return datetime;
        }
    }

    /**
     * Initialize event listeners
     */
    function init() {
        // Initialize comboboxes
        initDomainCombobox();
        initZoneCombobox();
        initModalZoneCombobox();
        
        // Search input
        const searchInput = document.getElementById('dns-search');
        if (searchInput) {
            searchInput.addEventListener('input', debounce(() => {
                loadDnsTable();
            }, 300));
        }

        // Type filter
        const typeFilter = document.getElementById('dns-type-filter');
        if (typeFilter) {
            typeFilter.addEventListener('change', () => loadDnsTable());
        }

        // Status filter
        const statusFilter = document.getElementById('dns-status-filter');
        if (statusFilter) {
            statusFilter.addEventListener('change', () => loadDnsTable());
        }

        // Create button - use prefilled version
        const createBtn = document.getElementById('dns-create-btn');
        if (createBtn) {
            createBtn.addEventListener('click', openCreateModalPrefilled);
            // Set initial state (disabled by default until zone is selected)
            updateCreateBtnState();
        }

        // Reset button
        const resetBtn = document.getElementById('dns-reset-filters-btn');
        if (resetBtn) {
            resetBtn.addEventListener('click', resetDomainZoneFilters);
        }

        // Form submit
        const form = document.getElementById('dns-form');
        if (form) {
            form.addEventListener('submit', submitDnsForm);
        }

        // Record type change listener
        const recordTypeSelect = document.getElementById('record-type');
        if (recordTypeSelect) {
            recordTypeSelect.addEventListener('change', updateFieldVisibility);
        }

        // Modal close button
        const closeBtn = document.getElementById('dns-modal-close');
        if (closeBtn) {
            closeBtn.addEventListener('click', closeModal);
        }

        // Close modal on outside click
        const modal = document.getElementById('dns-modal');
        if (modal) {
            window.addEventListener('click', (event) => {
                if (event.target === modal) {
                    closeModal();
                }
            });
        }

        // Initial load
        const tableBody = document.getElementById('dns-table-body');
        if (tableBody) {
            // Load table immediately (comboboxes initialized asynchronously)
            loadDnsTable();
        }
    }

    /**
     * Debounce function for search input
     */
    function debounce(func, wait) {
        let timeout;
        return function executedFunction(...args) {
            const later = () => {
                clearTimeout(timeout);
                func(...args);
            };
            clearTimeout(timeout);
            timeout = setTimeout(later, wait);
        };
    }

    // Expose public API
    window.dnsRecords = {
        loadDnsTable,
        openCreateModal,
        openEditModal,
        closeModal,
        submitDnsForm,
        deleteRecord,
        restoreRecord
    };

    // Initialize on DOM ready
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', init);
    } else {
        init();
    }
})();
