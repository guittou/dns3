# Testing Guide - Zone Preview with Validation Display

## Overview
This guide provides step-by-step instructions for testing the new zone preview with validation display feature.

## Prerequisites
- Access to the DNS3 application
- Admin account credentials
- At least one zone file in the system
- `named-checkzone` command available on the server (for validation)

## Test Scenarios

### Test 1: Basic Zone Generation and Preview

**Steps:**
1. Log in to DNS3 as an admin
2. Navigate to "Gestion des fichiers de zone"
3. Click on any zone from the list to open the editor modal
4. Switch to the "Éditeur" tab
5. Click the "Générer le fichier de zone" button

**Expected Results:**
- ✅ Preview modal opens immediately
- ✅ Initial state shows "Chargement…" in the textarea
- ✅ After 1-2 seconds, generated zone file content appears
- ✅ Content includes zone data, $INCLUDE directives, and DNS records
- ✅ Download button becomes active

**Screenshot Points:**
- Modal opening with loading state
- Generated content displayed
- Download button ready

---

### Test 2: Validation Display - Successful Validation

**Steps:**
1. Follow Test 1 steps 1-5
2. Wait for the generated content to appear
3. Look below the textarea for validation results

**Expected Results:**
- ✅ Validation section appears automatically (after content loads)
- ✅ Section header reads "Résultat de la validation (named-checkzone)"
- ✅ Status badge shows "✅ Validation réussie" in green
- ✅ Validation output shows named-checkzone command output
- ✅ Output includes text like "zone example.com/IN: loaded serial..."

**What to Look For:**
```
┌─────────────────────────────────────────────┐
│ Résultat de la validation (named-checkzone) │
├─────────────────────────────────────────────┤
│ ┌─────────────────────────────────────┐     │
│ │ ✅ Validation réussie (green bg)    │     │
│ └─────────────────────────────────────┘     │
│ ┌─────────────────────────────────────┐     │
│ │ zone example.com/IN: loaded serial  │     │
│ │ 2024102201                          │     │
│ │ OK                                  │     │
│ └─────────────────────────────────────┘     │
└─────────────────────────────────────────────┘
```

---

### Test 3: Validation Display - Failed Validation

**Steps:**
1. Create or edit a zone with intentionally invalid DNS syntax
2. Save the zone
3. Click "Générer le fichier de zone"
4. Wait for validation results

**Expected Results:**
- ✅ Status badge shows "❌ Validation échouée" in red
- ✅ Validation output shows specific error messages
- ✅ Error messages indicate what's wrong with the zone file

**What to Look For:**
```
┌─────────────────────────────────────────────┐
│ Résultat de la validation (named-checkzone) │
├─────────────────────────────────────────────┤
│ ┌─────────────────────────────────────┐     │
│ │ ❌ Validation échouée (red bg)      │     │
│ └─────────────────────────────────────┘     │
│ ┌─────────────────────────────────────┐     │
│ │ zone example.com/IN: loading from   │     │
│ │ file failed: syntax error          │     │
│ │ line 5: expected integer near 'abc' │     │
│ └─────────────────────────────────────┘     │
└─────────────────────────────────────────────┘
```

---

### Test 4: Download Functionality

**Steps:**
1. Complete Test 1 or Test 2
2. Click the "Télécharger" button in the modal footer

**Expected Results:**
- ✅ Browser downloads a file
- ✅ Filename matches the zone's filename (e.g., "example.com.zone")
- ✅ File content matches what's displayed in the textarea
- ✅ Success message appears: "Fichier de zone téléchargé avec succès"

**Verification:**
- Open the downloaded file in a text editor
- Compare with the content shown in the preview modal
- Both should be identical

---

### Test 5: Modal Overlay and z-index

**Steps:**
1. Open a zone editor modal
2. Click "Générer le fichier de zone" to open preview
3. Click outside the preview modal (on the dark overlay)
4. Observe modal behavior

**Expected Results:**
- ✅ Preview modal appears on top of editor modal
- ✅ Editor modal is still visible in the background
- ✅ Clicking outside preview modal closes only the preview
- ✅ Editor modal remains open
- ✅ No z-index issues (preview always on top)

**Visual Check:**
```
┌────────────────────────────────────────┐
│ Editor Modal (z-index: 1000)          │
│ ┌──────────────────────────────────┐  │
│ │ Preview Modal (z-index: 9999)    │  │
│ │ (This should be on top)          │  │
│ └──────────────────────────────────┘  │
└────────────────────────────────────────┘
```

---

### Test 6: Error Handling - Generation Failure

