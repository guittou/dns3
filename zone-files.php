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
    <div class="header-bar">
        <h1>Gestion des fichiers de zone</h1>
        <div class="header-actions">
            <button class="btn btn-primary" onclick="openCreateZoneModal()">
                <i class="fas fa-plus"></i> Nouvelle zone
            </button>
        </div>
    </div>
</div>

<div class="content-section zone-list-container">
    <!-- Search and Filters -->
    <div class="filters-section">
        <div class="search-box">
            <input type="text" id="searchInput" class="form-control" placeholder="Rechercher par nom ou fichier...">
        </div>
        <div class="filter-controls">
            <select id="filterType" class="form-control">
                <option value="">Tous les types</option>
                <option value="master">Master</option>
                <option value="include">Include</option>
            </select>
            <select id="filterStatus" class="form-control">
                <option value="active">Actifs</option>
                <option value="inactive">Inactifs</option>
                <option value="deleted">Supprimés</option>
                <option value="">Tous</option>
            </select>
            <select id="perPageSelect" class="form-control">
                <option value="25">25 par page</option>
                <option value="50">50 par page</option>
                <option value="100">100 par page</option>
            </select>
        </div>
    </div>

    <!-- Results Info -->
    <div class="results-info">
        <span id="resultsCount">Chargement...</span>
    </div>

    <!-- Zones Table -->
    <div class="table-wrapper">
        <table class="zones-table">
            <thead>
                <tr>
                    <th>Zone</th>
                    <th>Type</th>
                    <th>Nom de fichier</th>
                    <th>Parent</th>
                    <th>Propriétaire</th>
                    <th>Statut</th>
                    <th>Modifié le</th>
                </tr>
            </thead>
            <tbody id="zonesTableBody">
                <tr>
                    <td colspan="7" class="loading-cell">
                        <div class="loading">Chargement des zones...</div>
                    </td>
                </tr>
            </tbody>
        </table>
    </div>

    <!-- Pagination Controls -->
    <div class="pagination-controls">
        <button id="prevPage" class="btn btn-secondary" onclick="previousPage()" disabled>
            <i class="fas fa-chevron-left"></i> Précédent
        </button>
        <div class="page-info">
            Page <span id="currentPage">1</span> sur <span id="totalPages">1</span>
        </div>
        <button id="nextPage" class="btn btn-secondary" onclick="nextPage()" disabled>
            Suivant <i class="fas fa-chevron-right"></i>
        </button>
    </div>
</div>

<!-- Create Zone Modal -->
<div id="createZoneModal" class="modal">
    <div class="modal-content">
        <div class="modal-header">
            <h2>Créer une nouvelle zone</h2>
            <span class="close" onclick="closeCreateZoneModal()">&times;</span>
        </div>
        <form id="createZoneForm">
            <div class="form-group">
                <label for="createName">Nom *</label>
                <input type="text" id="createName" class="form-control" required>
            </div>
            <div class="form-group">
                <label for="createFilename">Nom de fichier *</label>
                <input type="text" id="createFilename" class="form-control" required>
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
            <div class="modal-footer">
                <button type="button" class="btn btn-secondary" onclick="closeCreateZoneModal()">Annuler</button>
                <button type="submit" class="btn btn-primary">Créer</button>
            </div>
        </form>
    </div>
</div>

<!-- Zone Edit Modal -->
<div id="zoneModal" class="modal">
    <div class="modal-content modal-large">
        <div class="modal-header">
            <h2 id="zoneModalTitle">Zone</h2>
            <span class="close" onclick="closeZoneModal()">&times;</span>
        </div>
        <div class="modal-body">
            <!-- Tabs -->
            <div class="tabs">
                <button type="button" class="tab-btn active" onclick="switchTab('details')">Détails</button>
                <button type="button" class="tab-btn" onclick="switchTab('editor')">Éditeur</button>
                <button type="button" class="tab-btn" onclick="switchTab('includes')">Includes</button>
            </div>
            
            <!-- Tab Content -->
            <div class="tab-content">
                <!-- Details Tab -->
                <div id="detailsTab" class="tab-pane active">
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
                <div id="editorTab" class="tab-pane">
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
                <div id="includesTab" class="tab-pane">
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
        <div class="modal-footer modal-footer-centered">
            <button type="button" class="btn btn-danger" id="deleteZoneBtn" onclick="deleteZone()">Supprimer</button>
            <button type="button" class="btn btn-secondary" onclick="closeZoneModal()">Annuler</button>
            <button type="button" class="btn btn-primary" onclick="saveZone()">Enregistrer</button>
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
        </div>
        <div class="modal-footer modal-footer-centered">
            <button type="button" id="closeZonePreview" class="btn btn-secondary" onclick="closeZonePreviewModal()">Fermer</button>
            <button type="button" id="downloadZoneFile" class="btn btn-primary">
                <i class="fas fa-download"></i> Télécharger
            </button>
        </div>
    </div>
</div>

<script src="<?php echo $basePath; ?>assets/js/zone-files.js"></script>

<?php
require_once __DIR__ . '/includes/footer.php';
?>
