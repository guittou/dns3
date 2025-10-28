# Manual Test Guide for Modal Height Fix

## Quick Test Instructions

### 1. Hard Refresh
- Open your browser and navigate to the zone files page
- Press `Ctrl+F5` (Windows/Linux) or `Cmd+Shift+R` (Mac) to force reload all assets

### 2. Open Developer Console
- Press `F12` to open browser developer tools
- Go to the Console tab

### 3. Test the Implementation

#### Test A: Open Modal and Check Initial Sizing
```javascript
// After opening a zone modal in the UI, run:
const modal = document.querySelector('.dns-modal-content');
console.log('Initial height:', modal.dataset._computedModalHeight);
console.log('Viewport:', modal.dataset._computedViewport);
console.log('Applied height:', modal.style.height);
```

**Expected Result:** You should see height values stored in the dataset.

#### Test B: Force Recalculation
```javascript
// Force a recalculation
adjustZoneModalTabHeights(true);
console.log('After force - height:', document.querySelector('.dns-modal-content').style.height);
```

**Expected Result:** Modal height may change if content or viewport has changed.

#### Test C: Tab Switch Stability
1. Open a zone modal
2. Note the modal height
3. Switch to "Éditeur" tab
4. Switch to "Includes" tab
5. Switch back to "Détails" tab

**Expected Result:** Modal height should remain constant throughout all tab switches.

#### Test D: Window Resize
1. Open a zone modal
2. Resize the browser window (make it smaller)
3. Check if modal adapts

```javascript
// Check if recalculation happened
const modal = document.querySelector('.dns-modal-content');
console.log('Height after resize:', modal.style.height);
```

**Expected Result:** Modal should adapt to new viewport size.

### 4. Using the Test Page

Open `test-modal-sizing.html` in your browser for a standalone test environment:

```bash
# From the repository root
open test-modal-sizing.html
# or just double-click the file
```

**Test Steps:**
1. Click "Open Test Modal"
2. Observe the console log showing initial calculations
3. Switch between tabs - height should stay stable
4. Click "Force Recalculation" - new calculation should occur
5. Resize window - automatic recalculation should trigger

### 5. Verify Editor Behavior

**In the Éditeur tab:**
- Textarea should fill the available space
- Scrolling should happen INSIDE the textarea, not on the modal
- Save/Cancel/Delete buttons should remain visible at the bottom

### 6. Check for Issues

**Common issues to watch for:**
❌ Modal "grows" when switching to Éditeur tab
❌ Textarea is cut off or not fully visible
❌ Modal doesn't adapt when resizing window
❌ Buttons (Save/Cancel/Delete) are hidden off-screen

**Expected behavior:**
✅ Modal size is stable across all tab switches
✅ Textarea scrolls internally
✅ All buttons remain visible
✅ Modal adapts to window resize

### 7. Browser Console Commands Reference

```javascript
// Get modal element
const modal = document.getElementById('zoneModal');
const modalContent = modal.querySelector('.dns-modal-content');

// Check stored values
console.log('Computed Height:', modalContent.dataset._computedModalHeight);
console.log('Computed Viewport:', modalContent.dataset._computedViewport);

// Force recalculation
adjustZoneModalTabHeights(true);

// Check current styles
console.log('Current height:', modalContent.style.height);
console.log('Current maxHeight:', modalContent.style.maxHeight);

// Clear stored values (simulates modal close/reopen)
delete modalContent.dataset._computedModalHeight;
delete modalContent.dataset._computedViewport;
```

### 8. Screenshot Verification

Take screenshots of:
1. Modal with "Détails" tab active
2. Modal with "Éditeur" tab active (should be same height as #1)
3. Modal with "Includes" tab active (should be same height as #1)

Compare the heights visually - they should all be identical.

### 9. Performance Check

The implementation should be fast:
- Initial calculation: < 100ms
- Tab switch (with cached height): < 10ms
- Window resize recalculation: < 100ms

You can measure this in the Console:
```javascript
console.time('tab-switch');
switchTab('editor');
console.timeEnd('tab-switch');
```

### 10. Edge Cases to Test

1. **Very small viewport:** Resize window to 400x600
2. **Very large viewport:** Maximize window on a large monitor
3. **Mobile simulation:** Use Chrome DevTools device toolbar (Ctrl+Shift+M)
4. **Rapid tab switching:** Quickly switch between tabs multiple times

## Success Criteria

✅ All tests pass without errors
✅ Modal height is stable when switching tabs
✅ Editor textarea is fully visible and scrollable
✅ Modal adapts to window resize
✅ No console errors
✅ Buttons remain accessible

## Troubleshooting

**Problem:** Modal still grows when switching tabs
**Solution:** Check that `force=false` on tab switches. Add console.log in switchTab() to verify.

**Problem:** Height is not stored in dataset
**Solution:** Verify modal is visible (display !== 'none') when adjustZoneModalTabHeights() is called.

**Problem:** Window resize doesn't trigger recalculation
**Solution:** Check that handleZoneModalResize() is calling adjustZoneModalTabHeights(true).

## Report Issues

If you encounter issues, provide:
1. Browser and version
2. Viewport size when issue occurred
3. Console errors (if any)
4. Screenshot showing the issue
5. Values from `modalContent.dataset._computedModalHeight`
