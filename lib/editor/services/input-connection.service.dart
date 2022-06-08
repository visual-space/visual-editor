import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../../controller/services/editor-controller.dart';
import '../../controller/services/editor-text.service.dart';
import '../../cursor/services/cursor.service.dart';
import '../../delta/services/delta.utils.dart';
import '../../documents/models/change-source.enum.dart';
import '../state/editor-config.state.dart';
import '../widgets/editor-renderer.dart';
import '../widgets/raw-editor.dart';
import 'editor-renderer.utils.dart';
import 'floating-cursor.service.dart';

class TextConnectionService {
  final _editorConfigState = EditorConfigState();
  final _editorRendererUtils = EditorRendererUtils();
  final _cursorService = CursorService();
  final _editorTextService = EditorTextService();
  final _floatingCursorService = FloatingCursorService();

  TextInputConnection? _textInputConnection;
  TextEditingValue? _lastKnownRemoteTextEditingValue;

  // Whether to create an input connection with the platform for text editing or not.
  // Read-only input fields do not need a connection with the platform since
  // there's no need for text editing capabilities (e.g. virtual keyboard).
  // On the web, we always need a connection because we want some browser
  // functionalities to continue to work on read-only input fields like:
  // - Relevant context menu.
  // - cmd/ctrl+c shortcut to copy.s
  // - cmd/ctrl+a to select all.
  // - Changing the selection using a physical keyboard.
  bool get shouldCreateInputConnection =>
      kIsWeb || !_editorConfigState.config.readOnly;

  // Returns `true` if there is open input connection.
  bool get hasConnection =>
      _textInputConnection != null && _textInputConnection!.attached;

  // Start TextInputClient implementation
  TextEditingValue? get currentTextEditingValue =>
      _lastKnownRemoteTextEditingValue;

  // Autofill is not needed
  AutofillScope? get currentAutofillScope => null;

  // The time it takes for the floating cursor to snap to the text aligned
  // cursor position after the user has finished placing it.
  static const Duration _floatingCursorResetTime = Duration(milliseconds: 125);

  // The original position of the caret on FloatingCursorDragState.start.
  Rect? _startCaretRect;

  // The most recent text position as determined by the location of the floating cursor.
  TextPosition? _lastTextPosition;

  // The offset of the floating cursor as determined from the start call.
  Offset? _pointOffsetOrigin;

  // The most recent position of the floating cursor.
  Offset? _lastBoundedOffset;

  static final _instance = TextConnectionService._privateConstructor();

  factory TextConnectionService() => _instance;

  TextConnectionService._privateConstructor();

  // Opens or closes input connection based on the current state of
  // [focusNode] and [value].
  void openOrCloseConnection(
    EditorRenderer editorRenderer,
    FocusNode focusNode,
    RawEditorState editorState,
    bool mounted,
  ) {
    if (focusNode.hasFocus && focusNode.consumeKeyboardToken()) {
      openConnectionIfNeeded(editorRenderer, editorState, mounted);
    } else if (!focusNode.hasFocus) {
      closeConnectionIfNeeded();
    }
  }

  void openConnectionIfNeeded(
    EditorRenderer editorRenderer,
    RawEditorState editorState,
    bool mounted,
  ) {
    if (!shouldCreateInputConnection) {
      return;
    }

    if (!hasConnection) {
      _lastKnownRemoteTextEditingValue = _editorTextService.textEditingValue;
      _textInputConnection = TextInput.attach(
        editorState,
        TextInputConfiguration(
          inputType: TextInputType.multiline,
          readOnly: _editorConfigState.config.readOnly,
          inputAction: TextInputAction.newline,
          enableSuggestions: _editorConfigState.config.readOnly,
          keyboardAppearance: _editorConfigState.config.keyboardAppearance,
          textCapitalization: _editorConfigState.config.textCapitalization,
        ),
      );

      _updateSizeAndTransform(editorRenderer, mounted);
      _textInputConnection!.setEditingState(_lastKnownRemoteTextEditingValue!);
    }

    _textInputConnection!.show();
  }

