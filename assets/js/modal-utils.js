/**
 * Modal Utilities
 * Helper functions for modal centering and viewport management
 */

(function() {
    'use strict';

    /**
     * Ensure modal is properly centered and sized within viewport
     * Forces reflow and sets max-height to prevent overflow
     * @param {HTMLElement} modalEl - The modal overlay element
     */
    function ensureModalCentered(modalEl) {
        if (!modalEl) {
            console.warn('[ensureModalCentered] Modal element not provided');
            return;
        }

        // Find modal content within the overlay
        const content = modalEl.querySelector('.dns-modal-content, .zone-modal-content');
        if (!content) {
            console.warn('[ensureModalCentered] Modal content not found within modal element');
            return;
        }

        // Force reflow to avoid visual glitches
        void modalEl.offsetHeight;

        // Calculate safe max-height (viewport height - 80px margin)
        const maxHeight = window.innerHeight - 80;
        content.style.maxHeight = maxHeight + 'px';
    }

    /**
     * Setup resize and orientation change handlers for visible modals
     */
    function setupResizeHandlers() {
        const handleResize = function() {
            // Find all visible modal overlays
            const visibleModals = document.querySelectorAll('.dns-modal[style*="display: block"], .zone-modal[style*="display: block"]');
            
            visibleModals.forEach(function(modal) {
                ensureModalCentered(modal);
            });
        };

        // Debounce resize handler
        let resizeTimeout;
        const debouncedResize = function() {
            clearTimeout(resizeTimeout);
            resizeTimeout = setTimeout(handleResize, 100);
        };

        window.addEventListener('resize', debouncedResize);
        window.addEventListener('orientationchange', function() {
            // Orientation change needs a small delay
            setTimeout(handleResize, 200);
        });
    }

    // Initialize resize handlers on load
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', setupResizeHandlers);
    } else {
        setupResizeHandlers();
    }

    // Expose to global scope
    window.ensureModalCentered = ensureModalCentered;
})();
