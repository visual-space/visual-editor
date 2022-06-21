
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../../controller/services/editor-text.service.dart';
import '../../controller/state/editor-controller.state.dart';
import '../../delta/services/delta.utils.dart';
import '../../documents/models/change-source.enum.dart';
import '../../editor/state/editor-config.state.dart';
import '../../editor/state/editor-renderer.state.dart';
import '../../editor/state/editor-state-widget.state.dart';
import '../../editor/state/focus-node.state.dart';

class TextConnectionService {
  final _editorConfigState = EditorConfigState();
  final _editorControllerState = EditorControllerState();
  final _focusNodeState = FocusNodeState();
  final _editorRendererState = EditorRendererState();
  final _editorTextService = EditorTextService();
  final _editorStateWidgetState = EditorStateWidgetState();

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

  static final _instance = TextConnectionService._privateConstructor();

  factory TextConnectionService() => _instance;

  TextConnectionService._privateConstructor();

  // Opens or closes input connection based on the current state of
  // [focusNode] and [value].
  void openOrCloseConnection() {
    final focusNode = _focusNodeState.node;

    if (focusNode.hasFocus && focusNode.consumeKeyboardToken()) {
      openConnectionIfNeeded();
    } else if (!focusNode.hasFocus) {
      closeConnectionIfNeeded();
    }
  }

  void openConnectionIfNeeded() {
    if (!shouldCreateInputConnection) {
      return;
    }

    if (!hasConnection) {
      _lastKnownRemoteTextEditingValue = _editorTextService.textEditingValue;
      _textInputConnection = TextInput.attach(
        _editorStateWidgetState.editor,
        TextInputConfiguration(
          inputType: TextInputType.multiline,
          readOnly: _editorConfigState.config.readOnly,
          inputAction: TextInputAction.newline,
          enableSuggestions: _editorConfigState.config.readOnly,
          keyboardAppearance: _editorConfigState.config.keyboardAppearance,
          textCapitalization: _editorConfigState.config.textCapitalization,
        ),
      );

      _updateSizeAndTransform();
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
      // Set composing to (-1, -1).
      // Otherwise an exception will be thrown if the values are different.
      actualValue.copyWith(
        composing: const TextRange(
          start: -1,
          end: -1,
        ),
      ),
    );
  }

  void updateEditingValue(TextEditingValue value) {
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
    final controller = _editorControllerState.controller;

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

  void connectionClosed() {
    if (!hasConnection) {
      return;
    }

    _textInputConnection!.connectionClosedReceived();
    _textInputConnection = null;
    _lastKnownRemoteTextEditingValue = null;
  }

  // === PRIVATE ===

  void _updateSizeAndTransform() {
    if (hasConnection) {
      // Asking for editorRenderer.size here can cause errors if layout hasn't occurred yet.
      // So we schedule a post frame callback instead.
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (!_editorStateWidgetState.editor.mounted) {
          return;
        }

        final size = _editorRendererState.renderer.size;
        final transform = _editorRendererState.renderer.getTransformTo(null);
        _textInputConnection?.setEditableSizeAndTransform(size, transform);
      });
    }
  }
}
