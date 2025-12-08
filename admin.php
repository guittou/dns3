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

<!-- Optional: Admin Tokens specific styles -->
<link rel="stylesheet" href="<?php echo BASE_URL; ?>assets/css/admin-tokens.css">


<div class="admin-container">
    <h1>Administration</h1>
    
    <!-- Tabs Navigation -->
    <div class="admin-tabs">
        <button class="admin-tab-button active" data-tab="users">Utilisateurs</button>
        <button class="admin-tab-button" data-tab="roles">Rôles</button>
        <button class="admin-tab-button" data-tab="mappings">Mappings AD/LDAP</button>
        <button class="admin-tab-button" data-tab="tokens">Tokens API</button>
    </div>
    
    <!-- Tab Content: Users -->
    <div class="admin-tab-content active" id="tab-users">
        <div class="tab-header">
            <h2>Gestion des Utilisateurs</h2>
            <button class="btn btn-primary" id="btn-create-user" onclick="if(typeof openCreateUserModal==='function')openCreateUserModal();">
                <span class="icon">+</span> Créer un utilisateur
            </button>
        </div>
        
        <div class="filters-section">
            <input type="text" id="filter-username" placeholder="Rechercher par nom d'utilisateur..." class="filter-input">
            <select id="filter-auth-method" class="filter-select">
                <option value="">Toutes les méthodes d'authentification</option>
                <option value="database">Base de données</option>
                <option value="ad">Active Directory</option>
                <option value="ldap">LDAP</option>
            </select>
            <select id="filter-is-active" class="filter-select">
                <option value="">Tous les statuts</option>
                <option value="1">Actif</option>
                <option value="0">Inactif</option>
            </select>
            <button class="btn btn-secondary" id="btn-filter-users">Filtrer</button>
            <button class="btn btn-secondary" id="btn-reset-filters">Réinitialiser</button>
        </div>
        
        <div class="table-container">
            <table class="admin-table" id="users-table">
                <thead>
                    <tr>
                        <th>ID</th>
                        <th>Nom d'utilisateur</th>
                        <th>Email</th>
                        <th>Méthode d'auth</th>
                        <th>Rôles</th>
                        <th>Statut</th>
                        <th>Créé le</th>
                        <th>Dernière connexion</th>
                        <th>Actions</th>
                    </tr>
                </thead>
                <tbody id="users-tbody">
                    <tr>
                        <td colspan="9" class="loading">Chargement des utilisateurs...</td>
                    </tr>
                </tbody>
            </table>
        </div>
    </div>
    
    <!-- Tab Content: Roles -->
    <div class="admin-tab-content" id="tab-roles">
        <div class="tab-header">
            <h2>Rôles Disponibles</h2>
        </div>
        
        <div class="table-container">
            <table class="admin-table" id="roles-table">
                <thead>
                    <tr>
                        <th>ID</th>
                        <th>Nom</th>
                        <th>Description</th>
                        <th>Créé le</th>
                    </tr>
                </thead>
                <tbody id="roles-tbody">
                    <tr>
                        <td colspan="4" class="loading">Chargement des rôles...</td>
                    </tr>
                </tbody>
            </table>
        </div>
    </div>
    
    <!-- Tab Content: Mappings -->
    <div class="admin-tab-content" id="tab-mappings">
        <div class="tab-header">
            <h2>Mappings AD/LDAP</h2>
            <button class="btn btn-primary" id="btn-create-mapping" onclick="if(typeof openCreateMappingModal==='function')openCreateMappingModal();">
                <span class="icon">+</span> Créer un mapping
            </button>
        </div>
        
        <div class="info-box">
            <p><strong>Mappings AD/LDAP</strong> permettent d'attribuer automatiquement des rôles aux utilisateurs lors de l'authentification basée sur leur groupe AD ou DN LDAP.</p>
            <p><strong>AD:</strong> Utilisez le DN complet du groupe, ex: <code>CN=DNSAdmins,OU=Groups,DC=example,DC=com</code></p>
            <p><strong>LDAP:</strong> Utilisez le DN ou chemin OU, ex: <code>ou=IT,dc=example,dc=com</code></p>
        </div>
        
        <div class="table-container">
            <table class="admin-table" id="mappings-table">
                <thead>
                    <tr>
                        <th>ID</th>
                        <th>Source</th>
                        <th>DN/Groupe</th>
                        <th>Rôle</th>
                        <th>Créé par</th>
                        <th>Créé le</th>
                        <th>Notes</th>
                        <th>Actions</th>
                    </tr>
                </thead>
                <tbody id="mappings-tbody">
                    <tr>
                        <td colspan="8" class="loading">Chargement des mappings...</td>
                    </tr>
                </tbody>
            </table>
        </div>
    </div>
    
    <!-- Tab Content: API Tokens -->
    <div class="admin-tab-content" id="tab-tokens">
        <div class="tab-header">
            <h2>Tokens API</h2>
            <button class="btn btn-primary" id="btn-create-token">
                <span class="icon">+</span> Créer un token
            </button>
        </div>
        
        <div class="info-box">
            <p><strong>Tokens API</strong> permettent l'authentification via Bearer token pour les appels API automatisés.</p>
            <p>⚠️ <strong>Important:</strong> Le token en clair n'est visible qu'une seule fois après création. Copiez-le et conservez-le en lieu sûr.</p>
            <p><strong>Utilisation:</strong> Ajoutez l'en-tête <code>Authorization: Bearer VOTRE_TOKEN</code> à vos requêtes API.</p>
        </div>
        
        <div class="table-container">
            <table class="admin-table" id="tokens-table">
                <thead>
                    <tr>
                        <th>ID</th>
                        <th>Nom</th>
                        <th>Préfixe</th>
                        <th>Créé le</th>
                        <th>Expire le</th>
                        <th>Dernier usage</th>
                        <th>Statut</th>
                        <th>Actions</th>
                    </tr>
                </thead>
                <tbody id="tokens-tbody">
                    <tr>
                        <td colspan="8" class="loading">Chargement des tokens...</td>
                    </tr>
                </tbody>
            </table>
        </div>
    </div>
