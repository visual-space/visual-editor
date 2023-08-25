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
  bool isSelectionStylingEnabled = true;
  bool isSelectionImageEnabled = true;
  bool isSelectionIndentEnabled = true;
  bool isSelectionColorEnabled = true;
  bool isSelectionChecklistEnabled = true;
  bool isSelectionCameraEnabled = true;
  bool isSelectionVideoEnabled = true;
  bool isSelectionAlignmentEnabled = true;
  bool isSelectionHeaderEnabled = true;
  bool isSelectionDropdownEnabled = true;
}
