<?php
require_once __DIR__ . '/includes/header.php';

// Check if user is logged in
if (!$auth->isLoggedIn()) {
    header('Location: ' . BASE_URL . 'login.php');
    exit;
}

// Allow access if user is admin OR zone_editor OR has any zone ACL
if (!$auth->isAdmin() && !$auth->isZoneEditor() && !$auth->hasZoneAcl()) {
    header('Location: ' . BASE_URL . 'index.php');
    exit;
}

// Get zone ID from URL
$zone_id = isset($_GET['id']) ? (int)$_GET['id'] : 0;
if ($zone_id <= 0) {
    header('Location: ' . BASE_URL . 'zone-files.php');
    exit;
}

// Determine if user is admin (for full access) or needs ACL check
$isAdmin = $auth->isAdmin();
?>
<script>
// Pass admin status to JavaScript for UI adjustments only.
// SECURITY NOTE: This variable is for UI enhancements (showing/hiding buttons).
// All critical authorization decisions are validated server-side in the API endpoints.
window.IS_ADMIN = <?php echo $isAdmin ? 'true' : 'false'; ?>;
</script>

<link rel="stylesheet" href="<?php echo BASE_URL; ?>assets/css/zone-files.css">

<div class="content-section">
    <div class="header-bar">
        <div class="breadcrumb">
            <a href="<?php echo BASE_URL; ?>zone-files.php">Fichiers de zone</a>
            <span class="separator">›</span>
            <span id="zoneBreadcrumbName">Chargement...</span>
        </div>
        <div class="header-actions">
            <button class="btn btn-secondary" onclick="window.location.href='<?php echo BASE_URL; ?>zone-files.php'">
                <i class="fas fa-arrow-left"></i> Retour à la liste
            </button>
        </div>
    </div>
</div>

<div class="content-section zone-detail-container">
    <div id="loadingState" class="loading-state">
        <div class="spinner"></div>
        <p>Chargement des détails de la zone...</p>
    </div>

    <div id="errorState" class="error-state" style="display: none;">
        <i class="fas fa-exclamation-triangle"></i>
        <p id="errorMessage">Une erreur est survenue</p>
        <button class="btn btn-primary" onclick="window.location.reload()">Réessayer</button>
    </div>

    <div id="zoneDetails" class="zone-details" style="display: none;">
        <div class="zone-header">
            <div class="zone-title-section">
                <h2 id="zoneName"></h2>
                <span id="zoneStatus" class="badge"></span>
                <span id="zoneType" class="badge"></span>
            </div>
            <div class="zone-actions">
                <button class="btn btn-sm btn-secondary" onclick="refreshZoneDetails()" title="Actualiser">
                    <i class="fas fa-sync"></i>
                </button>
                <button class="btn btn-sm btn-danger" onclick="deleteZone()" title="Supprimer">
                    <i class="fas fa-trash"></i> Supprimer
                </button>
            </div>
        </div>

        <div class="tabs">
            <button class="tab-btn active" data-tab="details" onclick="switchTab('details')">Détails</button>
            <button class="tab-btn" data-tab="editor" onclick="switchTab('editor')">Éditeur</button>
            <button class="tab-btn" data-tab="includes" onclick="switchTab('includes')">Includes</button>
            <button class="tab-btn" data-tab="history" onclick="switchTab('history')">Historique</button>
        </div>

        <div class="tab-content">
            <!-- Details Tab -->
            <div id="detailsTab" class="tab-pane active">
                <form id="detailsForm" class="form-grid">
                    <div class="form-group">
                        <label>Nom:</label>
                        <input type="text" id="detailName" class="form-control" required>
                    </div>
                    <div class="form-group">
                        <label>Nom de fichier:</label>
                        <input type="text" id="detailFilename" class="form-control" required>
                    </div>
                    <div class="form-group">
                        <label>Type:</label>
                        <select id="detailFileType" class="form-control" required>
                            <option value="master">Master</option>
                            <option value="include">Include</option>
                        </select>
                    </div>
                    <div class="form-group">
                        <label>Statut:</label>
                        <select id="detailStatus" class="form-control" required>
                            <option value="active">Actif</option>
                            <option value="inactive">Inactif</option>
                            <option value="deleted">Supprimé</option>
                        </select>
                    </div>
                    <div class="form-group full-width">
                        <label>Créé par:</label>
                        <span id="detailCreatedBy" class="detail-value"></span>
                    </div>
                    <div class="form-group full-width">
                        <label>Créé le:</label>
                        <span id="detailCreatedAt" class="detail-value"></span>
                    </div>
                    <div class="form-group full-width">
                        <label>Modifié par:</label>
                        <span id="detailUpdatedBy" class="detail-value"></span>
                    </div>
                    <div class="form-group full-width">
                        <label>Modifié le:</label>
                        <span id="detailUpdatedAt" class="detail-value"></span>
                    </div>
                    <div class="form-actions full-width">
                        <button type="submit" class="btn btn-primary">Enregistrer</button>
                        <button type="button" class="btn btn-secondary" onclick="loadZoneDetails()">Annuler</button>
                    </div>
                </form>
            </div>

            <!-- Editor Tab -->
            <div id="editorTab" class="tab-pane">
                <div class="editor-actions">
                    <button class="btn btn-sm btn-secondary" onclick="downloadZoneContent()">
                        <i class="fas fa-download"></i> Télécharger
                    </button>
                    <button class="btn btn-sm btn-info" onclick="showResolvedContent()">
                        <i class="fas fa-eye"></i> Voir le contenu résolu
                    </button>
                </div>
                <textarea id="contentEditor" class="code-editor" placeholder="Contenu de la zone..."></textarea>
                <div class="editor-footer">
                    <button class="btn btn-primary" onclick="saveContent()">Enregistrer le contenu</button>
                </div>
            </div>

            <!-- Includes Tab -->
            <div id="includesTab" class="tab-pane">
                <div class="includes-header">
                    <h3>Arborescence des includes</h3>
                    <button class="btn btn-sm btn-primary" onclick="openAddIncludeModal()">
                        <i class="fas fa-plus"></i> Ajouter include
                    </button>
                </div>
                <div id="includeTree" class="include-tree">
                    <div class="loading">Chargement...</div>
                </div>
            </div>

            <!-- History Tab -->
            <div id="historyTab" class="tab-pane">
                <div id="historyList" class="history-list">
                    <div class="loading">Chargement...</div>
                </div>
            </div>
        </div>
    </div>
