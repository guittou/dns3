/**
 * Zone Files Management JavaScript - Paginated List View
 * Handles paginated table view for zone file management
 */

// Global state
let currentPage = 1;
let perPage = 25;
let totalPages = 1;
let totalCount = 0;
let searchQuery = '';
let filterType = '';
let filterStatus = 'active';
let searchTimeout = null;

// API base URL
const API_BASE = window.API_BASE || '/api/zone_api.php';

/**
 * Initialize page on load
 */
document.addEventListener('DOMContentLoaded', function() {
    setupEventHandlers();
    loadZonesList();
    setupDelegatedHandlers();
});

/**
 * Setup delegated event handlers for dynamic content
 */
function setupDelegatedHandlers() {
    // Delegated handler for generate zone file button
    document.addEventListener('click', function(e) {
        const generateBtn = e.target.closest('#btnGenerateZoneFile');
        if (generateBtn) {
            e.preventDefault();
            e.stopPropagation();
            handleGenerateZoneFile();
        }
    });
    
    // Delegated handler for close preview modal (overlay click)
    document.addEventListener('click', function(e) {
        if (e.target.id === 'zonePreviewModal' && e.target.classList.contains('modal')) {
            e.stopPropagation();
            closeZonePreviewModal();
        }
    });
    
    // Delegated handler for close preview modal buttons
    document.addEventListener('click', function(e) {
        if (e.target.closest('#closeZonePreview') || e.target.closest('#closeZonePreviewBtn')) {
            e.preventDefault();
            e.stopPropagation();
            closeZonePreviewModal();
        }
    });
}

/**
 * Setup event handlers
 */
