// Toolbar buttons can be disabled in different contexts.
// For example: When selection is inside a code block or inline code,
// we are disabling the styling, and most of the buttons, thus we should also indicate in the toolbar
// that the styling buttons are disabled by changing their color to a more opaque one.
// We need to store the state of the disabled buttons in order to manipulate/access it in multiple places.
// For example, when selection changes or formatSelection is triggered.
// Also, based on selection attrs other buttons can be disabled too,
// like indentation, images, video, etc.
// Buttons can be disabled by the categories they are added inside the toolbar.
// For example: ToggleStyleButton, ImageButton, VideoButton, etc.
class DisabledButtonsState {
  // Selection styling buttons.
  bool isSelectionStylingEnabled = true;

  // Selection image button.
  bool isSelectionImageEnabled = true;

  // Selection indent button.
  bool isSelectionIndentEnabled = true;

  // Selection color button.
  bool isSelectionColorEnabled = true;

  // Selection checklist button.
  bool isSelectionChecklistEnabled = true;

  // Selection camera button.
  bool isSelectionCameraEnabled = true;

  // Selection video button.
  bool isSelectionVideoEnabled = true;

  // Selection alignment button.
  bool isSelectionAlignmentEnabled = true;

  // Selection header button.
  bool isSelectionHeaderEnabled = true;

  // Selection dropdown button.
  bool isSelectionDropdownEnabled = true;
}
