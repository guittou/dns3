// Dynamic underline for the header tabs: positions the .bandeau_active_underline
document.addEventListener('DOMContentLoaded', function () {
  const headerFull = document.querySelector('.bandeau_full');
  const underline = document.querySelector('.bandeau_active_underline');
  const tabs = Array.from(document.querySelectorAll('.bandeau_onglet'));

  if (!headerFull || !underline || tabs.length === 0) return;

  function updateUnderline() {
    const active = document.querySelector('.bandeau_onglet.active');
    if (!active) {
      underline.style.width = '0';
      return;
    }

    const headerRect = headerFull.getBoundingClientRect();
    const tabRect = active.getBoundingClientRect();

    // Compute left relative to headerFull
    const left = tabRect.left - headerRect.left;
    const width = tabRect.width;

    // Apply. Use integers to avoid subpixel anti-alias issues in some browsers
    underline.style.left = Math.round(left) + 'px';
    underline.style.width = Math.round(width) + 'px';
    underline.style.display = 'block';
  }

  // Update on load and resize
  window.addEventListener('resize', updateUnderline);
  window.addEventListener('orientationchange', updateUnderline);
  updateUnderline();

  // If tabs are navigated client-side, update on click
  tabs.forEach(tab => {
    tab.addEventListener('click', function (e) {
      // If the navigation is a full page load, the script will run again on the new page.
      // For SPA-like behavior, manage active class and update the underline.
      tabs.forEach(t => t.classList.remove('active'));
      this.classList.add('active');
      // Slight delay to allow layout to settle if needed
      setTimeout(updateUnderline, 20);
    });
  });

  // Observe potential changes in the header that affect layout
  const observer = new MutationObserver(function () {
    setTimeout(updateUnderline, 10);
  });
  observer.observe(headerFull, { attributes: true, childList: true, subtree: true });
});
