<?php
/**
 * DNS Management Page
 * Interface for managing DNS records (admin only)
 */
require_once 'includes/header.php';

// Check if user is logged in and is admin
if (!$auth->isLoggedIn()) {
    header('Location: ' . BASE_URL . 'login.php');
    exit;
}

if (!$auth->isAdmin()) {
    echo '<div class="content-section">
            <div class="error-message">
                Vous devez être administrateur pour accéder à cette page.
            </div>
          </div>';
    require_once 'includes/footer.php';
    exit;
}
?>

<div class="content-section">
    <h1 style="margin-bottom: 20px;">Gestion des enregistrements DNS</h1>
    
    <!-- Comboboxes pour Domaine et Fichier de zone -->
    <div class="dns-combobox-container" style="display: flex; gap: 20px; margin-bottom: 20px; flex-wrap: wrap; align-items: flex-end;">
        <!-- Combobox Domaine -->
        <div class="combobox-wrapper" style="flex: 1; min-width: 250px;">
            <label for="dns-domain-input" style="display: block; margin-bottom: 5px; font-weight: 500;">Domaine:</label>
            <div class="combobox">
                <input type="text" id="dns-domain-input" class="combobox-input" placeholder="Rechercher un domaine..." autocomplete="off">
                <input type="hidden" id="dns-zone-file-id">
                <!-- Backward compatibility: dns-domain-id is now mapped to dns-zone-file-id -->
                <input type="hidden" id="dns-domain-id">
                <ul id="dns-domain-list" class="combobox-list" style="display: none;"></ul>
            </div>
        </div>
        
        <!-- Combobox Fichier de zone -->
        <div class="combobox-wrapper" style="flex: 1; min-width: 250px;">
            <label for="dns-zone-input" style="display: block; margin-bottom: 5px; font-weight: 500;">Fichier de zone:</label>
            <div class="combobox">
                <input type="text" id="dns-zone-input" class="combobox-input" placeholder="Rechercher une zone..." autocomplete="off">
                <input type="hidden" id="dns-zone-id">
                <ul id="dns-zone-list" class="combobox-list" style="display: none;"></ul>
            </div>
        </div>
        
        <!-- Reset Button -->
        <div style="flex: 0 0 auto;">
            <button id="dns-reset-filters-btn" class="btn-reset">Réinitialiser</button>
        </div>
    </div>
    
    <div id="dns-message" class="dns-message" style="display: none;"></div>

    <div class="dns-toolbar">
        <div class="dns-filters">
            <input type="text" id="dns-search" placeholder="Rechercher par nom ou valeur..." aria-label="Rechercher par nom ou valeur" />
            <select id="dns-type-filter">
                <option value="">Tous les types</option>
                <option value="A">A</option>
                <option value="AAAA">AAAA</option>
                <option value="CNAME">CNAME</option>
                <option value="PTR">PTR</option>
                <option value="TXT">TXT</option>
            </select>
            <select id="dns-status-filter">                
                <option value="active">Actif seulement</option>
                <option value="deleted">Supprimé seulement</option>
                <option value="">Tous les statuts</option>
            </select>
        </div>
        <button id="dns-create-btn" class="btn-create" disabled>+ Ajouter un enregistrement</button>
    </div>

    <div class="dns-table-container">
        <table class="dns-table">
            <thead>
                <tr>
                    <th class="col-domain">Domaine</th>
                    <th class="col-zonefile">Fichier de zone</th>
                    <th class="col-name">Nom</th>
                    <th class="col-ttl">TTL</th>
                    <th class="col-class">Classe</th>
                    <th class="col-type">Type</th>
                    <th class="col-value">Valeur</th>
                    <th class="col-updated">Modifié le</th>
                    <th class="col-lastseen">Vu le</th>
                    <th class="col-status">Statut</th>
                    <th class="col-actions">Actions</th>
                </tr>
            </thead>
            <tbody id="dns-table-body">
                <tr>
                    <td colspan="11" style="text-align: center; padding: 20px;">Chargement...</td>
                </tr>
            </tbody>
        </table>
    </div>
</div>

