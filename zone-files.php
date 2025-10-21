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

<link rel="stylesheet" href="<?php echo BASE_URL; ?>assets/css/zone-files.css">

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

<div class="content-section zone-management-container">
    <div class="split-pane">
        <!-- Left Column: Zone List -->
        <div class="left-pane">
            <div class="filter-bar">
                <input type="text" id="searchZones" placeholder="Rechercher..." class="form-control">
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
            </div>
            
            <div class="zone-groups">
                <div class="zone-group">
                    <h3>Masters</h3>
                    <div id="masterZonesList" class="zone-list">
                        <div class="loading">Chargement...</div>
                    </div>
                </div>
                <div class="zone-group">
                    <h3>Includes</h3>
                    <div id="includeZonesList" class="zone-list">
                        <div class="loading">Chargement...</div>
                    </div>
                </div>
            </div>
        </div>

        <!-- Right Column: Zone Details -->
        <div class="right-pane">
            <div id="emptyState" class="empty-state">
                <i class="fas fa-file-alt"></i>
                <p>Sélectionnez une zone pour voir ses détails</p>
            </div>

            <div id="zoneDetails" class="zone-details" style="display: none;">
                <div class="zone-header">
                    <h2 id="zoneName"></h2>
                    <div class="zone-actions">
                        <button class="btn btn-sm btn-secondary" onclick="refreshZoneDetails()">
                            <i class="fas fa-sync"></i>
                        </button>
                        <button class="btn btn-sm btn-danger" onclick="deleteZone()">
                            <i class="fas fa-trash"></i> Supprimer
                        </button>
                    </div>
                </div>

                <div class="tabs">
                    <button class="tab-btn active" data-tab="details">Détails</button>
                    <button class="tab-btn" data-tab="editor">Éditeur</button>
                    <button class="tab-btn" data-tab="includes">Includes</button>
                    <button class="tab-btn" data-tab="history">Historique</button>
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
                                <button type="button" class="btn btn-secondary" onclick="loadZoneDetails(window.currentZoneId)">Annuler</button>
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
                <select id="createFileType" class="form-control" required>
                    <option value="master">Master</option>
                    <option value="include">Include</option>
                </select>
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

<!-- Add Include Modal -->
<div id="addIncludeModal" class="modal">
    <div class="modal-content">
        <div class="modal-header">
            <h2>Ajouter un include</h2>
            <span class="close" onclick="closeAddIncludeModal()">&times;</span>
        </div>
        <form id="addIncludeForm">
            <div class="form-group">
                <label for="selectInclude">Sélectionner un fichier include *</label>
                <select id="selectInclude" class="form-control" required>
                    <option value="">-- Choisir --</option>
                </select>
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

<script src="<?php echo BASE_URL; ?>assets/js/zone-files.js"></script>

<?php
require_once __DIR__ . '/includes/footer.php';
?>
