/**
 * DNS Records Management JavaScript
 * Handles client-side interactions for DNS record management
 */

(function() {
    'use strict';

    let currentRecords = [];

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
                tbody.innerHTML = '<tr><td colspan="7" style="text-align: center; padding: 20px;">Aucun enregistrement trouvé</td></tr>';
                return;
            }

            currentRecords.forEach(record => {
                const row = document.createElement('tr');
                row.innerHTML = `
                    <td>${escapeHtml(record.id)}</td>
                    <td>${escapeHtml(record.record_type)}</td>
                    <td>${escapeHtml(record.name)}</td>
                    <td>${escapeHtml(record.value)}</td>
                    <td>${escapeHtml(record.ttl)}</td>
                    <td><span class="status-badge status-${record.status}">${escapeHtml(record.status)}</span></td>
                    <td>
                        <button class="btn-small btn-edit" onclick="dnsRecords.openEditModal(${record.id})">Modifier</button>
                        <button class="btn-small btn-status" onclick="dnsRecords.toggleStatus(${record.id}, '${record.status}')">
                            ${record.status === 'active' ? 'Désactiver' : 'Activer'}
                        </button>
                        ${record.status !== 'deleted' ? `<button class="btn-small btn-delete" onclick="dnsRecords.deleteRecord(${record.id})">Supprimer</button>` : ''}
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
     * Open modal to create a new record
     */
    function openCreateModal() {
        const modal = document.getElementById('dns-modal');
        const form = document.getElementById('dns-form');
        const title = document.getElementById('dns-modal-title');
        
        if (!modal || !form || !title) return;

        title.textContent = 'Créer un enregistrement DNS';
        form.reset();
        form.dataset.mode = 'create';
        delete form.dataset.recordId;

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
            
            if (!modal || !form || !title) return;

            title.textContent = 'Modifier l\'enregistrement DNS';
            form.dataset.mode = 'edit';
            form.dataset.recordId = recordId;

            document.getElementById('record-type').value = record.record_type;
            document.getElementById('record-name').value = record.name;
            document.getElementById('record-value').value = record.value;
            document.getElementById('record-ttl').value = record.ttl;
            document.getElementById('record-priority').value = record.priority || '';

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

        const data = {
            record_type: document.getElementById('record-type').value,
            name: document.getElementById('record-name').value,
            value: document.getElementById('record-value').value,
            ttl: parseInt(document.getElementById('record-ttl').value),
            priority: document.getElementById('record-priority').value ? parseInt(document.getElementById('record-priority').value) : null
        };

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
     * Toggle record status (active/disabled)
     */
    async function toggleStatus(recordId, currentStatus) {
        const newStatus = currentStatus === 'active' ? 'disabled' : 'active';
        
        try {
            await apiCall('set_status', { id: recordId, status: newStatus });
            showMessage(`Statut changé à ${newStatus}`, 'success');
            await loadDnsTable();
        } catch (error) {
            console.error('Error changing status:', error);
            showMessage('Erreur lors du changement de statut: ' + error.message, 'error');
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
        toggleStatus,
        deleteRecord
    };

    // Initialize on DOM ready
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', init);
    } else {
        init();
    }
})();
