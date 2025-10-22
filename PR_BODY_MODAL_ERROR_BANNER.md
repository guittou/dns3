# PR: ui(modal): show inline red error banner on create/edit modals instead of browser popup

## Description

This PR implements inline error banners in the zone creation and editing modals to replace browser-native validation popups. When form validation fails or server errors occur, instead of showing a browser alert/popup, the error message is now displayed as a red alert banner inside the modal dialog itself.

## Changes

### Modified Files

1. **zone-files.php**
   - Added error banner div to Create Zone Modal (`createZoneErrorBanner`)
   - Added error banner div to Edit Zone Modal (`zoneModalErrorBanner`)
   - Changed Create button from `type="submit"` to `type="button"` to prevent native HTML5 validation
   - Both banners include accessibility attributes: `role="alert"` and `tabindex="-1"`

2. **assets/js/zone-files.js**
   - Added `showModalError(modalId, message)` helper function
   - Added `clearModalError(modalId)` helper function
   - Updated `createZone()` to use `showModalError()` for validation errors
   - Updated `saveZone()` to use `showModalError()` for validation errors
   - Updated `openCreateZoneModal()` to clear errors when opening
   - Updated `openZoneModal()` to clear errors when opening
   - Removed form submit event listener (no longer needed with type="button")

3. **MODAL_ERROR_BANNER_IMPLEMENTATION.md** (new)
   - Comprehensive documentation of the implementation
   - Test cases and usage examples

## Features

✅ **Inline Error Display**: Errors appear as red alert banners inside the modal
✅ **No Browser Popups**: Native HTML5 validation popups are prevented
✅ **Modal Stays Open**: Users can correct errors without reopening the modal
✅ **Accessibility**: Banners have `role="alert"`, `tabindex="-1"`, and auto-focus
✅ **French Messages**: Error messages from API are displayed in French
✅ **Automatic Clearing**: Banners are cleared when modal opens or on successful retry

## User Experience

### Before
- Browser popup appears with validation error
- User must dismiss popup
- Modal may close
- Inconsistent error display across browsers

### After
- Red banner appears at the top of the modal
- Error message is clear and visible
- Modal stays open for corrections
- Consistent experience across all browsers

## Testing

### Test Case 1: Create Zone with Space in Name
1. Click "Nouvelle zone"
2. Enter name with space: "test zone"
3. Enter filename: "test.zone"
4. Click "Créer"
5. ✅ Red banner appears with error message
6. ✅ Modal stays open
7. ✅ No browser popup

### Test Case 2: Edit Zone with Invalid Data
1. Open existing zone
2. Modify field to invalid value
3. Click "Enregistrer"
4. ✅ Red banner appears with error message
5. ✅ Modal stays open

### Test Case 3: Successful Submission
1. Enter valid data
2. Click submit
3. ✅ Banner is cleared (if previously shown)
4. ✅ Success message appears
5. ✅ Modal closes

## Screenshots

### Error Banner Display
![Modal Error Banner](https://github.com/user-attachments/assets/ffd82ad6-b6c5-4c7d-9f1c-15740996f3d0)

*Red error banner displayed at the top of the modal when validation fails*

## API Compatibility

The implementation works with existing API error responses (HTTP 422):
```json
{
  "error": "Le nom de la zone ne peut pas contenir d'espaces"
}
```

## Accessibility

- Screen readers announce errors via `role="alert"`
- Error banner is focusable via `tabindex="-1"`
- Automatic focus on error display for keyboard navigation

## Browser Compatibility

- ✅ Chrome/Edge
- ✅ Firefox
- ✅ Safari
- ✅ All modern browsers

## Future Enhancements

- Replace global `showError()` alerts with toast notifications
- Add animation for banner appearance
- Support multiple error messages
- Auto-dismiss on correction

## Validation

- [x] PHP syntax validated (`php -l zone-files.php`)
- [x] JavaScript syntax validated (`node -c assets/js/zone-files.js`)
- [x] Manual testing completed
- [x] Accessibility features verified
- [x] Screenshot captured

## Related Issues

Closes #[issue-number] (if applicable)

## Manual Test Instructions

1. Navigate to the zone files management page
2. Click "Nouvelle zone" button
3. Enter a zone name with a space (e.g., "test zone")
4. Fill in filename (e.g., "test.zone")
5. Click "Créer"
6. Verify red error banner appears in modal
7. Verify modal stays open
8. Verify no browser popup appears
9. Correct the error (remove space)
10. Click "Créer" again
11. Verify banner clears and zone is created successfully

---

**Ready for review and testing** ✨
