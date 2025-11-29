/**
 * Zone Permission Management JavaScript
 * Handles UI enable/disable based on user's zone file permissions
 * 
 * This module:
 * - Queries the API for the current user's permission on a zone file
 * - Enables/disables Delete and Save buttons based on permission level
 * - Users with 'admin' or 'write' permission can modify records
 * - Users with 'read' permission have buttons disabled
 */

(function() {
    'use strict';

    /**
     * Helper to build API URL robustly
     * Handles cases where BASE_URL may or may not contain the 'api' segment
     * @param {string} endpoint - The API endpoint (e.g., 'zone_api.php?action=...')
     * @returns {string} The complete API URL
     */
    function buildApiPath(endpoint) {
        // Use API_BASE if available (already includes /api/), otherwise fallback to BASE_URL
        const apiBase = (typeof window.API_BASE !== 'undefined' && window.API_BASE) 
            ? String(window.API_BASE) 
            : '';
        const base = apiBase || ((typeof window.BASE_URL !== 'undefined' && window.BASE_URL) ? String(window.BASE_URL) : '/');
        
        // Normalize: remove trailing slashes from base
        const b = base.replace(/\/+$/, '');
        // Normalize: remove leading slashes from endpoint
        const e = String(endpoint).replace(/^\/+/, '');
        
        // If API_BASE is used and already contains 'api/', don't add 'api/' prefix
        // If BASE_URL is used (no 'api/' segment), prepend 'api/' to endpoint
        if (apiBase) {
            // API_BASE already ends with 'api/', so just append the endpoint
            return b + '/' + e;
        } else {
            // BASE_URL doesn't contain 'api/', so prepend it
            return b + '/api/' + e;
        }
    }

    /**
     * Get the user's permission level for a specific zone file
     * @param {number|string} zoneFileId - The zone file ID to check
     * @returns {Promise<string|null>} Permission level ('admin', 'write', 'read') or null if forbidden/error
     */
    async function getZonePermission(zoneFileId) {
        if (!zoneFileId) return null;
        
        // Build URL using the robust helper
        const url = buildApiPath(`zone_api.php?action=get_zone_permission&zone_file_id=${encodeURIComponent(zoneFileId)}`);
        
        try {
            const res = await fetch(url, {
                credentials: 'same-origin',
                headers: {
                    'X-Requested-With': 'XMLHttpRequest'
                }
            });
            
            if (res.status === 403) return null;
            if (!res.ok) return null;
            
            const json = await res.json();
            return json.permission || null;
        } catch (error) {
            console.error('[zone-permission] Error fetching permission:', error);
            return null;
        }
    }

    /**
     * Apply UI changes based on permission level
     * Only hides Save and Delete buttons for explicit read-only users
     * When permission is absent/undefined, buttons are shown (server-side security handles 403)
     * @param {string|null} permission - Permission level ('admin', 'write', 'read', or null)
     */
    function applyUiPermission(permission) {
        const saveButton = document.querySelector('#record-save-btn');
        const deleteButton = document.querySelector('#record-delete-btn');
        const cancelButton = document.querySelector('#record-cancel-btn');
        
        // Only hide buttons when permission is explicitly 'read'
        // If permission is undefined/null, show buttons (UX) and let server-side security handle 403
        const isReadOnly = (permission === 'read');
        
        // Log warning if permission is missing (helps debugging)
        if (typeof permission === 'undefined' || permission === null) {
            console.warn('applyUiPermission: permission not provided for this record — defaulting to show Save/Delete. Ensure API returns permission/can_write.');
        }
        
        // Show/hide save button based on permission
        if (saveButton) {
            saveButton.style.display = isReadOnly ? 'none' : '';
            saveButton.disabled = isReadOnly;
        }
        
        // Show/hide delete button based on permission
        if (deleteButton) {
            deleteButton.style.display = isReadOnly ? 'none' : '';
            deleteButton.disabled = isReadOnly;
        }
        
        // Cancel button should ALWAYS be visible and enabled
        if (cancelButton) {
            cancelButton.style.display = '';
            cancelButton.disabled = false;
        }
    }

    /**
     * Apply modal buttons visibility based on permission
     * This is the function called directly by other modules
     * Only hides Save and Delete buttons for explicit read-only users
     * When permission is absent/undefined, buttons are shown (UX) and server-side handles 403
     * @param {string|null} permission - Permission level ('admin', 'write', 'read', or null)
     */
    function applyModalButtons(permission) {
        applyUiPermission(permission);
    }

    /**
     * Initialize the zone permission module
     */
    function init() {
        // Find zone select element using multiple fallback selectors
        const zoneSelect = document.getElementById('select-zone-file') 
            || document.querySelector('select[name="zone_file_id"]')
            || document.getElementById('dns-zone-id')
            || document.getElementById('record-zone-file');
        
        if (zoneSelect) {
            // Listen for changes on the zone select
            zoneSelect.addEventListener('change', async function() {
                const zoneFileId = this.value ? parseInt(this.value, 10) : null;
                const perm = await getZonePermission(zoneFileId);
                applyUiPermission(perm);
            });
            
            // Apply permission on initial load if a zone is already selected
            (async function() {
                const initialValue = zoneSelect.value;
                if (initialValue) {
                    const perm = await getZonePermission(parseInt(initialValue, 10));
                    applyUiPermission(perm);
                }
            })();
        }
        
        // Also listen for modal open events to re-check permissions
        // This handles cases where the modal is opened with a pre-selected zone
        const dnsModal = document.getElementById('dns-modal');
        if (dnsModal) {
            // MutationObserver to detect when modal becomes visible
            const observer = new MutationObserver(function(mutations) {
                mutations.forEach(function(mutation) {
                    if (mutation.attributeName === 'style' || mutation.attributeName === 'class') {
                        const isOpen = dnsModal.style.display !== 'none' && 
                                      (dnsModal.style.display === 'block' || dnsModal.classList.contains('open'));
                        if (isOpen) {
                            // Re-check permission when modal opens
                            const modalZoneSelect = document.getElementById('record-zone-file') 
                                || document.getElementById('modal-zonefile-id');
                            if (modalZoneSelect && modalZoneSelect.value) {
                                getZonePermission(parseInt(modalZoneSelect.value, 10)).then(perm => {
                                    applyUiPermission(perm);
                                });
                            }
                        }
                    }
                });
            });
            
            observer.observe(dnsModal, { attributes: true });
        }
    }

    // Expose functions globally for use by other modules
    window.zonePermission = {
        getZonePermission: getZonePermission,
        applyUiPermission: applyUiPermission,
        applyModalButtons: applyModalButtons,
        buildApiPath: buildApiPath
    };
    
    // Also expose buildApiPath directly on window for easy access
    window.buildApiPath = buildApiPath;

    // Initialize on DOM ready
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', init);
    } else {
        init();
    }
})();
