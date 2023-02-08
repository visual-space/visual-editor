import '../../document/models/attributes/attribute.model.dart';
import '../../shared/state/editor.state.dart';

// Not much here for now
class ToolbarService {
  final EditorState state;

  ToolbarService(this.state);

  Map<String, AttributeM> getToolbarButtonToggler() {
    return state.toolbar.buttonToggler;
  }
}
