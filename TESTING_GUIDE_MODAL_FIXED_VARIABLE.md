# Testing Guide: Generic Modal Fixed Height via CSS Variable

## Overview

This document describes the testing procedures for the new generic modal fixed-height mechanism using CSS custom properties and the `modal-fixed` class.

## Changes Summary

### CSS Changes (assets/css/style.css)
- **Removed**: `modal-fixed-720` class with hardcoded 720px height
- **Added**: 
  - `:root` CSS variable `--modal-fixed-height: 730px` (default)
  - `.modal-fixed` class that uses `var(--modal-fixed-height)`
  - Flexible height mechanism that can be changed globally or per-instance

### JavaScript Changes (assets/js/zone-files.js)
- **Updated**: `applyFixedModalHeight(height)` now accepts optional height parameter
- **Constants**: Added `MODAL_FIXED_CLASS = 'modal-fixed'` and `DEFAULT_MODAL_HEIGHT = '730px'`
- **Behavior**: Function now sets inline CSS variable when custom height provided
- **Cleanup**: `unlockZoneModalHeight()` now removes both class and inline CSS variable

## Test Cases

### Test 1: Default Modal Height (730px)

**Objective**: Verify modal opens with default 730px height from CSS variable

**Steps**:
1. Open zone-files.php page
2. Click on any zone to open the modal
3. Wait for modal to fully load (~150ms)

**Expected Results**:
- Modal opens with height of 730px
- Modal has `modal-fixed` class applied
- Internal content scrolls if it exceeds 730px
- Modal height remains constant when switching tabs

**Verification**:
```javascript
// In browser console
const modal = document.getElementById('zoneModal');
console.log(modal.classList.contains('modal-fixed')); // true
const height = getComputedStyle(modal.querySelector('.dns-modal-content')).height;
console.log(height); // "730px"
```

### Test 2: Custom Height via JavaScript

**Objective**: Verify dynamic height setting via function parameter

**Steps**:
1. Open zone modal
2. In browser console, run:
   ```javascript
   applyFixedModalHeight('740px');
   ```
3. Check modal height
4. Try different values: `'800px'`, `'80vh'`, `'90%'`

**Expected Results**:
- Modal height changes to specified value
- Inline style property `--modal-fixed-height` is set on modal element
- Changes take effect immediately
- Different units (px, vh, %) all work correctly

**Verification**:
```javascript
const modal = document.getElementById('zoneModal');
console.log(modal.style.getPropertyValue('--modal-fixed-height')); // "740px"
```

### Test 3: Global CSS Variable Change

**Objective**: Verify site-wide height can be changed via CSS variable

**Steps**:
1. In browser console, change global CSS variable:
   ```javascript
   document.documentElement.style.setProperty('--modal-fixed-height', '700px');
   ```
2. Open a new modal (or refresh existing)
3. Check modal height

**Expected Results**:
- All new modals use the new global height
- Existing modals with inline overrides keep their custom height
- Changes persist until page reload

**Verification**:
```javascript
const globalHeight = getComputedStyle(document.documentElement)
    .getPropertyValue('--modal-fixed-height').trim();
console.log(globalHeight); // "700px"
```

### Test 4: Lock/Unlock Functionality

**Objective**: Verify lock and unlock functions work correctly

**Steps**:
1. Open zone modal
2. Run `unlockZoneModalHeight()` in console
3. Check modal state
4. Run `lockZoneModalHeight()` in console
5. Check modal state again

**Expected Results**:

**After unlock**:
- `modal-fixed` class removed
- Inline CSS variable removed
- Modal height returns to auto/default
- Dataset properties cleared

**After lock**:
- `modal-fixed` class added
- Default height applied
- Internal panes have `overflow: auto`

**Verification**:
```javascript
// After unlock
const modal = document.getElementById('zoneModal');
console.log(modal.classList.contains('modal-fixed')); // false
console.log(modal.style.getPropertyValue('--modal-fixed-height')); // ""

// After lock
console.log(modal.classList.contains('modal-fixed')); // true
```

### Test 5: Tab Switching

**Objective**: Verify modal height remains constant when switching tabs

