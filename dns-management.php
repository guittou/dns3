<?php
/**
 * DNS Management Page
 * Interface for managing DNS records
 * Accessible to admins, zone editors, and users with zone ACL entries
 */
require_once 'includes/header.php';
?>
<link rel="stylesheet" href="<?php echo BASE_URL; ?>assets/css/dns-records-add.css">
<?php

// Check if user is logged in
if (!$auth->isLoggedIn()) {
    header('Location: ' . BASE_URL . 'login.php');
    exit;
}

// Allow access if user is admin OR zone_editor OR has any zone ACL
if (!$auth->isAdmin() && !$auth->isZoneEditor() && !$auth->hasZoneAcl()) {
    if (Auth::isXhrRequest()) {
        // Return JSON error for XHR requests
        Auth::sendJsonError(403, Auth::ERR_ZONE_ACCESS_DENIED);
    } else {
        // Show HTML error for normal requests
        echo '<div class="content-section">
                <div class="error-message">
                    ' . htmlspecialchars(Auth::ERR_ZONE_ACCESS_DENIED) . '
                </div>
              </div>';
        require_once 'includes/footer.php';
        exit;
    }
}

// Determine if user can manage all zones (admin) or only specific zones
$isAdmin = $auth->isAdmin();
?>
<script>
// Pass admin status to JavaScript for UI adjustments only.
// SECURITY NOTE: This variable is for UI enhancements (showing/hiding buttons).
// All critical authorization decisions are validated server-side in the API endpoints.
window.IS_ADMIN = <?php echo $isAdmin ? 'true' : 'false'; ?>;
</script>

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
                <optgroup label="Champs de pointage">
                    <option value="A">A</option>
                    <option value="AAAA">AAAA</option>
                    <option value="NS">NS</option>
                    <option value="CNAME">CNAME</option>
                    <option value="DNAME">DNAME</option>
                </optgroup>
                <optgroup label="Champs étendus">
                    <option value="CAA">CAA</option>
                    <option value="TXT">TXT</option>
                    <option value="NAPTR">NAPTR</option>
                    <option value="SRV">SRV</option>
                    <option value="LOC">LOC</option>
                    <option value="SSHFP">SSHFP</option>
                    <option value="TLSA">TLSA</option>
                    <option value="RP">RP</option>
                    <option value="SVCB">SVCB</option>
                    <option value="HTTPS">HTTPS</option>
                </optgroup>
                <optgroup label="Champs mails">
                    <option value="MX">MX</option>
                    <option value="SPF">SPF</option>
                    <option value="DKIM">DKIM</option>
                    <option value="DMARC">DMARC</option>
                </optgroup>
                <optgroup label="Autres">
                    <option value="PTR">PTR</option>
                    <option value="SOA">SOA</option>
                </optgroup>
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
        
        <!-- Zone File Combobox Row (centered below title) -->
        <div id="zonefile-combobox-row" class="modal-zonefile-row">
            <label for="modal-zonefile-input" class="modal-zonefile-label">Fichier de zone</label>
            <div class="combobox-wrapper">
                <div class="combobox" style="position: relative;">
                    <input type="text" id="modal-zonefile-input" class="combobox-input zonefile-select" placeholder="Rechercher une zone..." autocomplete="off">
                    <input type="hidden" id="modal-zonefile-id">
                    <ul id="modal-zonefile-list" class="combobox-list" style="display: none;"></ul>
                </div>
            </div>
        </div>
        
        <div class="dns-modal-body">
            <!-- Error Banner -->
            <div id="dnsModalErrorBanner" class="modal-error-banner" role="alert" tabindex="-1" style="display:none;">
                <button class="modal-error-close" aria-label="Fermer" onclick="clearModalError('dns')">&times;</button>
                <strong class="modal-error-title">Erreur&nbsp;:</strong>
                <div id="dnsModalErrorMessage" class="modal-error-message"></div>
            </div>
            
            <!-- Type Selection View (Step 1) - OVH-style categories -->
            <div id="type-selection-view" class="type-selection-view" style="display: none;">
                <p style="margin-bottom: 1rem; text-align: center; color: #555;">Sélectionnez le type d'enregistrement DNS à créer :</p>
                
                <!-- Pointing Records Category -->
                <div class="type-category">
                    <h4 class="type-category-title">Champs de pointage</h4>
                    <div class="type-buttons-container">
                        <button type="button" class="type-button" data-type="A" aria-label="Créer un enregistrement de type A">A</button>
                        <button type="button" class="type-button" data-type="AAAA" aria-label="Créer un enregistrement de type AAAA">AAAA</button>
                        <button type="button" class="type-button" data-type="NS" aria-label="Créer un enregistrement de type NS">NS</button>
                        <button type="button" class="type-button" data-type="CNAME" aria-label="Créer un enregistrement de type CNAME">CNAME</button>
                        <button type="button" class="type-button" data-type="DNAME" aria-label="Créer un enregistrement de type DNAME">DNAME</button>
                    </div>
                </div>
                
                <!-- Extended Records Category -->
                <div class="type-category">
                    <h4 class="type-category-title">Champs étendus</h4>
                    <div class="type-buttons-container">
                        <button type="button" class="type-button" data-type="CAA" aria-label="Créer un enregistrement de type CAA">CAA</button>
                        <button type="button" class="type-button" data-type="TXT" aria-label="Créer un enregistrement de type TXT">TXT</button>
                        <button type="button" class="type-button" data-type="NAPTR" aria-label="Créer un enregistrement de type NAPTR">NAPTR</button>
                        <button type="button" class="type-button" data-type="SRV" aria-label="Créer un enregistrement de type SRV">SRV</button>
                        <button type="button" class="type-button" data-type="LOC" aria-label="Créer un enregistrement de type LOC">LOC</button>
                        <button type="button" class="type-button" data-type="SSHFP" aria-label="Créer un enregistrement de type SSHFP">SSHFP</button>
                        <button type="button" class="type-button" data-type="TLSA" aria-label="Créer un enregistrement de type TLSA">TLSA</button>
                        <button type="button" class="type-button" data-type="RP" aria-label="Créer un enregistrement de type RP">RP</button>
                        <button type="button" class="type-button" data-type="SVCB" aria-label="Créer un enregistrement de type SVCB">SVCB</button>
                        <button type="button" class="type-button" data-type="HTTPS" aria-label="Créer un enregistrement de type HTTPS">HTTPS</button>
                    </div>
                </div>
                
                <!-- Mail Records Category -->
                <div class="type-category">
                    <h4 class="type-category-title">Champs mails</h4>
                    <div class="type-buttons-container">
                        <button type="button" class="type-button" data-type="MX" aria-label="Créer un enregistrement de type MX">MX</button>
                        <button type="button" class="type-button type-button-helper" data-type="SPF" aria-label="Créer un enregistrement SPF (stocké en TXT)">SPF</button>
                        <button type="button" class="type-button type-button-helper" data-type="DKIM" aria-label="Créer un enregistrement DKIM (stocké en TXT)">DKIM</button>
                        <button type="button" class="type-button type-button-helper" data-type="DMARC" aria-label="Créer un enregistrement DMARC (stocké en TXT)">DMARC</button>
                    </div>
                </div>
                
                <!-- Other Records Category -->
                <div class="type-category">
                    <h4 class="type-category-title">Autres</h4>
                    <div class="type-buttons-container">
                        <button type="button" class="type-button" data-type="PTR" aria-label="Créer un enregistrement de type PTR">PTR</button>
                    </div>
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
                        <input type="number" id="record-ttl" name="ttl" placeholder="defaut" min="60" required>
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
                    
                    <!-- NS record fields -->
                    <div class="form-group form-group-inline" id="record-ns-target-group" style="display: none;">
                        <label for="record-ns-target">Serveur de noms *</label>
                        <input type="text" id="record-ns-target" name="ns_target" placeholder="ns1.example.com">
                    </div>
                    
                    <!-- DNAME record fields -->
                    <div class="form-group form-group-inline" id="record-dname-target-group" style="display: none;">
                        <label for="record-dname-target">Cible DNAME *</label>
                        <input type="text" id="record-dname-target" name="dname_target" placeholder="target.example.com">
                    </div>
                    
                    <!-- MX record fields -->
                    <div class="form-group form-group-inline" id="record-mx-target-group" style="display: none;">
                        <label for="record-mx-target">Serveur mail *</label>
                        <input type="text" id="record-mx-target" name="mx_target" placeholder="mail.example.com">
                    </div>
                    <div class="form-group form-group-inline" id="record-priority-group" style="display: none;">
                        <label for="record-priority">Priorité *</label>
                        <input type="number" id="record-priority" name="priority" min="0" max="65535" placeholder="10">
                    </div>
                </div>
                
                <!-- Extended record type fields (shown on separate rows) -->
                
                <!-- SRV record fields -->
                <div class="form-row" id="record-srv-fields" style="display: none;">
                    <div class="form-group form-group-inline">
                        <label for="record-srv-priority">Priorité *</label>
                        <input type="number" id="record-srv-priority" name="priority" min="0" max="65535" placeholder="10">
                    </div>
                    <div class="form-group form-group-inline">
                        <label for="record-srv-weight">Poids *</label>
                        <input type="number" id="record-srv-weight" name="weight" min="0" max="65535" placeholder="5">
                    </div>
                    <div class="form-group form-group-inline">
                        <label for="record-srv-port">Port *</label>
                        <input type="number" id="record-srv-port" name="port" min="0" max="65535" placeholder="443">
                    </div>
                    <div class="form-group form-group-inline">
                        <label for="record-srv-target">Cible *</label>
                        <input type="text" id="record-srv-target" name="srv_target" placeholder="server.example.com">
                    </div>
                </div>
                
                <!-- CAA record fields -->
                <div class="form-row" id="record-caa-fields" style="display: none;">
                    <div class="form-group form-group-inline">
                        <label for="record-caa-flag">Flag</label>
                        <select id="record-caa-flag" name="caa_flag">
                            <option value="0">0 (Non-critique)</option>
                            <option value="128">128 (Critique)</option>
                        </select>
                    </div>
                    <div class="form-group form-group-inline">
                        <label for="record-caa-tag">Tag *</label>
                        <select id="record-caa-tag" name="caa_tag">
                            <option value="issue">issue</option>
                            <option value="issuewild">issuewild</option>
                            <option value="iodef">iodef</option>
                        </select>
                    </div>
                    <div class="form-group form-group-inline">
                        <label for="record-caa-value">Valeur *</label>
                        <input type="text" id="record-caa-value" name="caa_value" placeholder="letsencrypt.org">
                    </div>
                </div>
                
                <!-- TLSA record fields -->
                <div class="form-row" id="record-tlsa-fields" style="display: none;">
                    <div class="form-group form-group-inline">
                        <label for="record-tlsa-usage">Usage *</label>
                        <select id="record-tlsa-usage" name="tlsa_usage">
                            <option value="0">0 - PKIX-TA</option>
                            <option value="1">1 - PKIX-EE</option>
                            <option value="2">2 - DANE-TA</option>
                            <option value="3" selected>3 - DANE-EE</option>
                        </select>
                    </div>
                    <div class="form-group form-group-inline">
                        <label for="record-tlsa-selector">Sélecteur *</label>
                        <select id="record-tlsa-selector" name="tlsa_selector">
                            <option value="0">0 - Cert</option>
                            <option value="1" selected>1 - SPKI</option>
                        </select>
                    </div>
                    <div class="form-group form-group-inline">
                        <label for="record-tlsa-matching">Matching *</label>
                        <select id="record-tlsa-matching" name="tlsa_matching">
                            <option value="0">0 - Exact</option>
                            <option value="1" selected>1 - SHA-256</option>
                            <option value="2">2 - SHA-512</option>
                        </select>
                    </div>
                </div>
                <div class="form-row" id="record-tlsa-data-row" style="display: none;">
                    <div class="form-group">
                        <label for="record-tlsa-data">Données certificat (hex) *</label>
                        <input type="text" id="record-tlsa-data" name="tlsa_data" placeholder="a1b2c3d4e5f6..." style="font-family: monospace;">
                    </div>
                </div>
                
                <!-- SSHFP record fields -->
                <div class="form-row" id="record-sshfp-fields" style="display: none;">
                    <div class="form-group form-group-inline">
                        <label for="record-sshfp-algo">Algorithme *</label>
                        <select id="record-sshfp-algo" name="sshfp_algo">
                            <option value="1">1 - RSA</option>
                            <option value="2">2 - DSA</option>
                            <option value="3">3 - ECDSA</option>
                            <option value="4">4 - Ed25519</option>
                        </select>
                    </div>
                    <div class="form-group form-group-inline">
                        <label for="record-sshfp-type">Type empreinte *</label>
                        <select id="record-sshfp-type" name="sshfp_type">
                            <option value="1">1 - SHA-1</option>
                            <option value="2" selected>2 - SHA-256</option>
                        </select>
                    </div>
                </div>
                <div class="form-row" id="record-sshfp-fp-row" style="display: none;">
                    <div class="form-group">
                        <label for="record-sshfp-fingerprint">Empreinte (hex) *</label>
                        <input type="text" id="record-sshfp-fingerprint" name="sshfp_fingerprint" placeholder="a1b2c3d4e5f6..." style="font-family: monospace;">
                    </div>
                </div>
                
                <!-- NAPTR record fields -->
                <div class="form-row" id="record-naptr-fields" style="display: none;">
                    <div class="form-group form-group-inline">
                        <label for="record-naptr-order">Ordre *</label>
                        <input type="number" id="record-naptr-order" name="naptr_order" min="0" max="65535" placeholder="100">
                    </div>
                    <div class="form-group form-group-inline">
                        <label for="record-naptr-pref">Préférence *</label>
                        <input type="number" id="record-naptr-pref" name="naptr_pref" min="0" max="65535" placeholder="10">
                    </div>
                    <div class="form-group form-group-inline">
                        <label for="record-naptr-flags">Flags</label>
                        <input type="text" id="record-naptr-flags" name="naptr_flags" placeholder="U, S, A" maxlength="16">
                    </div>
                    <div class="form-group form-group-inline">
                        <label for="record-naptr-service">Service</label>
                        <input type="text" id="record-naptr-service" name="naptr_service" placeholder="E2U+sip">
                    </div>
                </div>
                <div class="form-row" id="record-naptr-extra-row" style="display: none;">
                    <div class="form-group form-group-inline">
                        <label for="record-naptr-regexp">Regexp</label>
                        <input type="text" id="record-naptr-regexp" name="naptr_regexp" placeholder="!^.*$!sip:info@example.com!">
                    </div>
                    <div class="form-group form-group-inline">
                        <label for="record-naptr-replacement">Replacement</label>
                        <input type="text" id="record-naptr-replacement" name="naptr_replacement" placeholder="." value=".">
                    </div>
                </div>
                
                <!-- SVCB/HTTPS record fields -->
                <div class="form-row" id="record-svc-fields" style="display: none;">
                    <div class="form-group form-group-inline">
                        <label for="record-svc-priority">Priorité *</label>
                        <input type="number" id="record-svc-priority" name="svc_priority" min="0" max="65535" placeholder="1">
                    </div>
                    <div class="form-group form-group-inline">
                        <label for="record-svc-target">Cible *</label>
                        <input type="text" id="record-svc-target" name="svc_target" placeholder="." value=".">
                    </div>
                </div>
                <div class="form-row" id="record-svc-params-row" style="display: none;">
                    <div class="form-group">
                        <label for="record-svc-params">Paramètres (optionnel)</label>
                        <input type="text" id="record-svc-params" name="svc_params" placeholder="alpn=h2 port=443">
                    </div>
                </div>
                
                <!-- LOC record fields -->
                <div class="form-row" id="record-loc-fields" style="display: none;">
                    <div class="form-group form-group-inline">
                        <label for="record-loc-latitude">Latitude *</label>
                        <input type="text" id="record-loc-latitude" name="loc_latitude" placeholder="52 22 23.000 N">
                    </div>
                    <div class="form-group form-group-inline">
                        <label for="record-loc-longitude">Longitude *</label>
                        <input type="text" id="record-loc-longitude" name="loc_longitude" placeholder="4 53 32.000 E">
                    </div>
                    <div class="form-group form-group-inline">
                        <label for="record-loc-altitude">Altitude</label>
                        <input type="text" id="record-loc-altitude" name="loc_altitude" placeholder="-2.00m">
                    </div>
                </div>
                
                <!-- RP record fields -->
                <div class="form-row" id="record-rp-fields" style="display: none;">
                    <div class="form-group form-group-inline">
                        <label for="record-rp-mbox">Mailbox *</label>
                        <input type="text" id="record-rp-mbox" name="rp_mbox" placeholder="admin.example.com">
                    </div>
                    <div class="form-group form-group-inline">
                        <label for="record-rp-txt">TXT domain *</label>
                        <input type="text" id="record-rp-txt" name="rp_txt" placeholder="." value=".">
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
                
                <!-- Record History Section (edit mode only) -->
                <div class="form-row" id="record-history-section">
                    <div class="form-group">
                        <button type="button" id="btn-open-history" class="btn-history-toggle">
                            Voir l'historique
                        </button>
                    </div>
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

