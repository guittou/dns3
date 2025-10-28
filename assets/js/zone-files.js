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
        // Clear any previous errors
        clearModalError('zoneModal');
        
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
            document.getElementById('zoneModal').classList.add('open');
            
            // Call centering helper if available
            const zoneModal = document.getElementById('zoneModal');
            if (typeof window.ensureModalCentered === 'function') {
                window.ensureModalCentered(zoneModal);
            }
            
            switchTab('details');
            
            // Setup change detection
            setupChangeDetection();
            
            // Adjust zone tab content height after modal is displayed
            // Use setTimeout to ensure DOM has updated and async content loaded
            // Force calculation on open to compute max height across all tabs
            // Allow modal to grow beyond viewport on open
            setTimeout(() => {
                adjustZoneModalTabHeights(true, true);
                lockZoneModalHeight();
            }, 150);
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
}

/* adjustZoneModalTabHeights: compute the max needed height among all panes once,
   store it on modalContent.dataset, reuse it on tab switches. Pass force=true to recompute. */
function adjustZoneModalTabHeights(force = false, allowGrowBeyondViewport = false) {
  const modal = document.getElementById('zoneModal') || document.querySelector('.zone-modal');
  if (!modal) return;
  const modalContent = modal.querySelector('.dns-modal-content, .zone-modal-content');
  if (!modalContent) return;
  const header = modalContent.querySelector('.dns-modal-header');
  const tabs = modalContent.querySelector('.tabs');
  const footer = modalContent.querySelector('.dns-modal-footer, .modal-footer');

  // If modal is hidden, nothing to do
  const modalStyle = getComputedStyle(modal);
  if (modalStyle.display === 'none') return;

  // If we've previously computed a stable height and no force, reuse it
  if (!force && modalContent.dataset._computedModalHeight) {
    modalContent.style.boxSizing = 'border-box';
    modalContent.style.maxHeight = modalContent.dataset._computedViewport || 'calc(100vh - 80px)';
    modalContent.style.height = modalContent.dataset._computedModalHeight;
    modalContent.querySelectorAll('.tab-pane, [id$="Tab"], .zone-tab-content, .tab-content, .dns-modal-body').forEach(tc => {
      tc.style.boxSizing = 'border-box';
      tc.style.minHeight = '0';
      tc.style.overflow = 'hidden';
      if (tc.classList && tc.classList.contains('active')) {
        tc.style.display = tc.style.display || 'flex';
        tc.style.flexDirection = tc.style.flexDirection || 'column';
        tc.style.flex = '1 1 auto';
      }
    });
    return;
  }

  // compute overlay padding and content padding
  let overlayPadding = 40;
  try {
    const overlayStyle = getComputedStyle(modal);
    const pt = parseFloat(overlayStyle.paddingTop) || 20;
    const pb = parseFloat(overlayStyle.paddingBottom) || 20;
    overlayPadding = pt + pb;
  } catch (e) {}

  let contentPadding = 0;
  try {
    const mcStyle = getComputedStyle(modalContent);
    const cpt = parseFloat(mcStyle.paddingTop) || 0;
    const cpb = parseFloat(mcStyle.paddingBottom) || 0;
    contentPadding = cpt + cpb;
  } catch (e) {}

  // helper to measure height without affecting layout
  function measureHeight(el) {
    const prev = {
      display: el.style.display || '',
      position: el.style.position || '',
      visibility: el.style.visibility || '',
      left: el.style.left || '',
      top: el.style.top || ''
    };
    let h;
    try {
      el.style.position = 'absolute';
      el.style.visibility = 'hidden';
      el.style.left = '-9999px';
      el.style.top = '-9999px';
      el.style.display = 'block';
      h = Math.max(el.scrollHeight, el.getBoundingClientRect().height);
    } finally {
      el.style.display = prev.display;
      el.style.position = prev.position;
      el.style.visibility = prev.visibility;
      el.style.left = prev.left;
      el.style.top = prev.top;
    }
    return Math.ceil(h);
  }

  // PRIORITY: Try to find and measure the editor zone first
  let maxPaneContentHeight = 0;
  let editorFound = false;
  
  // Search for editor elements: #zoneContent (textarea), .CodeMirror, or .ace_editor
  const editorSelectors = ['#zoneContent', '.CodeMirror', '.ace_editor'];
  for (const selector of editorSelectors) {
    const editor = modalContent.querySelector(selector);
    if (editor) {
      editorFound = true;
      // Find the editor's parent pane to measure properly
      let editorPane = editor.closest('.tab-pane, [id$="Tab"]');
      if (!editorPane) {
        editorPane = editor.closest('.zone-tab-content, .tab-content, .dns-modal-body');
      }
      if (editorPane) {
        maxPaneContentHeight = measureHeight(editorPane);
      } else {
        // Fallback: measure the editor element itself
        maxPaneContentHeight = measureHeight(editor);
      }
      console.log('Editor found (' + selector + '), using its height:', maxPaneContentHeight);
      break;
    }
  }
  
  // If no editor found, fall back to measuring all panes
  if (!editorFound) {
    const panes = Array.from(modalContent.querySelectorAll('.tab-pane, [id$="Tab"]'));
    if (panes.length === 0) {
      const fallback = modalContent.querySelector('.zone-tab-content, .tab-content, .dns-modal-body');
      if (fallback) panes.push(fallback);
    }
    
    panes.forEach(p => {
      const inner = p.querySelector('.zone-tab-content, .tab-content, .dns-modal-body') || p;
      const h = measureHeight(inner);
      if (h > maxPaneContentHeight) maxPaneContentHeight = h;
    });
    console.log('No editor found, using max pane height:', maxPaneContentHeight);
  }

  const headerH = header ? header.offsetHeight : 0;
  const tabsH = tabs ? tabs.offsetHeight : 0;
  const footerH = footer ? footer.offsetHeight : 0;

  // viewport cap
  const viewportAvailable = Math.max(200, window.innerHeight - overlayPadding - 40);

  // desired total modal content height (include paddings)
  let desired = headerH + tabsH + footerH + maxPaneContentHeight + contentPadding;
  desired = Math.max(200, desired);
  
  // Store allowGrow flag
  modalContent.dataset._allowGrow = allowGrowBeyondViewport ? '1' : '0';
  
  // Apply viewport cap only if allowGrowBeyondViewport is false
  const finalH = allowGrowBeyondViewport ? desired : Math.min(desired, viewportAvailable);

  // apply sizes and store them so subsequent tab switches reuse them
  modalContent.style.boxSizing = 'border-box';
  if (!allowGrowBeyondViewport) {
    modalContent.style.maxHeight = viewportAvailable + 'px';
  } else {
    // Remove maxHeight constraint when allowed to grow
    modalContent.style.maxHeight = '';
  }
  modalContent.style.height = finalH + 'px';
  modalContent.dataset._computedModalHeight = modalContent.style.height;
  modalContent.dataset._computedViewport = allowGrowBeyondViewport ? '' : viewportAvailable + 'px';

  // ensure panes/layout are flex columns so editor can fill internal space
  modalContent.querySelectorAll('.tab-pane, [id$="Tab"], .zone-tab-content, .tab-content, .dns-modal-body').forEach(tc => {
    tc.style.boxSizing = 'border-box';
    tc.style.minHeight = '0';
    // When allowGrowBeyondViewport, prevent internal scroll; otherwise allow scrolling when capped
    tc.style.overflow = allowGrowBeyondViewport ? 'hidden' : 'auto';
    if (tc.classList && tc.classList.contains('active')) {
      tc.style.display = tc.style.display || 'flex';
      tc.style.flexDirection = tc.style.flexDirection || 'column';
      tc.style.flex = '1 1 auto';
    }
  });

  // configure editors/textareas to fill and scroll internally
  // When allowGrowBeyondViewport is true, allow textareas to expand naturally
  modalContent.querySelectorAll('textarea, .code-editor, .editor, .ace_editor, .CodeMirror').forEach(e => {
    if (e.tagName && e.tagName.toLowerCase() === 'textarea') {
      e.style.boxSizing = 'border-box';
      e.style.flex = '1 1 auto';
      e.style.minHeight = '0';
      if (allowGrowBeyondViewport) {
        // Allow textarea to expand naturally without internal scroll
        e.style.height = 'auto';
        e.style.maxHeight = 'none';
        e.style.overflow = 'hidden';
      } else {
        e.style.height = 'auto';
        e.style.maxHeight = '100%';
        e.style.overflow = 'auto';
      }
      e.style.resize = 'none';
    } else {
      e.style.boxSizing = 'border-box';
      e.style.height = '100%';
      e.style.maxHeight = '100%';
      e.style.flex = '1 1 auto';
    }
  });

  // refresh editors if present
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
    window.dispatchEvent(new Event('resize'));
  }, 60);
}

