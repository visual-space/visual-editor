import 'package:flutter/material.dart';

import '../../../controller/services/editor-text.service.dart';
import '../../../controller/state/editor-controller.state.dart';
import '../clipboard.service.dart';

// +++ DOC
class CopySelectionAction extends ContextAction<CopySelectionTextIntent> {
  final _editorTextService = EditorTextService();
  final _clipboardService = ClipboardService();
  final _editorControllerState = EditorControllerState();

  CopySelectionAction();

  @override
  void invoke(CopySelectionTextIntent intent, [BuildContext? context]) {
    if (intent.collapseSelection) {
      _clipboardService.cutSelection(
        intent.cause,
        _editorControllerState.controller,
      );
    } else {
      _clipboardService.copySelection(
        intent.cause,
        _editorControllerState.controller,
      );
    }
  }

  @override
  bool get isActionEnabled =>
      _editorTextService.textEditingValue.selection.isValid &&
      !_editorTextService.textEditingValue.selection.isCollapsed;
}
