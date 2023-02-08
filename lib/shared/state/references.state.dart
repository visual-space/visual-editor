import 'package:flutter/material.dart';

import '../../controller/controllers/editor-controller.dart';
import '../../cursor/controllers/cursor.controller.dart';
import '../../document/controllers/document.controller.dart';
import '../../document/controllers/history.controller.dart';
import '../../editor/widgets/editor-textarea-renderer.dart';
import '../../embeds/controllers/embed-builder.controller.dart';
import '../../inputs/controllers/update-text-selection-to-adjiacent-line.action.dart';
import '../../main.dart';

// Caches references to different internal classes (widgets, renderers)
// We are forced to operate in this fashion due to the Flutter API.
// The VisualEditor and the EditorRenderer have overrides imposed by Flutter.
// Often times we need these overrides to be invoked from other classes.
// To avoid excess prop drilling we cached these references in a dedicated state object.
// Also we need convenient access to the ScrollController and FocusNode.
class ReferencesState {
  // Controllers
  late EditorController controller;
  late DocumentController documentController;
  late HistoryController historyController;
  late EmbedBuilderController embedBuilderController;
  late ScrollController scrollController;
  late CursorController cursorController;

  // Cache the prev instance of the controller to be able to
  // dispose of it after the new instance was created.
  // Full explanation in state-store.md
  CursorController? oldCursorController;
  bool cursorControllerInitialised = false;

  // Mix
  late FocusNode focusNode;
  late VisualEditorState widget;
  late EditorTextAreaRenderer renderer;
  UpdateTextSelectionToAdjacentLineAction<ExtendSelectionVerticallyToAdjacentLineIntent>? adjacentLineAction;
}