<!-- Record History Modal (fixed-size, scrollable) -->
<div id="recordHistoryModal" class="dns-modal history-modal">
    <div class="dns-modal-content history-modal-content">
        <div class="dns-modal-header">
            <h2>Historique de l'enregistrement</h2>
            <button type="button" class="dns-modal-close" onclick="window.closeHistoryModal()">&times;</button>
        </div>
        <div class="dns-modal-body">
            <div id="record-history-container" class="history-container">
                <!-- History will be loaded here -->
            </div>
        </div>
        <div class="dns-modal-footer">
            <button type="button" class="btn-cancel" onclick="window.closeHistoryModal()">Fermer</button>
        </div>
    </div>
</div>

<script src="<?php echo BASE_URL; ?>assets/js/modal-utils.js"></script>
<script src="<?php echo BASE_URL; ?>assets/js/combobox-utils.js"></script>
<script src="<?php echo BASE_URL; ?>assets/js/zone-combobox-shared.js"></script>
<script src="<?php echo BASE_URL; ?>assets/js/zone-combobox.js"></script>
<script src="<?php echo BASE_URL; ?>assets/js/dns-records.js"></script>
<script src="<?php echo BASE_URL; ?>assets/js/zone-permission.js"></script>

<script>
// History modal functions and event handlers
// This script must run AFTER dns-records.js to access window.fetchRecordHistory/renderRecordHistory
(function() {
    'use strict';
    
    // Open history modal function
    window.openHistoryModal = function() {
        var modal = document.getElementById('recordHistoryModal');
        if (!modal) return;
        
        // Try Bootstrap modal if available
        if (typeof jQuery !== 'undefined' && jQuery.fn && jQuery.fn.modal) {
            jQuery(modal).modal('show');
        } else {
            // Fallback: vanilla JS
            modal.style.display = 'block';
            modal.classList.add('open');
        }
    };
    
    // Close history modal function
    window.closeHistoryModal = function() {
        var modal = document.getElementById('recordHistoryModal');
        if (!modal) return;
        
        // Try Bootstrap modal if available
        if (typeof jQuery !== 'undefined' && jQuery.fn && jQuery.fn.modal) {
            jQuery(modal).modal('hide');
        } else {
            // Fallback: vanilla JS
            modal.style.display = 'none';
            modal.classList.remove('open');
        }
    };
    
    // Button click handler - lazy load history when opening the modal
    // Uses window.openRecordHistoryModalForCurrentRecord() which handles:
    // - Getting recordId from form
    // - Showing spinner
    // - Syncing modal size with edit modal
    // - Fetching and rendering history
    var btnOpenHistory = document.getElementById('btn-open-history');
    if (btnOpenHistory) {
        btnOpenHistory.addEventListener('click', function() {
            if (typeof window.openRecordHistoryModalForCurrentRecord === 'function') {
                window.openRecordHistoryModalForCurrentRecord();
            } else {
                console.warn('[History Modal] openRecordHistoryModalForCurrentRecord function not available');
            }
        });
    }
    
    // Close modal on outside click
    var historyModal = document.getElementById('recordHistoryModal');
    if (historyModal) {
        historyModal.addEventListener('click', function(event) {
            if (event.target === historyModal) {
                window.closeHistoryModal();
            }
        });
    }
})();
</script>

<?php
require_once 'includes/footer.php';
?>
