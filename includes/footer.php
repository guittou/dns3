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

  <!-- Publish popup -->
  <div id="publish-popup" role="dialog" aria-labelledby="publish-popup-title" aria-modal="true">
    <div class="publish-popup-content">
      <div class="publish-popup-header">
        <h3 id="publish-popup-title">Publication des zones</h3>
        <button class="publish-popup-close" onclick="closePublishPopup()" aria-label="Fermer">&times;</button>
      </div>
      <div class="publish-popup-body">
        <!-- Loading state -->
        <div class="publish-loading" id="publish-loading">
          <div class="publish-spinner"></div>
          <p>Traitement en cours…</p>
        </div>
        <!-- Results display -->
        <div class="publish-results" id="publish-results">
          <div class="publish-summary" id="publish-summary">
            <span class="publish-summary-icon" id="publish-summary-icon"></span>
            <div class="publish-summary-text" id="publish-summary-text"></div>
          </div>
          <div class="publish-details" id="publish-details">
            <h4>Détails :</h4>
            <ul class="publish-zone-list" id="publish-zone-list"></ul>
          </div>
        </div>
      </div>
      <div class="publish-popup-footer" id="publish-popup-footer" style="display: none;">
        <button class="publish-close-btn" onclick="closePublishPopup()">Fermer</button>
      </div>
    </div>
  </div>

  <!-- Include the underline script (deferred by DOMContentLoaded handler above) -->
  <script src="<?php echo $basePath; ?>assets/js/header-underline.js"></script>
  
  <!-- Publish zones functionality -->
  <script>
    function showPublishPopup() {
      const popup = document.getElementById('publish-popup');
      const loading = document.getElementById('publish-loading');
      const results = document.getElementById('publish-results');
      const footer = document.getElementById('publish-popup-footer');
      
      // Reset popup state
      loading.style.display = 'block';
      results.classList.remove('show');
      footer.style.display = 'none';
      
      // Show popup
      popup.classList.add('show');
    }
    
    function closePublishPopup() {
      const popup = document.getElementById('publish-popup');
      const button = document.querySelector('.btn-publish');
      
      popup.classList.remove('show');
      
      // Re-enable button
      if (button) {
        button.disabled = false;
        button.textContent = 'Publier';
        button.style.cursor = 'pointer';
      }
    }
    
    function showPublishResults(result, response) {
      const loading = document.getElementById('publish-loading');
      const results = document.getElementById('publish-results');
      const footer = document.getElementById('publish-popup-footer');
      const summary = document.getElementById('publish-summary');
      const summaryIcon = document.getElementById('publish-summary-icon');
      const summaryText = document.getElementById('publish-summary-text');
      const zoneList = document.getElementById('publish-zone-list');
      
      // Hide loading, show results
      loading.style.display = 'none';
      results.classList.add('show');
      footer.style.display = 'flex';
      
      // Determine status
      let isSuccess = result.success;
      let isError = !response.ok;
      let isPartial = response.ok && !isSuccess;
      
      // Set summary class and content
      summary.className = 'publish-summary';
      if (isError) {
        summary.classList.add('error');
        summaryIcon.textContent = '✗';
        summaryText.innerHTML = `<strong>Erreur lors de la publication</strong><br>${result.error || 'Erreur inconnue'}`;
      } else if (isSuccess) {
        summary.classList.add('success');
        summaryIcon.textContent = '✓';
        summaryText.innerHTML = `<strong>Publication réussie !</strong><br>${result.success_count} zone(s) publiée(s) avec succès.`;
      } else {
        summary.classList.add('partial');
        summaryIcon.textContent = '⚠';
        summaryText.innerHTML = `<strong>Publication partielle</strong><br>${result.success_count} zone(s) publiée(s), ${result.failure_count} zone(s) en échec.`;
      }
      
      // Build zone details list
      zoneList.innerHTML = '';
      if (result.zones && result.zones.length > 0) {
        result.zones.forEach(zone => {
          const li = document.createElement('li');
          li.className = 'publish-zone-item';
          li.classList.add(zone.status === 'success' ? 'success' : 'failed');
          
          const icon = document.createElement('span');
          icon.className = 'publish-zone-icon';
          icon.classList.add(zone.status === 'success' ? 'success' : 'failed');
          icon.textContent = zone.status === 'success' ? '✓' : '✗';
          
          const info = document.createElement('div');
          info.className = 'publish-zone-info';
          
          const name = document.createElement('div');
          name.className = 'publish-zone-name';
          name.textContent = zone.name;
          info.appendChild(name);
          
          if (zone.file_path && zone.status === 'success') {
            const path = document.createElement('div');
            path.className = 'publish-zone-path';
            path.textContent = `Fichier : ${zone.file_path}`;
            info.appendChild(path);
          }
          
          if (zone.error && zone.status === 'failed') {
            const error = document.createElement('div');
            error.className = 'publish-zone-error';
            error.textContent = zone.error;
            info.appendChild(error);
          }
          
          li.appendChild(icon);
          li.appendChild(info);
          zoneList.appendChild(li);
        });
      } else {
        const li = document.createElement('li');
        li.className = 'publish-zone-item';
        li.style.textAlign = 'center';
        li.style.color = '#999';
        li.textContent = 'Aucune zone à afficher';
        zoneList.appendChild(li);
      }
    }
    
    async function triggerPublish() {
      const button = document.querySelector('.btn-publish');
      
      // Disable button to prevent double-clicks
      button.disabled = true;
      button.textContent = 'Publication en cours...';
      button.style.cursor = 'wait';
      
      // Show popup with loading state
      showPublishPopup();
      
      try {
        const response = await fetch('<?php echo $basePath; ?>api/publish.php', {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json'
          },
          credentials: 'same-origin'
        });
        
        const result = await response.json();
        
        // Show results in popup
        showPublishResults(result, response);
        
        console.log('Publish result:', result);
        
      } catch (error) {
        // Show error in popup
        showPublishResults({
          success: false,
          error: `Erreur réseau : ${error.message}`,
          zones: []
        }, { ok: false });
        
        console.error('Publish error:', error);
      }
    }
    
    // Close popup on escape key
    document.addEventListener('keydown', function(event) {
      if (event.key === 'Escape') {
        const popup = document.getElementById('publish-popup');
        if (popup && popup.classList.contains('show')) {
          closePublishPopup();
        }
      }
    });
    
    // Close popup on overlay click
    document.addEventListener('click', function(event) {
      const popup = document.getElementById('publish-popup');
      if (event.target === popup) {
        closePublishPopup();
      }
    });
  </script>
</body>
</html>
