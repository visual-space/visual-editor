import 'package:flutter/material.dart';

import '../../state/editor-config.state.dart';
import '../../widgets/raw-editor.dart';

// +++ DOC
class SelectAllAction extends ContextAction<SelectAllTextIntent> {
  final _editorConfigState = EditorConfigState();

  SelectAllAction(this.state);

  final RawEditorState state;

  @override
  Object? invoke(SelectAllTextIntent intent, [BuildContext? context]) {
    return Actions.invoke(
      context!,
      UpdateSelectionIntent(
        state.textEditingValue,
        TextSelection(
          baseOffset: 0,
          extentOffset: state.textEditingValue.text.length,
        ),
        intent.cause,
      ),
    );
  }

  @override
  bool get isActionEnabled =>
      _editorConfigState.config.enableInteractiveSelection;
}
