# Modal Standardization - Testing Guide

## Manual Testing Checklist

### Prerequisites
1. Start the application server
2. Log in as an administrator
3. Navigate to the Administration page (`admin.php`)

### Test 1: Domain Modal
#### Create Domain Modal
1. Click on "Domaines" tab
2. Click "Créer un domaine" button
3. **Verify:**
   - ✅ Modal appears centered on screen
   - ✅ Modal has a semi-transparent overlay
   - ✅ Modal uses medium size (600px max-width)
   - ✅ Header shows "Créer un domaine"
   - ✅ Close button (×) is visible in top-right
   - ✅ Footer buttons are in order: ~~Supprimer~~ / Annuler / Enregistrer
   - ✅ Delete button is hidden for create mode
4. **Test interactions:**
   - Click overlay → Modal should close
   - Reopen modal, click "×" → Modal should close
   - Reopen modal, click "Annuler" → Modal should close
   - Reopen modal, press Escape → Check if modal closes (optional feature)

#### Edit Domain Modal
1. Find an existing domain in the table
2. Click the "Modifier" button
3. **Verify:**
   - ✅ Modal appears centered
   - ✅ Header shows "Modifier un domaine"
   - ✅ Form is pre-filled with domain data
   - ✅ Footer shows: Supprimer / Annuler / Enregistrer
   - ✅ Delete button is visible and styled in red
   - ✅ Created/Updated timestamps are visible

### Test 2: User Modal
#### Create User Modal
1. Click on "Utilisateurs" tab
2. Click "Créer un utilisateur" button
3. **Verify:**
   - ✅ Modal appears centered
   - ✅ Header shows "Créer un utilisateur"
   - ✅ Footer shows: Annuler / Enregistrer (no delete button)
   - ✅ Password field is required (marked with *)
   - ✅ Auth method field is hidden for new users

#### Edit User Modal
1. Find an existing user in the table
2. Click the "Modifier" button
3. **Verify:**
   - ✅ Modal appears centered
   - ✅ Header shows "Modifier un utilisateur"
   - ✅ Form is pre-filled with user data
   - ✅ Footer shows: Annuler / Enregistrer
   - ✅ Password field is optional (no * indicator)
   - ✅ Auth method is visible but disabled
   - ✅ Roles checkboxes are pre-selected

### Test 3: Mapping Modal
1. Click on "Mappings AD/LDAP" tab
2. Click "Créer un mapping" button
3. **Verify:**
   - ✅ Modal appears centered
   - ✅ Header shows "Créer un mapping AD/LDAP"
   - ✅ Footer shows: Annuler / Créer (no delete button)
   - ✅ Form has Source, DN/Groupe, Rôle, Notes fields

### Test 4: Responsive Behavior
#### Desktop (> 768px)
1. Resize browser to 1920x1080
2. Open any modal
3. **Verify:**
   - ✅ Modal is properly centered
   - ✅ Modal respects max-width constraints
   - ✅ Buttons are in horizontal row

#### Tablet (768px)
1. Resize browser to 768px width
2. Open any modal
3. **Verify:**
   - ✅ Modal takes 95% of width
   - ✅ Still centered vertically
   - ✅ Content is readable

#### Mobile (< 520px)
1. Resize browser to 375px width
2. Open any modal
3. **Verify:**
   - ✅ Modal takes full width (100%)
   - ✅ Buttons stack vertically
   - ✅ Padding is reduced
   - ✅ Close button is still accessible

### Test 5: Modal Styling
For each modal, verify:
1. **Colors:**
   - ✅ Delete button: Red background (#e74c3c)
   - ✅ Cancel button: Gray background (#95a5a6)
   - ✅ Save/Create button: Green background (#27ae60)
   
2. **Hover effects:**
   - ✅ Buttons darken on hover
   - ✅ Close (×) button changes color on hover

3. **Typography:**
   - ✅ Modal title is centered and prominent
   - ✅ Labels are bold
   - ✅ Form hints are smaller and gray

### Test 6: Accessibility
1. **Keyboard navigation:**
   - Tab through form fields
   - ✅ Focus indicators are visible
   - ✅ Tab order is logical
   
2. **Screen reader:**
   - ✅ Modal has proper ARIA labels (if implemented)
   - ✅ Close button has aria-label

### Test 7: Browser Compatibility
Test on:
- [ ] Chrome/Edge (Chromium)
- [ ] Firefox
- [ ] Safari (if available)

### Test 8: JavaScript Console
1. Open browser console (F12)
2. Open and close each modal
3. **Verify:**
   - ✅ No JavaScript errors
   - ✅ No console warnings
   - ✅ Functions execute cleanly

## Expected Results Summary

All modals should:
- ✅ Use the same visual structure as Zone modals
- ✅ Be centered both vertically and horizontally
- ✅ Have consistent button styling and order
- ✅ Close on overlay click
- ✅ Close on × button click
- ✅ Close on Cancel button click
- ✅ Work responsively on all screen sizes
- ✅ Have proper form validation
- ✅ Display no console errors

## Common Issues to Watch For

1. **Modal not centered:** Check if `modal-utils.js` loaded properly
2. **Buttons wrong color:** Check if `modal-utils.css` loaded properly
3. **Modal doesn't close on overlay:** Check click event listener
4. **Mobile layout broken:** Check responsive CSS rules
5. **Form submission fails:** Verify form `id` matches submit button `form` attribute

## Automated Checks

Run the verification script:
```bash
bash /tmp/verify_changes.sh
```

All checks should pass ✅

## Visual Regression Testing

Compare screenshots:
1. Before: Old modal design
2. After: New standardized design
3. Verify consistency with Zone modals

## Performance

Monitor:
- Modal open time should be < 100ms
- No layout shifts during modal opening
- Smooth animations (if any)

## Report Issues

If any tests fail, document:
- Browser and version
- Screen size
- Steps to reproduce
- Expected vs actual behavior
- Console errors (if any)
