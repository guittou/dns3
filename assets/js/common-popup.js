/**
 * Common Popup Utilities
 * Reusable popup functions for alerts and confirmations
 * Replaces native JavaScript alert() and confirm() with custom styled popups
 * Follows DNS3 UI design (blue/green/red colors, rounded corners)
 */

(function() {
    'use strict';

    /**
     * Show an alert popup (info, success, or error)
     * @param {string} message - The message to display
     * @param {string} type - The type of alert: 'info', 'success', or 'error' (default: 'info')
     * @param {string} title - Optional custom title (default based on type)
     */
    window.showAlert = function(message, type = 'info', title = null) {
        // Remove any existing alert popup
        const existingPopup = document.getElementById('common-alert-popup');
        if (existingPopup) {
            existingPopup.remove();
        }

        // Determine title and icon based on type
        let defaultTitle, iconClass, iconSymbol;
        switch (type) {
            case 'success':
                defaultTitle = 'Succès';
                iconClass = 'success';
                iconSymbol = '✓';
                break;
            case 'error':
                defaultTitle = 'Erreur';
                iconClass = 'error';
                iconSymbol = '✗';
                break;
            case 'info':
            default:
                defaultTitle = 'Information';
                iconClass = 'info';
                iconSymbol = 'ℹ';
                break;
        }

        const finalTitle = title || defaultTitle;

        // Create popup HTML
        const popup = document.createElement('div');
        popup.id = 'common-alert-popup';
        popup.className = 'common-popup-overlay';
        popup.setAttribute('role', 'dialog');
        popup.setAttribute('aria-labelledby', 'common-alert-title');
        popup.setAttribute('aria-modal', 'true');

        popup.innerHTML = `
            <div class="common-popup-content">
                <div class="common-popup-header">
                    <h3 id="common-alert-title">${escapeHtml(finalTitle)}</h3>
                    <button class="common-popup-close" aria-label="Fermer">&times;</button>
                </div>
                <div class="common-popup-body">
                    <div class="common-alert-message ${iconClass}">
                        <span class="common-alert-icon">${iconSymbol}</span>
                        <div class="common-alert-text">${escapeHtml(message)}</div>
                    </div>
                </div>
                <div class="common-popup-footer">
                    <button class="common-popup-btn common-popup-btn-primary">OK</button>
                </div>
            </div>
        `;

        document.body.appendChild(popup);

        // Show popup with animation
        setTimeout(() => popup.classList.add('show'), 10);

        // Close handlers
        const closePopup = () => {
            popup.classList.remove('show');
            setTimeout(() => popup.remove(), 200);
        };

        popup.querySelector('.common-popup-close').addEventListener('click', closePopup);
        popup.querySelector('.common-popup-btn-primary').addEventListener('click', closePopup);
        popup.addEventListener('click', (e) => {
            if (e.target === popup) closePopup();
        });

        // Close on Escape key
        const escapeHandler = (e) => {
            if (e.key === 'Escape') {
                closePopup();
                document.removeEventListener('keydown', escapeHandler);
            }
        };
        document.addEventListener('keydown', escapeHandler);
    };

    /**
     * Show a confirmation popup with custom buttons
     * @param {string} message - The confirmation message to display
     * @param {function} onConfirm - Callback function to execute if user confirms
     * @param {function} onCancel - Optional callback function to execute if user cancels
     * @param {Object} options - Optional configuration
     *   - {string} title - Custom title (default: 'Confirmation')
     *   - {string} confirmText - Text for confirm button (default: 'Confirmer')
     *   - {string} cancelText - Text for cancel button (default: 'Annuler')
     *   - {string} type - Type of confirmation: 'danger', 'warning', 'info' (default: 'warning')
     */
    window.showConfirm = function(message, onConfirm, onCancel = null, options = {}) {
        // Remove any existing confirm popup
        const existingPopup = document.getElementById('common-confirm-popup');
        if (existingPopup) {
            existingPopup.remove();
        }

        // Default options
        const title = options.title || 'Confirmation';
        const confirmText = options.confirmText || 'Confirmer';
        const cancelText = options.cancelText || 'Annuler';
        const type = options.type || 'warning';

        // Determine icon based on type
        let iconSymbol, messageClass;
        switch (type) {
            case 'danger':
                iconSymbol = '⚠';
                messageClass = 'danger';
                break;
            case 'info':
                iconSymbol = 'ℹ';
                messageClass = 'info';
                break;
            case 'warning':
            default:
                iconSymbol = '⚠';
                messageClass = 'warning';
                break;
        }

        // Create popup HTML
        const popup = document.createElement('div');
        popup.id = 'common-confirm-popup';
        popup.className = 'common-popup-overlay';
        popup.setAttribute('role', 'dialog');
        popup.setAttribute('aria-labelledby', 'common-confirm-title');
        popup.setAttribute('aria-modal', 'true');

        popup.innerHTML = `
            <div class="common-popup-content">
                <div class="common-popup-header">
                    <h3 id="common-confirm-title">${escapeHtml(title)}</h3>
                    <button class="common-popup-close" aria-label="Fermer">&times;</button>
                </div>
                <div class="common-popup-body">
                    <div class="common-confirm-message ${messageClass}">
                        <span class="common-confirm-icon">${iconSymbol}</span>
                        <div class="common-confirm-text">${escapeHtml(message)}</div>
                    </div>
                </div>
                <div class="common-popup-footer">
                    <button class="common-popup-btn common-popup-btn-secondary">${escapeHtml(cancelText)}</button>
                    <button class="common-popup-btn common-popup-btn-primary">${escapeHtml(confirmText)}</button>
                </div>
            </div>
        `;

        document.body.appendChild(popup);

        // Show popup with animation
        setTimeout(() => popup.classList.add('show'), 10);

        // Close handlers
        const closePopup = () => {
            popup.classList.remove('show');
            setTimeout(() => popup.remove(), 200);
        };

        const handleConfirm = () => {
            closePopup();
            if (typeof onConfirm === 'function') {
                onConfirm();
            }
        };

        const handleCancel = () => {
            closePopup();
            if (typeof onCancel === 'function') {
                onCancel();
            }
        };

        popup.querySelector('.common-popup-close').addEventListener('click', handleCancel);
        popup.querySelector('.common-popup-btn-secondary').addEventListener('click', handleCancel);
        popup.querySelector('.common-popup-btn-primary').addEventListener('click', handleConfirm);
        
        // Close on overlay click = cancel
        popup.addEventListener('click', (e) => {
            if (e.target === popup) handleCancel();
        });

        // Close on Escape key = cancel
        const escapeHandler = (e) => {
            if (e.key === 'Escape') {
                handleCancel();
                document.removeEventListener('keydown', escapeHandler);
            }
        };
        document.addEventListener('keydown', escapeHandler);
    };

    /**
     * Helper function to escape HTML and prevent XSS
     * @param {string} text - Text to escape
     * @returns {string} - Escaped HTML
     */
    function escapeHtml(text) {
        const div = document.createElement('div');
        div.textContent = text;
        return div.innerHTML;
    }

})();
