<?php
// Footer : ferme la zone scrollable ouverte dans header, et affiche le footer fixe.
// Ajout : separator en haut du footer identique à celui du header.
?>
    </main>
  </div> <!-- .page-body -->

  <footer class="footer" role="contentinfo">
    <div class="footer_separator" aria-hidden="true"></div>

    <div class="footer-container">
      <?php
        $version = htmlspecialchars(defined('APP_VERSION') ? APP_VERSION : '1.0.0', ENT_QUOTES, 'UTF-8');
        $label = htmlspecialchars(defined('CONTACT_LABEL') ? CONTACT_LABEL : 'Mon/Organisme/a/moi', ENT_QUOTES, 'UTF-8');
        $email = htmlspecialchars(defined('CONTACT_EMAIL') ? CONTACT_EMAIL : 'moi@mondomaine.fr', ENT_QUOTES, 'UTF-8');
        echo "<strong>Version:</strong> {$version} - {$label} &nbsp;&nbsp;&nbsp;---&nbsp;&nbsp;&nbsp; <strong>Contacts:</strong> <a href=\"mailto:{$email}\">{$email}</a>";
      ?>
    </div>
  </footer>

  <!-- Include the underline script (deferred by DOMContentLoaded handler above) -->
  <script src="<?php echo $basePath; ?>assets/js/header-underline.js"></script>
</body>
</html>
