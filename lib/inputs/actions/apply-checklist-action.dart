import 'package:flutter/cupertino.dart';

import '../../document/models/attributes/attributes-aliases.model.dart';
import '../../document/services/nodes/attribute.utils.dart';
import '../../shared/state/editor.state.dart';
import '../../styles/services/styles.service.dart';
import '../intents/apply-checklist.intent.dart';

// Used to transform a line of text into a check-list.
class ApplyCheckListAction extends Action<ApplyChecklistIntent> {
  late final StylesService _stylesService;

  final EditorState state;

  ApplyCheckListAction(this.state) {
    _stylesService = StylesService(state);
  }

  @override
  void invoke(ApplyChecklistIntent intent, [BuildContext? context]) {
    _stylesService.formatSelection(
      _stylesService.hasSelectionChecklistAttr() ? AttributeUtils.clone(AttributesAliasesM.unchecked, null) : AttributesAliasesM.unchecked,
    );
  }

  @override
  bool get isActionEnabled => true;
}