window.adjustZoneModalTabHeights = adjustZoneModalTabHeights;

/* lockZoneModalHeight: re-apply the computed height and overflow styles.
   This ensures the modal stays at the locked size during tab switches. */
function lockZoneModalHeight() {
  const modal = document.getElementById('zoneModal') || document.querySelector('.zone-modal');
  if (!modal) return;
  const modalContent = modal.querySelector('.dns-modal-content, .zone-modal-content');
  if (!modalContent) return;
  if (modalContent.dataset._computedModalHeight) {
    modalContent.style.height = modalContent.dataset._computedModalHeight;
    
    const allowGrow = modalContent.dataset._allowGrow === '1';
    
    // Only apply maxHeight if _allowGrow is not '1'
    if (allowGrow) {
      // No maxHeight constraint when allowed to grow
      modalContent.style.maxHeight = '';
    } else {
      modalContent.style.maxHeight = modalContent.dataset._computedViewport || modalContent.style.maxHeight;
    }
    
    // Reapply overflow styles to panes based on allowGrow flag
    modalContent.querySelectorAll('.tab-pane, [id$="Tab"], .zone-tab-content, .tab-content, .dns-modal-body').forEach(tc => {
      tc.style.overflow = allowGrow ? 'hidden' : 'auto';
    });
    
    // Reapply overflow styles to textareas based on allowGrow flag
    modalContent.querySelectorAll('textarea').forEach(e => {
      if (allowGrow) {
        e.style.overflow = 'hidden';
        e.style.height = 'auto';
        e.style.maxHeight = 'none';
      } else {
        e.style.overflow = 'auto';
        e.style.height = 'auto';
        e.style.maxHeight = '100%';
      }
    });
  }
}

