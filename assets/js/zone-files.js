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
let selectedDomainId = null;
let allMasters = [];

// API base URL
const API_BASE = window.API_BASE || '/api/zone_api.php';

/**
 * Initialize page on load
 */
document.addEventListener('DOMContentLoaded', function() {
    setupEventHandlers();
    initZonesPage();
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
    
    // Window resize handler to recalculate zone tab content height
    // Use debounce to avoid excessive recalculations
    let resizeTimeout = null;
    window.addEventListener('resize', function() {
        clearTimeout(resizeTimeout);
        resizeTimeout = setTimeout(function() {
            handleZoneModalResize();
        }, 150);
    });
    
    // Orientation change handler for mobile devices
    window.addEventListener('orientationchange', function() {
        setTimeout(function() {
            handleZoneModalResize();
        }, 200);
    });
    
    // Domain filter input click handler
    const domainFilterInput = document.getElementById('zone-domain-filter');
    if (domainFilterInput) {
        domainFilterInput.addEventListener('click', function() {
            const dropdown = document.getElementById('zone-domain-list');
            if (dropdown) {
                const isVisible = dropdown.style.display !== 'none';
                dropdown.style.display = isVisible ? 'none' : 'block';
            }
        });
    }
    
    // Close dropdown when clicking outside
    document.addEventListener('click', function(e) {
        const domainWrapper = document.querySelector('.domain-input-wrapper');
        const dropdown = document.getElementById('zone-domain-list');
        if (dropdown && !domainWrapper.contains(e.target)) {
            dropdown.style.display = 'none';
        }
    });
}

/**
 * Initialize zones page - load domains and zones
 */
async function initZonesPage() {
    await populateDomainSelect();
    await loadZonesList();
}

/**
 * Populate domain select with all master zones that have a domain
 */
async function populateDomainSelect() {
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
            
            const dropdown = document.getElementById('zone-domain-list');
            if (!dropdown) return;
            
            if (allMasters.length === 0) {
                dropdown.innerHTML = '<div class="domain-dropdown-item" style="padding: 1rem; text-align: center; color: #999;">Aucun domaine disponible</div>';
                return;
            }
            
            // Add "All" option
            dropdown.innerHTML = `
                <div class="domain-dropdown-item" data-id="" onclick="handleDomainClick('')">
                    <strong>Tous les domaines</strong>
                    <small>Afficher tous les includes</small>
                </div>
            `;
            
            // Add master domains
            dropdown.innerHTML += allMasters.map(master => `
                <div class="domain-dropdown-item" data-id="${master.id}" onclick="handleDomainClick(${master.id})">
                    <strong>${escapeHtml(master.domain)}</strong>
                    <small>${escapeHtml(master.name)} (${escapeHtml(master.filename)})</small>
                </div>
            `).join('');
        }
    } catch (error) {
        console.error('Failed to populate domain select:', error);
        showError('Erreur lors du chargement des domaines: ' + error.message);
    }
}

/**
 * Handle domain selection from dropdown
 */
function handleDomainClick(masterId) {
    const dropdown = document.getElementById('zone-domain-list');
    if (dropdown) {
        dropdown.style.display = 'none';
    }
    
    if (masterId === '') {
        onDomainSelected(null);
    } else {
        onDomainSelected(parseInt(masterId));
    }
}

/**
 * Handle domain selection - update UI and filter table
 */
