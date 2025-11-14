# Modal Height Fix Implementation

## Summary

This PR implements a fix for the zone editor modal height issue where the "Éditeur" tab was being truncated in the UI. The modal now correctly sizes itself to accommodate the tallest tab and maintains a stable height when switching between tabs.

## Changes Made

### Modified Files
- `assets/js/zone-files.js` - Updated modal height calculation functions
- `test-modal-sizing.html` - Enhanced test page with force recalculation button

### Key Implementation Details

#### 1. `adjustZoneModalTabHeights(force = false)`
- **New parameter**: `force` (boolean, default: false)
- **Behavior**:
  - On first call or when `force=true`: Measures ALL tab panes to find the maximum height needed
  - Stores the computed height in `modalContent.dataset._computedModalHeight`
  - Stores the viewport constraint in `modalContent.dataset._computedViewport`
  - On subsequent calls (without force): Reuses the stored height to prevent modal "growing" during tab switches
  
- **Key improvements**:
  - Uses a `measureHeight()` helper function that measures elements off-screen to avoid layout disruption
  - Applies proper flex layout to ensure editors fill available space
  - Configures textareas and code editors to scroll internally
  - Refreshes CodeMirror and ACE editor instances after sizing

#### 2. `lockZoneModalHeight()`
- **New behavior**: Re-applies stored computed height if available
- No longer a no-op, but uses the stored dataset values

#### 3. `unlockZoneModalHeight()`
- **Enhanced**: Now clears the stored dataset values (`_computedModalHeight` and `_computedViewport`)
- Ensures clean state when modal is closed

#### 4. `handleZoneModalResize()`
- **Updated**: Now calls `adjustZoneModalTabHeights(true)` to force recalculation on window resize

## How It Works

1. **On Modal Open**: 
   - `adjustZoneModalTabHeights()` is called
   - All tab panes are measured (even hidden ones) by temporarily making them visible off-screen
   - The maximum height is calculated and stored in the dataset
   - Modal content height is set to accommodate the tallest tab

2. **On Tab Switch**:
   - `adjustZoneModalTabHeights()` is called again
   - Since `force=false` and height is already computed, stored values are reused
   - Modal height remains stable - no "growing" effect

3. **On Window Resize**:
   - `handleZoneModalResize()` calls `adjustZoneModalTabHeights(true)`
   - Forces recalculation to adapt to new viewport size

4. **On Modal Close**:
   - `unlockZoneModalHeight()` clears stored dataset values
   - Clean slate for next modal open

## Testing

### Manual Testing Steps

1. Open `test-modal-sizing.html` in a browser
2. Click "Open Test Modal"
3. Switch between tabs: Détails → Éditeur → Includes
4. Verify modal height stays constant (check console log for height values)
5. Click "Force Recalculation" button
6. Resize browser window
7. Verify modal adapts to new viewport size

### Expected Behavior

✅ Modal opens sized to tallest tab (Éditeur)
✅ Height remains stable when switching tabs
✅ Editor textarea scrolls internally without affecting modal size
✅ Modal recalculates on window resize
✅ Console log shows consistent height values between tab switches
✅ Force recalculation button triggers new height computation

### Browser Console Testing

```javascript
// Force recalculation
adjustZoneModalTabHeights(true);

// Check stored values
const modal = document.querySelector('.dns-modal-content');
console.log('Computed height:', modal.dataset._computedModalHeight);
console.log('Viewport:', modal.dataset._computedViewport);
```

## Browser Compatibility

The implementation uses:
- `dataset` API (IE 11+)
- Arrow functions (transpile if needed for older browsers)
- `Array.from()` (IE 11+ or polyfill)
- Modern CSS flex layout

## Notes

- This is a minimal change focused only on `assets/js/zone-files.js` as requested
- Backward compatibility maintained through existing function signatures
- CodeMirror and ACE editor support is included but gracefully degrades if not present
- The implementation follows the existing code style and patterns in the file
