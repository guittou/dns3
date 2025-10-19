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
                    <img src="<?php echo BASE_URL; ?>assets/images/logo.png" alt="<?php echo SITE_NAME; ?>" onerror="this.style.display='none'; this.nextElementSibling.style.display='inline';">
                    <span class="logo-text"><?php echo SITE_NAME; ?></span>
                </a>
            </div>
            
            <nav class="header-nav">
                <ul class="nav-tabs">
                    <li><a href="<?php echo BASE_URL; ?>" class="<?php echo ($_SERVER['REQUEST_URI'] == BASE_URL || $_SERVER['REQUEST_URI'] == BASE_URL . 'index.php') ? 'active' : ''; ?>">Accueil</a></li>
                    <li><a href="<?php echo BASE_URL; ?>dashboard.php" class="<?php echo (strpos($_SERVER['REQUEST_URI'], 'dashboard') !== false) ? 'active' : ''; ?>">Tableau de bord</a></li>
                    <li><a href="<?php echo BASE_URL; ?>services.php" class="<?php echo (strpos($_SERVER['REQUEST_URI'], 'services') !== false) ? 'active' : ''; ?>">Services</a></li>
                    <li><a href="<?php echo BASE_URL; ?>about.php" class="<?php echo (strpos($_SERVER['REQUEST_URI'], 'about') !== false) ? 'active' : ''; ?>">À propos</a></li>
                </ul>
            </nav>
            
            <div class="header-right">
                <?php if ($user): ?>
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
