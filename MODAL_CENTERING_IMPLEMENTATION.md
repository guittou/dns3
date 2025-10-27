# Modal Centering Implementation

## Overview
This implementation adds vertical and horizontal centering for DNS and Zone modals with intelligent fallback to top-aligned scrolling when content exceeds viewport height.

## Files Modified

### New Files
- `assets/js/modal-utils.js` - Reusable modal positioning helper

### Modified Files
- `assets/css/style.css` - Modal centering CSS rules
- `assets/js/dns-records.js` - DNS modal integration
- `assets/js/zone-files.js` - Zone modal integration  
- `dns-management.php` - Script inclusion
- `zone-files.php` - Script inclusion

## Usage

The `adjustModalPosition()` function is automatically called:
- When DNS create/edit modals open
- When zone modals open
- When zone modal tabs are switched
- On window resize and orientation change

No manual intervention required - the system automatically:
1. Detects if modal content fits in viewport
2. Centers modal if content fits (using flexbox)
3. Top-aligns with scrolling if content exceeds viewport
4. Adjusts dynamically on resize

## Technical Details

### Buffer Zone
- 80px total buffer (40px top + 40px bottom)
- Ensures modal doesn't touch viewport edges

### CSS Classes
- `.modal-overlay` - Applied when content fits (flex centering)
- `.modal-top` - Applied when content tall (top alignment + scroll)

### Browser Support
Modern browsers with CSS Flexbox, requestAnimationFrame, and standard DOM APIs.

## Testing
Manual testing required to verify:
- Modal centering on desktop viewports
- Top-alignment on small viewports
- Responsive behavior on resize
- Tab switching in zone modals
- No JavaScript errors
