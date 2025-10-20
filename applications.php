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

<div class="content-section">
    <h1>Applications</h1>
    <p>Cette page permet la gestion des applications et de leurs configurations.</p>
</div>

<div class="content-section">
    <h2>Fonctionnalités disponibles</h2>
    <div class="card-grid">
        <div class="card">
            <h3>Gestion des applications</h3>
            <p>Consultez et gérez vos applications via l'interface ou l'API.</p>
            <p><a href="<?php echo BASE_URL; ?>api/app_api.php">Accéder à l'API Application</a></p>
        </div>
        <div class="card">
            <h3>À venir</h3>
            <p>Interface de gestion complète des applications avec configuration avancée.</p>
        </div>
    </div>
</div>

<?php
require_once __DIR__ . '/includes/footer.php';
?>
