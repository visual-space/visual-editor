import 'package:flutter/material.dart';

import '../../shared/state/editor.state.dart';
import '../services/clipboard.service.dart';

class CopySelectionAction extends ContextAction<CopySelectionTextIntent> {
  final _clipboardService = ClipboardService();

  final EditorState state;

  CopySelectionAction(this.state);

  @override
  void invoke(CopySelectionTextIntent intent, [BuildContext? context]) {
    if (intent.collapseSelection) {
      _clipboardService.cutSelection(intent.cause, state);
    } else {
      _clipboardService.copySelection(intent.cause, state);
    }
  }

  @override
  bool get isActionEnabled =>
      state.refs.editorController.plainTextEditingValue.selection.isValid &&
      !state.refs.editorController.plainTextEditingValue.selection.isCollapsed;
}