function onDomainSelected(masterZoneId) {
    selectedDomainId = masterZoneId;
    
    // Update input display
    const filterInput = document.getElementById('zone-domain-filter');
    if (filterInput) {
        if (masterZoneId) {
            const master = allMasters.find(m => m.id === masterZoneId);
            if (master) {
                filterInput.value = master.domain;
            }
        } else {
            filterInput.value = '';
            filterInput.placeholder = 'Sélectionner un domaine...';
        }
    }
    
    // Show/hide buttons based on selection
    const btnNewInclude = document.getElementById('btnNewInclude');
    const btnEditDomain = document.getElementById('btnEditDomain');
    
    if (masterZoneId) {
        if (btnNewInclude) btnNewInclude.style.display = 'inline-flex';
        if (btnEditDomain) btnEditDomain.style.display = 'inline-flex';
    } else {
        if (btnNewInclude) btnNewInclude.style.display = 'none';
        if (btnEditDomain) btnEditDomain.style.display = 'none';
    }
    
    // Show/hide Actions column header
    const actionsHeader = document.getElementById('actionsHeader');
    if (actionsHeader) {
        actionsHeader.style.display = masterZoneId ? 'table-cell' : 'none';
    }
    
    // Reload zones list with new filter
    currentPage = 1;
    loadZonesList();
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
        
        // Default to showing only includes
        if (!selectedDomainId) {
            params.file_type = 'include';
        } else {
            // When domain is selected, fetch all includes to filter by parent
            params.file_type = 'include';
            params.per_page = 1000; // Fetch more to filter client-side
        }
        
        if (filterType) {
            params.file_type = filterType;
        }
        if (filterStatus) {
            params.status = filterStatus;
        }

        const response = await zoneApiCall('list_zones', { params });

        if (response.success) {
            let filteredData = response.data;
            
            // If a domain is selected, filter includes by parent_id
            if (selectedDomainId) {
                filteredData = filteredData.filter(zone => zone.parent_id === selectedDomainId);
                totalCount = filteredData.length;
                totalPages = Math.ceil(totalCount / perPage);
            } else {
                totalCount = response.total;
                totalPages = response.total_pages || 1;
            }
            
            renderZonesTable(filteredData);
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
    const showActions = selectedDomainId !== null;
    const colspanValue = showActions ? 8 : 7;

    if (zones.length === 0) {
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
        return;
    }

    tbody.innerHTML = zones.map(zone => {
        const statusBadge = getStatusBadge(zone.status);
        const typeBadge = zone.file_type === 'master' ? 
            '<span class="badge badge-master">Master</span>' : 
            '<span class="badge badge-include">Include</span>';
        const parentDisplay = zone.parent_name ? escapeHtml(zone.parent_name) : '-';
        
        let actionsHtml = '';
        if (showActions) {
            actionsHtml = `
                <td class="actions-cell">
                    <button class="btn btn-sm btn-secondary" onclick="event.stopPropagation(); openZoneModal(${zone.id})" title="Modifier">
                        <i class="fas fa-edit"></i>
                    </button>
                    <button class="btn btn-sm btn-danger" onclick="event.stopPropagation(); confirmDeleteZone(${zone.id})" title="Supprimer">
                        <i class="fas fa-trash"></i>
                    </button>
                </td>
            `;
        }
        
        return `
            <tr class="zone-row" data-id="${zone.id}" data-parent-id="${zone.parent_id || ''}" onclick="handleZoneRowClick(${zone.id}, ${zone.parent_id || 'null'})" style="cursor: pointer;">
                <td><strong>${escapeHtml(zone.name)}</strong></td>
                <td>${typeBadge}</td>
                <td><code>${escapeHtml(zone.filename)}</code></td>
                <td>${parentDisplay}</td>
                <td>${escapeHtml(zone.created_by_username || 'N/A')}</td>
                <td>${statusBadge}</td>
                <td>${formatDate(zone.updated_at || zone.created_at)}</td>
                ${actionsHtml}
            </tr>
        `;
    }).join('');
}

/**
 * Handle zone row click - select parent domain if include
 */
async function handleZoneRowClick(zoneId, parentId) {
    if (parentId && parentId !== 'null') {
        // This is an include - select its parent domain
        onDomainSelected(parentId);
    }
    // Open the zone modal
    openZoneModal(zoneId);
}

/**
 * Confirm delete zone
 */
async function confirmDeleteZone(zoneId) {
    if (!confirm('Êtes-vous sûr de vouloir supprimer cette zone?')) {
        return;
    }
    
    try {
        await zoneApiCall('set_status_zone', {
            params: { id: zoneId, status: 'deleted' }
        });
        
        showSuccess('Zone supprimée avec succès');
        await loadZonesList();
    } catch (error) {
        console.error('Failed to delete zone:', error);
        showError('Erreur lors de la suppression: ' + error.message);
    }
}

/**
 * Render error state
 */
function renderErrorState() {
    const tbody = document.getElementById('zonesTableBody');
    const colspanValue = selectedDomainId ? 8 : 7;
    tbody.innerHTML = `
        <tr>
            <td colspan="${colspanValue}" class="error-cell">
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
        await loadZonesList();
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
 * Open create master modal (new domain)
 */
function openCreateMasterModal() {
    openCreateZoneModal();
}

/**
 * Open edit master modal for selected domain
 */
async function openEditMasterModal() {
    if (!selectedDomainId) {
        showError('Aucun domaine sélectionné');
        return;
    }
    
    try {
        await openZoneModal(selectedDomainId);
    } catch (error) {
        console.error('Failed to open edit modal:', error);
        showError('Erreur lors de l\'ouverture du modal: ' + error.message);
    }
}

/**
 * Open create include modal for selected domain
 */
function openCreateIncludeModal() {
    if (!selectedDomainId) {
        showError('Veuillez sélectionner un domaine d\'abord');
        return;
    }
    
    // Open the zone modal for the selected master, which has the includes tab
    openZoneModal(selectedDomainId);
    
    // Switch to includes tab after a short delay to ensure modal is loaded
    setTimeout(() => {
        switchTab('includes');
        // Open the create include form
        setTimeout(() => {
            const createBtn = document.querySelector('#includesTab button[onclick*="openCreateIncludeForm"]');
            if (createBtn) {
                createBtn.click();
            }
        }, 100);
    }, 200);
}

/**
 * Open create zone modal
 */
function openCreateZoneModal() {
    // Clear any previous errors
    clearModalError('createZone');
    
    document.getElementById('createZoneForm').reset();
    // Force master type and disable the select
    document.getElementById('createFileType').value = 'master';
    document.getElementById('createFileType').disabled = true;
    
    const modal = document.getElementById('createZoneModal');
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
    const modal = document.getElementById('createZoneModal');
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
        
        const data = {
            name: document.getElementById('createName').value,
            filename: document.getElementById('createFilename').value,
            file_type: 'master', // Always create as master from "Nouvelle zone" button
            content: document.getElementById('createContent').value,
            domain: document.getElementById('createDomain').value || null
        };

        const response = await zoneApiCall('create_zone', {
            method: 'POST',
            body: data
        });

        showSuccess('Zone créée avec succès');
        closeCreateZoneModal();
        
        // Refresh domain list if a domain was set
        if (data.domain) {
            await populateDomainSelect();
            // Optionally select the newly created domain
            if (response.id) {
                onDomainSelected(response.id);
            }
        }
        
        await loadZonesList();
        
        // Open the new zone in the modal instead of navigating
        if (response.id) {
            await openZoneModal(response.id);
        }
    } catch (error) {
        console.error('Failed to create zone:', error);
        
        // Show error in modal banner instead of global error
        const errorMessage = error.message || 'Erreur lors de la création de la zone';
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
 * Show error banner in a modal
 * @param {string} modalKey - Modal key (e.g., 'createZone' or 'zoneModal')
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
 * Clear error banner in a modal
 * @param {string} modalKey - Modal key (e.g., 'createZone' or 'zoneModal')
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

// Expose functions globally for inline event handlers
window.openZoneModal = openZoneModal;
window.onDomainSelected = onDomainSelected;
window.populateDomainSelect = populateDomainSelect;
window.handleDomainClick = handleDomainClick;
window.handleZoneRowClick = handleZoneRowClick;
window.openCreateMasterModal = openCreateMasterModal;
window.openEditMasterModal = openEditMasterModal;
window.openCreateIncludeModal = openCreateIncludeModal;
window.confirmDeleteZone = confirmDeleteZone;
