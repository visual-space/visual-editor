import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../selection/services/selection-actions.logic.dart';
import '../widgets/editor-renderer.dart';
import '../widgets/raw-editor.dart';

// +++ DELETE
// Base interface for the editor state which defines contract used by various mixins.
abstract class EditorStateM extends State<RawEditor>
    implements TextSelectionDelegate {
  ScrollController get scrollController;

  EditorRenderer get renderEditor;

  SelectionActionsLogic? get selectionActions;

  // Controls the floating cursor animation when it is released.
  // The floating cursor is animated to merge with the regular cursor.
  AnimationController get floatingCursorResetController;

  // void requestKeyboard();
}
