/**
 * Modal Utilities
 * Helper functions for modal centering and visual adjustments
 */

(function() {
    'use strict';

    /**
     * Ensure modal content is properly centered and sized
     * Forces a repaint and sets max-height to prevent overflow
     * Safe to call multiple times, including after async content loads
     * 
     * @param {HTMLElement} modalEl - The modal overlay element
     */
    window.ensureModalCentered = function(modalEl) {
        if (!modalEl) {
            return;
        }

        // Find the modal content element
        const contentEl = modalEl.querySelector('.dns-modal-content, .zone-modal-content, .modal-content');
        if (!contentEl) {
            return;
        }

        // Force a reflow to avoid visual glitches
        void contentEl.offsetHeight;

        // Set max-height based on viewport height with margin
        const maxHeight = window.innerHeight - 80;
        contentEl.style.maxHeight = maxHeight + 'px';
    };
})();
