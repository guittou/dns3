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
    <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 20px;">
        <h1 style="margin: 0;">Gestion des enregistrements DNS</h1>
        <div>
            <label for="dns-domain-filter" style="margin-right: 10px;">Domaine:</label>
            <select id="dns-domain-filter" style="min-width: 200px;">
                <option value="">Tous les domaines</option>
            </select>
        </div>
    </div>
    
    <div id="dns-message" class="dns-message" style="display: none;"></div>

    <div class="dns-toolbar">
        <div class="dns-filters">
            <input type="text" id="dns-search" placeholder="Rechercher par nom..." />
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
        <button id="dns-create-btn" class="btn-create">+ Créer un enregistrement</button>
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
            <h2 id="dns-modal-title">Créer un enregistrement DNS</h2>
            <button id="dns-modal-close" class="dns-modal-close">&times;</button>
        </div>
        <div class="dns-modal-body">
            <form id="dns-form">
                <!-- Two-column layout for main fields -->
                <div class="modal-two-columns">
                    <!-- Left column: Zone selector, Name, TTL, Type, IP Address field -->
                    <div class="modal-column-left">
                        <div class="form-group">
                            <label for="record-zone-file">Fichier de zone *</label>
                            <select id="record-zone-file" name="zone_file_id" required>
                                <option value="">-- Sélectionner une zone --</option>
                            </select>
                        </div>

                        <div class="form-group">
                            <label for="record-name">Nom *</label>
                            <input type="text" id="record-name" name="name" required placeholder="example.com">
                        </div>

                        <div class="form-group">
                            <label for="record-ttl">TTL (secondes)</label>
                            <input type="number" id="record-ttl" name="ttl" value="3600" min="60">
                        </div>

                        <div class="form-group">
                            <label for="record-type">Type d'enregistrement *</label>
                            <select id="record-type" name="record_type" required>
                                <option value="A">A - Adresse IPv4</option>
                                <option value="AAAA">AAAA - Adresse IPv6</option>
                                <option value="CNAME">CNAME - Alias canonique</option>
                                <option value="PTR">PTR - Pointeur</option>
                                <option value="TXT">TXT - Texte</option>
                            </select>
                        </div>

                        <!-- Type-specific value fields -->
                        <div class="form-group" id="record-address-ipv4-group" style="display: none;">
                            <label for="record-address-ipv4">Adresse IPv4 *</label>
                            <input type="text" id="record-address-ipv4" name="address_ipv4" placeholder="192.168.1.1">
                        </div>

                        <div class="form-group" id="record-address-ipv6-group" style="display: none;">
                            <label for="record-address-ipv6">Adresse IPv6 *</label>
                            <input type="text" id="record-address-ipv6" name="address_ipv6" placeholder="2001:0db8:85a3:0000:0000:8a2e:0370:7334">
                        </div>

                        <div class="form-group" id="record-cname-target-group" style="display: none;">
                            <label for="record-cname-target">Cible CNAME *</label>
                            <input type="text" id="record-cname-target" name="cname_target" placeholder="target.example.com">
                        </div>

                        <div class="form-group" id="record-ptrdname-group" style="display: none;">
                            <label for="record-ptrdname">Nom PTR (inversé) *</label>
                            <input type="text" id="record-ptrdname" name="ptrdname" placeholder="1.1.168.192.in-addr.arpa">
                        </div>

                        <div class="form-group" id="record-txt-group" style="display: none;">
                            <label for="record-txt">Texte *</label>
                            <textarea id="record-txt" name="txt" rows="3" placeholder="Contenu du champ TXT..."></textarea>
                        </div>
                    </div>

                    <!-- Right column: Ticket reference, Requester, Expiration date, Comment -->
                    <div class="modal-column-right modal-side-col">
                        <div class="form-group">
                            <label for="record-ticket-ref">Référence ticket</label>
                            <input type="text" id="record-ticket-ref" name="ticket_ref" placeholder="JIRA-123 ou REF-456">
                        </div>

                        <div class="form-group">
                            <label for="record-requester">Demandeur</label>
                            <input type="text" id="record-requester" name="requester" placeholder="Nom de la personne ou du système">
                        </div>

                        <div class="form-group">
                            <label for="record-expires-at">Date d'expiration</label>
                            <input type="datetime-local" id="record-expires-at" name="expires_at">
                        </div>

                        <div class="form-group modal-side-comment">
                            <label for="record-comment">Commentaire</label>
                            <textarea id="record-comment" name="comment" placeholder="Notes additionnelles..."></textarea>
                        </div>
                    </div>
                </div>

                <!-- Server-managed field (hidden) -->
                <div class="form-group" id="record-last-seen-group" style="display: none;">
                    <label for="record-last-seen">Vu pour la dernière fois</label>
                    <input type="text" id="record-last-seen" name="last_seen" disabled readonly placeholder="Non encore consulté">
                </div>

                <div class="dns-modal-footer">
                    <div class="modal-action-bar">
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
