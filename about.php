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
    <h1>À propos de <?php echo SITE_NAME; ?></h1>
    <p>Cette application web a été développée en PHP sans framework, offrant une solution légère et performante pour la gestion de services avec authentification multi-sources.</p>
</div>

<div class="content-section">
    <h2>Caractéristiques techniques</h2>
    <div class="card-grid">
        <div class="card">
            <h3>Technologies</h3>
            <p>PHP, MariaDB, HTML5, CSS3 - Développement sans framework pour plus de flexibilité.</p>
        </div>
        <div class="card">
            <h3>Authentification</h3>
            <p>Support multi-sources : Base de données, Active Directory et OpenLDAP.</p>
        </div>
        <div class="card">
            <h3>Sécurité</h3>
            <p>Hashage des mots de passe, sessions sécurisées, protection contre les injections SQL.</p>
        </div>
        <div class="card">
            <h3>Interface</h3>
            <p>Design moderne et responsive avec un bandeau fixe pour une navigation optimale.</p>
        </div>
    </div>
</div>

<div class="content-section">
    <h2>Architecture</h2>
    <p>L'application est structurée de manière modulaire :</p>
    <ul style="line-height: 2; margin-left: 20px;">
        <li><strong>config.php</strong> : Configuration centralisée de l'application</li>
        <li><strong>includes/</strong> : Classes et composants réutilisables (DB, Auth, Header, Footer)</li>
        <li><strong>assets/</strong> : Ressources statiques (CSS, images)</li>
        <li><strong>.htaccess</strong> : Gestion des URL propres et de la sécurité</li>
    </ul>
</div>

<?php
require_once 'includes/footer.php';
?>