function setupEventHandlers() {
    // Search with debounce
    document.getElementById('searchInput').addEventListener('input', function(e) {
        clearTimeout(searchTimeout);
        searchQuery = e.target.value;
        searchTimeout = setTimeout(() => {
            currentPage = 1;
            loadZonesList();
        }, 300);
    });

    // Filter handlers
    document.getElementById('filterType').addEventListener('change', function(e) {
        filterType = e.target.value;
        currentPage = 1;
        loadZonesList();
    });

    document.getElementById('filterStatus').addEventListener('change', function(e) {
        filterStatus = e.target.value;
        currentPage = 1;
        loadZonesList();
    });

    // Per page selector
    document.getElementById('perPageSelect').addEventListener('change', function(e) {
        perPage = parseInt(e.target.value);
        currentPage = 1;
        loadZonesList();
    });

    // Create zone form submission
    document.getElementById('createZoneForm').addEventListener('submit', function(e) {
        e.preventDefault();
        createZone();
    });

    // Modal close on outside click
    window.onclick = function(event) {
        if (event.target.classList.contains('modal')) {
            if (event.target.id === 'createZoneModal') {
                closeCreateZoneModal();
            } else if (event.target.id === 'zoneModal') {
                closeZoneModal();
            } else if (event.target.id === 'zonePreviewModal') {
                closeZonePreviewModal();
            } else {
                event.target.style.display = 'none';
            }
        }
    };
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

    if (method === 'GET' && Object.keys(params).length > 0) {
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
 * Load zones list with pagination
 */
async function loadZonesList() {
    try {
        const params = {
            page: currentPage,
            per_page: perPage
        };

        if (searchQuery) {
            params.q = searchQuery;
        }
        if (filterType) {
            params.file_type = filterType;
        }
        if (filterStatus) {
            params.status = filterStatus;
        }

        const response = await zoneApiCall('list_zones', { params });

        if (response.success) {
            totalCount = response.total;
            totalPages = response.total_pages || 1;
            renderZonesTable(response.data);
            updatePaginationControls();
            updateResultsInfo();
        }
    } catch (error) {
        console.error('Failed to load zones:', error);
        showError('Erreur lors du chargement des zones: ' + error.message);
        renderErrorState();
    }
}

/**
 * Render zones table
 */
function renderZonesTable(zones) {
    const tbody = document.getElementById('zonesTableBody');

    if (zones.length === 0) {
        tbody.innerHTML = `
            <tr>
                <td colspan="7" class="empty-cell">
                    <div class="empty-state">
                        <i class="fas fa-inbox"></i>
                        <p>Aucune zone trouvée</p>
                    </div>
                </td>
            </tr>
        `;
        return;
    }

    tbody.innerHTML = zones.map(zone => {
        const statusBadge = getStatusBadge(zone.status);
        const typeBadge = zone.file_type === 'master' ? 
            '<span class="badge badge-master">Master</span>' : 
            '<span class="badge badge-include">Include</span>';
        const parentDisplay = zone.parent_name ? escapeHtml(zone.parent_name) : '-';
        
        return `
            <tr class="zone-row" data-id="${zone.id}" onclick="openZoneModal(${zone.id})" style="cursor: pointer;">
                <td><strong>${escapeHtml(zone.name)}</strong></td>
                <td>${typeBadge}</td>
                <td><code>${escapeHtml(zone.filename)}</code></td>
                <td>${parentDisplay}</td>
                <td>${escapeHtml(zone.created_by_username || 'N/A')}</td>
                <td>${statusBadge}</td>
                <td>${formatDate(zone.updated_at || zone.created_at)}</td>
            </tr>
        `;
    }).join('');
}

/**
 * Render error state
 */
function renderErrorState() {
    const tbody = document.getElementById('zonesTableBody');
    tbody.innerHTML = `
        <tr>
            <td colspan="7" class="error-cell">
                <div class="error-state">
                    <i class="fas fa-exclamation-triangle"></i>
                    <p>Erreur lors du chargement des zones</p>
                </div>
            </td>
        </tr>
    `;
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
        loadZonesList();
    }
}

/**
 * Navigate to next page
 */
function nextPage() {
    if (currentPage < totalPages) {
        currentPage++;
        loadZonesList();
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
        // Store current zone ID
        currentZoneId = zoneId;
        
        // Load zone data
        const response = await zoneApiCall('get_zone', { params: { id: zoneId } });
        
        if (response.success) {
            currentZone = response.data;
            originalZoneData = JSON.parse(JSON.stringify(response.data));
            hasUnsavedChanges = false;
            
            // Populate modal
            document.getElementById('zoneId').value = currentZone.id;
            document.getElementById('zoneModalTitle').textContent = currentZone.name;
            document.getElementById('zoneName').value = currentZone.name;
            document.getElementById('zoneFilename').value = currentZone.filename;
            document.getElementById('zoneDirectory').value = currentZone.directory || '';
            document.getElementById('zoneFileType').value = currentZone.file_type;
            document.getElementById('zoneStatus').value = currentZone.status;
            
            // Set textarea content directly (no CodeMirror)
            document.getElementById('zoneContent').value = currentZone.content || '';
            
            // Show parent select only for includes
            const parentGroup = document.getElementById('parentGroup');
            if (currentZone.file_type === 'include') {
                parentGroup.style.display = 'block';
                await loadParentOptions(currentZone.parent_id);
            } else {
                parentGroup.style.display = 'none';
            }
            
            // Load includes list
            loadIncludesList(response.includes || []);
            
            // Show modal
            document.getElementById('zoneModal').style.display = 'block';
            switchTab('details');
            
            // Setup change detection
            setupChangeDetection();
        }
    } catch (error) {
        console.error('Failed to load zone:', error);
        showError('Erreur lors du chargement de la zone: ' + error.message);
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
    
    // Update tab buttons
    document.querySelectorAll('.tab-btn').forEach(btn => {
        btn.classList.remove('active');
        if (btn.onclick && btn.onclick.toString().includes(tabName)) {
            btn.classList.add('active');
        }
    });
    
    // Update tab panes
    document.querySelectorAll('.tab-pane').forEach(pane => {
        pane.classList.remove('active');
    });
    document.getElementById(tabName + 'Tab').classList.add('active');
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
        const zoneId = document.getElementById('zoneId').value;
        
        // Get content directly from textarea (no CodeMirror)
        const content = document.getElementById('zoneContent').value;
        
        const data = {
            name: document.getElementById('zoneName').value,
            filename: document.getElementById('zoneFilename').value,
            directory: document.getElementById('zoneDirectory').value || null,
            content: content
        };
        
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
        closeZoneModal();
        await loadZonesList();
    } catch (error) {
        console.error('Failed to save zone:', error);
        showError('Erreur lors de la sauvegarde: ' + error.message);
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
        await loadZonesList();
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
 * Submit create include
 */
async function submitCreateInclude() {
    try {
        const name = document.getElementById('includeNameInput').value.trim();
        const filename = document.getElementById('includeFilenameInput').value.trim();
        const content = document.getElementById('includeContentInput').value;
        
        if (!name || !filename) {
            showError('Veuillez remplir tous les champs requis');
            return;
        }
        
        const parentId = currentZone.id;
        
        const response = await zoneApiCall('create_and_assign_include', {
            method: 'POST',
            body: {
                name: name,
                filename: filename,
                content: content,
                parent_id: parentId
            }
        });
        
        showSuccess('Include créé et assigné avec succès');
        cancelCreateInclude();
        
        // Reload zone data to refresh includes list
        await openZoneModal(currentZone.id);
    } catch (error) {
        console.error('Failed to create include:', error);
        showError('Erreur lors de la création de l\'include: ' + error.message);
    }
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
 * Open create zone modal
 */
function openCreateZoneModal() {
    document.getElementById('createZoneForm').reset();
    // Force master type and disable the select
    document.getElementById('createFileType').value = 'master';
    document.getElementById('createFileType').disabled = true;
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
            file_type: 'master', // Always create as master from "Nouvelle zone" button
            content: document.getElementById('createContent').value
        };

        const response = await zoneApiCall('create_zone', {
            method: 'POST',
            body: data
        });

        showSuccess('Zone créée avec succès');
        closeCreateZoneModal();
        await loadZonesList();
        
        // Open the new zone in the modal instead of navigating
        if (response.id) {
            await openZoneModal(response.id);
        }
    } catch (error) {
        console.error('Failed to create zone:', error);
        showError('Erreur lors de la création: ' + error.message);
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
        
    } catch (error) {
        console.error('Failed to generate zone file:', error);
        
        // Show error in preview textarea
        const textarea = document.getElementById('zoneGeneratedPreview');
        textarea.value = `Erreur lors de la génération du fichier de zone:\n\n${error.message}\n\nVeuillez consulter la console pour plus de détails.`;
        
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
