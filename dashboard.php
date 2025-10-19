<?php
require_once 'includes/header.php';

if (!$auth->isLoggedIn()) {
    header('Location: ' . BASE_URL . 'login.php');
    exit;
}
?>

<div class="content-section">
    <h1>Tableau de bord</h1>
    <p>Bienvenue sur votre tableau de bord, <?php echo htmlspecialchars($user['username']); ?>!</p>
    
    <div class="success-message">
        <strong>Email:</strong> <?php echo htmlspecialchars($user['email']); ?><br>
        <strong>ID Utilisateur:</strong> <?php echo htmlspecialchars($user['id']); ?>
    </div>
</div>

<div class="content-section">
    <h2>Vos informations</h2>
    <div class="card-grid">
        <div class="card">
            <h3>Profil</h3>
            <p>Gérez vos informations personnelles et vos préférences.</p>
        </div>
        <div class="card">
            <h3>Activité récente</h3>
            <p>Consultez vos activités et actions récentes sur la plateforme.</p>
        </div>
        <div class="card">
            <h3>Notifications</h3>
            <p>Aucune nouvelle notification pour le moment.</p>
        </div>
    </div>
</div>

<?php
require_once 'includes/footer.php';
?>
