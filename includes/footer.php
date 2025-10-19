<?php
// Footer : ferme la zone scrollable ouverte dans header, et affiche le footer fixe.
// Ajout : separator en haut du footer identique à celui du header.
?>
    </main>
  </div> <!-- .page-body -->

  <footer class="footer" role="contentinfo">
    <div class="footer_separator" aria-hidden="true"></div>

    <div class="footer-container">
      &copy; <?php echo date('Y'); ?> <?php echo SITE_NAME; ?>. Tous droits réservés.
    </div>
  </footer>

  <!-- Include the underline script (deferred by DOMContentLoaded handler above) -->
  <script src="<?php echo BASE_URL; ?>assets/js/header-underline.js"></script>
</body>
</html>