**Steps:**
1. Use browser dev tools to simulate network failure
2. Click "Générer le fichier de zone"
3. Observe error handling

**Expected Results:**
- ✅ Error message appears in the textarea
- ✅ Message in French: "Erreur lors de la génération du fichier de zone"
- ✅ Error details included
- ✅ Validation section is hidden
- ✅ Console shows error details for debugging

**Alternative Test:**
- Temporarily break the API endpoint
- Try to generate a zone file
- Verify error is handled gracefully

---

### Test 7: Error Handling - Validation Failure

**Steps:**
1. Successfully generate a zone file
2. Simulate validation API failure (or if named-checkzone is not available)
3. Observe error handling in validation section

**Expected Results:**
- ✅ Generated content still displays correctly
- ✅ Validation section shows error
- ✅ Error message: "❌ Erreur lors de la récupération de la validation"
- ✅ Details explain the validation couldn't be performed
- ✅ Console shows error for debugging

---

### Test 8: Close Modal Behavior

**Steps:**
1. Open preview modal
2. Try each close method:
   a. Click the X button in the header
   b. Click the "Fermer" button in the footer
   c. Click on the dark overlay outside the modal

**Expected Results:**
- ✅ All three methods close the preview modal
- ✅ Editor modal remains open in all cases
- ✅ No JavaScript errors in console
- ✅ Modal can be re-opened without issues

---

### Test 9: Responsive Behavior

**Steps:**
1. Open preview modal on desktop view
2. Resize browser to tablet size (768px wide)
3. Resize to mobile size (375px wide)
4. Test all functionality at each size

**Expected Results:**
- ✅ Modal scales appropriately
- ✅ All elements remain readable
- ✅ Buttons remain accessible
- ✅ No horizontal scrolling required
- ✅ Validation section remains visible

---

### Test 10: Multiple Zones

**Steps:**
1. Open and generate preview for zone A
2. Close preview and editor modals
3. Open and generate preview for zone B
4. Compare results

**Expected Results:**
- ✅ Each zone shows its own content
- ✅ Validation results are specific to each zone
- ✅ No data contamination between previews
- ✅ Download button downloads correct file for each zone

---

## Browser Compatibility Testing

Test the feature in:
- ✅ Chrome/Edge (Chromium)
- ✅ Firefox
- ✅ Safari (if available)

## Performance Testing

**Metrics to Check:**
1. Time from button click to modal open: Should be < 100ms
2. Time to fetch and display content: Should be < 2 seconds
3. Time to display validation: Should be < 3 seconds total
4. No memory leaks after opening/closing multiple times

## Console Checks

Open browser Developer Tools → Console and verify:
- ✅ No JavaScript errors
- ✅ All fetch requests succeed (200 OK)
- ✅ Validation messages logged for debugging
- ✅ Error messages (if any) are descriptive

## Common Issues and Solutions

### Issue: Modal doesn't open
**Check:**
- JavaScript console for errors
- Button click handler is attached
- Modal element exists in DOM

### Issue: Content shows "Chargement…" forever
**Check:**
- API endpoint is accessible
- Network tab shows request succeeded
- Response is valid JSON
- Authentication is working

### Issue: Validation doesn't appear
**Check:**
- Validation API endpoint is accessible
- named-checkzone is installed on server
- Validation results are returned in correct format
- No JavaScript errors in console

### Issue: Download doesn't work
**Check:**
- Preview data is populated
- Blob creation succeeds
- Browser allows downloads
- No popup blocker interfering

### Issue: Wrong z-index (modals overlap incorrectly)
**Check:**
- Preview modal has z-index: 9999 applied
- CSS is loaded correctly
- No conflicting styles

## Testing Sign-off

After completing all tests, document results:

| Test | Status | Notes | Tester | Date |
|------|--------|-------|--------|------|
| Test 1 - Basic Generation | ⏳ | | | |
| Test 2 - Successful Validation | ⏳ | | | |
| Test 3 - Failed Validation | ⏳ | | | |
| Test 4 - Download | ⏳ | | | |
| Test 5 - Modal Overlay | ⏳ | | | |
| Test 6 - Generation Error | ⏳ | | | |
| Test 7 - Validation Error | ⏳ | | | |
| Test 8 - Close Behavior | ⏳ | | | |
| Test 9 - Responsive | ⏳ | | | |
| Test 10 - Multiple Zones | ⏳ | | | |

## Final Approval

- [ ] All critical tests passed
- [ ] No blocking issues found
- [ ] Performance is acceptable
- [ ] UI/UX is satisfactory
- [ ] Documentation is complete
- [ ] Ready for production deployment

**Approved by:** ________________  **Date:** __________
