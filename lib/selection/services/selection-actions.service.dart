import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../controller/services/editor-text.service.dart';
import '../../controller/state/editor-controller.state.dart';
import '../../editor/state/editor-config.state.dart';
import '../../editor/state/editor-renderer.state.dart';
import '../../editor/state/editor-state-widget.state.dart';
import '../../editor/state/editor-widget.state.dart';
import '../../editor/state/focus-node.state.dart';
import '../../shared/utils/platform.utils.dart';
import '../controllers/selection-actions.controller.dart';

class SelectionActionsService {
  final _editorConfigState = EditorConfigState();
  final _editorStateWidgetState = EditorStateWidgetState();
  final _editorTextService = EditorTextService();
  final _editorRendererState = EditorRendererState();
  final _editorWidgetState = EditorWidgetState();
  final _editorControllerState = EditorControllerState();
  final _focusNodeState = FocusNodeState();

  // +++ REVIEW Controller? State? Merge?
  // +++ It seems to be always un undefined
  SelectionActionsController? selectionActions;

  static final _instance = SelectionActionsService._privateConstructor();

  factory SelectionActionsService() => _instance;

  SelectionActionsService._privateConstructor();

  // Shows the selection buttons at the location of the current cursor.
  // Returns `false` if a buttons couldn't be shown.
  // When the buttons is already shown, or when no text selection currently exists.
  // Web is using native dom elements to enable clipboard functionality of the buttons: copy, paste, select, cut.
  // It might also provide additional functionality depending on the browser (such as translate).
  // Due to this we should not show Flutter buttons for the editable text elements.
  bool showToolbar() {
    if (kIsWeb) {
      return false;
    }

    final hasSelection = selectionActions == null;
    final hasToolbarAlready = selectionActions!.toolbar != null;

    if (hasSelection || hasToolbarAlready) {
      return false;
    }

    selectionActions!.update(_editorStateWidgetState.editor.textEditingValue);
    selectionActions!.showToolbar();

    return true;
  }

  void hideToolbar([bool hideHandles = true]) {
    // If the buttons is currently visible.
    if (selectionActions?.toolbar != null) {
      hideHandles ? selectionActions?.hide() : selectionActions?.hideToolbar();
    }
  }

  void updateOrDisposeSelectionOverlayIfNeeded() {
    if (selectionActions != null) {
      if (!_focusNodeState.node.hasFocus ||
          _editorTextService.textEditingValue.selection.isCollapsed) {
        selectionActions!.dispose();
        selectionActions = null;
      } else {
        selectionActions!.update(
          _editorTextService.textEditingValue,
        );
      }

    } else if (_focusNodeState.node.hasFocus) {
      final editor = _editorStateWidgetState.editor;

      selectionActions = SelectionActionsController(
        value: _editorTextService.textEditingValue,
        debugRequiredFor: _editorWidgetState.editor,
        renderObject: _editorRendererState.renderer,
        textSelectionControls: _editorConfigState.config.textSelectionControls,
        selectionDelegate: editor,
        clipboardStatus: editor.clipboardStatus,
      );

      selectionActions!.handlesVisible = shouldShowSelectionHandles();
      selectionActions!.showHandles();
    }
  }

  bool shouldShowSelectionHandles() {
    final context = _editorStateWidgetState.editor.context;
    // Whether to show selection handles.
    // When a selection is active, there will be two handles at each side of boundary,
    // or one handle if the selection is collapsed.
    // The handles can be dragged to adjust the selection.
    final showSelectionHandles = isMobile(Theme.of(context).platform);

    return showSelectionHandles &&
        !_editorControllerState.controller.selection.isCollapsed;
  }
}