  // Closes input connection if it's currently open. Otherwise does nothing.
  void closeConnectionIfNeeded() {
    if (!hasConnection) {
      return;
    }

    _textInputConnection!.close();
    _textInputConnection = null;
    _lastKnownRemoteTextEditingValue = null;
  }

  // Updates remote value based on current state of [document] and [selection].
  // This method may not actually send an update to native side if it thinks remote value is up to date or identical.
  void updateRemoteValueIfNeeded() {
    if (!hasConnection) {
      return;
    }

    final value = _editorTextService.textEditingValue;

    // Since we don't keep track of the composing range in value provided by the Controller
    // we need to add it here manually before comparing with the last known remote value.
    // It is important to prevent excessive remote updates as it can cause race conditions.
    final actualValue = value.copyWith(
      composing: _lastKnownRemoteTextEditingValue!.composing,
    );

    if (actualValue == _lastKnownRemoteTextEditingValue) {
      return;
    }

    _lastKnownRemoteTextEditingValue = actualValue;
    _textInputConnection!.setEditingState(
      // Set composing to (-1, -1), otherwise an exception will be thrown if the values are different.
      actualValue.copyWith(composing: const TextRange(start: -1, end: -1)),
    );
  }

  void updateEditingValue(TextEditingValue value, EditorController controller) {
    if (!shouldCreateInputConnection) {
      return;
    }

    if (_lastKnownRemoteTextEditingValue == value) {
      // There is no difference between this value and the last known value.
      return;
    }

    // Check if only composing range changed.
    if (_lastKnownRemoteTextEditingValue!.text == value.text &&
        _lastKnownRemoteTextEditingValue!.selection == value.selection) {
      // This update only modifies composing range. Since we don't keep track
      // of composing range we just need to update last known value here.
      // This check fixes an issue on Android when it sends composing updates separately
      // from regular changes for text and selection.
      _lastKnownRemoteTextEditingValue = value;
      return;
    }

    final effectiveLastKnownValue = _lastKnownRemoteTextEditingValue!;
    _lastKnownRemoteTextEditingValue = value;
    final oldText = effectiveLastKnownValue.text;
    final text = value.text;
    final cursorPosition = value.selection.extentOffset;
    final diff = getDiff(oldText, text, cursorPosition);

    if (diff.deleted.isEmpty && diff.inserted.isEmpty) {
      controller.updateSelection(value.selection, ChangeSource.LOCAL);
    } else {
      controller.replaceText(
        diff.start,
        diff.deleted.length,
        diff.inserted,
        value.selection,
      );
    }
  }

  void updateFloatingCursor(
    RawFloatingCursorPoint point,
    EditorRenderer editorRenderer,
    AnimationController floatingCursorResetController,
  ) {
    switch (point.state) {
      case FloatingCursorDragState.Start:
        if (floatingCursorResetController.isAnimating) {
          floatingCursorResetController.stop();
          onFloatingCursorResetTick(
            editorRenderer,
            floatingCursorResetController,
          );
        }

        // We want to send in points that are centered around a (0,0) origin, so we cache the position.
        _pointOffsetOrigin = point.offset;

        final currentTextPosition = TextPosition(
          offset: editorRenderer.selection.baseOffset,
        );
        _startCaretRect = _cursorService.getLocalRectForCaret(
          currentTextPosition,
          editorRenderer,
        );

        _lastBoundedOffset = _startCaretRect!.center -
            _floatingCursorOffset(currentTextPosition, editorRenderer);
        _lastTextPosition = currentTextPosition;

        _floatingCursorService.setFloatingCursor(
          point.state,
          _lastBoundedOffset!,
          _lastTextPosition!,
          editorRenderer,
        );
        break;

      case FloatingCursorDragState.Update:
        assert(_lastTextPosition != null, 'Last text position was not set');
        final floatingCursorOffset = _floatingCursorOffset(
          _lastTextPosition!,
          editorRenderer,
        );
        final centeredPoint = point.offset! - _pointOffsetOrigin!;
        final rawCursorOffset =
            _startCaretRect!.center + centeredPoint - floatingCursorOffset;

        final preferredLineHeight = _editorRendererUtils.preferredLineHeight(
          _lastTextPosition!,
          editorRenderer,
        );
        _lastBoundedOffset =
            _floatingCursorService.calculateBoundedFloatingCursorOffset(
          rawCursorOffset,
          preferredLineHeight,
          editorRenderer,
        );
        _lastTextPosition = _editorRendererUtils.getPositionForOffset(
          editorRenderer.localToGlobal(
            _lastBoundedOffset! + floatingCursorOffset,
          ),
          editorRenderer,
        );
        _floatingCursorService.setFloatingCursor(
          point.state,
          _lastBoundedOffset!,
          _lastTextPosition!,
          editorRenderer,
        );

        final newSelection = TextSelection.collapsed(
          offset: _lastTextPosition!.offset,
          affinity: _lastTextPosition!.affinity,
        );

        // Setting selection as floating cursor moves will have scroll view
        // bring background cursor into view
        editorRenderer.onSelectionChanged(
          newSelection,
          SelectionChangedCause.forcePress,
        );
        break;

      case FloatingCursorDragState.End:
        // We skip animation if no update has happened.
        if (_lastTextPosition != null && _lastBoundedOffset != null) {
          floatingCursorResetController
            ..value = 0.0
            ..animateTo(
              1,
              duration: _floatingCursorResetTime,
              curve: Curves.decelerate,
            );
        }
        break;
    }
  }

