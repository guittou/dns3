/**
 * Modal Utilities
 * Helper functions for modal centering and viewport management
 */

(function() {
    'use strict';

    /**
     * Ensure modal is properly centered and content fits within viewport
     * Forces reflow and adjusts max-height to prevent visual glitches
     * @param {HTMLElement} modalEl - The modal overlay element
     */
    window.ensureModalCentered = function(modalEl) {
        if (!modalEl) return;
        
        const content = modalEl.querySelector('.dns-modal-content, .zone-modal-content');
        if (!content) return;
        
        // Force reflow to ensure layout is stable
        void modalEl.offsetHeight;
        
        // Set max-height based on current viewport to avoid overflow
        const maxHeight = window.innerHeight - 80;
        content.style.maxHeight = maxHeight + 'px';
    };

    /**
     * Recompute centering for all visible modals on resize/orientation change
     */
    function recomputeVisibleModals() {
        // Find all visible modal overlays
        const visibleModals = document.querySelectorAll('.dns-modal.open, .zone-modal.open');
        
        visibleModals.forEach(function(modal) {
            if (modal.style.display !== 'none') {
                window.ensureModalCentered(modal);
            }
        });
    }

    // Listen for viewport changes
    window.addEventListener('resize', recomputeVisibleModals);
    window.addEventListener('orientationchange', recomputeVisibleModals);

})();