</div>

<!-- Modal: Create/Edit User -->
<div id="modal-user" class="dns-modal">
    <div class="dns-modal-content modal-medium">
        <div class="dns-modal-header">
            <h3 id="modal-user-title">Créer un utilisateur</h3>
            <button class="dns-modal-close" onclick="closeUserModal()">&times;</button>
        </div>
        <div class="dns-modal-body">
            <form id="form-user">
                <input type="hidden" id="user-id" value="">
                
                <div class="form-group">
                    <label for="user-username">Nom d'utilisateur *</label>
                    <input type="text" id="user-username" name="username" required>
                </div>
                
                <div class="form-group">
                    <label for="user-email">Email *</label>
                    <input type="email" id="user-email" name="email" required>
                </div>
                
                <div class="form-group" id="auth-method-group" style="display: none;">
                    <label for="user-auth-method">Méthode d'authentification</label>
                    <select id="user-auth-method" name="auth_method" disabled>
                        <option value="database">Base de données</option>
                        <option value="ad">Active Directory</option>
                        <option value="ldap">LDAP</option>
                    </select>
                    <small class="form-hint">Les utilisateurs créés via l'admin utilisent l'authentification par base de données. Les utilisateurs AD/LDAP sont créés automatiquement lors de leur première connexion.</small>
                </div>
                
                <div class="form-group" id="password-group">
                    <label for="user-password">Mot de passe <span id="password-required-indicator">*</span></label>
                    <input type="password" id="user-password" name="password">
                    <small class="form-hint" id="password-hint">Laissez vide pour ne pas modifier le mot de passe</small>
                </div>
                
                <div class="form-group">
                    <label for="user-is-active">Statut</label>
                    <select id="user-is-active" name="is_active">
                        <option value="1">Actif</option>
                        <option value="0">Inactif</option>
                    </select>
                </div>
                
                <div class="form-group">
                    <label>Rôles</label>
                    <div id="user-roles-checkboxes">
                        <!-- Will be populated dynamically -->
                    </div>
                </div>
            </form>
        </div>
        <div class="dns-modal-footer">
            <div class="modal-action-bar">
                <button type="button" class="btn-danger modal-action-button" id="btn-delete-user-modal" onclick="deactivateUserFromModal()" style="display: none;">Supprimer</button>
                <button type="submit" class="btn-success modal-action-button" id="btn-save-user" form="form-user">Enregistrer</button>
                <button type="button" class="btn-cancel modal-action-button" onclick="closeUserModal()">Annuler</button>
            </div>
        </div>
    </div>
</div>

