import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:tuple/tuple.dart';

import '../../documents/models/style.dart';
import '../../selection/services/editor-text-selection-overlay.utils.dart';
import '../widgets/editor-renderer.dart';
import '../widgets/raw-editor.dart';

// +++ DOC WHY
// Base interface for the editor state which defines contract used by various mixins.
abstract class EditorState extends State<RawEditor>
    implements TextSelectionDelegate {
  ScrollController get scrollController;

  RenderEditor get renderEditor;

  EditorTextSelectionOverlay? get selectionOverlay;

  List<Tuple2<int, Style>> get pasteStyle;

  String get pastePlainText;

  // Controls the floating cursor animation when it is released.
  // The floating cursor is animated to merge with the regular cursor.
  AnimationController get floatingCursorResetController;

  bool showToolbar();

  void requestKeyboard();
}