/**
 * Unlock zone modal height to restore clean state
 */
function unlockZoneModalHeight() {
    const modal = document.getElementById('zoneModal') || document.querySelector('.zone-modal');
    if (!modal) return;
    const modalContent = modal.querySelector('.dns-modal-content, .zone-modal-content');
    if (!modalContent) return;
    
    // Remove inline height and stored dataset to restore clean state for next open
    modalContent.style.height = '';
    delete modalContent.dataset._computedModalHeight;
    delete modalContent.dataset._computedViewport;
    delete modalContent.dataset._allowGrow;
    // Note: We keep maxHeight set so ensureModalCentered can use it on next open
}

/**
 * Handle window resize for zone modal
 * Simply recalculates the modal sizes to fit new viewport
 * On resize, cap at viewport (allowGrowBeyondViewport = false)
 */
function handleZoneModalResize() {
    const modal = document.getElementById('zoneModal') || document.querySelector('.zone-modal');
    if (!modal) return;
    
    const modalStyle = getComputedStyle(modal);
    if (modalStyle.display === 'none') return;
    
    // Check if modal is open
    if (!modal.classList.contains('open')) return;
    
    // Recalculate sizes for new viewport - force recalculation, capped at viewport
    adjustZoneModalTabHeights(true, false);
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
