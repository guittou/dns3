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
    const AUTOFILL_HIGHLIGHT_COLOR = '#fff7d6'; // Light cream color for autofill visual feedback
    const AUTOFILL_HIGHLIGHT_DURATION = 900; // Duration in ms for autofill highlight
    const AUTOFILL_TRANSITION_DURATION = 220; // Duration in ms for autofill highlight transition

    /**
     * Modal state: 'choose-type' or 'fill-fields'
     */
    let modalState = 'choose-type';
    
    /**
     * Per-type temporary values storage
     */
    let tempRecordValues = {
        'A': { name: '', ttl: '', value: '', ticket_ref: '', requester: '', comment: '' },
        'AAAA': { name: '', ttl: '', value: '', ticket_ref: '', requester: '', comment: '' },
        'CNAME': { name: '', ttl: '', value: '', ticket_ref: '', requester: '', comment: '' },
        'PTR': { name: '', ttl: '', value: '', ticket_ref: '', requester: '', comment: '' },
        'TXT': { name: '', ttl: '', value: '', ticket_ref: '', requester: '', comment: '' },
        'MX': { name: '', ttl: '', value: '', priority: '', ticket_ref: '', requester: '', comment: '' },
        'NS': { name: '', ttl: '', value: '', ticket_ref: '', requester: '', comment: '' },
        'DNAME': { name: '', ttl: '', value: '', ticket_ref: '', requester: '', comment: '' },
        'SRV': { name: '', ttl: '', priority: '', weight: '', port: '', srv_target: '', ticket_ref: '', requester: '', comment: '' },
        'CAA': { name: '', ttl: '', caa_flag: '0', caa_tag: 'issue', caa_value: '', ticket_ref: '', requester: '', comment: '' },
        'TLSA': { name: '', ttl: '', tlsa_usage: '3', tlsa_selector: '1', tlsa_matching: '1', tlsa_data: '', ticket_ref: '', requester: '', comment: '' },
        'SSHFP': { name: '', ttl: '', sshfp_algo: '1', sshfp_type: '2', sshfp_fingerprint: '', ticket_ref: '', requester: '', comment: '' },
        'NAPTR': { name: '', ttl: '', naptr_order: '', naptr_pref: '', naptr_flags: '', naptr_service: '', naptr_regexp: '', naptr_replacement: '.', ticket_ref: '', requester: '', comment: '' },
        'SVCB': { name: '', ttl: '', svc_priority: '1', svc_target: '.', svc_params: '', ticket_ref: '', requester: '', comment: '' },
        'HTTPS': { name: '', ttl: '', svc_priority: '1', svc_target: '.', svc_params: '', ticket_ref: '', requester: '', comment: '' },
        'LOC': { name: '', ttl: '', loc_latitude: '', loc_longitude: '', loc_altitude: '', ticket_ref: '', requester: '', comment: '' },
        'RP': { name: '', ttl: '', rp_mbox: '', rp_txt: '.', ticket_ref: '', requester: '', comment: '' },
        'SPF': { name: '', ttl: '', value: '', ticket_ref: '', requester: '', comment: '' },
        'DKIM': { name: '', ttl: '', value: '', ticket_ref: '', requester: '', comment: '' },
        'DMARC': { name: '', ttl: '', value: '', ticket_ref: '', requester: '', comment: '' }
    };
    
    /**
     * Currently selected record type (for create flow)
     */
    let currentRecordType = null;

    /**
     * Required fields by DNS record type
     */
    const REQUIRED_BY_TYPE = {
        'A': ['name', 'address_ipv4'],
        'AAAA': ['name', 'address_ipv6'],
        'CNAME': ['name', 'cname_target'],
        'PTR': ['name', 'ptrdname'],
        'TXT': ['name', 'txt'],
        'MX': ['name', 'mx_target'],
        'NS': ['name', 'ns_target'],
        'DNAME': ['name', 'dname_target'],
        'SRV': ['name', 'srv_target', 'port'],
        'CAA': ['name', 'caa_tag', 'caa_value'],
        'TLSA': ['name', 'tlsa_usage', 'tlsa_selector', 'tlsa_matching', 'tlsa_data'],
        'SSHFP': ['name', 'sshfp_algo', 'sshfp_type', 'sshfp_fingerprint'],
        'NAPTR': ['name', 'naptr_order', 'naptr_pref'],
        'SVCB': ['name', 'svc_priority', 'svc_target'],
        'HTTPS': ['name', 'svc_priority', 'svc_target'],
        'LOC': ['name', 'loc_latitude', 'loc_longitude'],
        'RP': ['name', 'rp_mbox', 'rp_txt'],
        'SPF': ['name', 'txt'],
        'DKIM': ['name', 'txt'],
        'DMARC': ['name', 'txt']
    };

    /**
     * Show error message in modal banner
     * Defensive implementation: uses window.__showModalError if available, otherwise DOM fallback
     * @param {string} modalKey - Modal identifier (e.g., 'dns')
     * @param {string} message - Error message to display
     * @param {string} fieldId - Optional field ID to focus after showing error
     */
    function showModalError(modalKey, message, fieldId) {
        try {
            // Try to use window.__showModalError if available
            if (typeof window.__showModalError === 'function') {
                window.__showModalError(modalKey, message, fieldId);
                return;
            }
            
            // Fallback: direct DOM manipulation
            const banner = document.getElementById(modalKey + 'ModalErrorBanner');
            const msgEl = document.getElementById(modalKey + 'ModalErrorMessage');
            
            if (!banner || !msgEl) {
                console.warn('[showModalError] Banner elements not found for modal:', modalKey);
                // Fallback to page-level message
                showMessage('Erreur : ' + (message || 'Une erreur est survenue'), 'error');
                return;
            }
            
            msgEl.textContent = message || "Erreur de validation : vérifiez les champs du formulaire.";
            banner.style.display = 'block';
            banner.focus();
            
            // If fieldId provided, try to focus it after a short delay
            if (fieldId) {
                setTimeout(() => {
                    const field = document.getElementById(fieldId);
                    if (field) {
                        field.focus();
                        // Add visual indicator
                        field.classList.add('error-field');
                        setTimeout(() => field.classList.remove('error-field'), 2000);
                    }
                }, 100);
            }
        } catch (e) {
            console.error('[showModalError] Failed:', e);
            // Final fallback
            showMessage('Erreur : ' + (message || 'Une erreur est survenue'), 'error');
        }
    }

    /**
     * Clear error banner in modal
     * Defensive implementation: uses window.__clearModalError if available, otherwise DOM fallback
     * @param {string} modalKey - Modal identifier (e.g., 'dns')
     */
    function clearModalError(modalKey) {
        try {
            // Try to use window.__clearModalError if available
            if (typeof window.__clearModalError === 'function') {
                window.__clearModalError(modalKey);
                return;
            }
            
            // Fallback: direct DOM manipulation
            const banner = document.getElementById(modalKey + 'ModalErrorBanner');
            const msgEl = document.getElementById(modalKey + 'ModalErrorMessage');
            
            if (!banner) return;
            
            banner.style.display = 'none';
            if (msgEl) msgEl.textContent = '';
        } catch (e) {
            console.error('[clearModalError] Failed:', e);
        }
    }

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
     * Normalize hostname by adding trailing dot if missing (for FQDN)
     * @param {string} hostname - The hostname to normalize
     * @returns {string} Normalized hostname with trailing dot
     */
    function normalizeHostname(hostname) {
        if (!hostname || hostname === '' || hostname === '.') {
            return hostname || '';
        }
        // Trim whitespace
        hostname = hostname.trim();
        // Add trailing dot if not present (except for @ and relative names without dots)
        if (hostname !== '@' && hostname.includes('.') && !hostname.endsWith('.')) {
            return hostname + '.';
        }
        return hostname;
    }

    /**
     * Check if a string is a valid hostname (FQDN)
     * @param {string} str - The string to check
     * @returns {boolean} True if valid hostname
     */
    function isValidHostname(str) {
        if (!str || str === '.') return true;
        // Robust FQDN validation: enforces proper label structure (1-63 chars per label),
        // prevents consecutive dots, and ensures labels don't start/end with hyphens
        const hostnameRegex = /^[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*\.?$/;
        return hostnameRegex.test(str);
    }

    /**
     * Check if a value is a valid integer within a range
     * @param {any} value - The value to check
     * @param {number} min - Minimum value (inclusive)
     * @param {number} max - Maximum value (inclusive)
     * @returns {boolean} True if valid integer in range
     */
    function isValidIntRange(value, min, max) {
        const num = parseInt(value, 10);
        return !isNaN(num) && num >= min && num <= max;
    }

    /**
     * Check if a string is a valid hex string
     * @param {string} str - The string to check
     * @returns {boolean} True if valid hex string
     */
    function isValidHex(str) {
        if (!str) return false;
        return /^[0-9A-Fa-f]+$/.test(str);
    }

    /**
     * Validate payload data for a specific record type
     * @param {string} recordType - The DNS record type
     * @param {Object} data - The payload data to validate
     * @returns {Object} { valid: boolean, error: string|null }
     */
    function validatePayloadForType(recordType, data) {
        const requiredFields = REQUIRED_BY_TYPE[recordType] || ['name'];
        
        // Check required fields (except for numeric fields that can be 0)
        for (const field of requiredFields) {
            const value = data[field];
            // Allow 0 as valid value for numeric fields
            const isNumericField = ['priority', 'port', 'weight', 'svc_priority', 'naptr_order', 'naptr_pref', 'caa_flag', 'tlsa_usage', 'tlsa_selector', 'tlsa_matching', 'sshfp_algo', 'sshfp_type'].includes(field);
            if (isNumericField) {
                if (value === undefined || value === null || value === '') {
                    return { valid: false, error: `Le champ "${field}" est requis pour le type ${recordType}` };
                }
            } else {
                if (!value || String(value).trim() === '') {
                    return { valid: false, error: `Le champ "${field}" est requis pour le type ${recordType}` };
                }
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
                if (!isValidHostname(data.cname_target)) {
                    return { valid: false, error: 'La cible CNAME doit être un nom d\'hôte valide' };
                }
                break;
                
            case 'PTR':
                if (!isValidHostname(data.ptrdname)) {
                    return { valid: false, error: 'Le nom PTR doit être un nom d\'hôte valide' };
                }
                break;
                
            case 'TXT':
            case 'SPF':
            case 'DKIM':
            case 'DMARC':
                if (!data.txt || data.txt.trim().length === 0) {
                    return { valid: false, error: 'Le contenu du champ TXT ne peut pas être vide' };
                }
                break;
                
            case 'NS':
                if (isIPv4(data.ns_target) || isIPv6(data.ns_target)) {
                    return { valid: false, error: 'La cible NS ne peut pas être une adresse IP (doit être un nom d\'hôte)' };
                }
                if (!isValidHostname(data.ns_target)) {
                    return { valid: false, error: 'La cible NS doit être un nom d\'hôte valide' };
                }
                break;
                
            case 'DNAME':
                if (!isValidHostname(data.dname_target)) {
                    return { valid: false, error: 'La cible DNAME doit être un nom d\'hôte valide' };
                }
                break;
                
            case 'MX':
                if (isIPv4(data.mx_target) || isIPv6(data.mx_target)) {
                    return { valid: false, error: 'La cible MX ne peut pas être une adresse IP (doit être un nom d\'hôte)' };
                }
                if (!isValidHostname(data.mx_target)) {
                    return { valid: false, error: 'La cible MX doit être un nom d\'hôte valide' };
                }
                if (!isValidIntRange(data.priority, 0, 65535)) {
                    return { valid: false, error: 'La priorité MX doit être un entier entre 0 et 65535' };
                }
                break;
                
            case 'SRV':
                if (!isValidIntRange(data.priority, 0, 65535)) {
                    return { valid: false, error: 'La priorité SRV doit être un entier entre 0 et 65535' };
                }
                if (!isValidIntRange(data.weight, 0, 65535)) {
                    return { valid: false, error: 'Le poids SRV doit être un entier entre 0 et 65535' };
                }
                if (!isValidIntRange(data.port, 0, 65535)) {
                    return { valid: false, error: 'Le port SRV doit être un entier entre 0 et 65535' };
                }
                if (!isValidHostname(data.srv_target)) {
                    return { valid: false, error: 'La cible SRV doit être un nom d\'hôte valide' };
                }
                break;
                
            case 'CAA':
                if (!isValidIntRange(data.caa_flag, 0, 255)) {
                    return { valid: false, error: 'Le flag CAA doit être un entier entre 0 et 255' };
                }
                if (!['issue', 'issuewild', 'iodef'].includes(data.caa_tag)) {
                    return { valid: false, error: 'Le tag CAA doit être issue, issuewild ou iodef' };
                }
                if (!data.caa_value || data.caa_value.trim().length === 0) {
                    return { valid: false, error: 'La valeur CAA ne peut pas être vide' };
                }
                break;
                
            case 'TLSA':
                if (!isValidIntRange(data.tlsa_usage, 0, 3)) {
                    return { valid: false, error: 'L\'usage TLSA doit être entre 0 et 3' };
                }
                if (!isValidIntRange(data.tlsa_selector, 0, 1)) {
                    return { valid: false, error: 'Le sélecteur TLSA doit être 0 ou 1' };
                }
                if (!isValidIntRange(data.tlsa_matching, 0, 2)) {
                    return { valid: false, error: 'Le type de correspondance TLSA doit être entre 0 et 2' };
                }
                if (!isValidHex(data.tlsa_data)) {
                    return { valid: false, error: 'Les données TLSA doivent être une chaîne hexadécimale valide' };
                }
                break;
                
            case 'SSHFP':
                if (!isValidIntRange(data.sshfp_algo, 1, 4)) {
                    return { valid: false, error: 'L\'algorithme SSHFP doit être entre 1 et 4' };
                }
                if (!isValidIntRange(data.sshfp_type, 1, 2)) {
                    return { valid: false, error: 'Le type d\'empreinte SSHFP doit être 1 ou 2' };
                }
                if (!isValidHex(data.sshfp_fingerprint)) {
                    return { valid: false, error: 'L\'empreinte SSHFP doit être une chaîne hexadécimale valide' };
                }
                break;
                
            case 'NAPTR':
                if (!isValidIntRange(data.naptr_order, 0, 65535)) {
                    return { valid: false, error: 'L\'ordre NAPTR doit être un entier entre 0 et 65535' };
                }
                if (!isValidIntRange(data.naptr_pref, 0, 65535)) {
                    return { valid: false, error: 'La préférence NAPTR doit être un entier entre 0 et 65535' };
                }
                break;
                
            case 'SVCB':
            case 'HTTPS':
                if (!isValidIntRange(data.svc_priority, 0, 65535)) {
                    return { valid: false, error: 'La priorité SVCB/HTTPS doit être un entier entre 0 et 65535' };
                }
                if (data.svc_target !== '.' && !isValidHostname(data.svc_target)) {
                    return { valid: false, error: 'La cible SVCB/HTTPS doit être un nom d\'hôte valide ou "."' };
                }
                break;
                
            case 'LOC':
                if (!data.loc_latitude || data.loc_latitude.trim().length === 0) {
                    return { valid: false, error: 'La latitude LOC est requise' };
                }
                if (!data.loc_longitude || data.loc_longitude.trim().length === 0) {
                    return { valid: false, error: 'La longitude LOC est requise' };
                }
                break;
                
            case 'RP':
                if (!data.rp_mbox || data.rp_mbox.trim().length === 0) {
                    return { valid: false, error: 'Le mailbox RP est requis' };
                }
                if (!data.rp_txt || data.rp_txt.trim().length === 0) {
                    return { valid: false, error: 'Le domaine TXT RP est requis' };
                }
                break;
        }
        
        return { valid: true, error: null };
    }

    /**
     * Check if user can write to a record's zone based on API response
     * @param {Object} record - Record object with can_write field from API
     * @returns {boolean} True if user can write (modify/delete) the record
     */
    function canWriteRecord(record) {
        return record && (record.can_write === 1 || record.can_write === true);
    }

    /**
     * Helper: hide a combobox list related to an input (robust selector + aria/class cleanup)
     */
    function hideComboboxListForInput(input) {
        if (!input || !input.id) return;
        // Try to find the associated list element using multiple strategies
        let list = document.getElementById(input.id + '-list')
                || input.parentElement?.querySelector('.combobox-list');
        if (list) {
            list.style.display = 'none';
            list.classList.remove('open', 'visible', 'show');
            try { 
                list.setAttribute('aria-hidden', 'true'); 
            } catch(e) { 
                // Silently ignore ARIA errors for older browsers
            }
        }
        try { 
            input.setAttribute('aria-expanded', 'false'); 
        } catch(e) { 
            // Silently ignore ARIA errors for older browsers
        }
        if (document.activeElement === input) input.blur();
    }

    /**
     * Helper: hide all combobox lists on the page (failsafe)
     * Uses broad selectors intentionally to catch all potential combobox lists
     */
    function hideAllComboboxLists() {
        // Broad selector is intentional - catches all combobox lists including dynamic ones
        document.querySelectorAll('.combobox-list, .dns-combobox-list, [id$="-list"]').forEach(list => {
            try {
                list.style.display = 'none';
                list.classList.remove('open', 'visible', 'show');
                list.setAttribute('aria-hidden', 'true');
            } catch (e) {
                // Silently ignore errors for elements that don't support these operations
            }
        });

        ['dns-domain-input', 'record-zone-input', 'dns-zone-input', 'dns-domain-search'].forEach(id => {
            const el = document.getElementById(id);
            if (el) {
                try { 
                    el.setAttribute('aria-expanded', 'false'); 
                } catch(e) {
                    // Silently ignore ARIA errors for older browsers
                }
                if (document.activeElement === el) el.blur();
            }
        });
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
            
            // Read response body once as text, then parse JSON
            const text = await response.text();
            
            let data;
            try {
                data = JSON.parse(text);
            } catch (jsonError) {
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
            
            // Read response body once as text, then parse JSON
            const text = await response.text();
            
            let data;
            try {
                data = JSON.parse(text);
            } catch (jsonError) {
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
     * Loads all available domains from masters and makes the combobox interactive for filtering
     */
    async function initDomainCombobox() {
        try {
            // Load all domains from master zones
            const result = await apiCall('list_domains');
            allDomains = result.data || [];
            
            const input = document.getElementById('dns-domain-input');
            const list = document.getElementById('dns-domain-list');
            const zoneFileIdInput = document.getElementById('dns-zone-file-id');
            const domainIdInput = document.getElementById('dns-domain-id');
            
            if (!input || !list) return;
            
            // Make input interactive
            input.readOnly = false;
            input.placeholder = 'Rechercher un domaine...';
            input.title = 'Sélectionnez un domaine pour filtrer les zones';
            
            // Input event - filter domains and show list
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
            
            // Focus - show all domains
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
     * Enable or disable the DNS zone combobox
     * @param {boolean} enabled - Whether to enable the combobox
     */
    function setDnsZoneComboboxEnabled(enabled) {
        const inputEl = document.getElementById('dns-zone-input');
        const hiddenEl = document.getElementById('dns-zone-id');
        
        if (!inputEl) {
            console.warn('[setDnsZoneComboboxEnabled] dns-zone-input not found');
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
            const listEl = document.getElementById('dns-zone-list');
            if (listEl) {
                listEl.style.display = 'none';
            }
        }
        
        console.debug('[setDnsZoneComboboxEnabled] DNS zone combobox', enabled ? 'enabled' : 'disabled');
    }

    /**
     * Initialize zone combobox with server-first search using unified helper
     */
    async function initZoneCombobox() {
        try {
            // Load all active zones for cache (backward compatibility)
            const result = await zoneApiCall('list_zones', { status: 'active' });
            allZones = (result.data || []).filter(z => z.file_type === 'master' || z.file_type === 'include');
            ALL_ZONES = [...allZones];  // Keep a copy of all zones
            CURRENT_ZONE_LIST = [...allZones];  // Initialize current list
            
            const inputEl = document.getElementById('dns-zone-input');
            const listEl = document.getElementById('dns-zone-list');
            const hiddenEl = document.getElementById('dns-zone-id');
            
            if (!inputEl || !listEl || !hiddenEl) {
                console.warn('[DNS initZoneCombobox] Required elements not found');
                return;
            }
            
            // Start with combobox disabled if no domain selected
            if (!selectedDomainId) {
                setDnsZoneComboboxEnabled(false);
            }
            
            // Use the unified initServerSearchCombobox helper from zone-files.js
            if (typeof window.initServerSearchCombobox === 'function') {
                console.debug('[DNS initZoneCombobox] Using unified initServerSearchCombobox helper');
                
                window.initServerSearchCombobox({
                    inputEl: inputEl,
                    listEl: listEl,
                    hiddenEl: hiddenEl,
                    file_type: '', // No filter, show all types (master + include)
                    onSelectItem: (zone) => {
                        // Call selectZone to maintain existing behavior
                        if (zone && zone.id) {
                            selectZone(zone.id, zone.name || zone.filename, zone.file_type);
                        }
                    },
                    minCharsForServer: 2,
                    blurDelay: COMBOBOX_BLUR_DELAY
                });
                
                console.debug('[DNS initZoneCombobox] Initialized using unified helper');
                return;
            }
            
            // Fallback: if unified helper not available, use inline implementation (backward compatibility)
            console.warn('[DNS initZoneCombobox] initServerSearchCombobox not found, using fallback implementation');
            
            // Input event - server search for queries ≥2 chars, client filter otherwise
            inputEl.addEventListener('input', async () => {
                const query = inputEl.value.toLowerCase().trim();
                
                // Server-first strategy for queries ≥2 chars
                if (query.length >= 2) {
                    console.debug('[DNS initZoneCombobox] Using server search for query:', query);
                    
                    // Use window.serverSearchZones if available (from zone-files.js)
                    if (typeof window.serverSearchZones === 'function') {
                        try {
                            const serverResults = await window.serverSearchZones(query, { limit: 100 });
                            
                            // Filter by selected master if one is selected
                            let filtered = serverResults;
                            if (window.ZONES_SELECTED_MASTER_ID && typeof window.isZoneInMasterTree === 'function') {
                                const masterId = parseInt(window.ZONES_SELECTED_MASTER_ID, 10);
                                filtered = serverResults.filter(z => window.isZoneInMasterTree(z, masterId, serverResults));
                            }
                            
                            populateComboboxList(listEl, filtered, (zone) => ({
                                id: zone.id,
                                text: `${zone.name} (${zone.file_type})`
                            }), (zone) => {
                                selectZone(zone.id, zone.name, zone.file_type);
                            });
                            return;
                        } catch (err) {
                            console.warn('[DNS initZoneCombobox] Server search failed, fallback to client:', err);
                            // Fall through to client filtering
                        }
                    }
                }
                
                // Client filtering for short queries or when server search unavailable/failed
                const sourceList = window.CURRENT_ZONE_LIST || CURRENT_ZONE_LIST || allZones;
                const filtered = sourceList.filter(z => 
                    z.name.toLowerCase().includes(query) || 
                    z.filename.toLowerCase().includes(query)
                );
                
                populateComboboxList(listEl, filtered, (zone) => ({
                    id: zone.id,
                    text: `${zone.name} (${zone.file_type})`
                }), (zone) => {
                    selectZone(zone.id, zone.name, zone.file_type);
                });
            });
            
            // Focus - show CURRENT_ZONE_LIST
            inputEl.addEventListener('focus', async () => {
                const sourceList = window.CURRENT_ZONE_LIST || CURRENT_ZONE_LIST || allZones;
                populateComboboxList(listEl, sourceList, (zone) => ({
                    id: zone.id,
                    text: `${zone.name} (${zone.file_type})`
                }), (zone) => {
                    selectZone(zone.id, zone.name, zone.file_type);
                });
            });
            
            // Blur - hide list (with delay to allow click)
            inputEl.addEventListener('blur', () => {
                setTimeout(() => {
                    listEl.style.display = 'none';
                }, COMBOBOX_BLUR_DELAY);
            });
            
            // Escape key - close list
            inputEl.addEventListener('keydown', (e) => {
                if (e.key === 'Escape') {
                    listEl.style.display = 'none';
                    inputEl.blur();
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
     * Sets domain display and zone_file_id (domain_id is now zone_file_id)
     */
    function selectDomain(zoneFileId, domainName) {
        selectedDomainId = zoneFileId; // Use zone_file_id as domain_id
        
        const input = document.getElementById('dns-domain-input');
        const zoneFileIdInput = document.getElementById('dns-zone-file-id');
        const domainIdInput = document.getElementById('dns-domain-id'); // Backward compat
        const list = document.getElementById('dns-domain-list');
        
        if (input) input.value = domainName || '';
        if (zoneFileIdInput) zoneFileIdInput.value = zoneFileId || '';
        if (domainIdInput) domainIdInput.value = zoneFileId || ''; // Map to zone_file_id
        if (list) list.style.display = 'none';
        
        // When domain is selected (via zone), filter zones
        if (zoneFileId) {
            populateZoneComboboxForDomain(zoneFileId);
            
            // Enable DNS zone combobox after population
            if (typeof setDnsZoneComboboxEnabled === 'function') {
                setDnsZoneComboboxEnabled(true);
            }
        } else {
            // Disable DNS zone combobox when no domain selected
            if (typeof setDnsZoneComboboxEnabled === 'function') {
                setDnsZoneComboboxEnabled(false);
            }
        }
        
        // Update create button state
        updateCreateBtnState();
        
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
     * Uses zone_api.php?action=list_zone_files&domain_id=... which applies ACL filtering for non-admin users
     * Now uses shared makeOrderedZoneList helper for consistent ordering
     */
    async function populateZoneComboboxForDomain(domainIdOrZoneId) {
        try {
            // Use the new list_zone_files endpoint from zone_api.php
            // This applies ACL filtering for non-admin users
            let result;
            try {
                result = await zoneApiCall('list_zone_files', { domain_id: domainIdOrZoneId });
            } catch (e) {
                console.warn('[populateZoneComboboxForDomain] list_zone_files failed, falling back:', e);
                // Fallback to old API (list_zones_by_domain) if list_zone_files is not available
                try {
                    result = await apiCall('list_zones_by_domain', { zone_id: domainIdOrZoneId });
                } catch (e2) {
                    result = await apiCall('list_zones_by_domain', { domain_id: domainIdOrZoneId });
                }
            }
            
            const zones = result.data || [];
            
            // Find the master zone from the zones array (it should be the one with file_type='master')
            // The domainIdOrZoneId parameter is typically the master zone ID
            const masterZone = zones.find(z => 
                (z.file_type || '').toLowerCase().trim() === 'master' && 
                parseInt(z.id, 10) === parseInt(domainIdOrZoneId, 10)
            );
            
            // Use shared helper for consistent ordering: master first, then includes sorted A-Z
            // Pass the master ID if found, otherwise pass the domainIdOrZoneId as-is
            const masterId = masterZone ? masterZone.id : domainIdOrZoneId;
            const orderedZones = window.makeOrderedZoneList(zones, masterId);
            
            // Update CURRENT_ZONE_LIST with ordered zones
            CURRENT_ZONE_LIST = orderedZones;
            
            // DO NOT open the combobox list - user must click/focus to see it
            // DO NOT auto-select a zone - zone selection must be explicit
        } catch (error) {
            console.error('Error populating zones for domain:', error);
            CURRENT_ZONE_LIST = [];
        }
    }

    /**
     * Set domain for a given zone (auto-complete domain based on zone)
     * Now reads from zone_files.domain field directly
     * For include zones, uses parent_domain from get_zone response
     * Falls back to get_domain_for_zone if parent_domain is empty
     */
    async function setDomainForZone(zoneId) {
        try {
            const res = await zoneApiCall('get_zone', { id: zoneId });
            const zone = res && res.data ? res.data : null;
            if (!zone) {
                // clear defensively
                const input = document.getElementById('dns-domain-input'); if (input) input.value = '';
                const zoneHidden = document.getElementById('dns-zone-file-id') || document.getElementById('dns-zone-id'); if (zoneHidden) zoneHidden.value = '';
                const legacy = document.getElementById('dns-domain-id'); if (legacy) legacy.value = '';
                const zoneInput = document.getElementById('dns-zone-input'); if (zoneInput) zoneInput.value = '';
                const recordZoneFile = document.getElementById('record-zone-file'); if (recordZoneFile) recordZoneFile.value = '';
                
                // Disable DNS zone combobox
                if (typeof setDnsZoneComboboxEnabled === 'function') {
                    setDnsZoneComboboxEnabled(false);
                }
                return;
            }

            // Calculate domain based on zone type:
            // - For master zones: use zone.domain (no fallback to zone.name)
            // - For include zones: use zone.parent_domain, with fallback to get_domain_for_zone API
            let domainName = '';
            if (zone.file_type === 'master') {
                // Master zone: use domain field directly (can be empty)
                domainName = zone.domain || '';
            } else {
                // Include zone: use parent_domain if available
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

            const domainInput = document.getElementById('dns-domain-input'); if (domainInput) domainInput.value = domainName;
            const zoneHidden = document.getElementById('dns-zone-file-id') || document.getElementById('dns-zone-id'); if (zoneHidden) zoneHidden.value = zone.id || '';
            const legacyDomainId = document.getElementById('dns-domain-id'); if (legacyDomainId) legacyDomainId.value = zone.id || '';

            // Update #dns-zone-input text display
            const zoneInput = document.getElementById('dns-zone-input');
            if (zoneInput) {
                zoneInput.value = `${zone.name} (${zone.file_type})`;
            }

            // Update #record-zone-file select - populate and select the zone
            const recordZoneFile = document.getElementById('record-zone-file');
            if (recordZoneFile) {
                // Check if option exists, if not add it
                let optionExists = false;
                for (let i = 0; i < recordZoneFile.options.length; i++) {
                    if (recordZoneFile.options[i].value == zone.id) {
                        optionExists = true;
                        break;
                    }
                }
                
                if (!optionExists) {
                    const option = document.createElement('option');
                    option.value = zone.id;
                    option.textContent = `${zone.name} (${zone.file_type})`;
                    recordZoneFile.appendChild(option);
                }
                
                recordZoneFile.value = zone.id;
            }

            // ALWAYS call populateZoneComboboxForDomain even if domainName is empty
            // This ensures CURRENT_ZONE_LIST is populated so the zone select shows the zone
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
                            // If no domain, at least include the current zone in the list
                            window.CURRENT_ZONE_LIST = window.ALL_ZONES.filter(z => z.id === zone.id);
                        }
                    }
                }
            }
            
            // Enable DNS zone combobox after population
            if (typeof setDnsZoneComboboxEnabled === 'function') {
                setDnsZoneComboboxEnabled(true);
            }

            if (typeof updateCreateBtnState === 'function') updateCreateBtnState();
        } catch (e) {
            console.error('setDomainForZone error', e);
        }
    }

    /**
     * Update create button state based on zone or domain selection
     * Button is enabled if EITHER a zone file is selected OR a domain is selected
     * 
     * Domain selection is detected via:
     * - selectedDomainId (module-level variable)
     * - dns-domain-id (hidden field for backward compatibility)
     * - dns-domain-input (visible input field value)
     */
    function updateCreateBtnState() {
        const createBtn = document.getElementById('dns-create-btn');
        const zoneId = document.getElementById('dns-zone-id');
        const domainId = document.getElementById('dns-domain-id');
        const domainInput = document.getElementById('dns-domain-input');
        
        if (!createBtn) return;
        
        // Check if zone is selected
        const hasZone = zoneId && zoneId.value && zoneId.value !== '';
        
        // Check if domain is selected (via selectedDomainId module variable, hidden field, or visible input)
        const hasDomain = (selectedDomainId && selectedDomainId !== '') ||
                         (domainId && domainId.value && domainId.value !== '') ||
                         (domainInput && domainInput.value && domainInput.value.trim() !== '');
        
        // Enable if either zone or domain is selected
        createBtn.disabled = !(hasZone || hasDomain);
    }

    /**
     * Reset domain and zone filters
     */
    function resetDomainZoneFilters() {
        // Clear domain selection
        selectedDomainId = null;
        const domainInput = document.getElementById('dns-domain-input');
        const zoneFileIdInput = document.getElementById('dns-zone-file-id');
        const domainIdInput = document.getElementById('dns-domain-id'); // Backward compat
        if (domainInput) domainInput.value = '';
        if (zoneFileIdInput) zoneFileIdInput.value = '';
        if (domainIdInput) domainIdInput.value = '';
        
        // Disable DNS zone combobox when filters are reset
        if (typeof setDnsZoneComboboxEnabled === 'function') {
            setDnsZoneComboboxEnabled(false);
        }
        
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
     * Initialize modal zone file combobox
     * Sets up event handlers for autocomplete behavior matching page-main comboboxes
     */
    async function initModalZoneCombobox() {
        const inputElement = document.getElementById('modal-zonefile-input');
        const hiddenElement = document.getElementById('modal-zonefile-id');
        const listElement = document.getElementById('modal-zonefile-list');
        
        if (!inputElement || !hiddenElement || !listElement) {
            console.warn('[initModalZoneCombobox] Modal combobox elements not found');
            return;
        }
        
        // Input event - filter zones and show list
        inputElement.addEventListener('input', () => {
            const query = inputElement.value.toLowerCase().trim();
            const allZonesJson = inputElement.dataset.allZones || '[]';
            let zones = [];
            
            try {
                zones = JSON.parse(allZonesJson);
            } catch (e) {
                console.error('[initModalZoneCombobox] Failed to parse zones:', e);
                return;
            }
            
            // Filter zones by query
            const filtered = zones.filter(z => 
                z.name.toLowerCase().includes(query) || 
                z.filename?.toLowerCase().includes(query) ||
                (z.file_type && z.file_type.toLowerCase().includes(query))
            );
            
            // Populate the list
            populateComboboxList(listElement, filtered, (zone) => ({
                id: zone.id,
                text: `${zone.name} (${zone.file_type})`
            }), (zone) => {
                // On selection
                inputElement.value = `${zone.name} (${zone.file_type})`;
                hiddenElement.value = zone.id;
                listElement.style.display = 'none';
                
                // Update hidden fields
                const recordZoneFile = document.getElementById('record-zone-file');
                if (recordZoneFile) {
                    recordZoneFile.value = zone.id;
                }
                const dnsZoneFileId = document.getElementById('dns-zone-file-id');
                if (dnsZoneFileId) {
                    dnsZoneFileId.value = zone.id;
                }
                
                // Update domain if setDomainForZone exists
                if (typeof setDomainForZone === 'function') {
                    setDomainForZone(zone.id).catch(err => {
                        console.error('[initModalZoneCombobox] Error setting domain for zone:', err);
                    });
                }
            });
        });
        
        // Focus - show all zones
        inputElement.addEventListener('focus', () => {
            const allZonesJson = inputElement.dataset.allZones || '[]';
            let zones = [];
            
            try {
                zones = JSON.parse(allZonesJson);
            } catch (e) {
                console.error('[initModalZoneCombobox] Failed to parse zones:', e);
                return;
            }
            
            populateComboboxList(listElement, zones, (zone) => ({
                id: zone.id,
                text: `${zone.name} (${zone.file_type})`
            }), (zone) => {
                // On selection
                inputElement.value = `${zone.name} (${zone.file_type})`;
                hiddenElement.value = zone.id;
                listElement.style.display = 'none';
                
                // Update hidden fields
                const recordZoneFile = document.getElementById('record-zone-file');
                if (recordZoneFile) {
                    recordZoneFile.value = zone.id;
                }
                const dnsZoneFileId = document.getElementById('dns-zone-file-id');
                if (dnsZoneFileId) {
                    dnsZoneFileId.value = zone.id;
                }
                
                // Update domain if setDomainForZone exists
                if (typeof setDomainForZone === 'function') {
                    setDomainForZone(zone.id).catch(err => {
                        console.error('[initModalZoneCombobox] Error setting domain for zone:', err);
                    });
                }
            });
        });
        
        // Blur - hide list (with delay to allow click)
        inputElement.addEventListener('blur', () => {
            setTimeout(() => {
                listElement.style.display = 'none';
            }, COMBOBOX_BLUR_DELAY);
        });
        
        // Escape key - close list
        inputElement.addEventListener('keydown', (e) => {
            if (e.key === 'Escape') {
                listElement.style.display = 'none';
                inputElement.blur();
            }
        });
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
            const input = document.getElementById('record-zone-input') || document.getElementById('dns-zone-input');
            try {
                hideComboboxListForInput(input);
                setTimeout(() => { hideAllComboboxLists(); }, 20);
            } catch (e) { /* silent */ }
        } catch (error) {
            console.error('[populateZoneFileSelect] Error:', error);
            // Don't show message to user, just log it
        }
    }

    /**
     * Helper function to get master zone ID from any zone ID
     * Uses cached data (window.ALL_ZONES, window.ZONES_ALL, window.CURRENT_ZONE_LIST) first
     * Falls back to zone_api get_zone if not in cache
     * @param {number|string} zoneId - Zone file ID to check
     * @returns {Promise<number|null>} - Master zone ID or null if not found
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
            allZones
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
                const result = await zoneApiCall('get_zone', { id: zoneIdNum });
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
     * Recursively traverses up the parent chain until finding a zone with parent_id == null
     * Uses caches (CURRENT_ZONE_LIST, ALL_ZONES, ZONES_ALL) first, then falls back to API
     * @param {number|string} zoneId - Zone file ID to start from
     * @returns {Promise<number|null>} - Top master zone ID or null if not found
     */
    async function getTopMasterId(zoneId) {
        if (!zoneId) return null;
        
        const zoneIdNum = parseInt(zoneId, 10);
        if (isNaN(zoneIdNum) || zoneIdNum <= 0) return null;
        
        console.debug('[getTopMasterId] Finding top master for zone:', zoneIdNum);
        
        let currentZoneId = zoneIdNum;
        let iterations = 0;
        const maxIterations = 20; // Safety limit to prevent infinite loops
        
        while (iterations < maxIterations) {
            iterations++;
            
            // Try to find current zone in caches first
            let zone = null;
            const cachesToCheck = [
                window.CURRENT_ZONE_LIST,
                window.ALL_ZONES,
                window.ZONES_ALL,
                allZones
            ];
            
            for (const cache of cachesToCheck) {
                if (Array.isArray(cache) && cache.length > 0) {
                    zone = cache.find(z => parseInt(z.id, 10) === currentZoneId);
                    if (zone) {
                        console.debug('[getTopMasterId] Found zone in cache:', zone.name, 'type:', zone.file_type, 'parent_id:', zone.parent_id);
                        break;
                    }
                }
            }
            
            // Fallback: fetch from API
            if (!zone) {
                try {
                    console.debug('[getTopMasterId] Zone not in cache, fetching from API:', currentZoneId);
                    const result = await zoneApiCall('get_zone', { id: currentZoneId });
                    zone = result && result.data ? result.data : null;
                    if (zone) {
                        console.debug('[getTopMasterId] Fetched zone from API:', zone.name, 'type:', zone.file_type, 'parent_id:', zone.parent_id);
                    }
                } catch (e) {
                    console.warn('[getTopMasterId] Failed to fetch zone:', currentZoneId, e);
                    return null;
                }
            }
            
            if (!zone) {
                console.warn('[getTopMasterId] Zone not found:', currentZoneId);
                return null;
            }
            
            // Check if this is a top master (no parent)
            if (!zone.parent_id || zone.parent_id === null || zone.parent_id === 0) {
                console.debug('[getTopMasterId] Found top master:', currentZoneId, 'name:', zone.name);
                return currentZoneId;
            }
            
            // Move up to parent
            const parentId = parseInt(zone.parent_id, 10);
            if (isNaN(parentId) || parentId <= 0) {
                console.debug('[getTopMasterId] Invalid parent_id, treating as top master:', currentZoneId);
                return currentZoneId;
            }
            
            console.debug('[getTopMasterId] Moving up to parent:', parentId);
            currentZoneId = parentId;
        }
        
        console.warn('[getTopMasterId] Max iterations reached, returning current zone:', currentZoneId);
        return currentZoneId;
    }

    /**
     * Fetch zones for a specific master using API with recursive flag
     * Calls zone_api.php?action=list_zones&master_id=...&recursive=1&per_page=1000
     * @param {number|string} masterId - Master zone ID
     * @returns {Promise<Array>} - Array of zone objects (master + all descendants)
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
        
        console.debug('[fetchZonesForMaster] Fetching zones for master:', masterIdNum);
        
        try {
            // Use zoneApiCall to fetch with master_id and recursive parameters
            const result = await zoneApiCall('list_zones', { 
                master_id: masterIdNum, 
                recursive: 1,
                per_page: 1000
            });
            
            const zones = result && result.data ? result.data : [];
            console.debug('[fetchZonesForMaster] Fetched', zones.length, 'zones for master:', masterIdNum);
            
            return zones;
        } catch (e) {
            console.error('[fetchZonesForMaster] Failed to fetch zones for master:', masterIdNum, e);
            return [];
        }
    }

    /**
     * Apply defensive subtree filtering to ensure only descendants of master are included
     * Uses BFS/closure approach to filter by parent_id relationships
     * @param {Array} zones - Array of zone objects to filter
     * @param {number} masterId - Master zone ID (root of subtree)
     * @returns {Array} - Filtered array containing only master and its descendants
     */
    function filterSubtreeDefensive(zones, masterId) {
        if (!zones || !Array.isArray(zones) || zones.length === 0) {
            return [];
        }
        
        const masterIdNum = parseInt(masterId, 10);
        if (isNaN(masterIdNum) || masterIdNum <= 0) {
            console.warn('[filterSubtreeDefensive] Invalid masterId:', masterId);
            return zones;
        }
        
        console.debug('[filterSubtreeDefensive] Filtering', zones.length, 'zones for master:', masterIdNum);
        
        // Build a set of valid zone IDs using BFS
        const validIds = new Set();
        validIds.add(masterIdNum);
        
        // Create a map of parent_id -> children for efficient lookup
        const childrenMap = new Map();
        zones.forEach(zone => {
            const zoneId = parseInt(zone.id, 10);
            const parentId = zone.parent_id ? parseInt(zone.parent_id, 10) : null;
            
            if (!childrenMap.has(parentId)) {
                childrenMap.set(parentId, []);
            }
            childrenMap.get(parentId).push(zoneId);
        });
        
        // BFS to find all descendants
        const queue = [masterIdNum];
        while (queue.length > 0) {
            const currentId = queue.shift();
            const children = childrenMap.get(currentId) || [];
            
            children.forEach(childId => {
                if (!validIds.has(childId)) {
                    validIds.add(childId);
                    queue.push(childId);
                }
            });
        }
        
        // Filter zones to only include valid IDs
        const filtered = zones.filter(zone => {
            const zoneId = parseInt(zone.id, 10);
            return validIds.has(zoneId);
        });
        
        console.debug('[filterSubtreeDefensive] Filtered to', filtered.length, 'zones (master + descendants)');
        return filtered;
    }

    /**
     * Fill modal zone file combobox with filtered zones
     * Replaces existing logic with reliable behavior:
     * - Fetches zones via fetchZonesForMaster when masterId present
     * - Falls back to CURRENT_ZONE_LIST/ALL_ZONES/API list_zones status=active
     * - Applies defensive subtree filtering
     * - Populates #modal-zonefile-input combobox and handles events
     * - Idempotent and error-tolerant
     * 
     * @param {number|string|null} masterId - Master zone ID to fetch tree for
     * @param {number|string|null} preselectedId - Zone ID to preselect
     */
    async function fillModalZonefileSelectFiltered(masterId, preselectedId = null) {
        const inputElement = document.getElementById('modal-zonefile-input');
        const hiddenElement = document.getElementById('modal-zonefile-id');
        const listElement = document.getElementById('modal-zonefile-list');
        
        if (!inputElement || !hiddenElement || !listElement) {
            console.warn('[fillModalZonefileSelectFiltered] Modal zonefile combobox elements not found');
            return;
        }
        
        console.debug('[fillModalZonefileSelectFiltered] Called with masterId:', masterId, 'preselectedId:', preselectedId);
        
        // Disable input during loading
        inputElement.disabled = true;
        
        try {
            let zones = [];
            
            // Step 1: Fetch zones based on masterId
            if (masterId) {
                const masterIdNum = parseInt(masterId, 10);
                if (!isNaN(masterIdNum) && masterIdNum > 0) {
                    console.debug('[fillModalZonefileSelectFiltered] Fetching zones for master:', masterIdNum);
                    zones = await fetchZonesForMaster(masterIdNum);
                    
                    // Apply defensive subtree filtering
                    if (zones.length > 0) {
                        zones = filterSubtreeDefensive(zones, masterIdNum);
                    }
                }
            }
            
            // Step 2: Fallback if no zones fetched
            if (zones.length === 0) {
                console.debug('[fillModalZonefileSelectFiltered] No zones from master, trying fallback sources');
                
                // Try CURRENT_ZONE_LIST first
                if (Array.isArray(window.CURRENT_ZONE_LIST) && window.CURRENT_ZONE_LIST.length > 0) {
                    zones = window.CURRENT_ZONE_LIST;
                    console.debug('[fillModalZonefileSelectFiltered] Using CURRENT_ZONE_LIST:', zones.length);
                }
                // Try ALL_ZONES
                else if (Array.isArray(window.ALL_ZONES) && window.ALL_ZONES.length > 0) {
                    zones = window.ALL_ZONES;
                    console.debug('[fillModalZonefileSelectFiltered] Using ALL_ZONES:', zones.length);
                }
                // Fetch all active zones from API
                else {
                    try {
                        console.debug('[fillModalZonefileSelectFiltered] Fetching all active zones from API');
                        const result = await zoneApiCall('list_zones', { status: 'active', per_page: 1000 });
                        zones = result && result.data ? result.data : [];
                        console.debug('[fillModalZonefileSelectFiltered] Fetched', zones.length, 'active zones');
                    } catch (e) {
                        console.error('[fillModalZonefileSelectFiltered] Failed to fetch zones:', e);
                    }
                }
            }
            
            // Step 3: Filter to only master and include types
            zones = zones.filter(z => z.file_type === 'master' || z.file_type === 'include');
            console.debug('[fillModalZonefileSelectFiltered] After filtering to master/include:', zones.length);
            
            // Step 4: Ensure preselected zone is in the list
            if (preselectedId) {
                const preselectedIdNum = parseInt(preselectedId, 10);
                if (!isNaN(preselectedIdNum) && preselectedIdNum > 0) {
                    const zoneExists = zones.some(z => parseInt(z.id, 10) === preselectedIdNum);
                    
                    if (!zoneExists) {
                        console.debug('[fillModalZonefileSelectFiltered] Preselected zone not in list, fetching:', preselectedIdNum);
                        try {
                            const specificZoneResult = await zoneApiCall('get_zone', { id: preselectedIdNum });
                            if (specificZoneResult && specificZoneResult.data) {
                                zones.push(specificZoneResult.data);
                                console.debug('[fillModalZonefileSelectFiltered] Added preselected zone to list');
                            }
                        } catch (fetchError) {
                            console.warn('[fillModalZonefileSelectFiltered] Failed to fetch preselected zone:', fetchError);
                        }
                    }
                }
            }
            
            // Store zones in a data attribute for filtering
            inputElement.dataset.allZones = JSON.stringify(zones);
            
            console.debug('[fillModalZonefileSelectFiltered] Stored', zones.length, 'zones for filtering');
            
            // Step 5: Set preselected value
            if (preselectedId) {
                const preselectedIdNum = parseInt(preselectedId, 10);
                const selectedZone = zones.find(z => parseInt(z.id, 10) === preselectedIdNum);
                
                if (selectedZone) {
                    inputElement.value = `${selectedZone.name} (${selectedZone.file_type})`;
                    hiddenElement.value = selectedZone.id;
                    
                    // Update hidden fields
                    const recordZoneFile = document.getElementById('record-zone-file');
                    if (recordZoneFile) {
                        recordZoneFile.value = selectedZone.id;
                    }
                    const dnsZoneFileId = document.getElementById('dns-zone-file-id');
                    if (dnsZoneFileId) {
                        dnsZoneFileId.value = selectedZone.id;
                    }
                    
                    console.debug('[fillModalZonefileSelectFiltered] Preselected zone:', selectedZone.name);
                } else {
                    inputElement.value = '';
                    hiddenElement.value = '';
                    console.warn('[fillModalZonefileSelectFiltered] Preselected zone not found after fetch attempt');
                }
            } else {
                inputElement.value = '';
                hiddenElement.value = '';
            }
            
            // Activate guard to protect against overwrites
            if (typeof activateModalComboboxGuard === 'function') {
                activateModalComboboxGuard();
            }
            
        } catch (error) {
            console.error('[fillModalZonefileSelectFiltered] Error:', error);
            // Don't block modal, just show error in console
        } finally {
            // Re-enable input
            inputElement.disabled = false;
        }
    }

    /**
     * Initialize modal zone file select combobox
     * Robust function that accepts multiple signatures for backward compatibility:
     * - (preselectedZoneFileId, masterId) - preselect a zone and fetch master + includes
     * - (preselectedZoneFileId, domainIdOrName) - preselect a zone and fetch zones for domain
     * - (singleId) - fetch master + includes for this zone and preselect it
     * - () - fetch all zones
     * 
     * @param {number|string|null} preselectedZoneFileId - Zone file ID to preselect
     * @param {number|string|null} domainIdOrName - Optional domain/master ID to filter zones
     */
    async function initModalZonefileSelect(preselectedZoneFileId = null, domainIdOrName = null) {
        try {
            console.debug('[initModalZonefileSelect] Called with:', { preselectedZoneFileId, domainIdOrName });
            
            let zones = [];
            let masterId = null;
            
            // Step 1: If we have a preselected zone, fetch it to determine if it's include or master
            if (preselectedZoneFileId) {
                const zoneIdNum = parseInt(preselectedZoneFileId, 10);
                if (!isNaN(zoneIdNum) && zoneIdNum > 0) {
                    try {
                        const zoneResult = await zoneApiCall('get_zone', { id: zoneIdNum });
                        const preselectedZone = zoneResult && zoneResult.data ? zoneResult.data : null;
                        
                        if (preselectedZone) {
                            console.debug('[initModalZonefileSelect] Preselected zone:', preselectedZone);
                            
                            // Determine master ID: if include, use parent_id; if master, use its own id
                            if (preselectedZone.file_type === 'include' && preselectedZone.parent_id) {
                                masterId = parseInt(preselectedZone.parent_id, 10);
                                console.debug('[initModalZonefileSelect] Zone is include, using parent_id as masterId:', masterId);
                            } else {
                                masterId = zoneIdNum;
                                console.debug('[initModalZonefileSelect] Zone is master or has no parent, using zone id as masterId:', masterId);
                            }
                        }
                    } catch (fetchError) {
                        console.warn('[initModalZonefileSelect] Failed to fetch preselected zone:', fetchError);
                    }
                }
            }
            
            // Step 2: Override masterId if explicitly provided as second parameter
            if (domainIdOrName) {
                const providedId = parseInt(domainIdOrName, 10);
                if (!isNaN(providedId) && providedId > 0) {
                    masterId = providedId;
                    console.debug('[initModalZonefileSelect] Using provided domainIdOrName as masterId:', masterId);
                }
            }
            
            // Step 3: Fetch zones list
            if (masterId) {
                // Fetch master + includes using list_zones_by_domain API with zone_id
                console.debug('[initModalZonefileSelect] Fetching master + includes for masterId:', masterId);
                try {
                    const res = await apiCall('list_zones_by_domain', { zone_id: masterId });
                    zones = (res && res.data ? res.data : []);
                    console.debug('[initModalZonefileSelect] Fetched zones via list_zones_by_domain:', zones.length);
                } catch (e) {
                    console.warn('[initModalZonefileSelect] list_zones_by_domain failed, trying fallback:', e);
                    // Fallback: try with domain_id for backward compatibility
                    try {
                        const res = await apiCall('list_zones_by_domain', { domain_id: masterId });
                        zones = (res && res.data ? res.data : []);
                        console.debug('[initModalZonefileSelect] Fetched zones via domain_id fallback:', zones.length);
                    } catch (e2) {
                        console.warn('[initModalZonefileSelect] domain_id fallback failed:', e2);
                    }
                }
            }
            
            // Step 4: If no zones fetched yet, use cached or fetch all
            if (zones.length === 0) {
                console.debug('[initModalZonefileSelect] No zones fetched via master, trying cache or all zones');
                if (Array.isArray(window.CURRENT_ZONE_LIST) && window.CURRENT_ZONE_LIST.length > 0) {
                    zones = window.CURRENT_ZONE_LIST;
                    console.debug('[initModalZonefileSelect] Using CURRENT_ZONE_LIST:', zones.length);
                } else if (Array.isArray(window.ALL_ZONES) && window.ALL_ZONES.length > 0) {
                    zones = window.ALL_ZONES;
                    console.debug('[initModalZonefileSelect] Using ALL_ZONES:', zones.length);
                } else {
                    try {
                        const res = await zoneApiCall('list_zones', { status: 'active' });
                        zones = (res && res.data ? res.data : []);
                        console.debug('[initModalZonefileSelect] Fetched all active zones:', zones.length);
                    } catch (e) {
                        console.error('[initModalZonefileSelect] Failed to fetch all zones:', e);
                    }
                }
            }
            
            // Step 5: Filter to only master and include types
            zones = zones.filter(z => z.file_type === 'master' || z.file_type === 'include');
            console.debug('[initModalZonefileSelect] Filtered to master/include types:', zones.length);
            
            // Step 6: Ensure preselected zone is in the list
            if (preselectedZoneFileId) {
                const zoneIdNum = parseInt(preselectedZoneFileId, 10);
                if (!isNaN(zoneIdNum) && zoneIdNum > 0) {
                    const zoneExists = zones.some(z => parseInt(z.id, 10) === zoneIdNum);
                    
                    if (!zoneExists) {
                        console.debug('[initModalZonefileSelect] Preselected zone not in list, fetching specifically:', zoneIdNum);
                        try {
                            const specificZoneResult = await zoneApiCall('get_zone', { id: zoneIdNum });
                            if (specificZoneResult && specificZoneResult.data) {
                                zones.push(specificZoneResult.data);
                                console.debug('[initModalZonefileSelect] Added preselected zone to list');
                            }
                        } catch (fetchError) {
                            console.warn('[initModalZonefileSelect] Failed to fetch preselected zone for addition:', fetchError);
                        }
                    }
                }
            }
            
            // Step 7: Fill the select with zones
            fillModalZonefileSelect(zones, preselectedZoneFileId);
            console.debug('[initModalZonefileSelect] Modal zonefile select filled successfully');
            
        } catch (error) {
            console.error('[initModalZonefileSelect] Error:', error);
            // Don't block modal opening, just log the error
        }
    }

    /**
     * Fill modal zone file combobox with zones
     * @param {Array} zones - Array of zone objects
     * @param {number|string|null} preselectedZoneFileId - Zone file ID to preselect
     */
    function fillModalZonefileSelect(zones, preselectedZoneFileId = null) {
        const inputElement = document.getElementById('modal-zonefile-input');
        const hiddenElement = document.getElementById('modal-zonefile-id');
        
        if (!inputElement || !hiddenElement) {
            console.warn('Modal zonefile combobox elements not found');
            return;
        }
        
        // Store zones in data attribute for filtering
        inputElement.dataset.allZones = JSON.stringify(zones);
        
        // Set the preselected value if provided
        if (preselectedZoneFileId) {
            const zoneIdNum = parseInt(preselectedZoneFileId, 10);
            const selectedZone = zones.find(z => parseInt(z.id, 10) === zoneIdNum);
            
            if (selectedZone) {
                inputElement.value = `${selectedZone.name} (${selectedZone.file_type})`;
                hiddenElement.value = selectedZone.id;
                
                // Update both the record-zone-file hidden field and dns-zone-file-id
                const recordZoneFile = document.getElementById('record-zone-file');
                if (recordZoneFile) {
                    recordZoneFile.value = selectedZone.id;
                }
                const dnsZoneFileId = document.getElementById('dns-zone-file-id');
                if (dnsZoneFileId) {
                    dnsZoneFileId.value = selectedZone.id;
                }
            } else {
                inputElement.value = '';
                hiddenElement.value = '';
            }
        } else {
            inputElement.value = '';
            hiddenElement.value = '';
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
                
                // Determine if user can write to this record's zone
                const canWrite = canWriteRecord(record);
                
                // Build actions cell based on permissions
                let actionsHtml = '';
                if (canWrite) {
                    actionsHtml = `<button class="btn-small btn-edit" onclick="dnsRecords.openEditModal(${record.id})">Modifier</button>`;
                    if (record.status !== 'deleted') {
                        actionsHtml += ` <button class="btn-small btn-delete" onclick="dnsRecords.deleteRecord(${record.id})">Supprimer</button>`;
                    }
                    if (record.status === 'deleted') {
                        actionsHtml += ` <button class="btn-small btn-restore" onclick="dnsRecords.restoreRecord(${record.id})">Restaurer</button>`;
                    }
                } else {
                    // Read-only: show Edit button only (modal will hide Save/Delete) + read-only badge
                    actionsHtml = `<button class="btn-small btn-edit" onclick="dnsRecords.openEditModal(${record.id})">Voir</button>`;
                    actionsHtml += ` <span class="badge badge-readonly" title="Vous n'avez pas les droits d'écriture sur cette zone">Lecture seule</span>`;
                }

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
                    <td class="col-actions">${actionsHtml}</td>
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

                        // 5) Visual feedback WITHOUT focusing the inputs (avoid opening combobox lists)
                        const domainInput = document.getElementById('dns-domain-input');
                        const zoneInput = document.getElementById('record-zone-input') || document.getElementById('dns-zone-input');
                        
                        // Hide all combobox lists robustly (small timeout to let other handlers run)
                        setTimeout(() => { hideAllComboboxLists(); }, 20);
                        
                        // Temporary visual feedback on domain input WITHOUT focusing it
                        if (domainInput) {
                            const prevBg = domainInput.style.backgroundColor;
                            domainInput.style.transition = `background-color ${AUTOFILL_TRANSITION_DURATION}ms`;
                            domainInput.style.backgroundColor = AUTOFILL_HIGHLIGHT_COLOR;
                            setTimeout(() => {
                                domainInput.style.backgroundColor = prevBg || '';
                                setTimeout(() => { domainInput.style.transition = ''; }, AUTOFILL_TRANSITION_DURATION + 30);
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
     * Update field visibility based on record type
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
        
        // Update preview
        updateDnsPreview();
    }

    /**
     * Clear all dedicated type-specific fields
     */
    function clearAllDedicatedFields() {
        // Basic fields
        const basicFields = [
            'record-address-ipv4', 'record-address-ipv6', 'record-cname-target',
            'record-ptrdname', 'record-txt'
        ];
        
        // Extended fields
        const extendedFields = [
            'record-ns-target', 'record-dname-target', 'record-mx-target', 'record-priority',
            'record-srv-priority', 'record-srv-weight', 'record-srv-port', 'record-srv-target',
            'record-caa-flag', 'record-caa-tag', 'record-caa-value',
            'record-tlsa-usage', 'record-tlsa-selector', 'record-tlsa-matching', 'record-tlsa-data',
            'record-sshfp-algo', 'record-sshfp-type', 'record-sshfp-fingerprint',
            'record-naptr-order', 'record-naptr-pref', 'record-naptr-flags', 'record-naptr-service',
            'record-naptr-regexp', 'record-naptr-replacement',
            'record-svc-priority', 'record-svc-target', 'record-svc-params',
            'record-loc-latitude', 'record-loc-longitude', 'record-loc-altitude',
            'record-rp-mbox', 'record-rp-txt'
        ];
        
        [...basicFields, ...extendedFields].forEach(fieldId => {
            const field = document.getElementById(fieldId);
            if (field) {
                if (field.tagName === 'SELECT') {
                    field.selectedIndex = 0;
                } else {
                    field.value = '';
                }
            }
        });
    }

    /**
     * Populate dedicated fields based on record data
     * @param {Object} record - Record object from API
     */
    function populateDedicatedFields(record) {
        if (!record || !record.record_type) return;
        
        const setFieldValue = (fieldId, value) => {
            const field = document.getElementById(fieldId);
            if (field) {
                field.value = value !== null && value !== undefined ? value : '';
            }
        };
        
        switch(record.record_type) {
            case 'A':
                setFieldValue('record-address-ipv4', record.address_ipv4 || record.value);
                break;
            case 'AAAA':
                setFieldValue('record-address-ipv6', record.address_ipv6 || record.value);
                break;
            case 'CNAME':
                setFieldValue('record-cname-target', record.cname_target || record.value);
                break;
            case 'PTR':
                setFieldValue('record-ptrdname', record.ptrdname || record.value);
                break;
            case 'TXT':
            case 'SPF':
            case 'DKIM':
            case 'DMARC':
                setFieldValue('record-txt', record.txt || record.value);
                break;
            case 'NS':
                setFieldValue('record-ns-target', record.ns_target || record.value);
                break;
            case 'DNAME':
                setFieldValue('record-dname-target', record.dname_target || record.value);
                break;
            case 'MX':
                setFieldValue('record-mx-target', record.mx_target || record.value);
                setFieldValue('record-priority', record.priority);
                break;
            case 'SRV':
                setFieldValue('record-srv-priority', record.priority);
                setFieldValue('record-srv-weight', record.weight);
                setFieldValue('record-srv-port', record.port);
                setFieldValue('record-srv-target', record.srv_target || record.value);
                break;
            case 'CAA':
                setFieldValue('record-caa-flag', record.caa_flag);
                setFieldValue('record-caa-tag', record.caa_tag);
                setFieldValue('record-caa-value', record.caa_value);
                break;
            case 'TLSA':
                setFieldValue('record-tlsa-usage', record.tlsa_usage);
                setFieldValue('record-tlsa-selector', record.tlsa_selector);
                setFieldValue('record-tlsa-matching', record.tlsa_matching);
                setFieldValue('record-tlsa-data', record.tlsa_data);
                break;
            case 'SSHFP':
                setFieldValue('record-sshfp-algo', record.sshfp_algo);
                setFieldValue('record-sshfp-type', record.sshfp_type);
                setFieldValue('record-sshfp-fingerprint', record.sshfp_fingerprint);
                break;
            case 'NAPTR':
                setFieldValue('record-naptr-order', record.naptr_order);
                setFieldValue('record-naptr-pref', record.naptr_pref);
                setFieldValue('record-naptr-flags', record.naptr_flags);
                setFieldValue('record-naptr-service', record.naptr_service);
                setFieldValue('record-naptr-regexp', record.naptr_regexp);
                setFieldValue('record-naptr-replacement', record.naptr_replacement || '.');
                break;
            case 'SVCB':
            case 'HTTPS':
                setFieldValue('record-svc-priority', record.svc_priority);
                setFieldValue('record-svc-target', record.svc_target || '.');
                setFieldValue('record-svc-params', record.svc_params);
                break;
            case 'LOC':
                setFieldValue('record-loc-latitude', record.loc_latitude);
                setFieldValue('record-loc-longitude', record.loc_longitude);
                setFieldValue('record-loc-altitude', record.loc_altitude);
                break;
            case 'RP':
                setFieldValue('record-rp-mbox', record.rp_mbox);
                setFieldValue('record-rp-txt', record.rp_txt || '.');
                break;
        }
    }

    /**
     * Show the type selection view (Step 1)
     */
    function showTypeSelectionView() {
        modalState = 'choose-type';
        
        const typeView = document.getElementById('type-selection-view');
        const formView = document.getElementById('dns-form');
        const saveBtn = document.getElementById('record-save-btn');
        const previousBtn = document.getElementById('record-previous-btn');
        const deleteBtn = document.getElementById('record-delete-btn');
        
        if (typeView) typeView.style.display = 'block';
        if (formView) formView.style.display = 'none';
        if (saveBtn) saveBtn.style.display = 'none';
        if (previousBtn) previousBtn.style.display = 'none';
        if (deleteBtn) deleteBtn.style.display = 'none';
        
        // Focus first type button
        const firstTypeBtn = document.querySelector('.type-button');
        if (firstTypeBtn) {
            setTimeout(() => firstTypeBtn.focus(), 100);
        }
    }

    /**
     * Show the form view (Step 2)
     */
    function showFormView(recordType) {
        modalState = 'fill-fields';
        currentRecordType = recordType;
        
        const typeView = document.getElementById('type-selection-view');
        const formView = document.getElementById('dns-form');
        const saveBtn = document.getElementById('record-save-btn');
        const previousBtn = document.getElementById('record-previous-btn');
        const deleteBtn = document.getElementById('record-delete-btn');
        const recordTypeInput = document.getElementById('record-type');
        
        if (typeView) typeView.style.display = 'none';
        if (formView) formView.style.display = 'block';
        if (saveBtn) saveBtn.style.display = 'inline-block';
        if (previousBtn) previousBtn.style.display = 'inline-block';
        
        // Set record type
        if (recordTypeInput) recordTypeInput.value = recordType;
        
        // Restore saved values for this type
        restoreFormValues(recordType);
        
        // Update field visibility for the selected type
        updateFieldVisibility();
        
        // Update DNS preview immediately to show at minimum "IN" format
        updateDnsPreview();
        
        // Focus first input
        const nameInput = document.getElementById('record-name');
        if (nameInput) {
            setTimeout(() => nameInput.focus(), 100);
        }
    }

    /**
     * Save current form values to temp storage
     */
    function saveFormValues(recordType) {
        if (!recordType || !tempRecordValues[recordType]) return;
        
        const nameInput = document.getElementById('record-name');
        const ttlInput = document.getElementById('record-ttl');
        const ticketInput = document.getElementById('record-ticket-ref');
        const requesterInput = document.getElementById('record-requester');
        const commentInput = document.getElementById('record-comment');
        
        // Get value based on record type
        let valueInput = null;
        switch(recordType) {
            case 'A':
                valueInput = document.getElementById('record-address-ipv4');
                break;
            case 'AAAA':
                valueInput = document.getElementById('record-address-ipv6');
                break;
            case 'CNAME':
                valueInput = document.getElementById('record-cname-target');
                break;
            case 'PTR':
                valueInput = document.getElementById('record-ptrdname');
                break;
            case 'TXT':
                valueInput = document.getElementById('record-txt');
                break;
        }
        
        tempRecordValues[recordType] = {
            name: nameInput ? nameInput.value : '',
            ttl: ttlInput ? ttlInput.value : '',
            value: valueInput ? valueInput.value : '',
            ticket_ref: ticketInput ? ticketInput.value : '',
            requester: requesterInput ? requesterInput.value : '',
            comment: commentInput ? commentInput.value : ''
        };
    }

    /**
     * Restore form values from temp storage
     */
    function restoreFormValues(recordType) {
        if (!recordType || !tempRecordValues[recordType]) return;
        
        const values = tempRecordValues[recordType];
        const nameInput = document.getElementById('record-name');
        const ttlInput = document.getElementById('record-ttl');
        const ticketInput = document.getElementById('record-ticket-ref');
        const requesterInput = document.getElementById('record-requester');
        const commentInput = document.getElementById('record-comment');
        
        if (nameInput) nameInput.value = values.name || '';
        if (ttlInput) ttlInput.value = values.ttl || '';
        if (ticketInput) ticketInput.value = values.ticket_ref || '';
        if (requesterInput) requesterInput.value = values.requester || '';
        if (commentInput) commentInput.value = values.comment || '';
        
        // Restore value based on record type
        let valueInput = null;
        switch(recordType) {
            case 'A':
                valueInput = document.getElementById('record-address-ipv4');
                break;
            case 'AAAA':
                valueInput = document.getElementById('record-address-ipv6');
                break;
            case 'CNAME':
                valueInput = document.getElementById('record-cname-target');
                break;
            case 'PTR':
                valueInput = document.getElementById('record-ptrdname');
                break;
            case 'TXT':
                valueInput = document.getElementById('record-txt');
                break;
        }
        
        if (valueInput) valueInput.value = values.value || '';
    }

    /**
     * Clear temp storage
     */
    function clearTempStorage() {
        tempRecordValues = {
            'A': { name: '', ttl: '', value: '', ticket_ref: '', requester: '', comment: '' },
            'AAAA': { name: '', ttl: '', value: '', ticket_ref: '', requester: '', comment: '' },
            'CNAME': { name: '', ttl: '', value: '', ticket_ref: '', requester: '', comment: '' },
            'PTR': { name: '', ttl: '', value: '', ticket_ref: '', requester: '', comment: '' },
            'TXT': { name: '', ttl: '', value: '', ticket_ref: '', requester: '', comment: '' }
        };
        currentRecordType = null;
    }

    /**
     * Generate BIND-style DNS record preview
     */
    function generateDnsPreview() {
        const recordType = document.getElementById('record-type').value;
        
        // If no record type selected, return empty
        if (!recordType) {
            return '';
        }
        
        const name = document.getElementById('record-name').value || '@';
        const ttl = document.getElementById('record-ttl').value || '';
        
        let value = '';
        switch(recordType) {
            case 'A':
                value = document.getElementById('record-address-ipv4').value || '';
                break;
            case 'AAAA':
                value = document.getElementById('record-address-ipv6').value || '';
                break;
            case 'CNAME':
                value = normalizeHostname(document.getElementById('record-cname-target').value || '');
                break;
            case 'PTR':
                value = normalizeHostname(document.getElementById('record-ptrdname').value || '');
                break;
            case 'TXT':
            case 'SPF':
            case 'DKIM':
            case 'DMARC':
                value = document.getElementById('record-txt').value || '';
                // Wrap TXT in quotes if not already
                if (value && !value.startsWith('"')) {
                    value = '"' + value + '"';
                }
                break;
            case 'NS':
                value = normalizeHostname(document.getElementById('record-ns-target').value || '');
                break;
            case 'DNAME':
                value = normalizeHostname(document.getElementById('record-dname-target').value || '');
                break;
            case 'MX': {
                const priority = document.getElementById('record-priority').value || '10';
                const target = normalizeHostname(document.getElementById('record-mx-target').value || '');
                value = `${priority} ${target}`;
                break;
            }
            case 'SRV': {
                const priority = document.getElementById('record-srv-priority').value || '0';
                const weight = document.getElementById('record-srv-weight').value || '0';
                const port = document.getElementById('record-srv-port').value || '0';
                const target = normalizeHostname(document.getElementById('record-srv-target').value || '');
                value = `${priority} ${weight} ${port} ${target}`;
                break;
            }
            case 'CAA': {
                const flag = document.getElementById('record-caa-flag').value || '0';
                const tag = document.getElementById('record-caa-tag').value || 'issue';
                const caaValue = document.getElementById('record-caa-value').value || '';
                value = `${flag} ${tag} "${caaValue}"`;
                break;
            }
            case 'TLSA': {
                const usage = document.getElementById('record-tlsa-usage').value || '3';
                const selector = document.getElementById('record-tlsa-selector').value || '1';
                const matching = document.getElementById('record-tlsa-matching').value || '1';
                const data = document.getElementById('record-tlsa-data').value || '';
                value = `${usage} ${selector} ${matching} ${data}`;
                break;
            }
            case 'SSHFP': {
                const algo = document.getElementById('record-sshfp-algo').value || '1';
                const fpType = document.getElementById('record-sshfp-type').value || '2';
                const fingerprint = document.getElementById('record-sshfp-fingerprint').value || '';
                value = `${algo} ${fpType} ${fingerprint}`;
                break;
            }
            case 'NAPTR': {
                const order = document.getElementById('record-naptr-order').value || '100';
                const pref = document.getElementById('record-naptr-pref').value || '10';
                const flags = document.getElementById('record-naptr-flags').value || '';
                const service = document.getElementById('record-naptr-service').value || '';
                const regexp = document.getElementById('record-naptr-regexp').value || '';
                const rawReplacement = document.getElementById('record-naptr-replacement').value || '.';
                const replacement = rawReplacement === '.' ? '.' : normalizeHostname(rawReplacement);
                value = `${order} ${pref} "${flags}" "${service}" "${regexp}" ${replacement}`;
                break;
            }
            case 'SVCB':
            case 'HTTPS': {
                const priority = document.getElementById('record-svc-priority').value || '1';
                const target = document.getElementById('record-svc-target').value || '.';
                const params = document.getElementById('record-svc-params').value || '';
                value = `${priority} ${target}${params ? ' ' + params : ''}`;
                break;
            }
            case 'LOC': {
                const lat = document.getElementById('record-loc-latitude').value || '';
                const lon = document.getElementById('record-loc-longitude').value || '';
                const alt = document.getElementById('record-loc-altitude').value || '';
                value = `${lat} ${lon}${alt ? ' ' + alt : ''}`;
                break;
            }
            case 'RP': {
                const mbox = normalizeHostname(document.getElementById('record-rp-mbox').value || '');
                const txt = document.getElementById('record-rp-txt').value || '.';
                value = `${mbox} ${txt}`;
                break;
            }
        }
        
        // Build preview showing at minimum "name [TTL] IN type [value]"
        // TTL is optional in display if empty (server will use default)
        const ttlPart = ttl ? `${ttl}\t` : '';
        const valuePart = value ? `\t${value}` : '';
        
        // BIND format: name [TTL] class type [value]
        return `${name}\t${ttlPart}IN\t${recordType}${valuePart}`;
    }

    /**
     * Update the DNS preview textarea
     */
    function updateDnsPreview() {
        const previewTextarea = document.getElementById('dns-preview');
        if (!previewTextarea) return;
        
        const preview = generateDnsPreview();
        previewTextarea.value = preview;
    }

    /**
     * Initialize type button event handlers
     */
    function initTypeButtons() {
        const typeButtons = document.querySelectorAll('.type-button');
        typeButtons.forEach(button => {
            button.addEventListener('click', function() {
                const recordType = this.dataset.type;
                if (recordType) {
                    showFormView(recordType);
                }
            });
        });
    }

    /**
     * Initialize previous button
     */
    function initPreviousButton() {
        const previousBtn = document.getElementById('record-previous-btn');
        if (previousBtn) {
            previousBtn.addEventListener('click', function() {
                // Save current form values before going back
                if (currentRecordType) {
                    saveFormValues(currentRecordType);
                }
                showTypeSelectionView();
            });
        }
    }

    /**
     * Initialize form field change listeners for preview update
     */
    function initPreviewListeners() {
        const fields = [
            // Basic fields
            'record-name',
            'record-ttl',
            'record-address-ipv4',
            'record-address-ipv6',
            'record-cname-target',
            'record-ptrdname',
            'record-txt',
            // Extended fields
            'record-ns-target',
            'record-dname-target',
            'record-mx-target',
            'record-priority',
            'record-srv-priority',
            'record-srv-weight',
            'record-srv-port',
            'record-srv-target',
            'record-caa-flag',
            'record-caa-tag',
            'record-caa-value',
            'record-tlsa-usage',
            'record-tlsa-selector',
            'record-tlsa-matching',
            'record-tlsa-data',
            'record-sshfp-algo',
            'record-sshfp-type',
            'record-sshfp-fingerprint',
            'record-naptr-order',
            'record-naptr-pref',
            'record-naptr-flags',
            'record-naptr-service',
            'record-naptr-regexp',
            'record-naptr-replacement',
            'record-svc-priority',
            'record-svc-target',
            'record-svc-params',
            'record-loc-latitude',
            'record-loc-longitude',
            'record-loc-altitude',
            'record-rp-mbox',
            'record-rp-txt'
        ];
        
        fields.forEach(fieldId => {
            const field = document.getElementById(fieldId);
            if (field) {
                field.addEventListener('input', updateDnsPreview);
                field.addEventListener('change', updateDnsPreview);
            }
        });
    }

    /**
     * Update form field visibility and required attributes based on record type
     */
    function updateFieldVisibility() {
        const recordType = document.getElementById('record-type').value;
        
        // Get all dedicated field groups - basic types
        const ipv4Group = document.getElementById('record-address-ipv4-group');
        const ipv6Group = document.getElementById('record-address-ipv6-group');
        const cnameGroup = document.getElementById('record-cname-target-group');
        const ptrGroup = document.getElementById('record-ptrdname-group');
        const txtGroup = document.getElementById('record-txt-group');
        
        // Extended type field groups
        const nsGroup = document.getElementById('record-ns-target-group');
        const dnameGroup = document.getElementById('record-dname-target-group');
        const mxGroup = document.getElementById('record-mx-target-group');
        const priorityGroup = document.getElementById('record-priority-group');
        const srvFields = document.getElementById('record-srv-fields');
        const caaFields = document.getElementById('record-caa-fields');
        const tlsaFields = document.getElementById('record-tlsa-fields');
        const tlsaDataRow = document.getElementById('record-tlsa-data-row');
        const sshfpFields = document.getElementById('record-sshfp-fields');
        const sshfpFpRow = document.getElementById('record-sshfp-fp-row');
        const naptrFields = document.getElementById('record-naptr-fields');
        const naptrExtraRow = document.getElementById('record-naptr-extra-row');
        const svcFields = document.getElementById('record-svc-fields');
        const svcParamsRow = document.getElementById('record-svc-params-row');
        const locFields = document.getElementById('record-loc-fields');
        const rpFields = document.getElementById('record-rp-fields');
        
        // Get all dedicated field inputs
        const ipv4Input = document.getElementById('record-address-ipv4');
        const ipv6Input = document.getElementById('record-address-ipv6');
        const cnameInput = document.getElementById('record-cname-target');
        const ptrInput = document.getElementById('record-ptrdname');
        const txtInput = document.getElementById('record-txt');
        
        // Hide all dedicated fields first
        const allGroups = [
            ipv4Group, ipv6Group, cnameGroup, ptrGroup, txtGroup,
            nsGroup, dnameGroup, mxGroup, priorityGroup,
            srvFields, caaFields, tlsaFields, tlsaDataRow,
            sshfpFields, sshfpFpRow, naptrFields, naptrExtraRow,
            svcFields, svcParamsRow, locFields, rpFields
        ];
        allGroups.forEach(g => { if (g) g.style.display = 'none'; });
        
        // Remove required attribute from all basic inputs
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
            case 'SPF':
            case 'DKIM':
            case 'DMARC':
                if (txtGroup) txtGroup.style.display = 'block';
                if (txtInput) txtInput.setAttribute('required', 'required');
                break;
            case 'NS':
                if (nsGroup) nsGroup.style.display = 'block';
                break;
            case 'DNAME':
                if (dnameGroup) dnameGroup.style.display = 'block';
                break;
            case 'MX':
                if (mxGroup) mxGroup.style.display = 'block';
                if (priorityGroup) priorityGroup.style.display = 'block';
                break;
            case 'SRV':
                if (srvFields) srvFields.style.display = 'flex';
                break;
            case 'CAA':
                if (caaFields) caaFields.style.display = 'flex';
                break;
            case 'TLSA':
                if (tlsaFields) tlsaFields.style.display = 'flex';
                if (tlsaDataRow) tlsaDataRow.style.display = 'flex';
                break;
            case 'SSHFP':
                if (sshfpFields) sshfpFields.style.display = 'flex';
                if (sshfpFpRow) sshfpFpRow.style.display = 'flex';
                break;
            case 'NAPTR':
                if (naptrFields) naptrFields.style.display = 'flex';
                if (naptrExtraRow) naptrExtraRow.style.display = 'flex';
                break;
            case 'SVCB':
            case 'HTTPS':
                if (svcFields) svcFields.style.display = 'flex';
                if (svcParamsRow) svcParamsRow.style.display = 'flex';
                break;
            case 'LOC':
                if (locFields) locFields.style.display = 'flex';
                break;
            case 'RP':
                if (rpFields) rpFields.style.display = 'flex';
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
        const historySection = document.getElementById('record-history-section');
        
        if (!modal || !form || !title) return;

        // Clear any previous errors
        clearModalError('dns');
        
        // Reset and hide history panel for create mode
        resetHistoryPanel();
        if (historySection) {
            historySection.style.display = 'none';
        }

        // Set title with new text
        title.textContent = 'Ajouter un enregistrement DNS';
        
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
        
        // Remove required attribute from TTL field to allow NULL TTL
        const ttlInput = document.getElementById('record-ttl');
        if (ttlInput) {
            ttlInput.removeAttribute('required');
            ttlInput.placeholder = 'défaut';
        }
        
        // Hide last_seen field for new records (server-managed)
        if (lastSeenGroup) {
            lastSeenGroup.style.display = 'none';
        }
        
        // Hide delete button for create mode
        if (deleteBtn) {
            deleteBtn.style.display = 'none';
        }
        
        // Set the zone_file_id from the selected zone
        const zoneFileInput = document.getElementById('record-zone-file');
        if (zoneFileInput && selectedZoneId) {
            zoneFileInput.value = selectedZoneId;
        }
        
        // Initialize modal zone file combobox with current zone using new approach
        if (typeof fillModalZonefileSelectFiltered === 'function') {
            try {
                // Determine top master from selectedZoneId
                let topMasterId = null;
                if (selectedZoneId) {
                    topMasterId = await getTopMasterId(selectedZoneId);
                    console.debug('[openCreateModalPrefilled] Top master for zone', selectedZoneId, ':', topMasterId);
                }
                
                // Preselect: use selectedZoneId if present, otherwise selectedDomainId
                const preselectedId = selectedZoneId || selectedDomainId;
                
                // Fill modal select with top master's full tree
                await fillModalZonefileSelectFiltered(topMasterId, preselectedId);
            } catch (error) {
                console.error('Error initializing modal zone file select:', error);
                // Fallback to old method if new method fails
                if (typeof initModalZonefileSelect === 'function') {
                    try {
                        const preselectedId = selectedZoneId || selectedDomainId;
                        await initModalZonefileSelect(preselectedId, await getMasterIdFromZoneId(selectedZoneId));
                    } catch (e) {
                        console.error('Fallback initModalZonefileSelect also failed:', e);
                    }
                }
            }
        }
        
        // Clear temp storage
        clearTempStorage();
        
        // Show type selection view (Step 1)
        showTypeSelectionView();

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
        // Delegate to prefilled version
        await openCreateModalPrefilled();
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

            // Clear any previous errors
            clearModalError('dns');
            
            // Reset history panel state
            resetHistoryPanel();

            // Set title with new text
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
            
            // Set the zone_file_id
            const zoneFileInput = document.getElementById('record-zone-file');
            if (zoneFileInput && record.zone_file_id) {
                zoneFileInput.value = record.zone_file_id;
            }
            
            // Initialize modal zone file combobox with record's zone using new approach
            // Determine top master from record.zone_file_id to fetch master + all includes
            if (typeof fillModalZonefileSelectFiltered === 'function') {
                try {
                    // Determine top master from record's zone
                    let topMasterId = null;
                    if (record.zone_file_id) {
                        topMasterId = await getTopMasterId(record.zone_file_id);
                        console.debug('[openEditModal] Top master for record zone', record.zone_file_id, ':', topMasterId);
                    }
                    
                    // Fill modal select with top master's full tree and preselect record's zone
                    await fillModalZonefileSelectFiltered(topMasterId, record.zone_file_id);
                } catch (error) {
                    console.error('Error initializing modal zone file select:', error);
                    // Fallback to old method if new method fails
                    if (typeof initModalZonefileSelect === 'function') {
                        try {
                            await initModalZonefileSelect(record.zone_file_id, await getMasterIdFromZoneId(record.zone_file_id));
                        } catch (e) {
                            console.error('Fallback initModalZonefileSelect also failed:', e);
                        }
                    }
                }
            }

            document.getElementById('record-type').value = record.record_type;
            document.getElementById('record-name').value = record.name;
            
            // Handle TTL: set value to empty string if null (allows user to leave it empty for default)
            const ttlInput = document.getElementById('record-ttl');
            if (ttlInput) {
                ttlInput.value = (record.ttl !== null && record.ttl !== undefined) ? record.ttl : '';
                ttlInput.removeAttribute('required');
                ttlInput.placeholder = 'défaut';
            }
            
            document.getElementById('record-requester').value = record.requester || '';
            document.getElementById('record-ticket-ref').value = record.ticket_ref || '';
            document.getElementById('record-comment').value = record.comment || '';
            
            // Clear all dedicated fields first
            clearAllDedicatedFields();
            
            // Set the appropriate dedicated field based on record type
            populateDedicatedFields(record);
            
            // Edit mode: show form directly (skip type selection)
            const typeView = document.getElementById('type-selection-view');
            const formView = document.getElementById('dns-form');
            const saveBtn = document.getElementById('record-save-btn');
            const previousBtn = document.getElementById('record-previous-btn');
            const deleteBtn = document.getElementById('record-delete-btn');
            const cancelBtn = document.getElementById('record-cancel-btn');
            
            if (typeView) typeView.style.display = 'none';
            if (formView) formView.style.display = 'block';
            if (previousBtn) previousBtn.style.display = 'none'; // No previous button in edit mode
            
            // Convert SQL datetime to datetime-local format (if expires_at exists)
            const expiresInput = document.getElementById('record-expires-at');
            if (record.expires_at && expiresInput) {
                expiresInput.value = sqlToDatetimeLocal(record.expires_at);
            } else if (expiresInput) {
                expiresInput.value = '';
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

            // Update DNS preview immediately with loaded record data
            updateDnsPreview();

            // Apply permission-based button visibility
            // Use canWriteRecord helper to check permission from API response
            const canWrite = canWriteRecord(record);
            
            // Show/hide save button based on permission
            if (saveBtn) {
                saveBtn.style.display = canWrite ? 'inline-block' : 'none';
            }
            
            // Show/hide delete button based on permission and record status
            if (deleteBtn) {
                if (canWrite && record.status !== 'deleted') {
                    deleteBtn.style.display = 'block';
                    // Remove any previous click listeners and add new one
                    deleteBtn.onclick = function() {
                        dnsRecords.deleteRecord(recordId);
                    };
                } else {
                    deleteBtn.style.display = 'none';
                }
            }
            
            // Cancel button should ALWAYS be visible
            if (cancelBtn) {
                cancelBtn.style.display = '';
                cancelBtn.disabled = false;
            }
            
            // Also update modal title if read-only
            if (!canWrite) {
                title.textContent = 'Consulter l\'enregistrement DNS';
            }
            
            // Show history section in edit mode
            const historySection = document.getElementById('record-history-section');
            if (historySection) {
                historySection.style.display = 'block';
            }

            modal.style.display = 'block';
            modal.classList.add('open');
            
            // Call centering helper if available
            if (typeof window.ensureModalCentered === 'function') {
                window.ensureModalCentered(modal);
            }
        } catch (error) {
            console.error('Error opening edit modal:', error);
            // Show error in modal banner if modal is open, otherwise use page message
            const modal = document.getElementById('dns-modal');
            if (modal && modal.style.display !== 'none') {
                showModalError('dns', 'Erreur lors du chargement de l\'enregistrement : ' + error.message);
            } else {
                showMessage('Erreur lors du chargement de l\'enregistrement: ' + error.message, 'error');
            }
        }
    }

    /**
     * Close modal
     */
    function closeModal() {
        // Clear any error messages
        clearModalError('dns');
        
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

        // Clear any previous errors
        clearModalError('dns');

        const form = document.getElementById('dns-form');
        const mode = form.dataset.mode;
        const recordId = form.dataset.recordId;

        const recordType = document.getElementById('record-type').value;
        const zoneFileId = document.getElementById('record-zone-file').value;
        
        // Validate zone_file_id is selected
        if (!zoneFileId || zoneFileId === '') {
            showModalError('dns', 'Veuillez sélectionner un fichier de zone', 'record-zone-file');
            return;
        }

        // Handle TTL: if empty, send null; if provided, validate it's a positive integer
        const rawTtl = (document.getElementById('record-ttl').value || '').trim();
        let ttlValue = null;
        if (rawTtl !== '') {
            const parsedTtl = parseInt(rawTtl, 10);
            if (isNaN(parsedTtl) || parsedTtl <= 0) {
                showModalError('dns', 'Le TTL doit être un nombre entier positif', 'record-ttl');
                return;
            }
            ttlValue = parsedTtl;
        }
        
        const data = {
            zone_file_id: parseInt(zoneFileId),
            record_type: recordType,
            name: document.getElementById('record-name').value,
            ttl: ttlValue,
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
                data.cname_target = normalizeHostname(dedicatedValue);
                break;
            case 'PTR':
                dedicatedValue = document.getElementById('record-ptrdname').value;
                data.ptrdname = normalizeHostname(dedicatedValue);
                break;
            case 'TXT':
            case 'SPF':
            case 'DKIM':
            case 'DMARC':
                dedicatedValue = document.getElementById('record-txt').value;
                data.txt = dedicatedValue;
                break;
            case 'NS':
                dedicatedValue = document.getElementById('record-ns-target').value;
                data.ns_target = normalizeHostname(dedicatedValue);
                break;
            case 'DNAME':
                dedicatedValue = document.getElementById('record-dname-target').value;
                data.dname_target = normalizeHostname(dedicatedValue);
                break;
            case 'MX':
                dedicatedValue = document.getElementById('record-mx-target').value;
                data.mx_target = normalizeHostname(dedicatedValue);
                data.priority = parseInt(document.getElementById('record-priority').value, 10) || 10;
                break;
            case 'SRV':
                data.priority = parseInt(document.getElementById('record-srv-priority').value, 10) || 0;
                data.weight = parseInt(document.getElementById('record-srv-weight').value, 10) || 0;
                data.port = parseInt(document.getElementById('record-srv-port').value, 10) || 0;
                dedicatedValue = document.getElementById('record-srv-target').value;
                data.srv_target = normalizeHostname(dedicatedValue);
                break;
            case 'CAA':
                data.caa_flag = parseInt(document.getElementById('record-caa-flag').value, 10) || 0;
                data.caa_tag = document.getElementById('record-caa-tag').value || 'issue';
                dedicatedValue = document.getElementById('record-caa-value').value;
                data.caa_value = dedicatedValue;
                break;
            case 'TLSA':
                data.tlsa_usage = parseInt(document.getElementById('record-tlsa-usage').value, 10);
                data.tlsa_selector = parseInt(document.getElementById('record-tlsa-selector').value, 10);
                data.tlsa_matching = parseInt(document.getElementById('record-tlsa-matching').value, 10);
                dedicatedValue = document.getElementById('record-tlsa-data').value;
                data.tlsa_data = dedicatedValue;
                break;
            case 'SSHFP':
                data.sshfp_algo = parseInt(document.getElementById('record-sshfp-algo').value, 10);
                data.sshfp_type = parseInt(document.getElementById('record-sshfp-type').value, 10);
                dedicatedValue = document.getElementById('record-sshfp-fingerprint').value;
                data.sshfp_fingerprint = dedicatedValue;
                break;
            case 'NAPTR':
                data.naptr_order = parseInt(document.getElementById('record-naptr-order').value, 10) || 0;
                data.naptr_pref = parseInt(document.getElementById('record-naptr-pref').value, 10) || 0;
                data.naptr_flags = document.getElementById('record-naptr-flags').value || '';
                data.naptr_service = document.getElementById('record-naptr-service').value || '';
                data.naptr_regexp = document.getElementById('record-naptr-regexp').value || '';
                dedicatedValue = document.getElementById('record-naptr-replacement').value || '.';
                data.naptr_replacement = dedicatedValue === '.' ? '.' : normalizeHostname(dedicatedValue);
                break;
            case 'SVCB':
            case 'HTTPS':
                data.svc_priority = parseInt(document.getElementById('record-svc-priority').value, 10) || 1;
                dedicatedValue = document.getElementById('record-svc-target').value || '.';
                data.svc_target = normalizeHostname(dedicatedValue);
                data.svc_params = document.getElementById('record-svc-params').value || '';
                break;
            case 'LOC':
                data.loc_latitude = document.getElementById('record-loc-latitude').value || '';
                data.loc_longitude = document.getElementById('record-loc-longitude').value || '';
                data.loc_altitude = document.getElementById('record-loc-altitude').value || '';
                dedicatedValue = data.loc_latitude;
                break;
            case 'RP':
                dedicatedValue = document.getElementById('record-rp-mbox').value || '';
                data.rp_mbox = normalizeHostname(dedicatedValue);
                data.rp_txt = document.getElementById('record-rp-txt').value || '.';
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
            // Determine which field has the error for focus
            let errorFieldId = 'record-name';
            const error = validation.error.toLowerCase();
            
            // Map error messages to form field IDs
            if (error.includes('ipv4') || (error.includes('adresse') && recordType === 'A')) {
                errorFieldId = 'record-address-ipv4';
            } else if (error.includes('ipv6') || (error.includes('adresse') && recordType === 'AAAA')) {
                errorFieldId = 'record-address-ipv6';
            } else if (error.includes('cname')) {
                errorFieldId = 'record-cname-target';
            } else if (error.includes('ptr')) {
                errorFieldId = 'record-ptrdname';
            } else if (error.includes('txt')) {
                errorFieldId = 'record-txt';
            } else if (error.includes('ns_target') || (error.includes('ns') && recordType === 'NS')) {
                errorFieldId = 'record-ns-target';
            } else if (error.includes('dname')) {
                errorFieldId = 'record-dname-target';
            } else if (error.includes('mx_target') || (error.includes('mx') && recordType === 'MX' && error.includes('cible'))) {
                errorFieldId = 'record-mx-target';
            } else if (error.includes('priorité') && recordType === 'MX') {
                errorFieldId = 'record-priority';
            } else if (error.includes('srv') && error.includes('cible')) {
                errorFieldId = 'record-srv-target';
            } else if (error.includes('srv') && error.includes('port')) {
                errorFieldId = 'record-srv-port';
            } else if (error.includes('srv') && error.includes('poids')) {
                errorFieldId = 'record-srv-weight';
            } else if (error.includes('srv') && error.includes('priorité')) {
                errorFieldId = 'record-srv-priority';
            } else if (error.includes('caa') && error.includes('valeur')) {
                errorFieldId = 'record-caa-value';
            } else if (error.includes('caa') && error.includes('tag')) {
                errorFieldId = 'record-caa-tag';
            } else if (error.includes('tlsa') && error.includes('données')) {
                errorFieldId = 'record-tlsa-data';
            } else if (error.includes('sshfp') && error.includes('empreinte')) {
                errorFieldId = 'record-sshfp-fingerprint';
            } else if (error.includes('naptr') && error.includes('ordre')) {
                errorFieldId = 'record-naptr-order';
            } else if (error.includes('naptr') && error.includes('préférence')) {
                errorFieldId = 'record-naptr-pref';
            } else if (error.includes('svcb') || error.includes('https')) {
                if (error.includes('priorité')) {
                    errorFieldId = 'record-svc-priority';
                } else if (error.includes('cible')) {
                    errorFieldId = 'record-svc-target';
                }
            } else if (error.includes('loc') && error.includes('latitude')) {
                errorFieldId = 'record-loc-latitude';
            } else if (error.includes('loc') && error.includes('longitude')) {
                errorFieldId = 'record-loc-longitude';
            } else if (error.includes('rp') && error.includes('mailbox')) {
                errorFieldId = 'record-rp-mbox';
            } else if (error.includes('rp') && error.includes('txt domain')) {
                errorFieldId = 'record-rp-txt';
            }
            
            showModalError('dns', validation.error, errorFieldId);
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
            showModalError('dns', 'Erreur : ' + error.message);
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
     * Optional guard/observer to protect modal zonefile select from being overwritten
     * Monitors the select for unexpected changes within 800ms after initialization
     * Acts as a safety net during progressive deployment
     */
    let modalSelectGuardTimeout = null;
    let modalSelectLastSnapshot = null;
    
    function activateModalSelectGuard() {
        const selectElement = document.getElementById('modal-zonefile-select');
        if (!selectElement) return;
        
        // Clear any existing guard
        if (modalSelectGuardTimeout) {
            clearTimeout(modalSelectGuardTimeout);
            modalSelectGuardTimeout = null;
        }
        
        // Take snapshot of current state
        modalSelectLastSnapshot = {
            innerHTML: selectElement.innerHTML,
            value: selectElement.value,
            timestamp: Date.now()
        };
        
        console.debug('[modalSelectGuard] Activated, snapshot taken');
        
        // Set timeout to check after 800ms
        modalSelectGuardTimeout = setTimeout(() => {
            if (!modalSelectLastSnapshot) return;
            
            const currentInnerHTML = selectElement.innerHTML;
            const currentValue = selectElement.value;
            
            // Check if select was unexpectedly modified
            if (currentInnerHTML !== modalSelectLastSnapshot.innerHTML || 
                currentValue !== modalSelectLastSnapshot.value) {
                console.warn('[modalSelectGuard] Modal select was overwritten, restoring...');
                
                // Restore snapshot
                selectElement.innerHTML = modalSelectLastSnapshot.innerHTML;
                selectElement.value = modalSelectLastSnapshot.value;
                
                // Trigger change event
                const changeEvent = new Event('change', { bubbles: true });
                selectElement.dispatchEvent(changeEvent);
            } else {
                console.debug('[modalSelectGuard] Select unchanged, guard deactivated');
            }
            
            // Clear guard
            modalSelectGuardTimeout = null;
            modalSelectLastSnapshot = null;
        }, 800);
    }
    
    /**
     * Guard function for modal combobox (replaces activateModalSelectGuard for combobox)
     * Monitors the combobox for unexpected changes within 800ms after initialization
     */
    let modalComboboxGuardTimeout = null;
    let modalComboboxLastSnapshot = null;
    
    function activateModalComboboxGuard() {
        const inputElement = document.getElementById('modal-zonefile-input');
        const hiddenElement = document.getElementById('modal-zonefile-id');
        
        if (!inputElement || !hiddenElement) return;
        
        // Clear any existing guard
        if (modalComboboxGuardTimeout) {
            clearTimeout(modalComboboxGuardTimeout);
            modalComboboxGuardTimeout = null;
        }
        
        // Take snapshot of current state
        modalComboboxLastSnapshot = {
            inputValue: inputElement.value,
            hiddenValue: hiddenElement.value,
            allZones: inputElement.dataset.allZones || '',
            timestamp: Date.now()
        };
        
        console.debug('[modalComboboxGuard] Activated, snapshot taken');
        
        // Set timeout to check after 800ms
        modalComboboxGuardTimeout = setTimeout(() => {
            if (!modalComboboxLastSnapshot) return;
            
            const currentInputValue = inputElement.value;
            const currentHiddenValue = hiddenElement.value;
            const currentAllZones = inputElement.dataset.allZones || '';
            
            // Check if combobox was unexpectedly modified
            if (currentInputValue !== modalComboboxLastSnapshot.inputValue || 
                currentHiddenValue !== modalComboboxLastSnapshot.hiddenValue ||
                currentAllZones !== modalComboboxLastSnapshot.allZones) {
                console.warn('[modalComboboxGuard] Modal combobox was overwritten, restoring...');
                
                // Restore snapshot
                inputElement.value = modalComboboxLastSnapshot.inputValue;
                hiddenElement.value = modalComboboxLastSnapshot.hiddenValue;
                inputElement.dataset.allZones = modalComboboxLastSnapshot.allZones;
            } else {
                console.debug('[modalComboboxGuard] Combobox unchanged, guard deactivated');
            }
            
            // Clear guard
            modalComboboxGuardTimeout = null;
            modalComboboxLastSnapshot = null;
        }, 800);
    }

    /**
     * Initialize event listeners
     */
    function init() {
        // Initialize comboboxes
        initDomainCombobox();
        initZoneCombobox();
        initModalZoneCombobox();
        
        // Populate domain select (if element exists)
        if (document.getElementById('dns-domain-filter')) {
            populateDomainSelect();
        }
        
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
        
        // Initialize type buttons for two-step modal flow
        initTypeButtons();
        
        // Initialize previous button
        initPreviousButton();
        
        // Initialize preview listeners
        initPreviewListeners();

        // Initial load
        const tableBody = document.getElementById('dns-table-body');
        if (tableBody) {
            // Load table immediately (comboboxes initialized asynchronously)
            loadDnsTable();
        }
    }

    // =========================================================================
    // Record History Functions
    // =========================================================================
    
    /**
     * Fetch record history from API
     * Defensive implementation with fallback for BASE_URL
     * @param {number} recordId - The record ID to fetch history for
     * @returns {Promise<Array>} - Array of history entries or empty array on error
     */
    async function fetchRecordHistory(recordId) {
        if (!recordId || recordId <= 0) {
            console.warn('[fetchRecordHistory] Invalid recordId:', recordId);
            return [];
        }

        try {
            const url = getApiUrl('get_record_history', { record_id: recordId });
            const response = await fetch(url, {
                method: 'GET',
                credentials: 'same-origin',
                headers: {
                    'X-Requested-With': 'XMLHttpRequest'
                }
            });

            const text = await response.text();
            let data;
            try {
                data = JSON.parse(text);
            } catch (jsonError) {
                console.error('[fetchRecordHistory] Failed to parse JSON:', jsonError);
                return [];
            }

            if (!response.ok || !data.success) {
                console.error('[fetchRecordHistory] API error:', data.error || response.statusText);
                return [];
            }

            return data.data || [];
        } catch (error) {
            console.error('[fetchRecordHistory] Exception:', error);
            return [];
        }
    }

    /**
     * Render record history into a container
     * @param {HTMLElement} container - The container element to render into
     * @param {Array} rows - Array of history entries
     */
    function renderRecordHistory(container, rows) {
        if (!container) {
            console.warn('[renderRecordHistory] Container element not provided');
            return;
        }

        // Clear container
        container.innerHTML = '';

        if (!rows || rows.length === 0) {
            container.innerHTML = '<p class="history-empty">Aucun historique disponible pour cet enregistrement.</p>';
            return;
        }

        // Create compact table
        const table = document.createElement('table');
        table.className = 'history-table';
        
        // Header
        const thead = document.createElement('thead');
        thead.innerHTML = `
            <tr>
                <th>Date</th>
                <th>Action</th>
                <th>Utilisateur</th>
                <th>Détails</th>
            </tr>
        `;
        table.appendChild(thead);

        // Body
        const tbody = document.createElement('tbody');
        rows.forEach(row => {
            const tr = document.createElement('tr');
            
            // Format date
            const dateStr = row.changed_at ? formatDateTime(row.changed_at) : '-';
            
            // Format action
            const actionLabels = {
                'created': 'Créé',
                'updated': 'Modifié',
                'status_changed': 'Statut modifié'
            };
            const actionLabel = actionLabels[row.action] || row.action;
            
            // Username
            const username = escapeHtml(row.changed_by_username || 'Inconnu');
            
            // Build details summary
            let details = [];
            if (row.name) details.push('Nom: ' + escapeHtml(String(row.name)));
            if (row.record_type) details.push('Type: ' + escapeHtml(String(row.record_type)));
            if (row.value) {
                const valueStr = String(row.value);
                const truncated = valueStr.substring(0, 50) + (valueStr.length > 50 ? '...' : '');
                details.push('Valeur: ' + escapeHtml(truncated));
            }
            if (row.ttl !== null && row.ttl !== undefined) details.push('TTL: ' + escapeHtml(String(row.ttl)));
            if (row.old_status && row.new_status && row.action === 'status_changed') {
                details.push(escapeHtml(String(row.old_status)) + ' → ' + escapeHtml(String(row.new_status)));
            }
            if (row.notes) details.push(escapeHtml(String(row.notes)));
            
            const detailsStr = details.length > 0 ? details.join(', ') : '-';
            
            tr.innerHTML = `
                <td class="history-date">${dateStr}</td>
                <td class="history-action"><span class="action-badge action-${escapeHtml(String(row.action))}">${actionLabel}</span></td>
                <td class="history-user">${username}</td>
                <td class="history-details">${detailsStr}</td>
            `;
            tbody.appendChild(tr);
        });
        table.appendChild(tbody);

        container.appendChild(table);
    }

    /**
     * Toggle history panel visibility and load history if needed
     * DEPRECATED: This function is kept for backward compatibility.
     * The new implementation uses a dedicated modal (recordHistoryModal).
     * @param {number} recordId - The record ID to load history for
     */
    async function toggleHistoryPanel(recordId) {
        // Try new modal first
        const historyModal = document.getElementById('recordHistoryModal');
        const historyContainer = document.getElementById('record-history-container');
        
        if (historyModal && historyContainer) {
            // Use new modal approach
            historyContainer.innerHTML = '<p class="history-loading">Chargement de l\'historique...</p>';
            
            // Open modal
            if (typeof window.openHistoryModal === 'function') {
                window.openHistoryModal();
            } else {
                historyModal.style.display = 'block';
                historyModal.classList.add('open');
            }
            
            // Fetch and render history
            const history = await fetchRecordHistory(recordId);
            renderRecordHistory(historyContainer, history);
            return;
        }
        
        // Fallback: Old inline panel approach (for backward compatibility)
        const panel = document.getElementById('record-history-panel');
        const content = document.getElementById('record-history-content');
        const toggleBtn = document.getElementById('record-history-toggle');
        
        if (!panel || !content) {
            console.warn('[toggleHistoryPanel] History panel elements not found');
            return;
        }

        const isHidden = panel.style.display === 'none' || !panel.style.display;
        
        if (isHidden) {
            // Show panel
            panel.style.display = 'block';
            if (toggleBtn) {
                toggleBtn.textContent = 'Masquer l\'historique';
                toggleBtn.setAttribute('aria-expanded', 'true');
            }
            
            // Lazy load history if not already loaded for this record
            const currentRecordId = panel.dataset.recordId || '';
            const needsLoad = panel.dataset.loaded !== 'true' || currentRecordId !== String(recordId);
            
            if (needsLoad) {
                content.innerHTML = '<p class="history-loading">Chargement de l\'historique...</p>';
                
                const history = await fetchRecordHistory(recordId);
                renderRecordHistory(content, history);
                
                panel.dataset.loaded = 'true';
                panel.dataset.recordId = String(recordId);
            }
        } else {
            // Hide panel
            panel.style.display = 'none';
            if (toggleBtn) {
                toggleBtn.textContent = 'Voir l\'historique';
                toggleBtn.setAttribute('aria-expanded', 'false');
            }
        }
    }

    /**
     * Reset history panel/modal state (called when edit modal opens)
     * Works with both old inline panel and new modal approach
     */
    function resetHistoryPanel() {
        // New modal approach
        const historyContainer = document.getElementById('record-history-container');
        if (historyContainer) {
            historyContainer.innerHTML = '';
        }
        
        // Close history modal if open
        const historyModal = document.getElementById('recordHistoryModal');
        if (historyModal) {
            if (typeof window.closeHistoryModal === 'function') {
                window.closeHistoryModal();
            } else {
                historyModal.style.display = 'none';
                historyModal.classList.remove('open');
            }
        }
        
        // Old inline panel approach (backward compatibility)
        const panel = document.getElementById('record-history-panel');
        const content = document.getElementById('record-history-content');
        const toggleBtn = document.getElementById('record-history-toggle');
        
        if (panel) {
            panel.style.display = 'none';
            panel.dataset.loaded = '';
            panel.dataset.recordId = '';
        }
        if (content) {
            content.innerHTML = '';
        }
        if (toggleBtn) {
            toggleBtn.textContent = 'Voir l\'historique';
            toggleBtn.setAttribute('aria-expanded', 'false');
        }
    }

    /**
     * Alias for resetHistoryPanel for API consistency with spec
     * Called from openEditModal() to reset modal state
     */
    function resetRecordHistoryModalState() {
        resetHistoryPanel();
    }

    /**
     * Sync history modal size with edit modal
     * Copies the width/height from dns-modal-content to history-modal-content
     * so the history modal has the same size as the edit popup
     */
    function syncHistoryModalSize() {
        const editModalContent = document.querySelector('#dns-modal .dns-modal-content');
        const historyModalContent = document.querySelector('#recordHistoryModal .dns-modal-content');
        
        if (!editModalContent || !historyModalContent) {
            console.warn('[syncHistoryModalSize] Modal content elements not found');
            return;
        }
        
        // Get computed styles from edit modal
        const editStyles = window.getComputedStyle(editModalContent);
        const editRect = editModalContent.getBoundingClientRect();
        
        // Apply size to history modal if edit modal is visible
        if (editRect.width > 0 && editRect.height > 0) {
            historyModalContent.style.width = editRect.width + 'px';
            historyModalContent.style.maxWidth = editRect.width + 'px';
            historyModalContent.style.minHeight = Math.min(editRect.height, window.innerHeight * 0.8) + 'px';
            
            // Copy modal size classes from edit modal for consistent sizing
            // (e.g., modal-lg, modal-sm, modal-xl from Bootstrap)
            const editClasses = editModalContent.className.split(' ').filter(function(c) {
                // Copy modal size classes but exclude content wrapper class
                return c.indexOf('modal-') === 0 && c !== 'dns-modal-content';
            });
            editClasses.forEach(function(cls) {
                if (!historyModalContent.classList.contains(cls)) {
                    historyModalContent.classList.add(cls);
                }
            });
        }
        
        // Ensure history modal body is scrollable
        const historyBody = historyModalContent.querySelector('.dns-modal-body');
        if (historyBody) {
            historyBody.style.overflowY = 'auto';
            historyBody.style.maxHeight = 'calc(70vh - 120px)';
        }
    }

    /**
     * Open record history modal for the currently editing record
     * Called from the #btn-open-history button click handler
     * Syncs modal size, shows spinner, fetches history, and opens modal
     */
    async function openRecordHistoryModalForCurrentRecord() {
        const form = document.getElementById('dns-form');
        const recordId = form && form.dataset.recordId ? parseInt(form.dataset.recordId, 10) : 0;
        
        if (!recordId || recordId <= 0) {
            console.warn('[openRecordHistoryModalForCurrentRecord] No valid recordId found');
            return;
        }
        
        // Show spinner in container
        const container = document.getElementById('record-history-container');
        if (container) {
            container.innerHTML = '<p class="history-loading">Chargement de l\'historique...</p>';
        }
        
        // Sync modal size with edit modal
        syncHistoryModalSize();
        
        // Open the history modal
        if (typeof window.openHistoryModal === 'function') {
            window.openHistoryModal();
        } else {
            // Fallback if openHistoryModal not yet defined
            const historyModal = document.getElementById('recordHistoryModal');
            if (historyModal) {
                historyModal.style.display = 'block';
                historyModal.classList.add('open');
            }
        }
        
        // Fetch and render history (defensive check for function availability)
        try {
            if (typeof fetchRecordHistory !== 'function') {
                throw new Error('fetchRecordHistory function not available');
            }
            const rows = await fetchRecordHistory(recordId);
            if (container && typeof renderRecordHistory === 'function') {
                renderRecordHistory(container, rows);
            }
        } catch (error) {
            console.error('[openRecordHistoryModalForCurrentRecord] Error fetching history:', error);
            if (container) {
                container.innerHTML = '<p class="history-empty">Erreur lors du chargement de l\'historique.</p>';
            }
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
        restoreRecord,
        toggleHistoryPanel
    };

    // Expose helper functions globally for event handlers
    window.setDomainForZone = setDomainForZone;
    window.populateZoneFileCombobox = populateZoneFileCombobox;
    window.populateZoneComboboxForDomain = populateZoneComboboxForDomain;
    window.populateDomainSelect = populateDomainSelect;
    window.initModalZonefileSelect = initModalZonefileSelect;
    window.fillModalZonefileSelect = fillModalZonefileSelect;
    window.getMasterIdFromZoneId = getMasterIdFromZoneId;
    window.setDnsZoneComboboxEnabled = setDnsZoneComboboxEnabled;
    
    // Expose combobox init functions for reuse by zone-files.js
    window.initDomainCombobox = initDomainCombobox;
    window.initZoneCombobox = initZoneCombobox;
    
    // Expose new helper functions
    window.getTopMasterId = getTopMasterId;
    window.fetchZonesForMaster = fetchZonesForMaster;
    window.filterSubtreeDefensive = filterSubtreeDefensive;
    window.fillModalZonefileSelectFiltered = fillModalZonefileSelectFiltered;
    window.activateModalSelectGuard = activateModalSelectGuard;
    window.activateModalComboboxGuard = activateModalComboboxGuard;
    
    // Expose record history functions
    window.fetchRecordHistory = fetchRecordHistory;
    window.renderRecordHistory = renderRecordHistory;
    window.toggleHistoryPanel = toggleHistoryPanel;
    window.resetHistoryPanel = resetHistoryPanel;
    window.resetRecordHistoryModalState = resetRecordHistoryModalState;
    window.syncHistoryModalSize = syncHistoryModalSize;
    window.openRecordHistoryModalForCurrentRecord = openRecordHistoryModalForCurrentRecord;
    
    // Expose modal error handling functions
    window.showModalError = showModalError;
    window.clearModalError = clearModalError;
    
    // Expose API functions globally for debugging
    window.zoneApiCall = zoneApiCall;
    window.apiCall = apiCall;

    // Initialize on DOM ready
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', init);
    } else {
        init();
    }
})();
