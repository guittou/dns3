<?php
require_once __DIR__ . '/includes/header.php';

// Check if user is logged in and is admin
if (!$auth->isLoggedIn()) {
    header('Location: ' . BASE_URL . 'login.php');
    exit;
}

if (!$auth->isAdmin()) {
    header('Location: ' . BASE_URL . 'index.php');
    exit;
}
?>

<link rel="stylesheet" href="<?php echo $basePath; ?>assets/css/zone-files.css">

<div class="content-section">
    <div class="header-bar" style="display: flex; justify-content: space-between; align-items: center;">
        <h1>Gestion des fichiers de zone</h1>
        <button id="btn-new-domain" class="btn-create" onclick="openCreateMasterModal()">
            <i class="fas fa-plus"></i> Nouveau domaine
        </button>
    </div>
</div>

<div class="content-section zone-list-container">
    <!-- Toolbar with Domain and Zone File Comboboxes -->
    <div class="dns-combobox-container" style="display: flex; gap: 20px; margin-bottom: 20px; flex-wrap: wrap; align-items: flex-end;">
        <!-- Domain Combobox -->
        <div class="combobox-wrapper" style="flex: 1; min-width: 250px;">
            <label for="zone-domain-input" style="display: block; margin-bottom: 5px; font-weight: 500;">Domaine:</label>
            <div class="combobox">
                <input type="text" id="zone-domain-input" class="combobox-input" placeholder="Rechercher un domaine..." autocomplete="off">
                <input type="hidden" id="zone-master-id">
                <ul id="zone-domain-list" class="combobox-list" style="display: none;"></ul>
            </div>
        </div>
        
        <!-- Zone File Combobox -->
        <div class="combobox-wrapper" style="flex: 1; min-width: 250px;">
            <label for="zone-file-input" style="display: block; margin-bottom: 5px; font-weight: 500;">Fichier de zone:</label>
            <div class="combobox">
                <input type="text" id="zone-file-input" class="combobox-input" placeholder="Rechercher une zone..." autocomplete="off">
                <input type="hidden" id="zone-file-id">
                <ul id="zone-file-list" class="combobox-list" style="display: none;"></ul>
            </div>
        </div>
        
        <!-- Reset Button -->
        <div style="flex: 0 0 auto;">
            <button id="btn-reset-domain" class="btn-reset" style="display: inline-block;">Réinitialiser</button>
        </div>
    </div>
    
    <!-- Search and Filters -->
    <div class="filters-section" style="display: flex; gap: 10px; margin-bottom: 20px; align-items: center;">
        <div class="search-box" style="flex: 1;">
            <input type="text" id="searchInput" class="form-control" placeholder="Rechercher par nom ou fichier...">
        </div>
        <div style="flex: 0 0 auto;">
            <select id="filterStatus" class="form-control">
                <option value="active">Actifs</option>
                <option value="inactive">Inactifs</option>
                <option value="deleted">Supprimés</option>
                <option value="">Tous</option>
            </select>
        </div>
        <div style="flex: 0 0 auto;">
            <button id="btn-new-zone-file" class="btn-create" disabled>
                <i class="fas fa-plus"></i> Nouveau fichier de zone
            </button>
        </div>
    </div>

    <!-- Results Info -->
    <div class="results-info">
        <span id="resultsCount">Chargement...</span>
    </div>

    <!-- Zones Table -->
    <div class="table-wrapper">
        <table class="zones-table">
            <thead id="zones-table-head">
                <tr>
                    <th>Zone</th>
                    <th>Nom de fichier</th>
                    <th>Parent</th>
                    <th>Modifié le</th>
                    <th>Statut</th>
                    <th id="zones-table-header-actions" style="display: none;">Actions</th>
                </tr>
            </thead>
            <tbody id="zones-table-body">
                <tr>
                    <td colspan="6" class="loading-cell">
                        <div class="loading">Chargement des zones...</div>
                    </td>
                </tr>
            </tbody>
        </table>
    </div>

    <!-- Pagination Controls -->
    <div class="pagination-controls" style="display: flex; justify-content: space-between; align-items: center; margin-top: 20px; gap: 20px;">
        <div>
            <select id="perPageSelect" class="form-control" style="width: auto; display: inline-block;">
                <option value="25">25 par page</option>
                <option value="50">50 par page</option>
                <option value="100">100 par page</option>
            </select>
        </div>
        <div id="zones-pagination-info" class="page-info">
            Page <span id="currentPage">1</span> sur <span id="totalPages">1</span>
        </div>
        <div style="display: flex; gap: 10px;">
            <button id="prevPage" class="btn btn-secondary" onclick="previousPage()" disabled>
                <i class="fas fa-chevron-left"></i> Précédent
            </button>
            <button id="nextPage" class="btn btn-secondary" onclick="nextPage()" disabled>
                Suivant <i class="fas fa-chevron-right"></i>
            </button>
        </div>
    </div>
