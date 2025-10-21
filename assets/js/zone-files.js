/**
 * Zone Files Management JavaScript
 * Handles UI interactions for zone file management with recursive includes
 */

// Global state
window.currentZoneId = null;
window.zones = [];

// API base URL
const API_BASE = window.API_BASE || '/api/zone_api.php';

/**
 * Initialize page on load
 */
document.addEventListener('DOMContentLoaded', function() {
    loadZonesList();
    setupEventHandlers();
});

/**
 * Setup event handlers
 */
function setupEventHandlers() {
    // Tab switching
    document.querySelectorAll('.tab-btn').forEach(btn => {
        btn.addEventListener('click', function() {
            switchTab(this.dataset.tab);
        });
    });

    // Details form submission
    document.getElementById('detailsForm').addEventListener('submit', function(e) {
        e.preventDefault();
        saveZoneDetails();
    });

    // Create zone form submission
    document.getElementById('createZoneForm').addEventListener('submit', function(e) {
        e.preventDefault();
        createZone();
    });

    // Add include form submission
    document.getElementById('addIncludeForm').addEventListener('submit', function(e) {
        e.preventDefault();
        addIncludeToZone();
    });

    // Search and filter handlers
    document.getElementById('searchZones').addEventListener('input', filterZones);
    document.getElementById('filterType').addEventListener('change', filterZones);
    document.getElementById('filterStatus').addEventListener('change', filterZones);

    // Modal close on outside click
    window.onclick = function(event) {
        if (event.target.classList.contains('modal')) {
            event.target.style.display = 'none';
        }
    };
}

/**
 * Make API call to zone API
 */
async function zoneApiCall(action, options = {}) {
    const method = options.method || 'GET';
    const params = options.params || {};
    const body = options.body || null;

    let url = `${API_BASE}?action=${action}`;
    if (method === 'GET' && Object.keys(params).length > 0) {
        const queryString = new URLSearchParams(params).toString();
        url += `&${queryString}`;
    }

    const fetchOptions = {
        method: method,
        headers: {
            'Content-Type': 'application/json'
        }
    };

    if (body && (method === 'POST' || method === 'PUT')) {
        fetchOptions.body = JSON.stringify(body);
    }

    try {
        const response = await fetch(url, fetchOptions);
        const data = await response.json();

        if (!response.ok) {
            throw new Error(data.error || `HTTP error ${response.status}`);
        }

        return data;
    } catch (error) {
        console.error('API call failed:', error);
        throw error;
    }
}

/**
 * Load zones list
 */
async function loadZonesList() {
    try {
        const response = await zoneApiCall('list_zones', {
            params: {
                status: document.getElementById('filterStatus').value || 'active',
                limit: 1000
            }
        });

        window.zones = response.data || [];
        renderZonesList();
    } catch (error) {
        console.error('Failed to load zones:', error);
        showError('Erreur lors du chargement des zones: ' + error.message);
    }
}

/**
 * Render zones list
 */
function renderZonesList() {
    const masterList = document.getElementById('masterZonesList');
    const includeList = document.getElementById('includeZonesList');

    const filteredZones = getFilteredZones();

    const masters = filteredZones.filter(z => z.file_type === 'master');
    const includes = filteredZones.filter(z => z.file_type === 'include');

    masterList.innerHTML = masters.length > 0
        ? masters.map(zone => renderZoneItem(zone)).join('')
        : '<div class="empty-list">Aucune zone master</div>';

    includeList.innerHTML = includes.length > 0
        ? includes.map(zone => renderZoneItem(zone)).join('')
        : '<div class="empty-list">Aucun fichier include</div>';
}

/**
 * Get filtered zones based on search and filters
 */
function getFilteredZones() {
    const search = document.getElementById('searchZones').value.toLowerCase();
    const typeFilter = document.getElementById('filterType').value;
    const statusFilter = document.getElementById('filterStatus').value;

    return window.zones.filter(zone => {
        const matchesSearch = !search || 
            zone.name.toLowerCase().includes(search) ||
            zone.filename.toLowerCase().includes(search);
        const matchesType = !typeFilter || zone.file_type === typeFilter;
        const matchesStatus = !statusFilter || zone.status === statusFilter;

        return matchesSearch && matchesType && matchesStatus;
    });
}

