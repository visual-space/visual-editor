import 'package:flutter/cupertino.dart';

import '../../document/services/nodes/attribute.utils.dart';
import '../../shared/state/editor.state.dart';
import '../../styles/services/styles.service.dart';
import '../intents/toggle-text-style.intent.dart';

// Toggles a text style (underline, bold, italic, strikethrough) on, or off.
class ToggleTextStyleAction extends Action<ToggleTextStyleIntent> {
  late final StylesService _stylesService;

  final EditorState state;

  ToggleTextStyleAction(this.state) {
    _stylesService = StylesService(state);
  }

  @override
  void invoke(ToggleTextStyleIntent intent, [BuildContext? context]) {
    _stylesService.formatSelection(
      // Checks whether the intent attribute is applied or not to the selection
      _stylesService.isAttributeToggledInSelection(intent.attribute)
          ? AttributeUtils.clone(intent.attribute, null)
          : intent.attribute,
    );
  }

  @override
  bool get isActionEnabled => true;
}
