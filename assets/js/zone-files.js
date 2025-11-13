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

// Lightweight reusable combobox initializer
// opts: { inputEl, listEl, hiddenEl?, getItems?:fn, mapItem:fn, onSelectItem:fn, blurDelay }
function initCombobox(opts) {
    const input = opts.inputEl;
    const list = opts.listEl;
    const hidden = opts.hiddenEl || null;
    const blurDelay = opts.blurDelay || 150;
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
                per_page: 1000
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
 */
async function populateZoneComboboxForDomain(masterId) {
    try {
        let result;
        try {
            // Try zone_id parameter (new API)
            result = await apiCall('list_zones_by_domain', { zone_id: masterId });
        } catch (e) {
            // Fallback to domain_id parameter (old API)
            result = await apiCall('list_zones_by_domain', { domain_id: masterId });
        }
        
        const zones = result.data || [];
        
        // Update CURRENT_ZONE_LIST with filtered zones
        window.CURRENT_ZONE_LIST = zones;
        
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
                // Fallback: filter ALL_ZONES by domain if available
                if (Array.isArray(window.ALL_ZONES)) {
                    if (domainName) {
                        window.CURRENT_ZONE_LIST = window.ALL_ZONES.filter(z => (z.domain || '') === domainName);
                    } else {
                        window.CURRENT_ZONE_LIST = window.ALL_ZONES.filter(z => z.id === zone.id);
                    }
                }
            }
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
        // Enable only if zone is selected (has non-empty value)
        createBtn.disabled = !zoneId.value || zoneId.value === '';
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
 * Ensure zone files initialization and expose helpers on window
 * Should be called before any combobox initialization
 */
function ensureZoneFilesInit() {
    initZonesCache();
    syncSelectedIds();
    
    // Expose helpers on window for global access
    window.apiCall = apiCall;
    window.getMasterIdFromZoneId = getMasterIdFromZoneId;
    window.getTopMasterId = getTopMasterId;
    window.fetchZonesForMaster = fetchZonesForMaster;
    window.populateZoneComboboxForDomain = populateZoneComboboxForDomain;
    window.setDomainForZone = setDomainForZone;
    window.updateCreateBtnState = updateCreateBtnState;
    window.syncSelectedIds = syncSelectedIds;
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
function onZoneDomainSelected(masterZoneId) {
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
        }
        
        // Populate zone file combobox for the selected domain (without auto-selecting)
        populateZoneFileCombobox(masterZoneId, null, false);
    } else {
        if (btnNewZoneFile) {
            btnNewZoneFile.disabled = true;
        }
        if (btnEditDomain) {
            btnEditDomain.style.display = 'none';
        }
        
        // Clear zone file combobox
        clearZoneFileSelection();
    }
    
    // Hide combobox list
    const list = document.getElementById('zone-domain-list');
    if (list) {
        list.style.display = 'none';
    }
    
    // Re-render table with filter
    currentPage = 1;
    renderZonesTable();
}

/**
 * Initialize zone file combobox
 * Handles input/focus events and fetches recursive includes when cache is insufficient
 */
async function initZoneFileCombobox() {
    await ensureZonesCache();
    const input = document.getElementById('zone-file-input');
    const list = document.getElementById('zone-file-list');
    const hiddenInput = document.getElementById('zone-file-id');
    if (!input || !list || !hiddenInput) return;
    
    input.readOnly = false;
    input.placeholder = 'Rechercher une zone...';
    
    async function currentComboboxZones() {
        const zones = getFilteredZonesForCombobox() || [];
        
        // If we have a selected master and got 0 or 1 results (master only, no includes),
        // fetch recursive includes from API to populate cache
        if (window.ZONES_SELECTED_MASTER_ID && zones.length <= 1) {
            try {
                const masterId = parseInt(window.ZONES_SELECTED_MASTER_ID, 10);
                const fetched = await fetchZonesForMaster(masterId);
                
                // Merge fetched includes into cache (deduplicate)
                if (!Array.isArray(window.ZONES_ALL)) window.ZONES_ALL = [];
                (fetched || []).forEach(z => {
                    if (!window.ZONES_ALL.find(x => String(x.id) === String(z.id))) {
                        window.ZONES_ALL.push(z);
                    }
                });
                
                // Re-filter after cache update
                return getFilteredZonesForCombobox() || [];
            } catch (e) {
                console.warn('initZoneFileCombobox: fetchZonesForMaster failed', e);
                return zones;
            }
        }
        
        return zones;
    }
    
    // Clone input to remove old event listeners
    const newInput = input.cloneNode(true);
    input.parentNode.replaceChild(newInput, input);
    const inputEl = document.getElementById('zone-file-input');
    
    inputEl.addEventListener('input', async () => {
        const query = inputEl.value.toLowerCase().trim();
        const zones = await currentComboboxZones();
        const filtered = zones.filter(z => 
            (z.name||'').toLowerCase().includes(query) || 
            (z.filename||'').toLowerCase().includes(query)
        );
        
        window.CURRENT_ZONE_LIST = filtered.slice();
        populateComboboxList(list, filtered, (zone) => ({ 
            id: zone.id, 
            text: `${zone.name} (${zone.file_type})` 
        }), (zone) => { 
            onZoneFileSelected(zone.id); 
        });
    });
    
    inputEl.addEventListener('focus', async () => { 
        const zones = await currentComboboxZones();
        window.CURRENT_ZONE_LIST = zones.slice();
        populateComboboxList(list, zones, (zone) => ({ 
            id: zone.id, 
            text: `${zone.name} (${zone.file_type})` 
        }), (zone) => { 
            onZoneFileSelected(zone.id); 
        }); 
    });
    
    inputEl.addEventListener('blur', () => { 
        setTimeout(() => { 
            list.style.display = 'none'; 
        }, window.COMBOBOX_BLUR_DELAY || 200); 
    });
    
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
}

/**
 * Get filtered zones for combobox based on selected domain
 * Uses recursive ancestor-based filtering to include all nested includes
 */
function getFilteredZonesForCombobox() {
    const zonesAll = Array.isArray(window.ZONES_ALL) && window.ZONES_ALL.length
        ? window.ZONES_ALL
        : (Array.isArray(window.ALL_ZONES) ? window.ALL_ZONES : []);

    if (!window.ZONES_SELECTED_MASTER_ID) {
        const includeZones = zonesAll.filter(z => z.file_type === 'include');
        return [...allMasters, ...includeZones];
    }

    const masterId = parseInt(window.ZONES_SELECTED_MASTER_ID, 10);
    const masterZone = allMasters.find(m => parseInt(m.id, 10) === masterId);
    
    // Recursive ancestor-based filter: include all zones whose ancestor chain contains masterId
    const includeZones = zonesAll.filter(zone => {
        if (zone.file_type !== 'include') return false;
        
        // Check if this zone's ancestor chain contains the master
        let currentZone = zone;
        let iterations = 0;
        const maxIterations = 50; // Safety limit to prevent infinite loops
        
        while (currentZone && iterations < maxIterations) {
            iterations++;
            const parentId = parseInt(currentZone.parent_id || 0, 10);
            
            if (parentId === masterId) {
                return true; // Found the master in the ancestor chain
            }
            
            if (parentId === 0 || !parentId) {
                break; // No more parents
            }
            
            // Find the parent zone in the cache
            currentZone = zonesAll.find(z => parseInt(z.id, 10) === parentId) ||
                         allMasters.find(m => parseInt(m.id, 10) === parentId);
        }
        
        return false;
    });
    
    return masterZone ? [masterZone, ...includeZones] : includeZones;
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

        // Try to get recursive includes from the cache first using ancestor-based filter
        let includeZones = (window.ZONES_ALL || []).filter(zone => {
            if (zone.file_type !== 'include') return false;
            
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

        // If cache is empty or incomplete for this master, fetch from API
        if (!includeZones || includeZones.length === 0) {
            try {
                const fetched = await fetchZonesForMaster(masterId);
                includeZones = fetched || [];
                
                // Merge fetched includes into cache to keep it up-to-date (deduplicate)
                if (!Array.isArray(window.ZONES_ALL)) window.ZONES_ALL = [];
                includeZones.forEach(z => {
                    if (!window.ZONES_ALL.find(x => String(x.id) === String(z.id))) {
                        window.ZONES_ALL.push(z);
                    }
                });
            } catch (e) {
                console.warn('populateZoneFileCombobox: fetchZonesForMaster failed', e);
                includeZones = includeZones || [];
            }
        }

        const input = document.getElementById('zone-file-input');
        const hiddenInput = document.getElementById('zone-file-id');
        const listEl = document.getElementById('zone-file-list');
        if (!input) return;

        // Build the items list: master (if present) + all recursive includes
        const items = masterZone ? [masterZone, ...includeZones] : includeZones;

        // Keep CURRENT_ZONE_LIST in sync with what's shown in combobox
        window.CURRENT_ZONE_LIST = items.slice();

        // Populate the visible list so user sees updated options
        // Don't show the list automatically when autoSelect is false
        if (listEl) {
            populateComboboxList(listEl, items, z => ({ id: z.id, text: `${z.name} (${z.file_type})` }), (z) => { onZoneFileSelected(z.id); }, autoSelect);
            // Explicitly ensure list is hidden when autoSelect is false
            if (!autoSelect) {
                listEl.style.display = 'none';
                listEl.setAttribute('aria-hidden', 'true');
            }
        }

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
                    const selectedZone = includeZones.find(z => parseInt(z.id, 10) === selectedId);
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
    } catch (error) {
        console.error('Failed to populate zone file combobox:', error);
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
            
            // Update master ID - if this is an include, find its parent
            if (zone.file_type === 'include' && zone.parent_id) {
                const parentId = parseInt(zone.parent_id, 10);
                if (!isNaN(parentId)) {
                    window.ZONES_SELECTED_MASTER_ID = parentId;
                    window.selectedDomainId = parentId;
                    
                    // Update domain combobox text
                    const parentZone = allMasters.find(m => parseInt(m.id, 10) === parentId);
                    if (parentZone && domainInput) {
                        domainInput.value = parentZone.domain;
                    }
                }
            } else if (zone.file_type === 'master') {
                // This is a master zone
                window.ZONES_SELECTED_MASTER_ID = zoneFileId;
                window.selectedDomainId = zoneFileId;
                
                // Update domain combobox text
                if (zone.domain && domainInput) {
                    domainInput.value = zone.domain;
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
function resetZoneDomainSelection() {
    onZoneDomainSelected(null);
    clearZoneFileSelection();
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
 * 1. If ZONES_SELECTED_ZONEFILE_ID => show rows with parent_id == zonefileId
 * 2. Else if ZONES_SELECTED_MASTER_ID => show rows with parent_id == masterId
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
    
    // Filter by selection precedence
    if (window.ZONES_SELECTED_ZONEFILE_ID) {
        // Show only includes that are children of the selected zone file
        const selectedZoneFileId = parseInt(window.ZONES_SELECTED_ZONEFILE_ID, 10);
        filteredZones = filteredZones.filter(zone => {
            const parentId = parseInt(zone.parent_id, 10);
            return !isNaN(parentId) && parentId === selectedZoneFileId;
        });
    } else if (window.ZONES_SELECTED_MASTER_ID) {
        // Show only includes that are children of the selected master
        const selectedMasterId = parseInt(window.ZONES_SELECTED_MASTER_ID, 10);
        filteredZones = filteredZones.filter(zone => {
            const parentId = parseInt(zone.parent_id, 10);
            return !isNaN(parentId) && parentId === selectedMasterId;
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

        if (typeof populateZoneIncludes === 'function') try { await populateZoneIncludes(zone.id); } catch (e) {}
        
        // Store current zone ID and data (maintain existing functionality)
        currentZoneId = zoneId;
        currentZone = zone;
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
        const response = await zoneApiCall('list_zones', { 
            params: { 
                status: 'active',
                per_page: 100 
            } 
        });
        
        if (response.success) {
            const select = document.getElementById('zoneParent');
            select.innerHTML = '<option value="">Aucun parent</option>';
            
            // Filter out the current zone itself
            const zones = response.data.filter(z => z.id != currentZone.id);
            
            zones.forEach(zone => {
                const option = document.createElement('option');
                option.value = zone.id;
                option.textContent = `${zone.name} (${zone.file_type})`;
                if (zone.id == currentParentId) {
                    option.selected = true;
                }
                select.appendChild(option);
            });
        }
    } catch (error) {
        console.error('Failed to load parent options:', error);
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
    const inputs = ['zoneName', 'zoneFilename', 'zoneDirectory', 'zoneStatus', 'zoneContent', 'zoneParent'];
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
        
        // Add domain field only for master zones
        if (currentZone.file_type === 'master') {
            data.domain = document.getElementById('zoneDomain').value || null;
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
 * @param {number} parentId - Optional parent master zone ID (defaults to currently selected)
 */
async function openCreateIncludeModal(parentId) {
    const masterId = parentId || window.ZONES_SELECTED_MASTER_ID;
    
    if (!masterId) {
        showError('Veuillez sélectionner un domaine d\'abord');
        return;
    }
    
    try {
        // Clear any previous errors
        clearModalError('includeCreate');
        
        // Fetch the master zone data
        const response = await zoneApiCall('get_zone', { params: { id: masterId } });
        if (!response || !response.data) {
            showError('Impossible de charger les données du domaine');
            return;
        }
        
        const masterZone = response.data;
        
        // Store master ID in hidden field
        document.getElementById('include-domain-id').value = masterId;
        document.getElementById('include-parent-zone-id').value = masterId;
        
        // Prefill domain field (disabled)
        const domainField = document.getElementById('include-domain');
        if (domainField) {
            domainField.value = masterZone.domain || masterZone.name || '-';
        }
        
        // Update modal titles
        const domainTitle = document.getElementById('include-modal-domain');
        const fileTitle = document.getElementById('include-modal-title');
        if (domainTitle) {
            domainTitle.textContent = masterZone.domain || masterZone.name || '-';
        }
        if (fileTitle) {
            fileTitle.textContent = 'Nouveau fichier de zone';
        }
        
        // Clear input fields (creation mode)
        document.getElementById('include-name').value = '';
        document.getElementById('include-filename').value = '';
        document.getElementById('include-directory').value = '';
        
        // Populate parent combobox with domain's zones (master should be default)
        await populateIncludeParentCombobox(masterZone.domain, masterId);
        
        // Show modal
        const modal = document.getElementById('include-create-modal');
        modal.style.display = 'block';
        modal.classList.add('open');
        
        // Call centering helper if available
        if (typeof window.ensureModalCentered === 'function') {
            window.ensureModalCentered(modal);
        }
    } catch (error) {
        console.error('Failed to open create include modal:', error);
        showError('Erreur lors de l\'ouverture du modal: ' + error.message);
    }
}

/**
 * Populate parent combobox with zones for the selected domain
 * @param {string} domain - Domain name
 * @param {number} defaultParentId - ID of the master zone to preselect
 */
async function populateIncludeParentCombobox(domain, defaultParentId) {
    try {
        // Fetch all active zones (both master and includes) for this domain
        const response = await zoneApiCall('list_zones', {
            params: {
                status: 'active',
                per_page: 100
            }
        });
        
        if (!response.success) {
            console.error('Failed to load zones for parent combobox');
            return;
        }
        
        // Filter zones that match the domain
        const zones = response.data.filter(zone => {
            // For master zones, match by domain field
            if (zone.file_type === 'master' && zone.domain === domain) {
                return true;
            }
            // For includes, check if their parent has the same domain
            if (zone.file_type === 'include' && zone.parent_id == defaultParentId) {
                return true;
            }
            return false;
        });
        
        // Setup combobox
        const input = document.getElementById('include-parent-input');
        const list = document.getElementById('include-parent-list');
        const hiddenField = document.getElementById('include-parent-zone-id');
        
        if (!input || !list || !hiddenField) return;
        
        // Find default master zone
        const defaultZone = zones.find(z => z.id == defaultParentId);
        if (defaultZone) {
            input.value = `${defaultZone.name} (${defaultZone.file_type})`;
            hiddenField.value = defaultParentId;
        }
        
        // Remove old event listeners by cloning the input element
        const newInput = input.cloneNode(true);
        input.parentNode.replaceChild(newInput, input);
        const inputEl = document.getElementById('include-parent-input'); // Get the new reference
        
        // Input event - filter zones and show list
        inputEl.addEventListener('input', () => {
            const query = inputEl.value.toLowerCase().trim();
            const filtered = zones.filter(z => 
                z.name.toLowerCase().includes(query) || 
                z.filename.toLowerCase().includes(query)
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
            populateComboboxList(list, zones, (zone) => ({
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
            }
        });
    } catch (error) {
        console.error('Failed to populate parent combobox:', error);
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
        
        // Validate name field (required only, no format validation)
        if (!name) {
            showModalError('includeCreate', 'Le Nom de la zone est requis.');
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
        
        // Validate zone name: REQUIRED only (no format validation)
        if (!name) {
            showModalError('createZone', 'Le Nom de la zone est requis.');
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
        
        // Prepare data for API call
        const data = {
            name: name,
            filename: filename,
            file_type: 'master', // Always create as master from "Nouveau domaine" button
            content: '', // Empty content for new master zones - content omitted
            domain: domain || null,
            directory: directory
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

// Initialize on DOM ready
if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', initZonesPage);
} else {
    // DOM already loaded, init immediately
    initZonesPage();
}
