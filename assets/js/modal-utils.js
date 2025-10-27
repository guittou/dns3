/**
 * Modal Utilities
 * Helper functions for modal positioning and behavior
 */

(function() {
    'use strict';

    /**
     * Adjust modal position based on viewport height
     * Centers modal when content fits, falls back to top alignment when content is taller
     * 
     * @param {HTMLElement} modalEl - The modal overlay element (.dns-modal or similar)
     */
    function adjustModalPosition(modalEl) {
        if (!modalEl || modalEl.style.display === 'none') {
            return;
        }

        // Find the modal content element (could be .dns-modal-content or .zone-modal-content)
        const modalContent = modalEl.querySelector('.dns-modal-content, .zone-modal-content');
        if (!modalContent) {
            console.warn('[modal-utils] No modal content found for', modalEl);
            return;
        }

        // Get viewport height
        const viewportHeight = window.innerHeight;
        
        // Get modal content height (including padding, border)
        const contentHeight = modalContent.offsetHeight;
        
        // Small buffer for spacing (e.g., 80px total: 40px top + 40px bottom)
        const buffer = 80;
        
        // Determine if content fits in viewport with buffer
        const contentFits = (contentHeight + buffer) <= viewportHeight;
        
        if (contentFits) {
            // Content fits: use flex centering
            modalEl.classList.remove('modal-top');
            modalEl.classList.add('modal-overlay');
            
            // Reset max-height on content to allow natural sizing
            modalContent.style.maxHeight = '';
        } else {
            // Content too tall: use top alignment
            modalEl.classList.remove('modal-overlay');
            modalEl.classList.add('modal-top');
            
            // Set max-height on content so it scrolls internally
            // Leave some space at top and bottom for visual breathing room
            const maxContentHeight = viewportHeight - buffer;
            modalContent.style.maxHeight = maxContentHeight + 'px';
        }
    }

    /**
     * Setup global resize and orientation change listeners
     * Recomputes position for all visible modals
     */
    function setupGlobalListeners() {
        let resizeTimeout;
        
        function handleResize() {
            // Debounce resize events
            clearTimeout(resizeTimeout);
            resizeTimeout = setTimeout(() => {
                // Find all visible modals (both inline style and class-based visibility)
                const visibleModals = document.querySelectorAll('.dns-modal[style*="display: block"], .dns-modal.open, .dns-modal.modal-overlay, .dns-modal.modal-top');
                visibleModals.forEach(modal => {
                    adjustModalPosition(modal);
                });
            }, 100);
        }
        
        window.addEventListener('resize', handleResize);
        window.addEventListener('orientationchange', handleResize);
    }

    // Initialize global listeners once
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', setupGlobalListeners);
    } else {
        setupGlobalListeners();
    }

    // Expose to global scope
    window.adjustModalPosition = adjustModalPosition;
})();
