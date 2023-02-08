import 'package:flutter/material.dart';

import '../../controller/controllers/editor-controller.dart';
import '../../cursor/controllers/cursor.controller.dart';
import '../../document/controllers/document.controller.dart';
import '../../document/controllers/history.controller.dart';
import '../../editor/widgets/editor-textarea-renderer.dart';
import '../../embeds/controllers/embed-builder.controller.dart';
import '../../inputs/actions/update-text-selection-to-adjiacent-line.action.dart';
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
  late EmbedBuilderController embedBuilderController;
  late ScrollController scrollController;

  // Toolbar initialises eagerly, way sooner than this controller is available
  late DocumentController documentController;
  bool documentControllerInitialised = false;

  // Toolbar initialises eagerly, way sooner than this controller is available
  late HistoryController historyController;
  bool historyControllerInitialised = false;

  // Cache the prev instance of the controller to be able to
  // dispose of it after the new instance was created.
  // Full explanation in state-store.md
  late CursorController cursorController;
  CursorController? oldCursorController;
  bool cursorControllerInitialised = false;

  late OverlayEntry overlayEntry;

  // Mix
  late FocusNode focusNode;
  late VisualEditorState widget;
  late EditorTextAreaRenderer renderer;
  UpdateTextSelectionToAdjacentLineAction<ExtendSelectionVerticallyToAdjacentLineIntent>? adjacentLineAction;
}
