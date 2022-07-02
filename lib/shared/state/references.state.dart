import 'package:flutter/material.dart';

import '../../controller/controllers/editor-controller.dart';
import '../../cursor/controllers/cursor.controller.dart';
import '../../editor/widgets/editor-renderer-inner.dart';
import '../../main.dart';

// References to the various widgets that compose the editor.
// We are forced to operate in this fashion due to the Flutter API.
// Many of these classes have overrides over base class methods.
// Often times we need these overrides to be invoked from other classes.
// To avoid excess prop drilling we cached these references in a dedicated state object.
class ReferencesState {
  // === EDITOR CONTROLLER ===

  late EditorController _editorController;

  EditorController get editorController => _editorController;

  void setEditorController(EditorController controller) {
    _editorController = controller;
  }

  // === SCROLL CONTROLLER ===

  late ScrollController _scrollController;

  ScrollController get scrollController => _scrollController;

  void setScrollController(ScrollController controller) {
    _scrollController = controller;
  }

  // === CURSOR CONTROLLER ===

  late CursorController _cursorController;

  CursorController get cursorController => _cursorController;

  void setCursorController(CursorController controller) {
    _cursorController = controller;
  }

  // === EDITOR WIDGET ===

  late VisualEditor _editorWidget;

  VisualEditor get editor => _editorWidget;

  void setEditor(VisualEditor editor) => _editorWidget = editor;

  // === EDITOR STATE WIDGET ===

  late VisualEditorState _editorWidgetState;

  VisualEditorState get editorState => _editorWidgetState;

  void setEditorState(VisualEditorState editor) => _editorWidgetState = editor;

  // === EDITOR RENDERER ===

  late EditorRendererInner _renderer;

  EditorRendererInner get renderer => _renderer;

  void setRenderer(EditorRendererInner renderer) => _renderer = renderer;

  // === FOCUS NODE ===

  late FocusNode _focusNode;

  FocusNode get focusNode => _focusNode;

  void setFocusNode(FocusNode node) => _focusNode = node;
}
