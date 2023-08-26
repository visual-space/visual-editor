import '../../document/models/attributes/attribute.model.dart';
import '../../shared/state/editor.state.dart';

class ToolbarService {
  final EditorState state;

  ToolbarService(this.state);

  // === TOGGLE STATES ===

  Map<String, AttributeM> getToolbarButtonToggler() => state.toolbar.buttonToggler;

  // === DISABLE STYLING OPTIONS ===

  bool get isStylingEnabled => state.toolbar.isStylingEnabled;

  void toggleStylingButtons(bool enabled) {
    state.toolbar.toggleStylingButtons(enabled);
  }
}