/**
 * Render single zone item
 */
function renderZoneItem(zone) {
    const statusClass = zone.status === 'active' ? 'status-active' : 
                       zone.status === 'inactive' ? 'status-inactive' : 'status-deleted';
    const isActive = window.currentZoneId === zone.id ? 'active' : '';

    return `
        <div class="zone-item ${isActive} ${statusClass}" onclick="loadZoneDetails(${zone.id})">
            <div class="zone-item-name">${escapeHtml(zone.name)}</div>
            <div class="zone-item-filename">${escapeHtml(zone.filename)}</div>
            <div class="zone-item-status">${zone.status}</div>
        </div>
    `;
}

/**
 * Filter zones based on current filters
 */
function filterZones() {
    renderZonesList();
}

/**
 * Load zone details
 */
async function loadZoneDetails(zoneId) {
    window.currentZoneId = zoneId;

    try {
        const response = await zoneApiCall('get_zone', {
            params: { id: zoneId }
        });

        const zone = response.data;
        displayZoneDetails(zone);
        
        // Update includes tab
        loadIncludeTree(zoneId);
        
        // Update history tab
        displayHistory(response.history || []);

        // Highlight selected zone in list
        document.querySelectorAll('.zone-item').forEach(item => {
            item.classList.remove('active');
        });
        document.querySelectorAll('.zone-item').forEach(item => {
            if (item.onclick.toString().includes(`(${zoneId})`)) {
                item.classList.add('active');
            }
        });

    } catch (error) {
        console.error('Failed to load zone details:', error);
        showError('Erreur lors du chargement des détails: ' + error.message);
    }
}

/**
 * Display zone details in the right pane
 */
function displayZoneDetails(zone) {
    document.getElementById('emptyState').style.display = 'none';
    document.getElementById('zoneDetails').style.display = 'block';

    document.getElementById('zoneName').textContent = zone.name;
    document.getElementById('detailName').value = zone.name;
    document.getElementById('detailFilename').value = zone.filename;
    document.getElementById('detailFileType').value = zone.file_type;
    document.getElementById('detailStatus').value = zone.status;
    document.getElementById('contentEditor').value = zone.content || '';

    document.getElementById('detailCreatedBy').textContent = zone.created_by_username || 'N/A';
    document.getElementById('detailCreatedAt').textContent = formatDate(zone.created_at);
    document.getElementById('detailUpdatedBy').textContent = zone.updated_by_username || 'N/A';
    document.getElementById('detailUpdatedAt').textContent = formatDate(zone.updated_at);
}

/**
 * Save zone details
 */
async function saveZoneDetails() {
    try {
        const data = {
            name: document.getElementById('detailName').value,
            filename: document.getElementById('detailFilename').value,
            file_type: document.getElementById('detailFileType').value
        };

        // Only update status via setStatus endpoint if changed
        const currentZone = window.zones.find(z => z.id === window.currentZoneId);
        const newStatus = document.getElementById('detailStatus').value;
        
        if (currentZone && currentZone.status !== newStatus) {
            await zoneApiCall('set_status_zone', {
                method: 'GET',
                params: { id: window.currentZoneId, status: newStatus }
            });
        }

        await zoneApiCall('update_zone', {
            method: 'POST',
            params: { id: window.currentZoneId },
            body: data
        });

        showSuccess('Zone mise à jour avec succès');
        loadZonesList();
        loadZoneDetails(window.currentZoneId);
    } catch (error) {
        console.error('Failed to save zone:', error);
        showError('Erreur lors de la sauvegarde: ' + error.message);
    }
}

/**
 * Save content
 */
async function saveContent() {
    try {
        const content = document.getElementById('contentEditor').value;

        await zoneApiCall('update_zone', {
            method: 'POST',
            params: { id: window.currentZoneId },
            body: { content: content }
        });

        showSuccess('Contenu sauvegardé avec succès');
        loadZoneDetails(window.currentZoneId);
    } catch (error) {
        console.error('Failed to save content:', error);
        showError('Erreur lors de la sauvegarde du contenu: ' + error.message);
    }
}

/**
 * Delete zone
 */
