/**
 * Zone File Detail Page JavaScript
 * Handles the dedicated detail page for a single zone file
 */

// API base URL
const API_BASE = window.API_BASE || '/api/zone_api.php';

// Global zone data
let zoneData = null;
let autocompleteTimeout = null;

/**
 * Initialize page on load
 */
document.addEventListener('DOMContentLoaded', function() {
    setupEventHandlers();
    loadZoneDetails();
    
    // Check if a specific tab was requested
    const urlParams = new URLSearchParams(window.location.search);
    const tab = urlParams.get('tab');
    if (tab) {
        switchTab(tab);
    }
});

/**
 * Setup event handlers
 */
function setupEventHandlers() {
    // Details form submission
    const detailsForm = document.getElementById('detailsForm');
    if (detailsForm) {
        detailsForm.addEventListener('submit', function(e) {
            e.preventDefault();
            saveZoneDetails();
        });
    }

    // Add include form submission
    const addIncludeForm = document.getElementById('addIncludeForm');
    if (addIncludeForm) {
        addIncludeForm.addEventListener('submit', function(e) {
            e.preventDefault();
            addIncludeToZone();
        });
    }

    // Autocomplete for include search
    const includeSearch = document.getElementById('includeSearch');
    if (includeSearch) {
        includeSearch.addEventListener('input', function(e) {
            handleIncludeSearch(e.target.value);
        });
        
        // Clear selection when input changes
        includeSearch.addEventListener('input', function() {
            document.getElementById('selectedIncludeId').value = '';
        });
    }

    // Modal close on outside click
    window.onclick = function(event) {
        if (event.target.classList.contains('modal')) {
            event.target.style.display = 'none';
        }
    };
}

/**
 * Load zone details
 */
async function loadZoneDetails() {
    try {
        showLoading();
        
        const response = await zoneApiCall('get_zone', {
            params: { id: window.currentZoneId }
        });

        zoneData = response.data;
        displayZoneDetails(zoneData);
        
        // Update includes tab (load lazily when tab is opened)
        if (document.getElementById('includesTab').classList.contains('active')) {
            loadIncludeTree(window.currentZoneId);
        }
        
        // Update history tab
        displayHistory(response.history || []);
        
        hideLoading();
    } catch (error) {
        console.error('Failed to load zone details:', error);
        showErrorState('Erreur lors du chargement des détails: ' + error.message);
    }
}

/**
 * Display zone details
 */
function displayZoneDetails(zone) {
    // Update breadcrumb and header
    document.getElementById('zoneBreadcrumbName').textContent = zone.name;
    document.getElementById('zoneName').textContent = zone.name;
    
    // Update status and type badges
    const statusBadge = document.getElementById('zoneStatus');
    statusBadge.textContent = zone.status;
    statusBadge.className = 'badge badge-' + (zone.status === 'active' ? 'success' : 
                                                zone.status === 'inactive' ? 'warning' : 'danger');
    
    const typeBadge = document.getElementById('zoneType');
    typeBadge.textContent = zone.file_type;
    typeBadge.className = 'badge badge-' + (zone.file_type === 'master' ? 'master' : 'include');
    
    // Update form fields
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

        // Check if status changed
        const newStatus = document.getElementById('detailStatus').value;
        if (zoneData && zoneData.status !== newStatus) {
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
        loadZoneDetails();
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
        loadZoneDetails();
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
        // Redirect to list after deletion
        setTimeout(() => {
            window.location.href = window.BASE_URL + 'zone-files.php';
        }, 1000);
    } catch (error) {
        console.error('Failed to delete zone:', error);
        showError('Erreur lors de la suppression: ' + error.message);
    }
}

/**
 * Refresh zone details
 */
function refreshZoneDetails() {
    loadZoneDetails();
}

/**
 * Switch tab
 */
function switchTab(tabName) {
    // Update tab buttons
    document.querySelectorAll('.tab-btn').forEach(btn => {
        btn.classList.remove('active');
    });
    const tabBtn = document.querySelector(`.tab-btn[data-tab="${tabName}"]`);
    if (tabBtn) {
        tabBtn.classList.add('active');
    }

    // Update tab panes
    document.querySelectorAll('.tab-pane').forEach(pane => {
        pane.classList.remove('active');
    });
    const tabPane = document.getElementById(`${tabName}Tab`);
    if (tabPane) {
        tabPane.classList.add('active');
    }

    // Lazy load data for specific tabs
    if (tabName === 'includes' && window.currentZoneId) {
        loadIncludeTree(window.currentZoneId);
    }
}

