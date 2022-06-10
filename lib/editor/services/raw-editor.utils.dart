import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';

import '../../controller/services/editor-text.service.dart';
import '../../controller/state/editor-controller.state.dart';
import '../../controller/state/scroll-controller.state.dart';
import '../../cursor/services/cursor.service.dart';
import '../../cursor/state/cursor-controller.state.dart';
import '../../documents/models/change-source.enum.dart';
import '../../inputs/services/keyboard.service.dart';
import '../../inputs/state/keyboard-visible.state.dart';
import '../../selection/services/selection-actions.logic.dart';
import '../../selection/services/selection-actions.service.dart';
import '../../shared/utils/platform.utils.dart';
import '../state/editor-config.state.dart';
import '../state/editor-renderer.state.dart';
import '../state/focus-node.state.dart';
import '../state/raw-editor-swidget.state.dart';
import '../state/raw-editor-widget.state.dart';
import '../state/scrollControllerAnimation.state.dart';
import 'input-connection.service.dart';
import 'keyboard-actions.service.dart';

// +++ Rename to DocumentUtils
class RawEditorUtils {
  final _textConnectionService = TextConnectionService();
  final _selectionActionsService = SelectionActionsService();
  final _editorTextService = EditorTextService();
  final _cursorService = CursorService();
  final _editorControllerState = EditorControllerState();
  final _editorRendererState = EditorRendererState();
  final _scrollControllerState = ScrollControllerState();
  final _cursorControllerState = CursorControllerState();
  final _editorConfigState = EditorConfigState();
  final _focusNodeState = FocusNodeState();
  final _rawEditorSWidgetState = RawEditorSWidgetState();
  final _rawEditorWidgetState = RawEditorWidgetState();
  final _keyboardService = KeyboardService();
  final _keyboardActionsService = KeyboardActionsService();
  final _keyboardVisibleState = KeyboardVisibleState();
  final _scrollControllerAnimationState = ScrollControllerAnimationState();

  bool _showCaretOnScreenScheduled = false;

  static final _instance = RawEditorUtils._privateConstructor();

  factory RawEditorUtils() => _instance;

  RawEditorUtils._privateConstructor();

  void handleSelectionChanged(
    TextSelection selection,
    SelectionChangedCause cause,
  ) {
    final oldSelection = _editorControllerState.controller.selection;

    _editorControllerState.controller.updateSelection(
      selection,
      ChangeSource.LOCAL,
    );
    _selectionActionsService.selectionActions?.handlesVisible =
        shouldShowSelectionHandles();

    if (!_keyboardVisibleState.isVisible) {
      // This will show the keyboard for all selection changes on the editor,
      // not just changes triggered by user gestures.
      _keyboardService.requestKeyboard(this);
    }

    if (cause == SelectionChangedCause.drag) {
      // When user updates the selection while dragging make sure to bring
      // the updated position (base or extent) into view.
      if (oldSelection.baseOffset != selection.baseOffset) {
        _cursorService.bringIntoView(selection.base);
      } else if (oldSelection.extentOffset != selection.extentOffset) {
        _cursorService.bringIntoView(selection.extent);
      }
    }
  }

