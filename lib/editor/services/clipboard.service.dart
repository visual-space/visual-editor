import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../state/editor-config.state.dart';

class ClipboardService {
  final _editorConfigState = EditorConfigState();
  static final _instance = ClipboardService._privateConstructor();

  factory ClipboardService() => _instance;

  ClipboardService._privateConstructor();

  ToolbarOptions toolbarOptions() {
    final enable = _editorConfigState.config.enableInteractiveSelection;

    return ToolbarOptions(
      copy: enable,
      cut: enable,
      paste: enable,
      selectAll: enable,
    );
  }

  bool cutEnabled() =>
      toolbarOptions().cut && !_editorConfigState.config.readOnly;

  bool copyEnabled() => toolbarOptions().copy;

  bool pasteEnabled() =>
      toolbarOptions().paste && !_editorConfigState.config.readOnly;
}