<!-- Modal: Create Mapping -->
<div id="modal-mapping" class="dns-modal">
    <div class="dns-modal-content modal-medium">
        <div class="dns-modal-header">
            <h3>Créer un mapping AD/LDAP</h3>
            <button class="dns-modal-close" onclick="closeMappingModal()">&times;</button>
        </div>
        <div class="dns-modal-body">
            <form id="form-mapping">
                <div class="form-group">
                    <label for="mapping-source">Source *</label>
                    <select id="mapping-source" name="source" required>
                        <option value="ad">Active Directory</option>
                        <option value="ldap">LDAP</option>
                    </select>
                </div>
                
                <div class="form-group">
                    <label for="mapping-dn-or-group">DN/Groupe *</label>
                    <input type="text" id="mapping-dn-or-group" name="dn_or_group" required 
                           placeholder="Ex: CN=DNSAdmins,OU=Groups,DC=example,DC=com">
                    <small class="form-hint">
                        <strong>AD:</strong> DN complet du groupe<br>
                        <strong>LDAP:</strong> DN ou chemin OU
                    </small>
                </div>
                
                <div class="form-group">
                    <label for="mapping-role">Rôle *</label>
                    <select id="mapping-role" name="role_id" required>
                        <!-- Will be populated dynamically -->
                    </select>
                </div>
                
                <div class="form-group">
                    <label for="mapping-notes">Notes</label>
                    <textarea id="mapping-notes" name="notes" rows="3" 
                              placeholder="Description ou notes sur ce mapping"></textarea>
                </div>
            </form>
        </div>
        <div class="dns-modal-footer">
            <div class="modal-action-bar">
                <button type="submit" class="btn-success modal-action-button" form="form-mapping">Créer</button>
                <button type="button" class="btn-cancel modal-action-button" onclick="closeMappingModal()">Annuler</button>
            </div>
        </div>
    </div>
</div>

<!-- Modal: Create Token -->
<div id="modal-token" class="dns-modal">
    <div class="dns-modal-content modal-medium">
        <div class="dns-modal-header">
            <h3>Créer un token API</h3>
            <button class="dns-modal-close" onclick="closeTokenModal()">&times;</button>
        </div>
        <div class="dns-modal-body">
            <form id="form-token">
                <div class="form-group">
                    <label for="token-name">Nom du token *</label>
                    <input type="text" id="token-name" name="token_name" required 
                           placeholder="Ex: Script de backup, CI/CD, Application mobile">
                    <small class="form-hint">Donnez un nom descriptif pour identifier l'usage de ce token</small>
                </div>
                
                <div class="form-group">
                    <label for="token-expires-in-days">Expiration (jours)</label>
                    <input type="number" id="token-expires-in-days" name="expires_in_days" min="1" max="3650" 
                           placeholder="Optionnel - laissez vide pour pas d'expiration">
                    <small class="form-hint">Nombre de jours avant expiration. Laissez vide pour un token sans expiration.</small>
                </div>
            </form>
        </div>
        <div class="dns-modal-footer">
            <div class="modal-action-bar">
                <button type="submit" class="btn-success modal-action-button" form="form-token">Créer</button>
                <button type="button" class="btn-cancel modal-action-button" onclick="closeTokenModal()">Annuler</button>
            </div>
        </div>
    </div>
</div>

<!-- Modal: Display Token Once -->
<div id="modal-token-display" class="dns-modal">
    <div class="dns-modal-content modal-medium">
        <div class="dns-modal-header">
            <h3>⚠️ Token créé - Copiez-le maintenant</h3>
            <button class="dns-modal-close" onclick="closeTokenDisplayModal()">&times;</button>
        </div>
        <div class="dns-modal-body">
            <div class="warning-box">
                <p><strong>IMPORTANT:</strong> Ce token ne sera plus jamais affiché. Copiez-le maintenant et conservez-le en lieu sûr.</p>
            </div>
            
            <div class="form-group">
                <label for="token-display-value">Votre token API:</label>
                <div class="token-display-container">
                    <input type="text" id="token-display-value" readonly class="token-display-input">
                    <button type="button" class="btn btn-primary" id="btn-copy-token" onclick="copyTokenToClipboard()">
                        📋 Copier
                    </button>
                </div>
            </div>
            
            <div class="info-box">
                <p><strong>Utilisation:</strong></p>
                <p>Ajoutez cet en-tête à vos requêtes API:</p>
                <pre><code>Authorization: Bearer VOTRE_TOKEN</code></pre>
            </div>
        </div>
        <div class="dns-modal-footer">
            <div class="modal-action-bar">
                <button type="button" class="btn-success modal-action-button" onclick="closeTokenDisplayModal()">J'ai copié le token</button>
            </div>
        </div>
    </div>
</div>

<style>
.admin-container {
    padding: 20px;
    max-width: 1400px;
    margin: 0 auto;
}

.admin-container h1 {
    margin-bottom: 20px;
    color: #2c3e50;
}

.admin-tabs {
    display: flex;
    border-bottom: 2px solid #e0e0e0;
    margin-bottom: 20px;
}

.admin-tab-button {
    padding: 12px 24px;
    background: none;
    border: none;
    border-bottom: 3px solid transparent;
    cursor: pointer;
    font-size: 16px;
    color: #666;
    transition: all 0.3s;
}

.admin-tab-button:hover {
    color: #2c3e50;
    background-color: #f5f5f5;
}

.admin-tab-button.active {
    color: #2c3e50;
    border-bottom-color: #3498db;
    font-weight: bold;
}

.admin-tab-content {
    display: none;
}

.admin-tab-content.active {
    display: block;
}

.tab-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 20px;
}