<!-- DNS Record Modal -->
<div id="dns-modal" class="dns-modal">
    <div class="dns-modal-content">
        <div class="dns-modal-header">
            <div class="dns-modal-title-wrapper">
                <h2 id="dns-modal-title">Ajouter un enregistrement DNS</h2>
                <div id="dns-modal-domain" class="dns-modal-domain" style="display:none;"></div>
            </div>
            <button id="dns-modal-close" class="dns-modal-close">&times;</button>
        </div>
        <div class="dns-modal-body">
            <!-- Type Selection View (Step 1) -->
            <div id="type-selection-view" class="type-selection-view" style="display: none;">
                <p style="margin-bottom: 1rem; text-align: center; color: #555;">Sélectionnez le type d'enregistrement DNS à créer :</p>
                <div class="type-buttons-container">
                    <button type="button" class="type-button" data-type="A" aria-label="Créer un enregistrement de type A">A</button>
                    <button type="button" class="type-button" data-type="AAAA" aria-label="Créer un enregistrement de type AAAA">AAAA</button>
                    <button type="button" class="type-button" data-type="CNAME" aria-label="Créer un enregistrement de type CNAME">CNAME</button>
                    <button type="button" class="type-button" data-type="PTR" aria-label="Créer un enregistrement de type PTR">PTR</button>
                    <button type="button" class="type-button" data-type="TXT" aria-label="Créer un enregistrement de type TXT">TXT</button>
                </div>
            </div>
            
            <!-- Form View (Step 2 and Edit mode) -->
            <form id="dns-form" style="display: block;">
                <!-- Hidden field for zone file (managed by combobox on page) -->
                <input type="hidden" id="record-zone-file" name="zone_file_id">
                
                <!-- Row 1: Name, TTL, Value (type-specific) -->
                <div class="form-row form-row-main">
                    <div class="form-group form-group-inline">
                        <label for="record-name">Nom *</label>
                        <input type="text" id="record-name" name="name" required placeholder="example.com">
                    </div>

                    <div class="form-group form-group-inline">
                        <label for="record-ttl">TTL *</label>
                        <input type="number" id="record-ttl" name="ttl" value="3600" min="60" required>
                    </div>

                    <!-- Type-specific value fields (only one visible at a time) -->
                    <div class="form-group form-group-inline" id="record-address-ipv4-group" style="display: none;">
                        <label for="record-address-ipv4" id="record-address-ipv4-label">Adresse IPv4 *</label>
                        <input type="text" id="record-address-ipv4" name="address_ipv4" placeholder="192.168.1.1">
                    </div>

                    <div class="form-group form-group-inline" id="record-address-ipv6-group" style="display: none;">
                        <label for="record-address-ipv6" id="record-address-ipv6-label">Adresse IPv6 *</label>
                        <input type="text" id="record-address-ipv6" name="address_ipv6" placeholder="2001:0db8:85a3::1">
                    </div>

                    <div class="form-group form-group-inline" id="record-cname-target-group" style="display: none;">
                        <label for="record-cname-target" id="record-cname-target-label">Cible *</label>
                        <input type="text" id="record-cname-target" name="cname_target" placeholder="target.example.com">
                    </div>

                    <div class="form-group form-group-inline" id="record-ptrdname-group" style="display: none;">
                        <label for="record-ptrdname" id="record-ptrdname-label">Nom PTR *</label>
                        <input type="text" id="record-ptrdname" name="ptrdname" placeholder="host.example.com">
                    </div>

                    <div class="form-group form-group-inline" id="record-txt-group" style="display: none;">
                        <label for="record-txt" id="record-txt-label">Texte *</label>
                        <input type="text" id="record-txt" name="txt" placeholder="Texte TXT">
                    </div>
                </div>
                
                <!-- Row 2: Ticket reference, Requester -->
                <div class="form-row">
                    <div class="form-group form-group-inline">
                        <label for="record-ticket-ref">Référence ticket</label>
                        <input type="text" id="record-ticket-ref" name="ticket_ref" placeholder="JIRA-123">
                    </div>

                    <div class="form-group form-group-inline">
                        <label for="record-requester">Demandeur</label>
                        <input type="text" id="record-requester" name="requester" placeholder="Nom du demandeur">
                    </div>
                </div>
                
                <!-- Row 3: Comment -->
                <div class="form-row">
                    <div class="form-group">
                        <label for="record-comment">Commentaire</label>
                        <textarea id="record-comment" name="comment" rows="2" placeholder="Notes additionnelles..."></textarea>
                    </div>
                </div>
                
                <!-- Row 4: DNS Preview -->
                <div class="form-row" id="dns-preview-row">
                    <div class="form-group">
                        <label for="dns-preview">Champ DNS actuellement généré</label>
                        <textarea id="dns-preview" readonly rows="3" placeholder="La prévisualisation apparaîtra ici..." style="font-family: monospace; background-color: #f5f5f5;"></textarea>
                    </div>
                </div>

                <!-- Hidden fields for backward compatibility and edit mode -->
                <input type="hidden" id="record-type" name="record_type">
                <input type="hidden" id="record-expires-at" name="expires_at">
                
                <!-- Server-managed field (hidden) -->
                <div class="form-group" id="record-last-seen-group" style="display: none;">
                    <label for="record-last-seen">Vu pour la dernière fois</label>
                    <input type="text" id="record-last-seen" name="last_seen" disabled readonly placeholder="Non encore consulté">
                </div>

                <div class="dns-modal-footer">
                    <div class="modal-action-bar">
                        <button type="button" id="record-previous-btn" class="btn-secondary modal-action-button" style="display: none;">Précédent</button>
                        <button type="submit" id="record-save-btn" class="btn-submit modal-action-button">Enregistrer</button>
                        <button type="button" id="record-cancel-btn" class="btn-cancel modal-action-button" onclick="dnsRecords.closeModal()">Annuler</button>
                        <button type="button" id="record-delete-btn" class="btn-delete modal-action-button" style="display: none;">Supprimer</button>
                    </div>
                </div>
            </form>
        </div>
    </div>
</div>

<script src="<?php echo BASE_URL; ?>assets/js/modal-utils.js"></script>
<script src="<?php echo BASE_URL; ?>assets/js/dns-records.js"></script>

<?php
require_once 'includes/footer.php';
?>
