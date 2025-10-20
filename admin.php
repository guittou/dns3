<?php
// admin.php - administration console (users / roles / mappings)
require_once 'includes/header.php';

if (!$auth->isLoggedIn()) {
    header('Location: ' . BASE_URL . 'login.php');
    exit;
}
if (!$auth->isAdmin()) {
    echo '<div class="content-section"><div class="error-message">Accès réservé aux administrateurs.</div></div>';
    require_once 'includes/footer.php';
    exit;
}
?>

<div class="content-section">
  <h1>Administration</h1>
  <div class="admin-tabs">
    <button data-tab="users" class="admin-tab-button active">Utilisateurs</button>
    <button data-tab="roles" class="admin-tab-button">Rôles</button>
    <button data-tab="mappings" class="admin-tab-button">Mappings AD/LDAP</button>
    <!-- ACL removed as requested -->
  </div>

  <div id="admin-content">
    <section id="tab-users" class="admin-tab active">
      <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:8px;">
        <input id="admin-user-search" placeholder="Rechercher utilisateur..." />
        <button id="admin-create-user" class="btn">Créer un utilisateur</button>
      </div>
      <table class="admin-table">
        <thead><tr><th>ID</th><th>Username</th><th>Email</th><th>Roles</th><th>Active</th><th>Actions</th></tr></thead>
        <tbody id="admin-users-body"><tr><td colspan="6">Chargement...</td></tr></tbody>
      </table>
    </section>

    <section id="tab-roles" class="admin-tab" style="display:none;">
      <div id="admin-roles-list">Chargement des rôles...</div>
    </section>

    <section id="tab-mappings" class="admin-tab" style="display:none;">
      <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:8px;">
        <small>Mapper un groupe AD / OU LDAP à un rôle applicatif.</small>
        <button id="admin-create-mapping" class="btn">Créer mapping</button>
      </div>
      <table class="admin-table">
        <thead><tr><th>ID</th><th>Source</th><th>DN / Groupe</th><th>Role</th><th>Créé le</th><th>Actions</th></tr></thead>
        <tbody id="admin-mappings-body"><tr><td colspan="6">Chargement...</td></tr></tbody>
      </table>
    </section>

    <!-- ACL section removed -->
  </div>
</div>

<!-- Modals -->
<div id="admin-user-modal" class="dns-modal" style="display:none;">
  <div class="dns-modal-content">
    <div class="dns-modal-header"><h2 id="admin-user-modal-title">Créer un utilisateur</h2><button id="admin-user-modal-close" class="dns-modal-close">&times;</button></div>
    <div class="dns-modal-body">
      <form id="admin-user-form">
        <input type="hidden" name="id" id="admin-user-id" />
        <div class="form-group"><label>Nom d'utilisateur</label><input name="username" id="admin-username" required /></div>
        <div class="form-group"><label>Email</label><input name="email" id="admin-email" required /></div>
        <div class="form-group"><label>Mot de passe</label><input name="password" id="admin-password" type="password" /></div>
        <div class="form-group"><label>Rôles</label><select id="admin-roles-select" name="roles[]" multiple></select></div>
        <div style="text-align:right;"><button type="submit" class="btn">Enregistrer</button></div>
      </form>
    </div>
  </div>
</div>

<script src="<?php echo BASE_URL; ?>assets/js/admin.js"></script>
<?php require_once 'includes/footer.php'; ?>