  // Specifies the floating cursor dimensions and position based the animation controller value.
  // The floating cursor is resized (see [RenderAbstractEditor.setFloatingCursor]) and repositioned
  // (linear interpolation between position of floating cursor and current position of background cursor)
  void onFloatingCursorResetTick(
    EditorRenderer editorRenderer,
    AnimationController floatingCursorResetController,
  ) {
    final finalPosition = _cursorService
            .getLocalRectForCaret(_lastTextPosition!, editorRenderer)
            .centerLeft -
        _floatingCursorOffset(_lastTextPosition!, editorRenderer);

    if (floatingCursorResetController.isCompleted) {
      _floatingCursorService.setFloatingCursor(
        FloatingCursorDragState.End,
        finalPosition,
        _lastTextPosition!,
        editorRenderer,
      );
      _startCaretRect = null;
      _lastTextPosition = null;
      _pointOffsetOrigin = null;
      _lastBoundedOffset = null;
    } else {
      final lerpValue = floatingCursorResetController.value;
      final lerpX = lerpDouble(
        _lastBoundedOffset!.dx,
        finalPosition.dx,
        lerpValue,
      )!;
      final lerpY = lerpDouble(
        _lastBoundedOffset!.dy,
        finalPosition.dy,
        lerpValue,
      )!;

      _floatingCursorService.setFloatingCursor(
        FloatingCursorDragState.Update,
        Offset(lerpX, lerpY),
        _lastTextPosition!,
        editorRenderer,
        resetLerpValue: lerpValue,
      );
    }
  }

  void connectionClosed() {
    if (!hasConnection) {
      return;
    }

    _textInputConnection!.connectionClosedReceived();
    _textInputConnection = null;
    _lastKnownRemoteTextEditingValue = null;
  }

  // === PRIVATE ===

  // Because the center of the cursor is preferredLineHeight / 2 below the touch origin,
  // but the touch origin is used to determine which line the cursor is on,
  // we need this offset to correctly render and move the cursor.
  Offset _floatingCursorOffset(
    TextPosition textPosition,
    EditorRenderer editorRenderer,
  ) =>
      Offset(
        0,
        _editorRendererUtils.preferredLineHeight(
              textPosition,
              editorRenderer,
            ) /
            2,
      );

  void _updateSizeAndTransform(EditorRenderer editorRenderer, bool mounted) {
    if (hasConnection) {
      // Asking for editorRenderer.size here can cause errors if layout hasn't occurred yet.
      // So we schedule a post frame callback instead.
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }

        final size = editorRenderer.size;
        final transform = editorRenderer.getTransformTo(null);
        _textInputConnection?.setEditableSizeAndTransform(size, transform);
      });
    }
  }
}
