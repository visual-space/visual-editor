import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../../documents/models/change-source.enum.dart';
import '../../documents/services/delta.utils.dart';
import '../../shared/state/editor.state.dart';

// Manages the connection to the input used by the platform (android, ios, or web html)
class InputConnectionService {
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
  bool shouldCreateInputConnection(EditorState state) =>
      kIsWeb || !state.editorConfig.config.readOnly;

  // Returns `true` if there is open input connection.
  bool get hasConnection =>
      _textInputConnection != null && _textInputConnection!.attached;

  // Start TextInputClient implementation
  TextEditingValue? get currentTextEditingValue =>
      _lastKnownRemoteTextEditingValue;

  // Autofill is not needed
  AutofillScope? get currentAutofillScope => null;

  static final _instance = InputConnectionService._privateConstructor();

  factory InputConnectionService() => _instance;

  InputConnectionService._privateConstructor();

  // Opens or closes input connection based on the current state of focusNode and value.
  void openOrCloseConnection(EditorState state) {
    final focusNode = state.refs.focusNode;

    if (focusNode.hasFocus && focusNode.consumeKeyboardToken()) {
      openConnectionIfNeeded(state);
    } else if (!focusNode.hasFocus) {
      closeConnectionIfNeeded();
    }
  }

  // Establishes a connection to the input used by the platform (android, ios)
  void openConnectionIfNeeded(EditorState state) {
    if (!shouldCreateInputConnection(state)) {
      return;
    }

    if (!hasConnection) {
      _lastKnownRemoteTextEditingValue =
          state.refs.editorController.plainTextEditingValue;
      _textInputConnection = TextInput.attach(
        state.refs.editorState,
        TextInputConfiguration(
          inputType: TextInputType.multiline,
          readOnly: state.editorConfig.config.readOnly,
          inputAction: TextInputAction.newline,
          enableSuggestions: state.editorConfig.config.readOnly,
          keyboardAppearance: state.editorConfig.config.keyboardAppearance,
          textCapitalization: state.editorConfig.config.textCapitalization,
        ),
      );

      _updateSizeAndTransform(state);
      _textInputConnection!.setEditingState(_lastKnownRemoteTextEditingValue!);
    }

    _textInputConnection!.show();
  }

  // Closes input connection if it's currently open.
  // Otherwise does nothing.
  void closeConnectionIfNeeded() {
    if (!hasConnection) {
      return;
    }

    _textInputConnection!.close();
    _textInputConnection = null;
    _lastKnownRemoteTextEditingValue = null;
  }

  // Updates remote value based on current state of document and selection.
  // This method may not actually send an update to native side if it thinks remote value is up to date or identical.
  void updateRemoteValueIfNeeded(EditorState state) {
    if (!hasConnection) {
      return;
    }

    final value = state.refs.editorController.plainTextEditingValue;

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

  void updateEditingValue(TextEditingValue value, EditorState state) {
    if (!shouldCreateInputConnection(state)) {
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
    final controller = state.refs.editorController;

    if (diff.deleted.isEmpty && diff.inserted.isEmpty) {
      controller.updateSelection(
        value.selection,
        ChangeSource.LOCAL,
      );
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

  void _updateSizeAndTransform(EditorState state) {
    if (hasConnection) {
      // Asking for editorRenderer.size here can cause errors if layout hasn't occurred yet.
      // So we schedule a post frame callback instead.
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (!state.refs.editorState.mounted) {
          return;
        }

        final size = state.refs.renderer.size;
        final transform = state.refs.renderer.getTransformTo(null);
        _textInputConnection?.setEditableSizeAndTransform(size, transform);
      });
    }
  }
}
