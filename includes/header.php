<?php
// Header template with fixed banner

require_once __DIR__ . '/../config.php';
require_once __DIR__ . '/auth.php';

$auth = new Auth();
$user = $auth->getCurrentUser();
?>
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title><?php echo SITE_NAME; ?></title>
    <link rel="stylesheet" href="<?php echo BASE_URL; ?>assets/css/style.css">
</head>
<body>
    <header class="fixed-header">
        <div class="header-container">
            <div class="header-left">
                <a href="<?php echo BASE_URL; ?>" class="logo">
                    <!-- Logo transparent demandé -->
                    <img src="<?php echo BASE_URL; ?>assets/images/logo_cnd_transparent.png" alt="<?php echo SITE_NAME; ?>" class="logo-img" onerror="this.style.display='none'; this.nextElementSibling.style.display='inline';">
                    <span class="logo-text"><?php echo SITE_NAME; ?></span>
                </a>
            </div>
            
            <nav class="header-nav">
                <ul class="nav-tabs">
                    <li><a href="<?php echo BASE_URL; ?>" class="<?php echo basename($_SERVER['PHP_SELF']) === 'index.php' ? 'active' : ''; ?>">Accueil</a></li>
                    <li><a href="<?php echo BASE_URL; ?>services.php" class="<?php echo basename($_SERVER['PHP_SELF']) === 'services.php' ? 'active' : ''; ?>">Services</a></li>
                    <li><a href="<?php echo BASE_URL; ?>about.php" class="<?php echo basename($_SERVER['PHP_SELF']) === 'about.php' ? 'active' : ''; ?>">À propos</a></li>
                </ul>
            </nav>
            
            <div class="header-right">
                <?php if ($auth->isLoggedIn() && $user): ?>
                    <div class="user-menu">
                        <span class="username"><?php echo htmlspecialchars($user['username']); ?></span>
                        <a href="<?php echo BASE_URL; ?>logout.php" class="btn btn-logout">Déconnexion</a>
                    </div>
                <?php else: ?>
                    <a href="<?php echo BASE_URL; ?>login.php" class="btn btn-login">Se connecter</a>
                <?php endif; ?>
            </div>
        </div>
    </header>
    
    <main class="main-content">
