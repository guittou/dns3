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
});

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
            event.target.style.display = 'none';
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
                <td colspan="8" class="empty-cell">
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
        
        return `
            <tr>
                <td><strong>${escapeHtml(zone.name)}</strong></td>
                <td>${typeBadge}</td>
                <td><code>${escapeHtml(zone.filename)}</code></td>
                <td>${zone.includes_count || 0}</td>
                <td>${escapeHtml(zone.created_by_username || 'N/A')}</td>
                <td>${statusBadge}</td>
                <td>${formatDate(zone.updated_at || zone.created_at)}</td>
                <td class="actions-cell">
                    <button class="btn btn-xs btn-primary" onclick="viewZone(${zone.id})" title="Voir">
                        <i class="fas fa-eye"></i>
                    </button>
                    <button class="btn btn-xs btn-secondary" onclick="editZone(${zone.id})" title="Éditer">
                        <i class="fas fa-edit"></i>
                    </button>
                </td>
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
            <td colspan="8" class="error-cell">
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

/**
 * View zone details (navigate to detail page)
 */
function viewZone(zoneId) {
    window.location.href = `${window.BASE_URL}zone-file.php?id=${zoneId}`;
}

/**
 * Edit zone (navigate to detail page with editor tab)
 */
function editZone(zoneId) {
    window.location.href = `${window.BASE_URL}zone-file.php?id=${zoneId}&tab=editor`;
}

// All detail view functions have been moved to zone-file-detail.js
// This file now only handles the paginated list view

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
        
        // Navigate to the new zone's detail page
        if (response.id) {
            window.location.href = `${window.BASE_URL}zone-file.php?id=${response.id}`;
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
