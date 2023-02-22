import 'package:flutter/cupertino.dart';

import '../../document/models/attributes/attributes-aliases.model.dart';
import '../../document/models/attributes/attributes.model.dart';
import '../../document/services/nodes/attribute.utils.dart';
import '../../shared/state/editor.state.dart';
import '../../styles/services/styles.service.dart';
import '../../toolbar/services/toolbar.service.dart';
import '../intents/apply-checklist.intent.dart';

class ApplyCheckListAction extends Action<ApplyChecklistIntent> {
  late final StylesService _stylesService;
  late final ToolbarService _toolbarService;

  final EditorState state;

  ApplyCheckListAction(this.state) {
    _stylesService = StylesService(state);
    _toolbarService = ToolbarService(state);
  }

  bool _getIsToggled() {
    final attrs = _stylesService
        .getSelectionStyle()
        .attributes;
    var attribute = _toolbarService.getToolbarButtonToggler()[AttributesM.list
        .key];

    if (attribute == null) {
      attribute = attrs[AttributesM.list.key];
    } else {
      // checkbox tapping causes controller.selection to go to offset 0
      _toolbarService.getToolbarButtonToggler().remove(AttributesM.list.key);
    }

    if (attribute == null) {
      return false;
    }

    return attribute.value == AttributesAliasesM.unchecked.value ||
        attribute.value == AttributesAliasesM.checked.value;
  }

  @override
  void invoke(ApplyChecklistIntent intent, [BuildContext? context]) {
    state.refs.controller.formatSelection(_getIsToggled()
        ? AttributeUtils.clone(AttributesAliasesM.unchecked, null)
        : AttributesAliasesM.unchecked);
  }

  @override
  bool get isActionEnabled => true;
}
