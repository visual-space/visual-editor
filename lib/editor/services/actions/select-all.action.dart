import 'package:flutter/material.dart';

import '../../../controller/services/editor-text.service.dart';
import '../../state/editor-config.state.dart';

class SelectAllAction extends ContextAction<SelectAllTextIntent> {
  final _editorTextService = EditorTextService();
  final _editorConfigState = EditorConfigState();

  SelectAllAction();

  @override
  Object? invoke(SelectAllTextIntent intent, [BuildContext? context]) {
    return Actions.invoke(
      context!,
      UpdateSelectionIntent(
        _editorTextService.textEditingValue,
        TextSelection(
          baseOffset: 0,
          extentOffset: _editorTextService.textEditingValue.text.length,
        ),
        intent.cause,
      ),
    );
  }

  @override
  bool get isActionEnabled =>
      _editorConfigState.config.enableInteractiveSelection;
}
