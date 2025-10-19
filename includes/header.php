<?php
// Header adapté — structure en DIVs similaire à ton bandeau.php
require_once __DIR__ . '/../config.php';
require_once __DIR__ . '/auth.php';

$auth = new Auth();
$user = $auth->getCurrentUser();
?>
<!DOCTYPE html>
<html lang="fr">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width,initial-scale=1">
  <title><?php echo SITE_NAME; ?></title>
  <link rel="stylesheet" href="<?php echo BASE_URL; ?>assets/css/style.css">
</head>
<body>
  <header class="entete_fixee" role="banner">
    <div class="bandeau_bothrows">
      <div class="bandeau_content"> <!-- conteneur centré qui définit la largeur du site -->
        <!-- logo: positionné à l'extrême gauche via CSS (voir .bandeau_logo) -->
        <div class="bandeau_logo" aria-hidden="false">
          <a href="<?php echo BASE_URL; ?>" class="logo-link" aria-label="<?php echo SITE_NAME; ?>">
            <img src="<?php echo BASE_URL; ?>assets/images/logo_cnd_transparent.png" alt="<?php echo SITE_NAME; ?>" class="bandeau_logo_img" onerror="this.style.display='none';">
          </a>
        </div>

        <!-- centre : titre + onglets (title en haut, onglets en dessous) -->
        <div class="bandeau_center">
          <div class="bandeau_title_wrap">
            <h1 class="bandeau_title">Gestion du DNS</h1>
          </div>

          <div class="bandeau_ongletswrap">
            <div class="bandeau_onglets_row">
              <ul class="bandeau_onglets">
                <li><a href="<?php echo BASE_URL; ?>index.php" class="bandeau_onglet<?php echo (basename($_SERVER['PHP_SELF'])==='index.php') ? ' active' : ''; ?>">Accueil</a></li>
                <li><a href="<?php echo BASE_URL; ?>services.php" class="bandeau_onglet<?php echo (basename($_SERVER['PHP_SELF'])==='services.php') ? ' active' : ''; ?>">Services</a></li>
                <li><a href="<?php echo BASE_URL; ?>about.php" class="bandeau_onglet<?php echo (basename($_SERVER['PHP_SELF'])==='about.php') ? ' active' : ''; ?>">À propos</a></li>
              </ul>
            </div>
          </div>
        </div>

        <!-- zone droite : boutons / utilisateur (positionnée à l'extrême droite via CSS) -->
        <div class="bandeau_droite" aria-hidden="false">
          <?php if ($auth->isLoggedIn() && $user): ?>
            <span class="bandeau_user"><?php echo htmlspecialchars($user['username']); ?></span>
            <a href="<?php echo BASE_URL; ?>logout.php" class="btn btn-logout">Déconnexion</a>
          <?php else: ?>
            <a href="<?php echo BASE_URL; ?>login.php" class="btn btn-login">Se connecter</a>
          <?php endif; ?>
        </div>
      </div> <!-- .bandeau_content -->
    </div> <!-- .bandeau_bothrows -->
  </header>

  <main class="main-content">
