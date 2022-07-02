import 'package:flutter/material.dart';

import '../../shared/state/editor.state.dart';

class SelectAllAction extends ContextAction<SelectAllTextIntent> {
  final EditorState state;

  SelectAllAction(
    this.state,
  );

  @override
  Object? invoke(SelectAllTextIntent intent, [BuildContext? context]) {
    return Actions.invoke(
      context!,
      UpdateSelectionIntent(
        state.refs.editorController.plainTextEditingValue,
        TextSelection(
          baseOffset: 0,
          extentOffset:
              state.refs.editorController.plainTextEditingValue.text.length,
        ),
        intent.cause,
      ),
    );
  }

  @override
  bool get isActionEnabled =>
      state.editorConfig.config.enableInteractiveSelection;
}