async function deleteZone() {
    if (!confirm('Êtes-vous sûr de vouloir supprimer cette zone?')) {
        return;
    }

    try {
        await zoneApiCall('set_status_zone', {
            method: 'GET',
            params: { id: window.currentZoneId, status: 'deleted' }
        });

        showSuccess('Zone supprimée avec succès');
        window.currentZoneId = null;
        document.getElementById('emptyState').style.display = 'block';
        document.getElementById('zoneDetails').style.display = 'none';
        loadZonesList();
    } catch (error) {
        console.error('Failed to delete zone:', error);
        showError('Erreur lors de la suppression: ' + error.message);
    }
}

/**
 * Refresh zone details
 */
function refreshZoneDetails() {
    if (window.currentZoneId) {
        loadZoneDetails(window.currentZoneId);
    }
}

/**
 * Switch tab
 */
function switchTab(tabName) {
    // Update tab buttons
    document.querySelectorAll('.tab-btn').forEach(btn => {
        btn.classList.remove('active');
    });
    document.querySelector(`.tab-btn[data-tab="${tabName}"]`).classList.add('active');

    // Update tab panes
    document.querySelectorAll('.tab-pane').forEach(pane => {
        pane.classList.remove('active');
    });
    document.getElementById(`${tabName}Tab`).classList.add('active');

    // Load data for specific tabs if needed
    if (tabName === 'includes' && window.currentZoneId) {
        loadIncludeTree(window.currentZoneId);
    }
}

/**
 * Load include tree
 */
async function loadIncludeTree(zoneId) {
    const treeContainer = document.getElementById('includeTree');
    treeContainer.innerHTML = '<div class="loading">Chargement...</div>';

    try {
        const response = await zoneApiCall('get_tree', {
            params: { id: zoneId }
        });

        if (response.data) {
            treeContainer.innerHTML = renderIncludeTree(response.data, true);
        } else {
            treeContainer.innerHTML = '<div class="empty-list">Aucun include</div>';
        }
    } catch (error) {
        console.error('Failed to load include tree:', error);
        treeContainer.innerHTML = '<div class="error">Erreur lors du chargement</div>';
    }
}

/**
 * Render include tree recursively
 */
function renderIncludeTree(node, isRoot = false) {
    let html = '';

    if (isRoot) {
        html += `<div class="tree-node root-node">
            <div class="tree-node-content">
                <i class="fas fa-folder-open"></i>
                <strong>${escapeHtml(node.name)}</strong>
                <span class="badge">${node.file_type}</span>
            </div>`;
    }

    if (node.includes && node.includes.length > 0) {
        html += '<ul class="tree-children">';
        node.includes.forEach(include => {
            html += `<li class="tree-node">
                <div class="tree-node-content">
                    <i class="fas fa-file"></i>
                    <span>${escapeHtml(include.name)}</span>
                    <span class="badge badge-include">include</span>
                    <span class="badge badge-position">pos: ${include.position}</span>
                    <button class="btn btn-xs btn-danger" onclick="removeInclude(${node.id}, ${include.id})" title="Supprimer">
                        <i class="fas fa-times"></i>
                    </button>
                </div>`;

            if (include.includes && include.includes.length > 0) {
                html += renderIncludeTree(include, false);
            }

            html += '</li>';
        });
        html += '</ul>';
    } else if (!isRoot) {
        // Leaf node with no children
    }

    if (isRoot) {
        html += '</div>';
    }

    return html;
}

/**
 * Remove include from zone
 */
async function removeInclude(parentId, includeId) {
    if (!confirm('Supprimer cet include?')) {
        return;
    }

    try {
        await zoneApiCall('remove_include', {
            params: { parent_id: parentId, include_id: includeId }
        });

        showSuccess('Include supprimé avec succès');
        loadIncludeTree(window.currentZoneId);
    } catch (error) {
        console.error('Failed to remove include:', error);
        showError('Erreur lors de la suppression: ' + error.message);
    }
}

/**
 * Display history
 */
