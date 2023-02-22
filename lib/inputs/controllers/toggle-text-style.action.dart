import 'package:flutter/cupertino.dart';

import '../../document/models/attributes/attribute.model.dart';
import '../../document/models/attributes/attributes.model.dart';
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

  bool _isStyleActive(AttributeM styleAttr, Map<String, AttributeM> attrs) {
    if (styleAttr.key == AttributesM.list.key) {
      final attribute = attrs[styleAttr.key];
      if (attribute == null) {
        return false;
      }
      return attribute.value == styleAttr.value;
    }
    return attrs.containsKey(styleAttr.key);
  }

  @override
  void invoke(ToggleTextStyleIntent intent, [BuildContext? context]) {
    final isActive = _isStyleActive(
      intent.attribute,
      _stylesService.getSelectionStyle().attributes,
    );

    state.refs.controller.formatSelection(
      isActive
          ? AttributeUtils.clone(intent.attribute, null)
          : intent.attribute,
    );
  }

  @override
  bool get isActionEnabled => true;
}
