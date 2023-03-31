import 'package:flutter/material.dart';

import '../../editor/services/editor.service.dart';
import '../../selection/services/selection-handles.service.dart';
import '../../shared/state/editor.state.dart';
import '../services/clipboard.service.dart';

class CopySelectionAction extends ContextAction<CopySelectionTextIntent> {
  late final EditorService _editorService;
  late final ClipboardService _clipboardService;
  late final SelectionHandlesService _selectionHandlesService;

  final EditorState state;

  CopySelectionAction(this.state) {
    _editorService = EditorService(state);
    _clipboardService = ClipboardService(state);
  }

  @override
  void invoke(CopySelectionTextIntent intent, [BuildContext? context]) {
    if (intent.collapseSelection) {
      _clipboardService.cutSelection(
        intent.cause,
        _selectionHandlesService.hideToolbar,
      );
    } else {
      _clipboardService.copySelection(intent.cause);
    }
  }

  @override
  bool get isActionEnabled {
    final selection = _editorService.plainText.selection;

    return selection.isValid && !selection.isCollapsed;
  }
}