**Steps**:
1. Open zone modal
2. Switch between tabs (Details, Content, Includes)
3. Observe modal height

**Expected Results**:
- Modal outer height remains constant at 730px (or custom height)
- Tab content scrolls internally
- No modal resize/jump when switching tabs
- All tabs display correctly within fixed height

### Test 6: Window Resize

**Objective**: Verify modal height behavior on window resize

**Steps**:
1. Open zone modal with fixed height
2. Resize browser window
3. Observe modal behavior

**Expected Results**:
- Modal maintains fixed pixel height (if using px units)
- Modal adjusts if using viewport units (vh)
- No layout breaks or overflow issues
- Content remains scrollable

### Test 7: Responsive Viewport Units

**Objective**: Test using viewport-relative units

**Steps**:
1. Set modal height to viewport unit:
   ```javascript
   applyFixedModalHeight('80vh');
   ```
2. Resize browser window
3. Check modal adapts to viewport

**Expected Results**:
- Modal height is 80% of viewport height
- Height adjusts when resizing window
- Works correctly on different screen sizes

## Manual QA Checklist

- [ ] Modal opens with default 730px height
- [ ] `modal-fixed` class is applied to modal
- [ ] Internal panes (`tab-pane`, `tab-content`, etc.) scroll correctly
- [ ] Tab switching doesn't change modal height
- [ ] Can set custom height via `applyFixedModalHeight('XXXpx')`
- [ ] Can change global height via CSS variable
- [ ] `unlockZoneModalHeight()` removes class and inline variable
- [ ] `lockZoneModalHeight()` reapplies fixed height
- [ ] Different units work (px, vh, %)
- [ ] CodeMirror/ACE editors refresh correctly after height change
- [ ] No console errors when applying/removing fixed height
- [ ] Close and reopen modal maintains correct behavior

## Browser Testing

Test in the following browsers:
- [ ] Chrome/Edge (latest)
- [ ] Firefox (latest)
- [ ] Safari (latest)
- [ ] Mobile Safari (iOS)
- [ ] Mobile Chrome (Android)

## Regression Testing

Ensure the following still work correctly:
- [ ] Modal centering on small screens
- [ ] Modal error banners display correctly
- [ ] Form validation in modals
- [ ] Zone file generation and preview
- [ ] Include management in modal
- [ ] Save/delete operations

## Performance Testing

- [ ] No performance degradation when opening/closing modals
- [ ] No memory leaks (check DevTools Memory tab)
- [ ] Smooth scrolling in modal content
- [ ] Editor refresh completes quickly (<100ms)

## Compatibility Notes

### CSS Variable Support
- All modern browsers support CSS variables
- IE11 does NOT support CSS variables (not a concern for this project)

### Fallback Behavior
- If CSS variable not set, JavaScript applies DEFAULT_MODAL_HEIGHT (730px)
- Graceful degradation in case of missing elements

## Known Limitations

1. **Viewport units and mobile**: Using `vh` units on mobile may be affected by address bar show/hide
2. **Percentage units**: Using `%` requires parent element to have defined height
3. **Max content**: Modal content exceeding fixed height will scroll (intended behavior)

## Success Criteria

✅ The implementation is successful if:
1. Modal height can be controlled via single CSS variable
2. Height can be customized per-instance via JavaScript
3. No breaking changes to existing functionality
4. Code is cleaner and more maintainable than hardcoded values
5. All tests pass without errors

## Troubleshooting

### Modal height not applying
- Check browser console for errors
- Verify `modal-fixed` class is present
- Check computed style of `--modal-fixed-height`

### Height not changing
- Check if inline style is overriding CSS variable
- Clear inline styles and reapply
- Verify CSS variable syntax is correct

### Internal scrolling not working
- Check `overflow: auto` is applied to tab panes
- Verify modal content exceeds fixed height
- Check for conflicting CSS rules

## Test File

A standalone test file is provided: `test-modal-fixed-variable.html`

This file includes:
- Interactive buttons to test all scenarios
- Visual feedback for each test
- Code examples showing JavaScript calls
- Verification helpers

To use:
1. Open `test-modal-fixed-variable.html` in browser
2. Follow the test sections in order
3. Verify expected results match actual behavior