/**
 * Load include tree (lazy loaded)
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
 * Handle include search (autocomplete)
 */
async function handleIncludeSearch(query) {
    clearTimeout(autocompleteTimeout);
    
    const resultsContainer = document.getElementById('autocompleteResults');
    
    if (query.length < 2) {
        resultsContainer.style.display = 'none';
        return;
    }
    
    autocompleteTimeout = setTimeout(async () => {
        try {
            const response = await zoneApiCall('search_zones', {
                params: {
                    q: query,
                    file_type: 'include',
                    limit: 20
                }
            });
            
            displayAutocompleteResults(response.data || []);
        } catch (error) {
            console.error('Autocomplete search failed:', error);
        }
    }, 300);
}

/**
 * Display autocomplete results
 */
function displayAutocompleteResults(results) {
    const container = document.getElementById('autocompleteResults');
    
    if (results.length === 0) {
        container.innerHTML = '<div class="autocomplete-item">Aucun résultat</div>';
        container.style.display = 'block';
        return;
    }
    
    container.innerHTML = results.map(zone => {
        // Don't show current zone to prevent self-reference
        if (zone.id === window.currentZoneId) {
            return '';
        }
        
        return `
            <div class="autocomplete-item" onclick="selectInclude(${zone.id}, '${escapeHtml(zone.name)}', '${escapeHtml(zone.filename)}')">
                <strong>${escapeHtml(zone.name)}</strong>
                <br>
                <small>${escapeHtml(zone.filename)}</small>
            </div>
        `;
    }).join('');
    
    container.style.display = 'block';
}

/**
 * Select an include from autocomplete
 */
function selectInclude(id, name, filename) {
    document.getElementById('includeSearch').value = `${name} (${filename})`;
    document.getElementById('selectedIncludeId').value = id;
    document.getElementById('autocompleteResults').style.display = 'none';
}

/**
 * Open add include modal
 */
function openAddIncludeModal() {
    document.getElementById('addIncludeForm').reset();
    document.getElementById('autocompleteResults').style.display = 'none';
    document.getElementById('addIncludeModal').style.display = 'block';
}

/**
 * Close add include modal
 */
function closeAddIncludeModal() {
    document.getElementById('addIncludeModal').style.display = 'none';
    document.getElementById('autocompleteResults').style.display = 'none';
}

/**
 * Add include to zone
 */
async function addIncludeToZone() {
    try {
        const includeId = document.getElementById('selectedIncludeId').value;
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
 * Show loading state
 */
function showLoading() {
    document.getElementById('loadingState').style.display = 'block';
    document.getElementById('errorState').style.display = 'none';
    document.getElementById('zoneDetails').style.display = 'none';
}

/**
 * Hide loading state
 */
function hideLoading() {
    document.getElementById('loadingState').style.display = 'none';
    document.getElementById('zoneDetails').style.display = 'block';
}

/**
 * Show error state
 */
function showErrorState(message) {
    document.getElementById('loadingState').style.display = 'none';
    document.getElementById('errorState').style.display = 'block';
    document.getElementById('errorMessage').textContent = message;
    document.getElementById('zoneDetails').style.display = 'none';
}

/**
 * Make API call to zone API
 */
async function zoneApiCall(action, options = {}) {
    const method = (options.method || 'GET').toUpperCase();
    const params = options.params || {};
    const body = options.body || null;

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
        credentials: 'same-origin'
    };

    if (body && (method === 'POST' || method === 'PUT' || method === 'PATCH')) {
        fetchOptions.headers['Content-Type'] = 'application/json';
        fetchOptions.body = JSON.stringify(body);
    }

    try {
        const response = await fetch(url.toString(), fetchOptions);
        let data;
        try {
            data = await response.json();
        } catch (jsonErr) {
            const text = await response.text();
            console.error('Invalid JSON response', text);
            throw new Error('Invalid JSON response from server');
        }

        if (!response.ok) {
            throw new Error(data.error || `HTTP ${response.status}`);
        }

        return data;
    } catch (err) {
        console.error('API call error:', err);
        throw err;
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
    alert(message);
}

function showError(message) {
    alert('Erreur: ' + message);
}
