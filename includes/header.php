<?php
// Header : logo à l'extrême gauche, bouton à droite, titre centré en haut du bandeau,
// onglets en bas et underline positionnée dynamiquement par JS pour coïncider avec la separator
require_once __DIR__ . '/../config.php';
require_once __DIR__ . '/auth.php';

$auth = new Auth();
$user = $auth->getCurrentUser();

// Robust basePath calculation with fallback
$basePath = defined('BASE_URL') ? rtrim(BASE_URL, '/') : rtrim(dirname($_SERVER['SCRIPT_NAME']), '/');
if ($basePath === '') {
    $basePath = '/';
} else {
    $basePath .= '/';
}
?>
<!DOCTYPE html>
<html lang="fr">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width,initial-scale=1">
  <title><?php echo SITE_NAME; ?></title>
  <link rel="stylesheet" href="<?php echo $basePath; ?>assets/css/style.css">
  <link rel="stylesheet" href="<?php echo $basePath; ?>assets/css/modal-utils.css">
  <script>
    // Expose BASE_URL for JavaScript to construct proper URLs
    window.BASE_URL = '<?php echo $basePath; ?>';
    window.API_BASE = window.BASE_URL + 'api/';
  </script>
  <script src="<?php echo $basePath; ?>assets/js/modal-utils.js" defer></script>
</head>
<body>
  <header class="entete_fixee" role="banner" aria-label="Bandeau principal">
    <div class="bandeau_full" role="presentation">
      <!-- LOGO: collé à l'extrême gauche du viewport (avec offset via CSS --edge-offset) -->
      <div class="bandeau_logo" aria-hidden="false">
        <a href="<?php echo $basePath; ?>" class="logo-link" aria-label="<?php echo SITE_NAME; ?>">
          <img src="<?php echo $basePath; ?>assets/images/logo_cnd_transparent.png" alt="<?php echo SITE_NAME; ?>" class="bandeau_logo_img" onerror="this.style.display='none';">
        </a>
      </div>

      <!-- CONTENU CENTRÉ : titre au sommet (top) de la zone du bandeau -->
      <div class="bandeau_content" role="region" aria-label="Bandeau centre">
        <div class="bandeau_center">
          <div class="bandeau_title_wrap">
            <h1 class="bandeau_title">Gestion du DNS</h1>
          </div>
        </div>
      </div>

      <!-- BOUTON / UTILISATEUR: collé à l'extrême droite du viewport -->
      <div class="bandeau_droite" aria-hidden="false">
        <?php if ($auth->isLoggedIn() && $user): ?>
          <span class="bandeau_user"><?php echo htmlspecialchars($user['username']); ?></span>
          <a href="<?php echo $basePath; ?>logout.php" class="btn btn-logout">Déconnexion</a>
        <?php else: ?>
          <a href="<?php echo $basePath; ?>login.php" class="btn btn-login">Se connecter</a>
        <?php endif; ?>
      </div>

      <!-- ONGLETS: positionnés en bas du bandeau (centrés par rapport à la largeur du contenu) -->
      <div class="bandeau_onglets_row" role="navigation" aria-label="Navigation principale">
        <ul class="bandeau_onglets">
          <?php if ($auth->isLoggedIn()): ?>
            <?php 
            // Determine tab visibility:
            // - DNS tab: visible if user is admin OR has zone ACL entries
            // - Zones tab: visible ONLY if user is admin
            $canSeeDnsTab = $auth->isAdmin() || $auth->hasZoneAcl();
            $canSeeZonesTab = $auth->isAdmin();
            ?>
            <?php if ($canSeeDnsTab): ?>
            <li><a href="<?php echo $basePath; ?>dns-management.php" class="bandeau_onglet<?php echo (basename($_SERVER['PHP_SELF'])==='dns-management.php') ? ' active' : ''; ?>">DNS</a></li>
            <?php endif; ?>
            <?php if ($canSeeZonesTab): ?>
            <li><a href="<?php echo $basePath; ?>zone-files.php" class="bandeau_onglet<?php echo (basename($_SERVER['PHP_SELF'])==='zone-files.php' || basename($_SERVER['PHP_SELF'])==='zone-file.php') ? ' active' : ''; ?>">Zones</a></li>
            <?php endif; ?>
            <?php if ($auth->isAdmin()): ?>
            <li><a href="<?php echo $basePath; ?>admin.php" class="bandeau_onglet<?php echo (basename($_SERVER['PHP_SELF'])==='admin.php') ? ' active' : ''; ?>">Administration</a></li>
            <?php endif; ?>
          <?php endif; ?>
        </ul>
      </div>

      <!-- SEPARATOR: ligne de séparation full-width (en bas du bandeau) -->
      <div class="bandeau_separator" aria-hidden="true"></div>

      <!-- UNDERLINE DYNAMIQUE : positionnée par JS pour coïncider parfaitement avec la separator -->
      <div class="bandeau_active_underline" aria-hidden="true"></div>
    </div><!-- .bandeau_full -->
  </header>

  <!-- zone scrollable entre header et footer -->
  <div class="page-body" role="main">
    <main class="main-content">
