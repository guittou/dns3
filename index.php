<?php
require_once 'config.php';
require_once 'includes/auth.php';

// Initialize auth
$auth = new Auth();

// Require authentication - redirect to login if not logged in
if (!$auth->isLoggedIn()) {
    header('Location: ' . BASE_URL . 'login.php');
    exit;
}

require_once 'includes/header.php';
?>

<div class="content-section">
    <h1>Bienvenue sur <?php echo SITE_NAME; ?></h1>
    <p>Cette application web PHP vous permet de gérer vos services avec une authentification sécurisée via base de données, Active Directory ou OpenLDAP.</p>
    
    <?php if ($user): ?>
        <div class="success-message">
            Bienvenue, <?php echo htmlspecialchars($user['username']); ?>! Vous êtes connecté.
        </div>
    <?php else: ?>
        <p>Veuillez vous <a href="<?php echo BASE_URL; ?>login.php">connecter</a> pour accéder à toutes les fonctionnalités.</p>
    <?php endif; ?>
</div>

<div class="content-section">
    <h2>Fonctionnalités principales</h2>
    <div class="card-grid">
        <div class="card">
            <h3>Authentification Multi-Source</h3>
            <p>Connectez-vous via base de données, Active Directory ou OpenLDAP selon vos préférences.</p>
        </div>
        <div class="card">
            <h3>Interface Moderne</h3>
            <p>Une interface utilisateur responsive et élégante pour une meilleure expérience.</p>
        </div>
        <div class="card">
            <h3>Navigation Intuitive</h3>
            <p>Un bandeau fixe avec onglets pour naviguer facilement entre les différentes sections.</p>
        </div>
        <div class="card">
            <h3>Sécurité Renforcée</h3>
            <p>Protection des sessions et des données avec les meilleures pratiques de sécurité.</p>
        </div>
    </div>
</div>

<?php
require_once 'includes/footer.php';
?>