  void showCaretOnScreen() {
    if (!_editorConfigState.config.showCursor || _showCaretOnScreenScheduled) {
      return;
    }

    _showCaretOnScreenScheduled = true;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (_editorConfigState.config.scrollable ||
          _scrollControllerState.controller.hasClients) {
        _showCaretOnScreenScheduled = false;
        final renderer = _editorRendererState.renderer;

        if (!_rawEditorSWidgetState.editor.mounted) {
          return;
        }

        final viewport = RenderAbstractViewport.of(renderer);
        final editorOffset = renderer.localToGlobal(
          const Offset(0, 0),
          ancestor: viewport,
        );
        final offsetInViewport =
            _scrollControllerState.controller.offset + editorOffset.dy;

        final offset = renderer.getOffsetToRevealCursor(
          _scrollControllerState.controller.position.viewportDimension,
          _scrollControllerState.controller.offset,
          offsetInViewport,
        );

        if (offset != null) {
          if (_scrollControllerAnimationState.disabled) {
            _scrollControllerAnimationState.disableAnimationOnce(false);
            return;
          }
          _scrollControllerState.controller.animateTo(
            math.min(
              offset,
              _scrollControllerState.controller.position.maxScrollExtent,
            ),
            duration: const Duration(milliseconds: 100),
            curve: Curves.fastOutSlowIn,
          );
        }
      }
    });
  }

  void handleFocusChanged() {
    _textConnectionService.openOrCloseConnection();
    _cursorControllerState.controller.startOrStopCursorTimerIfNeeded(
      _editorControllerState.controller.selection,
    );
    _updateOrDisposeSelectionOverlayIfNeeded();

    if (_focusNodeState.node.hasFocus) {
      WidgetsBinding.instance.addObserver(
        _rawEditorSWidgetState.editor,
      );
      showCaretOnScreen();
    } else {
      WidgetsBinding.instance.removeObserver(
        _rawEditorSWidgetState.editor,
      );
    }

    _rawEditorSWidgetState.editor.safeUpdateKeepAlive();
  }

  void onChangeTextEditingValue(
    bool ignoreCaret,
  ) {
    _textConnectionService.updateRemoteValueIfNeeded();

    if (ignoreCaret) {
      return;
    }

    showCaretOnScreen();
    _cursorControllerState.controller.startOrStopCursorTimerIfNeeded(
      _editorControllerState.controller.selection,
    );

    if (_textConnectionService.hasConnection) {
      // To keep the cursor from blinking while typing, we want to restart the
      // cursor timer every time a new character is typed.
      _cursorControllerState.controller
        ..stopCursorTimer(resetCharTicks: false)
        ..startCursorTimer();
    }

    // Refresh selection overlay after the build step had a chance to
    // update and register all children of RenderEditor.
    // Otherwise this will fail in situations where a new line of text is entered, which adds a new RenderEditableBox child.
    // If we try to update selection overlay immediately it'll not be able to find
    // the new child since it hasn't been built yet.
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!_rawEditorSWidgetState.editor.mounted) {
        return;
      }
      _updateOrDisposeSelectionOverlayIfNeeded();
    });

    if (_rawEditorSWidgetState.editor.mounted) {
      _rawEditorSWidgetState.editor.refresh();
    }
  }

  bool shouldShowSelectionHandles() {
    final context = _rawEditorSWidgetState.editor.context;
    // Whether to show selection handles.
    // When a selection is active, there will be two handles at each side of boundary,
    // or one handle if the selection is collapsed.
    // The handles can be dragged to adjust the selection.
    final showSelectionHandles = isMobile(Theme.of(context).platform);

    return showSelectionHandles &&
        !_editorControllerState.controller.selection.isCollapsed;
  }

  void didChangeTextEditingValue([bool ignoreFocus = false]) {
    if (kIsWeb) {
      onChangeTextEditingValue(ignoreFocus);
      if (!ignoreFocus) {
        _keyboardService.requestKeyboard(this);
      }
      return;
    }

    if (ignoreFocus || _keyboardVisibleState.isVisible) {
      onChangeTextEditingValue(ignoreFocus);
    } else {
      _keyboardService.requestKeyboard(this);
      if (_rawEditorSWidgetState.editor.mounted) {
        _rawEditorSWidgetState.editor.refresh();
      }
    }

    _keyboardActionsService
        .getAdjacentLineAction()
        .stopCurrentVerticalRunIfSelectionChanges();
  }

  // === PRIVATE ===

  void _updateOrDisposeSelectionOverlayIfNeeded() {
    if (_selectionActionsService.selectionActions != null) {
      if (!_focusNodeState.node.hasFocus ||
          _editorTextService.textEditingValue.selection.isCollapsed) {
        _selectionActionsService.selectionActions!.dispose();
        _selectionActionsService.selectionActions = null;
      } else {
        _selectionActionsService.selectionActions!.update(
          _editorTextService.textEditingValue,
        );
      }
    } else if (_focusNodeState.node.hasFocus) {
      final editor = _rawEditorSWidgetState.editor;
      _selectionActionsService.selectionActions = SelectionActionsLogic(
        value: _editorTextService.textEditingValue,
        debugRequiredFor: _rawEditorWidgetState.editor,
        toolbarLayerLink: editor.toolbarLayerLink,
        startHandleLayerLink: editor.startHandleLayerLink,
        endHandleLayerLink: editor.endHandleLayerLink,
        renderObject: _editorRendererState.renderer,
        textSelectionControls: _editorConfigState.config.textSelectionControls,
        selectionDelegate: editor,
        clipboardStatus: editor.clipboardStatus,
      );

      _selectionActionsService.selectionActions!.handlesVisible =
          shouldShowSelectionHandles();
      _selectionActionsService.selectionActions!.showHandles();
    }
  }
}
