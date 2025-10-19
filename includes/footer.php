<?php
// Footer : ferme la zone scrollable ouverte dans header, et affiche le footer fixe.
?>
    </main>
  </div> <!-- .page-body -->

  <footer class="footer" role="contentinfo">
    <div class="footer-container" style="max-width:var(--content-max-width); width:100%; margin:0 auto; text-align:center;">
      &copy; <?php echo date('Y'); ?> <?php echo SITE_NAME; ?>. Tous droits réservés.
    </div>
  </footer>

  <!-- Include the underline script (deferred by DOMContentLoaded handler above) -->
  <script src="<?php echo BASE_URL; ?>assets/js/header-underline.js"></script>
</body>
</html>
