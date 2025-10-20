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
    <h1>Gestion des enregistrements DNS</h1>
    
    <div id="dns-message" class="dns-message" style="display: none;"></div>

    <div class="dns-toolbar">
        <div class="dns-filters">
            <input type="text" id="dns-search" placeholder="Rechercher par nom..." />
            <select id="dns-type-filter">
                <option value="">Tous les types</option>
                <option value="A">A</option>
                <option value="AAAA">AAAA</option>
                <option value="CNAME">CNAME</option>
                <option value="MX">MX</option>
                <option value="TXT">TXT</option>
                <option value="NS">NS</option>
                <option value="SOA">SOA</option>
                <option value="PTR">PTR</option>
                <option value="SRV">SRV</option>
            </select>
            <select id="dns-status-filter">
                <option value="">Actif seulement</option>
                <option value="active">Actif seulement</option>
                <option value="deleted">Supprimé seulement</option>
            </select>
        </div>
        <button id="dns-create-btn" class="btn-create">+ Créer un enregistrement</button>
    </div>

    <div class="dns-table-container">
        <table class="dns-table">
            <thead>
                <tr>
                    <th>ID</th>
                    <th>Type</th>
                    <th>Nom</th>
                    <th>Valeur</th>
                    <th>TTL</th>
                    <th>Demandeur</th>
                    <th>Expire</th>
                    <th>Vu le</th>
                    <th>Statut</th>
                    <th>Actions</th>
                </tr>
            </thead>
            <tbody id="dns-table-body">
                <tr>
                    <td colspan="10" style="text-align: center; padding: 20px;">Chargement...</td>
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
                <div class="form-group">
                    <label for="record-type">Type d'enregistrement *</label>
                    <select id="record-type" name="record_type" required>
                        <option value="A">A - Adresse IPv4</option>
                        <option value="AAAA">AAAA - Adresse IPv6</option>
                        <option value="CNAME">CNAME - Alias canonique</option>
                        <option value="MX">MX - Serveur de messagerie</option>
                        <option value="TXT">TXT - Texte</option>
                        <option value="NS">NS - Serveur de noms</option>
                        <option value="SOA">SOA - Start of Authority</option>
                        <option value="PTR">PTR - Pointeur</option>
                        <option value="SRV">SRV - Service</option>
                    </select>
                </div>

                <div class="form-group">
                    <label for="record-name">Nom *</label>
                    <input type="text" id="record-name" name="name" required placeholder="example.com">
                </div>

                <div class="form-group">
                    <label for="record-value">Valeur *</label>
                    <input type="text" id="record-value" name="value" required placeholder="192.168.1.1">
                </div>

                <div class="form-group">
                    <label for="record-ttl">TTL (secondes)</label>
                    <input type="number" id="record-ttl" name="ttl" value="3600" min="60">
                </div>

                <div class="form-group">
                    <label for="record-priority">Priorité (pour MX, SRV)</label>
                    <input type="number" id="record-priority" name="priority" min="0" placeholder="10">
                </div>

                <div class="form-group">
                    <label for="record-requester">Demandeur</label>
                    <input type="text" id="record-requester" name="requester" placeholder="Nom de la personne ou du système">
                </div>

                <div class="form-group">
                    <label for="record-expires-at">Date d'expiration</label>
                    <input type="datetime-local" id="record-expires-at" name="expires_at">
                </div>

                <div class="form-group">
                    <label for="record-ticket-ref">Référence ticket</label>
                    <input type="text" id="record-ticket-ref" name="ticket_ref" placeholder="JIRA-123 ou REF-456">
                </div>

                <div class="form-group">
                    <label for="record-comment">Commentaire</label>
                    <textarea id="record-comment" name="comment" rows="3" placeholder="Notes additionnelles..."></textarea>
                </div>

                <div class="form-group" id="record-last-seen-group" style="display: none;">
                    <label for="record-last-seen">Vu pour la dernière fois</label>
                    <input type="text" id="record-last-seen" name="last_seen" disabled readonly placeholder="Non encore consulté">
                </div>

                <div class="dns-modal-footer">
                    <button type="button" class="btn-cancel" onclick="dnsRecords.closeModal()">Annuler</button>
                    <button type="submit" class="btn-submit">Enregistrer</button>
                </div>
            </form>
        </div>
    </div>
</div>

<script src="<?php echo BASE_URL; ?>assets/js/dns-records.js"></script>

<?php
require_once 'includes/footer.php';
?>