</div>

<!-- Add Include Modal -->
<div id="addIncludeModal" class="modal">
    <div class="modal-content">
        <div class="modal-header">
            <h2>Ajouter un include</h2>
            <span class="close" onclick="closeAddIncludeModal()">&times;</span>
        </div>
        <form id="addIncludeForm">
            <div class="form-group">
                <label for="includeSearch">Rechercher un fichier include *</label>
                <input type="text" id="includeSearch" class="form-control" placeholder="Tapez pour rechercher..." autocomplete="off">
                <div id="autocompleteResults" class="autocomplete-results" style="display: none;"></div>
                <input type="hidden" id="selectedIncludeId" required>
            </div>
            <div class="form-group">
                <label for="includePosition">Position (ordre)</label>
                <input type="number" id="includePosition" class="form-control" value="0" min="0">
            </div>
            <div class="modal-footer">
                <button type="button" class="btn btn-secondary" onclick="closeAddIncludeModal()">Annuler</button>
                <button type="submit" class="btn btn-primary">Ajouter</button>
            </div>
        </form>
    </div>
</div>

<!-- Resolved Content Modal -->
<div id="resolvedContentModal" class="modal">
    <div class="modal-content modal-large">
        <div class="modal-header">
            <h2>Contenu résolu (avec includes)</h2>
            <span class="close" onclick="closeResolvedContentModal()">&times;</span>
        </div>
        <div class="modal-body">
            <pre id="resolvedContent" class="resolved-content"></pre>
        </div>
        <div class="modal-footer">
            <button type="button" class="btn btn-secondary" onclick="closeResolvedContentModal()">Fermer</button>
        </div>
    </div>
</div>

<script>
// Pass zone ID to JavaScript
window.currentZoneId = <?php echo $zone_id; ?>;
</script>
<script src="<?php echo BASE_URL; ?>assets/js/zone-file-detail.js"></script>

<?php
require_once __DIR__ . '/includes/footer.php';
?>