</div>

<!-- Create Zone Modal (styled like DNS modal) -->
<div id="createZoneModal" class="dns-modal">
    <div class="dns-modal-content">
        <div class="dns-modal-header">
            <h2>Nouvelle zone</h2>
            <button class="dns-modal-close" onclick="closeCreateZoneModal()" aria-label="Fermer">&times;</button>
        </div>
        <div class="dns-modal-body">
            <!-- Error banner for create modal -->
            <div id="createZoneErrorBanner" class="modal-error-banner" role="alert" tabindex="-1" style="display:none;">
                <button class="modal-error-close" aria-label="Fermer" onclick="clearModalError('createZone')">&times;</button>
                <strong class="modal-error-title">Erreur&nbsp;:</strong>
                <div id="createZoneErrorMessage" class="modal-error-message"></div>
            </div>

            <form id="createZoneForm" onsubmit="return false;">
                <div class="form-group">
                    <label for="createName">Nom *</label>
                    <input id="createName" class="form-control" type="text" required>
                </div>
                <div class="form-group">
                    <label for="createFilename">Nom de fichier *</label>
                    <input id="createFilename" class="form-control" type="text" required>
                </div>
                <div class="form-group">
                    <label for="createDomain">Domaine</label>
                    <input id="createDomain" class="form-control" type="text" placeholder="ex: example.com">
                    <small class="form-text text-muted">Nom de domaine associé à cette zone master (optionnel)</small>
                </div>
                <div class="form-group">
                    <label for="createFileType">Type *</label>
                    <select id="createFileType" class="form-control" required disabled>
                        <option value="master" selected>Master</option>
                    </select>
                    <small class="form-text text-muted">Les zones master sont créées via "Nouvelle zone". Les includes sont créés depuis le modal d'édition d'une zone.</small>
                </div>
                <div class="form-group">
                    <label for="createContent">Contenu</label>
                    <textarea id="createContent" class="form-control code-editor" rows="10"></textarea>
                </div>
                <div class="dns-modal-footer">
                    <div class="modal-action-bar">
                        <button type="button" id="zone-create-save-btn" class="btn-success modal-action-button" onclick="createZone()">Créer</button>
                        <button type="button" id="zone-create-cancel-btn" class="btn-cancel modal-action-button" onclick="closeCreateZoneModal()">Annuler</button>
                    </div>
                </div>
            </form>
        </div>
    </div>
</div>

