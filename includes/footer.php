<?php
// Footer : ferme la zone scrollable ouverte dans header, et affiche le footer fixe.
// Ajout : separator en haut du footer identique à celui du header.
?>
    </main>
  </div> <!-- .page-body -->

  <footer class="footer" role="contentinfo">
    <div class="footer_separator" aria-hidden="true"></div>

    <div class="footer_content">
      <!-- Center: text content (version, contact) -->
      <div class="footer_center">
        <?php
          $version = htmlspecialchars(defined('APP_VERSION') ? APP_VERSION : '1.0.0', ENT_QUOTES, 'UTF-8');
          $label = htmlspecialchars(defined('CONTACT_LABEL') ? CONTACT_LABEL : 'Mon/Organisme/a/moi', ENT_QUOTES, 'UTF-8');
          $email = htmlspecialchars(defined('CONTACT_EMAIL') ? CONTACT_EMAIL : 'moi@mondomaine.fr', ENT_QUOTES, 'UTF-8');
          echo "<strong>Version:</strong> {$version} - {$label} &nbsp;&nbsp;&nbsp;---&nbsp;&nbsp;&nbsp; <strong>Contacts:</strong> <a href=\"mailto:{$email}\">{$email}</a>";
        ?>
      </div>

      <!-- Right: Publier button (admin only) - aligned right like header -->
      <?php
        // Display "Publier" button only for admin users
        if (isset($auth) && $auth->isAdmin()):
      ?>
      <div class="footer_right" aria-hidden="false">
        <button class="btn-publish" onclick="triggerPublish()">Publier</button>
      </div>
      <?php endif; ?>
    </div>
  </footer>

  <!-- Include the underline script (deferred by DOMContentLoaded handler above) -->
  <script src="<?php echo $basePath; ?>assets/js/header-underline.js"></script>
  
  <!-- Publish zones functionality -->
  <script>
    async function triggerPublish() {
      const button = document.querySelector('.btn-publish');
      
      // Confirm action
      if (!confirm('Publier toutes les zones actives ? Cette opération va générer et écrire tous les fichiers de zones sur le disque.')) {
        return;
      }
      
      // Disable button and show loading state
      button.disabled = true;
      button.textContent = 'Publication en cours...';
      button.style.cursor = 'wait';
      
      try {
        const response = await fetch('<?php echo $basePath; ?>api/publish.php', {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json'
          },
          credentials: 'same-origin'
        });
        
        const result = await response.json();
        
        // Re-enable button
        button.disabled = false;
        button.textContent = 'Publier';
        button.style.cursor = 'pointer';
        
        if (!response.ok) {
          alert('Erreur lors de la publication: ' + (result.error || 'Erreur inconnue'));
          console.error('Publish error:', result);
          return;
        }
        
        // Show detailed results
        if (result.success) {
          let message = `✓ Publication réussie!\n\n`;
          message += `${result.success_count} zone(s) publiée(s) avec succès.\n`;
          
          if (result.zones && result.zones.length > 0) {
            message += '\nDétails:\n';
            result.zones.forEach(zone => {
              message += `- ${zone.name}: ${zone.status === 'success' ? '✓ OK' : '✗ Échec'}\n`;
              if (zone.file_path) {
                message += `  Fichier: ${zone.file_path}\n`;
              }
            });
          }
          
          alert(message);
        } else {
          let message = `⚠ Publication partielle\n\n`;
          message += `${result.success_count} zone(s) publiée(s)\n`;
          message += `${result.failure_count} zone(s) en échec\n\n`;
          
          if (result.zones && result.zones.length > 0) {
            message += 'Détails:\n';
            result.zones.forEach(zone => {
              if (zone.status === 'failed') {
                message += `✗ ${zone.name}: ${zone.error || 'Erreur inconnue'}\n`;
              } else if (zone.status === 'success') {
                message += `✓ ${zone.name}: OK\n`;
              }
            });
          }
          
          alert(message);
        }
        
        console.log('Publish result:', result);
        
      } catch (error) {
        // Re-enable button
        button.disabled = false;
        button.textContent = 'Publier';
        button.style.cursor = 'pointer';
        
        alert('Erreur réseau lors de la publication: ' + error.message);
        console.error('Publish error:', error);
      }
    }
  </script>
</body>
</html>
