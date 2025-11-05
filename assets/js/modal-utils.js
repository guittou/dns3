/**
 * Modal Utilities
 * Helper functions for modal centering, viewport management, and modal lifecycle
 */

(function() {
    'use strict';

    /**
     * Open a modal by ID and apply centering and height management
     * @param {string} modalId - The ID of the modal element to open
     */
    window.openModalById = function(modalId) {
        const modalEl = document.getElementById(modalId);
        if (!modalEl) {
            console.error('Modal not found:', modalId);
            return;
        }
        
        // Add open class to show modal
        modalEl.classList.add('open');
        modalEl.style.display = 'flex';
        
        // Apply height and centering after a short delay to ensure DOM is ready
        setTimeout(function() {
            window.applyFixedModalHeight(modalEl);
            window.ensureModalCentered(modalEl);
        }, 10);
    };

    /**
     * Close a modal by ID and clean up styling
     * @param {string} modalId - The ID of the modal element to close
     */
    window.closeModalById = function(modalId) {
        const modalEl = document.getElementById(modalId);
        if (!modalEl) {
            console.error('Modal not found:', modalId);
            return;
        }
        
        // Remove open class and hide modal
        modalEl.classList.remove('open');
        modalEl.style.display = 'none';
        
        // Unlock modal height
        window.unlockModalHeight(modalEl);
    };

    /**
     * Apply fixed height to modal to prevent resizing during tab switches
     * Enforces 720px height with responsive fallback for smaller viewports
     * @param {HTMLElement} modalEl - The modal overlay element
     */
    window.applyFixedModalHeight = function(modalEl) {
        if (!modalEl) return;
        
        const content = modalEl.querySelector('.dns-modal-content, .zone-modal-content, .modal-content');
        if (!content) return;
        
        // Fixed height target: 720px
        const targetHeight = 720;
        
        // Responsive fallback: if viewport is smaller than 720px + padding (80px), use viewport height
        const viewportHeight = window.innerHeight;
        const availableHeight = viewportHeight - 80; // 40px padding top + 40px padding bottom
        
        // Choose the smaller of target height or available height
        const finalHeight = Math.min(targetHeight, availableHeight);
        
        // Apply the fixed height
        content.style.height = finalHeight + 'px';
        content.style.maxHeight = finalHeight + 'px';
        modalEl.classList.add('modal-fixed');
    };

    /**
     * Unlock modal height to allow natural sizing
     * @param {HTMLElement} modalEl - The modal overlay element
     */
    window.unlockModalHeight = function(modalEl) {
        if (!modalEl) return;
        
        const content = modalEl.querySelector('.dns-modal-content, .zone-modal-content, .modal-content');
        if (!content) return;
        
        // Remove fixed height
        content.style.height = '';
        content.style.maxHeight = '';
        modalEl.classList.remove('modal-fixed');
    };

    /**
     * Ensure modal is properly centered and content fits within viewport
     * Forces reflow and adjusts max-height to prevent visual glitches
     * @param {HTMLElement} modalEl - The modal overlay element
     */
    window.ensureModalCentered = function(modalEl) {
        if (!modalEl) return;
        
        const content = modalEl.querySelector('.dns-modal-content, .zone-modal-content, .modal-content');
        if (!content) return;
        
        // Force reflow to ensure layout is stable
        void modalEl.offsetHeight;
        
        // Set max-height based on current viewport to avoid overflow if not already fixed
        if (!modalEl.classList.contains('modal-fixed')) {
            const maxHeight = window.innerHeight - 80;
            content.style.maxHeight = maxHeight + 'px';
        }
    };

    /**
     * Recompute centering for all visible modals on resize/orientation change
     */
    function recomputeVisibleModals() {
        // Find all visible modal overlays (all modals use .dns-modal class)
        const visibleModals = document.querySelectorAll('.dns-modal.open');
        
        visibleModals.forEach(function(modal) {
            if (modal.style.display !== 'none') {
                window.ensureModalCentered(modal);
            }
        });
    }

    /**
     * Close modal when clicking on overlay (unless data-no-overlay-close is set)
     */
    function handleOverlayClick(event) {
        const modalEl = event.target;
        
        // Only close if clicking directly on the overlay (not on modal content)
        if (modalEl.classList.contains('dns-modal') && modalEl === event.target) {
            // Check if overlay close is disabled
            if (modalEl.getAttribute('data-no-overlay-close') === 'true') {
                return;
            }
            
            // Close the modal
            modalEl.classList.remove('open');
            modalEl.style.display = 'none';
            window.unlockModalHeight(modalEl);
        }
    }

    // Listen for viewport changes
    window.addEventListener('resize', recomputeVisibleModals);
    window.addEventListener('orientationchange', recomputeVisibleModals);

    // Listen for clicks on modal overlays
    document.addEventListener('click', handleOverlayClick);

})();