function displayHistory(history) {
    const historyList = document.getElementById('historyList');

    if (history.length === 0) {
        historyList.innerHTML = '<div class="empty-list">Aucun historique</div>';
        return;
    }

    historyList.innerHTML = history.map(entry => {
        return `
            <div class="history-entry">
                <div class="history-header">
                    <span class="history-action">${entry.action}</span>
                    <span class="history-date">${formatDate(entry.changed_at)}</span>
                </div>
                <div class="history-details">
                    <div><strong>Par:</strong> ${escapeHtml(entry.changed_by_username || 'N/A')}</div>
                    ${entry.old_status ? `<div><strong>Ancien statut:</strong> ${entry.old_status}</div>` : ''}
                    ${entry.new_status ? `<div><strong>Nouveau statut:</strong> ${entry.new_status}</div>` : ''}
                    ${entry.notes ? `<div><strong>Notes:</strong> ${escapeHtml(entry.notes)}</div>` : ''}
                </div>
            </div>
        `;
    }).join('');
}

/**
 * Open create zone modal
 */
function openCreateZoneModal() {
    document.getElementById('createZoneForm').reset();
    document.getElementById('createZoneModal').style.display = 'block';
}

/**
 * Close create zone modal
 */
function closeCreateZoneModal() {
    document.getElementById('createZoneModal').style.display = 'none';
}

/**
 * Create zone
 */
async function createZone() {
    try {
        const data = {
            name: document.getElementById('createName').value,
            filename: document.getElementById('createFilename').value,
            file_type: document.getElementById('createFileType').value,
            content: document.getElementById('createContent').value
        };

        const response = await zoneApiCall('create_zone', {
            method: 'POST',
            body: data
        });

        showSuccess('Zone créée avec succès');
        closeCreateZoneModal();
        await loadZonesList();
        
        // Load the new zone
        if (response.id) {
            loadZoneDetails(response.id);
        }
    } catch (error) {
        console.error('Failed to create zone:', error);
        showError('Erreur lors de la création: ' + error.message);
    }
}

/**
 * Open add include modal
 */
async function openAddIncludeModal() {
    // Load available includes
    try {
        const response = await zoneApiCall('list_zones', {
            params: { file_type: 'include', status: 'active', limit: 1000 }
        });

        const select = document.getElementById('selectInclude');
        select.innerHTML = '<option value="">-- Choisir --</option>';
        
        response.data.forEach(zone => {
            // Don't show current zone or its ancestors to prevent cycles
            if (zone.id !== window.currentZoneId) {
                select.innerHTML += `<option value="${zone.id}">${escapeHtml(zone.name)} (${zone.filename})</option>`;
            }
        });

        document.getElementById('addIncludeModal').style.display = 'block';
    } catch (error) {
        console.error('Failed to load includes:', error);
        showError('Erreur lors du chargement des includes: ' + error.message);
    }
}

/**
 * Close add include modal
 */
function closeAddIncludeModal() {
    document.getElementById('addIncludeModal').style.display = 'none';
}

/**
 * Add include to zone
 */
async function addIncludeToZone() {
    try {
        const includeId = document.getElementById('selectInclude').value;
        const position = document.getElementById('includePosition').value;

        if (!includeId) {
            showError('Veuillez sélectionner un fichier include');
            return;
        }

        await zoneApiCall('assign_include', {
            method: 'POST',
            body: {
                parent_id: window.currentZoneId,
                include_id: parseInt(includeId),
                position: parseInt(position)
            }
        });

        showSuccess('Include ajouté avec succès');
        closeAddIncludeModal();
        loadIncludeTree(window.currentZoneId);
    } catch (error) {
        console.error('Failed to add include:', error);
        showError('Erreur lors de l\'ajout de l\'include: ' + error.message);
    }
}

/**
 * Download zone content
 */
function downloadZoneContent() {
    if (!window.currentZoneId) return;
    
    window.location.href = `${API_BASE}?action=download_zone&id=${window.currentZoneId}`;
}

/**
 * Show resolved content
 */
async function showResolvedContent() {
    try {
        const response = await zoneApiCall('render_resolved', {
            params: { id: window.currentZoneId }
        });

        document.getElementById('resolvedContent').textContent = response.content;
        document.getElementById('resolvedContentModal').style.display = 'block';
    } catch (error) {
        console.error('Failed to load resolved content:', error);
        showError('Erreur lors du chargement du contenu résolu: ' + error.message);
    }
}

/**
 * Close resolved content modal
 */
function closeResolvedContentModal() {
    document.getElementById('resolvedContentModal').style.display = 'none';
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