.tab-header h2 {
    margin: 0;
    color: #2c3e50;
}

.filters-section {
    display: flex;
    gap: 10px;
    margin-bottom: 20px;
    flex-wrap: wrap;
}

.filter-input, .filter-select {
    padding: 8px 12px;
    border: 1px solid #ddd;
    border-radius: 4px;
    font-size: 14px;
}

.filter-input {
    flex: 1;
    min-width: 200px;
}

.filter-select {
    min-width: 150px;
}

.btn {
    padding: 10px 20px;
    border: none;
    border-radius: 4px;
    cursor: pointer;
    font-size: 14px;
    transition: all 0.3s;
}

.btn-primary {
    background-color: #3498db;
    color: white;
}

.btn-primary:hover {
    background-color: #2980b9;
}

.btn-secondary {
    background-color: #95a5a6;
    color: white;
}

.btn-secondary:hover {
    background-color: #7f8c8d;
}

.btn-danger {
    background-color: #e74c3c;
    color: white;
    padding: 6px 12px;
    font-size: 12px;
}

.btn-danger:hover {
    background-color: #c0392b;
}

.btn-edit {
    background-color: #f39c12;
    color: white;
    padding: 6px 12px;
    font-size: 12px;
    margin-right: 5px;
}

.btn-edit:hover {
    background-color: #e67e22;
}

.btn .icon {
    font-size: 18px;
    font-weight: bold;
}

.table-container {
    overflow-x: auto;
    background: white;
    border-radius: 4px;
    box-shadow: 0 2px 4px rgba(0,0,0,0.1);
}

.admin-table {
    width: 100%;
    border-collapse: collapse;
}

.admin-table th {
    background-color: #34495e;
    color: white;
    padding: 12px;
    text-align: left;
    font-weight: bold;
}

.admin-table td {
    padding: 12px;
    border-bottom: 1px solid #ecf0f1;
}

.admin-table tbody tr:hover {
    background-color: #f8f9fa;
}

.admin-table .loading {
    text-align: center;
    color: #7f8c8d;
    font-style: italic;
}

.badge {
    display: inline-block;
    padding: 4px 8px;
    border-radius: 3px;
    font-size: 12px;
    font-weight: bold;
}

.badge-admin {
    background-color: #e74c3c;
    color: white;
}

.badge-user {
    background-color: #3498db;
    color: white;
}

.badge-active {
    background-color: #27ae60;
    color: white;
}

.badge-inactive {
    background-color: #95a5a6;
    color: white;
}

.badge-ad {
    background-color: #9b59b6;
    color: white;
}

.badge-ldap {
    background-color: #e67e22;
    color: white;
}

.badge-database {
    background-color: #16a085;
    color: white;
}

.info-box {
    background-color: #e8f4f8;
    border-left: 4px solid #3498db;
    padding: 15px;
    margin-bottom: 20px;
    border-radius: 4px;
}

.info-box p {
    margin: 5px 0;
}

.info-box code {
    background-color: #34495e;
    color: #ecf0f1;
    padding: 2px 6px;
    border-radius: 3px;
    font-family: monospace;
    font-size: 12px;
}

#user-roles-checkboxes {
    display: flex;
    flex-direction: column;
    gap: 8px;
}

#user-roles-checkboxes label {
    display: flex;
    align-items: center;
    font-weight: normal;
    cursor: pointer;
}

#user-roles-checkboxes input[type="checkbox"] {
    width: auto;
    margin-right: 8px;
}

/* Token-specific styles */
.warning-box {
    background-color: #fff3cd;
    border-left: 4px solid #ffc107;
    padding: 15px;
    margin-bottom: 20px;
    border-radius: 4px;
}

.warning-box p {
    margin: 5px 0;
    color: #856404;
}

.token-display-container {
    display: flex;
    gap: 10px;
    align-items: center;
}

.token-display-input {
    flex: 1;
    font-family: monospace;
    font-size: 14px;
    padding: 10px;
    border: 2px solid #3498db;
    border-radius: 4px;
    background-color: #f8f9fa;
}

.badge-revoked {
    background-color: #e74c3c;
    color: white;
}

.badge-expired {
    background-color: #e67e22;
    color: white;
}

.badge-token-active {
    background-color: #27ae60;
    color: white;
}
</style>

<script src="<?php echo BASE_URL; ?>assets/js/admin.js"></script>
<script>
    // Expose current user ID for client-side validation
    // Note: This page is only accessible to logged-in admin users (checked at top of file)
    // so $auth->getCurrentUser() will always return a valid user
    <?php $currentUser = $auth->getCurrentUser(); ?>
    window.CURRENT_USER_ID = <?php echo $currentUser ? (int)$currentUser['id'] : 0; ?>;
</script>

<?php
require_once __DIR__ . '/includes/footer.php';
?>
