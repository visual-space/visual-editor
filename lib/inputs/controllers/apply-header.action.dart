import 'package:flutter/cupertino.dart';

import '../../document/models/attributes/attribute.model.dart';
import '../../document/models/attributes/attributes.model.dart';
import '../../shared/state/editor.state.dart';
import '../../styles/services/styles.service.dart';
import '../../toolbar/services/toolbar.service.dart';
import '../intents/apply-header.intent.dart';

class ApplyHeaderAction extends Action<ApplyHeaderIntent> {
  late final ToolbarService _toolbarService;
  late final StylesService _stylesService;

  final EditorState state;

  ApplyHeaderAction(this.state) {
    _toolbarService = ToolbarService(state);
    _stylesService = StylesService(state);
  }

  AttributeM<dynamic> _getHeaderValue() {
    final attr = _toolbarService.getToolbarButtonToggler()[AttributesM.header.key];
    if (attr != null) {
      // Checkbox tapping causes controller.selection to go to offset 0
      _toolbarService.getToolbarButtonToggler().remove(AttributesM.header.key);
      return attr;
    }
    return _stylesService.getSelectionStyle().attributes[AttributesM.header.key] ??
        AttributesM.header;
  }

  @override
  void invoke(ApplyHeaderIntent intent, [BuildContext? context]) {
    final _attribute =
        _getHeaderValue() == intent.header ? AttributesM.header : intent.header;
    state.refs.controller.formatSelection(_attribute);
  }

  @override
  bool get isActionEnabled => true;
}
