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
     * Get the user's permission level for a specific zone file
     * @param {number|string} zoneFileId - The zone file ID to check
     * @returns {Promise<string|null>} Permission level ('admin', 'write', 'read') or null if forbidden/error
     */
    async function getZonePermission(zoneFileId) {
        if (!zoneFileId) return null;
        
        // Use window.API_BASE or window.BASE_URL or fallback to current origin
        const apiBase = window.API_BASE || window.BASE_URL || '';
        const normalizedBase = apiBase.endsWith('/') ? apiBase : (apiBase ? apiBase + '/' : '');
        const url = `${normalizedBase}api/zone_api.php?action=get_zone_permission&zone_file_id=${encodeURIComponent(zoneFileId)}`;
        
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
     * @param {string|null} permission - Permission level ('admin', 'write', 'read', or null)
     */
    function applyUiPermission(permission) {
        const deleteButtons = document.querySelectorAll('.btn-delete-record, .btn-delete');
        const saveButton = document.querySelector('#record-save-btn');
        const canWrite = (permission === 'admin' || permission === 'write');
        
        // Enable/disable delete buttons
        deleteButtons.forEach(btn => {
            btn.disabled = !canWrite;
            if (!canWrite) {
                btn.title = 'Vous n\'avez pas les droits pour supprimer cet enregistrement';
            } else {
                btn.title = '';
            }
        });
        
        // Enable/disable save button
        if (saveButton) {
            saveButton.disabled = !canWrite;
            if (!canWrite) {
                saveButton.title = 'Vous n\'avez pas les droits pour modifier cet enregistrement';
            } else {
                saveButton.title = '';
            }
        }
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
        applyUiPermission: applyUiPermission
    };

    // Initialize on DOM ready
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', init);
    } else {
        init();
    }
})();
