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
                    <th># Includes</th>
                    <th>Propriétaire</th>
                    <th>Statut</th>
                    <th>Modifié le</th>
                    <th>Actions</th>
                </tr>
            </thead>
            <tbody id="zonesTableBody">
                <tr>
                    <td colspan="8" class="loading-cell">
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

<script src="<?php echo BASE_URL; ?>assets/js/zone-files.js"></script>

<?php
require_once __DIR__ . '/includes/footer.php';
?>