<!-- Zone Edit Modal (styled like DNS modal) -->
<div id="zoneModal" class="dns-modal">
    <div class="dns-modal-content modal-large zone-modal-content">
        <div class="dns-modal-header">
            <h2 id="zoneModalTitle">Zone</h2>
            <button class="dns-modal-close" onclick="closeZoneModal()" aria-label="Fermer">&times;</button>
        </div>
        <div class="dns-modal-body">
            <!-- Error banner for edit modal -->
            <div id="zoneModalErrorBanner" class="modal-error-banner" role="alert" tabindex="-1" style="display:none;">
                <button class="modal-error-close" aria-label="Fermer" onclick="clearModalError('zoneModal')">&times;</button>
                <strong class="modal-error-title">Erreur&nbsp;:</strong>
                <div id="zoneModalErrorMessage" class="modal-error-message"></div>
            </div>
            
            <!-- Tabs -->
            <div class="tabs">
                <button type="button" class="tab-btn active" data-zone-tab="details" onclick="switchTab('details')">Détails</button>
                <button type="button" class="tab-btn" data-zone-tab="editor" onclick="switchTab('editor')">Éditeur</button>
                <button type="button" class="tab-btn" data-zone-tab="includes" onclick="switchTab('includes')">Includes</button>
            </div>
            
            <!-- Tab Content -->
            <div class="tab-content">
                <!-- Details Tab -->
                <div id="detailsTab" class="tab-pane zone-tab-content active">
                    <form id="zoneDetailsForm">
                        <input type="hidden" id="zoneId">
                        <div class="form-grid">
                            <div class="form-group">
                                <label for="zoneName">Nom *</label>
                                <input type="text" id="zoneName" class="form-control" required>
                            </div>
                            <div class="form-group">
                                <label for="zoneFilename">Nom de fichier *</label>
                                <input type="text" id="zoneFilename" class="form-control" required>
                            </div>
                            <div class="form-group" id="zoneDomainGroup">
                                <label for="zoneDomain">Domaine</label>
                                <input type="text" id="zoneDomain" class="form-control" placeholder="ex: example.com">
                                <small class="form-text text-muted">Nom de domaine associé à cette zone master (optionnel)</small>
                            </div>
                            <div class="form-group">
                                <label for="zoneDirectory">Répertoire</label>
                                <input type="text" id="zoneDirectory" class="form-control" placeholder="Exemple: /etc/bind/zones">
                                <small class="form-text text-muted">Répertoire pour les directives $INCLUDE (optionnel)</small>
                            </div>
                            <div class="form-group">
                                <label for="zoneFileType">Type</label>
                                <select id="zoneFileType" class="form-control" disabled>
                                    <option value="master">Master</option>
                                    <option value="include">Include</option>
                                </select>
                                <small class="form-text text-muted">Le type ne peut pas être modifié après la création.</small>
                            </div>
                            <div class="form-group">
                                <label for="zoneStatus">Statut</label>
                                <select id="zoneStatus" class="form-control">
                                    <option value="active">Actif</option>
                                    <option value="inactive">Inactif</option>
                                </select>
                            </div>
                            <div class="form-group" id="parentGroup" style="display: none;">
                                <label for="zoneParent">Parent</label>
                                <select id="zoneParent" class="form-control">
                                    <option value="">Aucun parent</option>
                                </select>
                                <small class="form-text text-muted">Vous pouvez réassigner cet include à un autre parent.</small>
                            </div>
                        </div>
                    </form>
                </div>
                
                <!-- Editor Tab -->
                <div id="editorTab" class="tab-pane zone-tab-content">
                    <div class="form-group">
                        <label for="zoneContent">Contenu du fichier de zone</label>
                        <textarea id="zoneContent" class="form-control code-editor" rows="20"></textarea>
                    </div>
                    <div style="margin-top: 1rem;">
                        <button type="button" id="btnGenerateZoneFile" class="btn btn-secondary" onclick="generateZoneFileContent(event)">
                            <i class="fas fa-file-code"></i> Générer le fichier de zone
                        </button>
                        <small class="form-text text-muted" style="display: inline-block; margin-left: 1rem;">
                            Génère le contenu complet avec les directives $INCLUDE et les enregistrements DNS
                        </small>
                    </div>
                </div>
                
                <!-- Includes Tab -->
                <div id="includesTab" class="tab-pane zone-tab-content">
                    <div class="includes-header">
                        <h3>Fichiers inclus dans cette zone</h3>
                        <button type="button" class="btn btn-sm btn-primary" onclick="openCreateIncludeForm()">
                            <i class="fas fa-plus"></i> Créer un include
                        </button>
                    </div>
                    <div id="includesList">
                        <div class="loading">Chargement...</div>
                    </div>
                    
                    <!-- Create Include Form (hidden by default) -->
                    <div id="createIncludeForm" style="display: none; margin-top: 1rem; padding: 1rem; border: 1px solid #ddd; border-radius: 4px;">
                        <h4>Créer un nouvel include</h4>
                        <div class="form-group">
                            <label for="includeNameInput">Nom *</label>
                            <input type="text" id="includeNameInput" class="form-control" required>
                        </div>
                        <div class="form-group">
                            <label for="includeFilenameInput">Nom de fichier *</label>
                            <input type="text" id="includeFilenameInput" class="form-control" required>
                        </div>
                        <div class="form-group">
                            <label for="includeContentInput">Contenu</label>
                            <textarea id="includeContentInput" class="form-control" rows="6"></textarea>
                        </div>
                        <div style="display: flex; gap: 0.5rem;">
                            <button type="button" class="btn btn-secondary" onclick="cancelCreateInclude()">Annuler</button>
                            <button type="button" class="btn btn-primary" onclick="submitCreateInclude()">Créer et assigner</button>
                        </div>
                    </div>
                </div>
            </div>
        </div>
        <div class="dns-modal-footer">
            <div class="modal-action-bar">
                <button type="button" id="zone-save-btn" class="btn-success modal-action-button" onclick="saveZone()">Enregistrer</button>
                <button type="button" id="zone-cancel-btn" class="btn-cancel modal-action-button" onclick="closeZoneModal()">Annuler</button>
                <button type="button" id="zone-delete-btn" class="btn-delete modal-action-button" onclick="deleteZone()">Supprimer</button>
            </div>
        </div>
    </div>
</div>

