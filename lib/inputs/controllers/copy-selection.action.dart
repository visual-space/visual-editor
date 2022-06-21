import 'package:flutter/material.dart';

import '../../controller/services/editor-text.service.dart';
import '../services/clipboard.service.dart';

class CopySelectionAction extends ContextAction<CopySelectionTextIntent> {
  final _editorTextService = EditorTextService();
  final _clipboardService = ClipboardService();

  CopySelectionAction();

  @override
  void invoke(CopySelectionTextIntent intent, [BuildContext? context]) {
    if (intent.collapseSelection) {
      _clipboardService.cutSelection(intent.cause);
    } else {
      _clipboardService.copySelection(intent.cause);
    }
  }

  @override
  bool get isActionEnabled =>
      _editorTextService.textEditingValue.selection.isValid &&
      !_editorTextService.textEditingValue.selection.isCollapsed;
}
