import 'package:flutter/material.dart';

import '../../editor/services/editor.service.dart';
import '../../shared/state/editor.state.dart';

// Activated when user presses CTRL + A. Selects all the text inside a document.
class SelectAllAction extends ContextAction<SelectAllTextIntent> {
  late final EditorService _editorService;

  final EditorState state;

  SelectAllAction(this.state) {
    _editorService = EditorService(state);
  }

  @override
  Object? invoke(SelectAllTextIntent intent, [BuildContext? context]) {
    final plainText = _editorService.plainText;

    return Actions.invoke(
      context!,
      UpdateSelectionIntent(
        plainText,
        TextSelection(
          baseOffset: 0,
          extentOffset: plainText.text.length,
        ),
        intent.cause,
      ),
    );
  }

  @override
  bool get isActionEnabled => state.config.enableInteractiveSelection;
}
