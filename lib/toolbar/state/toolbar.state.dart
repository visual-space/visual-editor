import '../../document/models/attributes/attribute.model.dart';

class ToolbarState {

  // Notify buttons directly with attributes.
  // TODO Research and better document this feature
  Map<String, AttributeM> buttonToggler = {};

  // When selection is inside a code block or inline code, the styling buttons are disabled.
  bool isStylingEnabled = true;

  void toggleStylingButtons(bool enabled) {
    isStylingEnabled = enabled;
  }
}