<!-- Zone Preview Modal (positioned at document root for high z-index) -->
<div id="zonePreviewModal" class="modal preview-modal">
    <div class="modal-content modal-large">
        <div class="modal-header">
            <h2 id="zonePreviewModalTitle">Aperçu du fichier de zone</h2>
            <span class="close" id="closeZonePreviewBtn" onclick="closeZonePreviewModal()">&times;</span>
        </div>
        <div class="modal-body">
            <div class="form-group">
                <label>Contenu généré du fichier de zone</label>
                <div id="zonePreviewContentContainer">
                    <textarea id="zoneGeneratedPreview" class="form-control code-editor" rows="25" readonly></textarea>
                </div>
            </div>
            <div id="zoneValidationResults" class="validation-results" style="display: none;">
                <h4>Résultat de la validation (named-checkzone)</h4>
                <div id="zoneValidationStatus" class="validation-status"></div>
                <div id="zoneValidationOutput" class="validation-output"></div>
            </div>
        </div>
        <div class="modal-footer modal-footer-centered">
            <button type="button" id="closeZonePreview" class="btn btn-secondary" onclick="closeZonePreviewModal()">Fermer</button>
            <button type="button" id="downloadZoneFile" class="btn btn-primary">
                <i class="fas fa-download"></i> Télécharger
            </button>
        </div>
    </div>
</div>

<!-- Include Create Modal -->
<div id="include-create-modal" class="dns-modal">
    <div class="dns-modal-content">
        <div class="dns-modal-header">
            <h2 style="text-align: center; margin-bottom: 0.25rem;">
                <span id="include-modal-domain">-</span>
            </h2>
            <h3 style="text-align: center; font-weight: normal; font-size: 1rem; color: #666; margin-top: 0;">
                <span id="include-modal-title">Nouveau fichier de zone</span>
            </h3>
            <button class="dns-modal-close" onclick="closeIncludeCreateModal()" aria-label="Fermer">&times;</button>
        </div>
        <div class="dns-modal-body">
            <!-- Error banner -->
            <div id="includeCreateErrorBanner" class="modal-error-banner" role="alert" tabindex="-1" style="display:none;">
                <button class="modal-error-close" aria-label="Fermer" onclick="clearModalError('includeCreate')">&times;</button>
                <strong class="modal-error-title">Erreur&nbsp;:</strong>
                <div id="includeCreateErrorMessage" class="modal-error-message"></div>
            </div>

            <form id="includeCreateForm" onsubmit="return false;">
                <!-- Hidden fields -->
                <input type="hidden" id="include-domain-id">
                <input type="hidden" id="include-parent-zone-id">

                <!-- Domain field (disabled, prefilled) -->
                <div class="form-group">
                    <label for="include-domain">Domaine</label>
                    <input id="include-domain" class="form-control" type="text" disabled>
                </div>

                <!-- Parent zone combobox (searchable) -->
                <div class="form-group">
                    <label for="include-parent-input">Fichier de zone parent *</label>
                    <div class="combobox">
                        <input type="text" id="include-parent-input" class="combobox-input form-control" placeholder="Rechercher un fichier de zone..." autocomplete="off">
                        <ul id="include-parent-list" class="combobox-list" style="display: none;"></ul>
                    </div>
                </div>

                <!-- Name field (required, empty) -->
                <div class="form-group">
                    <label for="include-name">Nom *</label>
                    <input id="include-name" class="form-control" type="text" required>
                </div>

                <!-- Filename field (required, empty) -->
                <div class="form-group">
                    <label for="include-filename">Nom de fichier *</label>
                    <input id="include-filename" class="form-control" type="text" required>
                </div>

                <!-- Directory field (optional) -->
                <div class="form-group">
                    <label for="include-directory">Répertoire</label>
                    <input id="include-directory" class="form-control" type="text" placeholder="/etc/bind/zones">
                    <small class="form-text text-muted">Répertoire pour les directives $INCLUDE (optionnel)</small>
                </div>

                <div class="dns-modal-footer">
                    <div class="modal-action-bar">
                        <button type="button" id="include-save-btn" class="btn-success modal-action-button" onclick="saveInclude()">Enregistrer</button>
                        <button type="button" id="include-cancel-btn" class="btn-cancel modal-action-button" onclick="closeIncludeCreateModal()">Annuler</button>
                    </div>
                </div>
            </form>
        </div>
    </div>
</div>

<script src="<?php echo $basePath; ?>assets/js/modal-utils.js"></script>
<script src="<?php echo $basePath; ?>assets/js/zone-files.js"></script>

<?php
require_once __DIR__ . '/includes/footer.php';
?>
