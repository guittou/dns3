/**
 * DNS Records Management JavaScript
 * Handles client-side interactions for DNS record management
 */

(function() {
    'use strict';

    let currentRecords = [];

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
     * Construct API URL using window.API_BASE
     */
    function getApiUrl(action, params = {}) {
        const url = new URL(window.API_BASE + 'dns_api.php', window.location.origin);
        url.searchParams.append('action', action);
        
        Object.keys(params).forEach(key => {
            url.searchParams.append(key, params[key]);
        });

        return url.toString();
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

            const response = await fetch(url, options);
            
            // Try to parse JSON, fallback to text for debugging
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
            console.error('API call error:', error);
            throw error;
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

            const result = await apiCall('list', filters);
            currentRecords = result.data || [];

            const tbody = document.getElementById('dns-table-body');
            if (!tbody) return;

            tbody.innerHTML = '';

            if (currentRecords.length === 0) {
                tbody.innerHTML = '<tr><td colspan="10" style="text-align: center; padding: 20px;">Aucun enregistrement trouvé</td></tr>';
                return;
            }

            // Remplace la génération de la ligne (row.innerHTML = `...`) par ceci :
            currentRecords.forEach(record => {
                const row = document.createElement('tr');
                row.innerHTML = `
                    <td>${escapeHtml(record.id)}</td>
                    <td>${escapeHtml(record.name)}</td>
                    <td>${escapeHtml(record.ttl)}</td>
                    <td>${escapeHtml(record.class || 'IN')}</td>
                    <td>${escapeHtml(record.record_type)}</td>
                    <td>${escapeHtml(record.value)}</td>

                    <td>${escapeHtml(record.requester || '-')}</td>
                    <td>${record.expires_at ? formatDateTime(record.expires_at) : '-'}</td>
                    <td>${record.last_seen ? formatDateTime(record.last_seen) : '-'}</td>
                    <td><span class="status-badge status-${record.status}">${escapeHtml(record.status)}</span></td>
                    
                    <td>
                        <button class="btn-small btn-edit" onclick="dnsRecords.openEditModal(${record.id})">Modifier</button>
                        ${record.status !== 'deleted' ? `<button class="btn-small btn-delete" onclick="dnsRecords.deleteRecord(${record.id})">Supprimer</button>` : ''}
                        ${record.status === 'deleted' ? `<button class="btn-small btn-restore" onclick="dnsRecords.restoreRecord(${record.id})">Restaurer</button>` : ''}
                    </td>
                `;
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
     * Open modal to create a new record
     */
    function openCreateModal() {
        const modal = document.getElementById('dns-modal');
        const form = document.getElementById('dns-form');
        const title = document.getElementById('dns-modal-title');
        const lastSeenGroup = document.getElementById('record-last-seen-group');
        
        if (!modal || !form || !title) return;

        title.textContent = 'Créer un enregistrement DNS';
        form.reset();
        form.dataset.mode = 'create';
        delete form.dataset.recordId;
        
        // Hide last_seen field for new records
        if (lastSeenGroup) {
            lastSeenGroup.style.display = 'none';
        }

        // Update field visibility based on default record type
        updateFieldVisibility();

        modal.style.display = 'block';
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
            
            if (!modal || !form || !title) return;

            title.textContent = 'Modifier l\'enregistrement DNS';
            form.dataset.mode = 'edit';
            form.dataset.recordId = recordId;

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

            modal.style.display = 'block';
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

        const data = {
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

        // Create button
        const createBtn = document.getElementById('dns-create-btn');
        if (createBtn) {
            createBtn.addEventListener('click', openCreateModal);
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
