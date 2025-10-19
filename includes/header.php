<?php
// Header : logo à l'extrême gauche du viewport, bouton à l'extrême droite,
// titre + onglets centrés. Ouvre la zone scrollable (.page-body).
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
  <header class="entete_fixee" role="banner" aria-label="Bandeau principal">
    <div class="bandeau_full" role="presentation">
      <!-- logo collé à l'extrême gauche du viewport (avec offset contrôlable via --edge-offset) -->
      <div class="bandeau_logo" aria-hidden="false">
        <a href="<?php echo BASE_URL; ?>" class="logo-link" aria-label="<?php echo SITE_NAME; ?>">
          <img src="<?php echo BASE_URL; ?>assets/images/logo_cnd_transparent.png" alt="<?php echo SITE_NAME; ?>" class="bandeau_logo_img" onerror="this.style.display='none';">
        </a>
      </div>

      <!-- contenu centré : titre + onglets -->
      <div class="bandeau_content" role="region" aria-label="Bandeau centre">
        <div class="bandeau_center">
          <div class="bandeau_title_wrap">
            <h1 class="bandeau_title">Gestion du DNS</h1>
          </div>

          <div class="bandeau_ongletswrap" role="navigation" aria-label="Navigation principale">
            <div class="bandeau_onglets_row">
              <ul class="bandeau_onglets">
                <li><a href="<?php echo BASE_URL; ?>index.php" class="bandeau_onglet<?php echo (basename($_SERVER['PHP_SELF'])==='index.php') ? ' active' : ''; ?>">Accueil</a></li>
                <li><a href="<?php echo BASE_URL; ?>services.php" class="bandeau_onglet<?php echo (basename($_SERVER['PHP_SELF'])==='services.php') ? ' active' : ''; ?>">Services</a></li>
                <li><a href="<?php echo BASE_URL; ?>about.php" class="bandeau_onglet<?php echo (basename($_SERVER['PHP_SELF'])==='about.php') ? ' active' : ''; ?>">À propos</a></li>
              </ul>
            </div>
          </div>
        </div>
      </div>

      <!-- bouton / utilisateur collé à l'extrême droite du viewport -->
      <div class="bandeau_droite" aria-hidden="false">
        <?php if ($auth->isLoggedIn() && $user): ?>
          <span class="bandeau_user"><?php echo htmlspecialchars($user['username']); ?></span>
          <a href="<?php echo BASE_URL; ?>logout.php" class="btn btn-logout">Déconnexion</a>
        <?php else: ?>
          <a href="<?php echo BASE_URL; ?>login.php" class="btn btn-login">Se connecter</a>
        <?php endif; ?>
      </div>

      <!-- ligne de séparation exacte, positionnée en bas du header et limitée à la largeur du contenu -->
      <div class="bandeau_separator" aria-hidden="true"></div>
    </div><!-- .bandeau_full -->
  </header>

  <!-- zone scrollable entre header et footer -->
  <div class="page-body" role="main">
    <main class="main-content">
