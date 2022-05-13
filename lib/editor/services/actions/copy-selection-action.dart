import 'package:flutter/material.dart';

import '../../widgets/raw-editor.dart';

// +++ DOC
class CopySelectionAction extends ContextAction<CopySelectionTextIntent> {
  CopySelectionAction(this.state);

  final RawEditorState state;

  @override
  void invoke(CopySelectionTextIntent intent, [BuildContext? context]) {
    if (intent.collapseSelection) {
      state.cutSelection(intent.cause);
    } else {
      state.copySelection(intent.cause);
    }
  }

  @override
  bool get isActionEnabled =>
      state.textEditingValue.selection.isValid &&
      !state.textEditingValue.selection.isCollapsed;
}
