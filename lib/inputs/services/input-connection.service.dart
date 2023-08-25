import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../../document/models/history/change-source.enum.dart';
import '../../document/services/delta.utils.dart';
import '../../editor/services/editor.service.dart';
import '../../selection/services/selection.service.dart';
import '../../shared/state/editor.state.dart';

// When a user start typing, new characters are inserted by the remote input.
// The remote input is the input used by the system to synchronize the content of the input
// with the state of the software keyboard or other input devices.
// The remote input stores only plain text.
// The actual rich text is stored in the editor state store as a DocumentM.
// This services handles the connection to the input used by the platform (android, ios, or web html).
// Establishes a TextInputConnection between the system's text input and a TextInputClient.
class InputConnectionService {
  final _du = DeltaUtils();

  final EditorState state;

  InputConnectionService(this.state);

  // === UPDATE DOCUMENT MODEL ===

  // Check if we need to connect to the remote input (if readonly it's not needed).
  // Compares the old cached plain text state with the new one
  // Computes the diff between old and new plain text and applies
  // the delta to the document model ( text or selection).
  void diffPlainTextAndUpdateDocumentModel(
    TextEditingValue plainText,
    UpdateSelectionCallback updateSelection,
    ReplaceTextCallback replace,
    bool emitEvent,
  ) {
    if (!shouldCreateInputConnection()) {
      return;
    }

    final _prevPlainText = state.input.prevPlainText;

    if (_prevPlainText == plainText) {
      // There is no difference between this value and the last known value.
      return;
    }

    // Check if only composing range changed.
    // TODO The old comments don't explain what a composing range is. Provide explanation.
    final textAndSelectionUnchanged = _prevPlainText.text == plainText.text &&
        _prevPlainText.selection == plainText.selection;

    if (textAndSelectionUnchanged) {
      // This update only modifies composing range.
      // Since we don't keep track of composing range we just need to update last known value here.
      // This check fixes an issue on Android when it sends composing updates
      // separately from regular changes for text and selection.
      state.input.prevPlainText = plainText;

      return;
    }

    // Compute text deltas between prev remote input value and
    // current remote value then update the document model.
    final prevText = _prevPlainText.text;
    state.input.prevPlainText = plainText;
    final text = plainText.text;
    final cursorPosition = plainText.selection.extentOffset;
    final diff = _du.getDiff(prevText, text, cursorPosition);

    // Update Selection
    if (diff.deleted.isEmpty && diff.inserted.isEmpty) {
      updateSelection(plainText.selection, ChangeSource.LOCAL);

      // Replace Text
    } else {
      replace(
        diff.start,
        diff.deleted.length,
        diff.inserted,
        plainText.selection,
        emitEvent: emitEvent,
      );
    }
  }

  // === MANAGE REMOTE INPUT CONNECTION ===

  // Whether to create an input connection with the platform for text editing or not.
  // Read-only input fields do not need a connection with the platform since
  // there's no need for text editing capabilities (e.g. virtual keyboard).
  // On the web, we always need a connection because we want some browser
  // functionalities to continue to work on read-only input fields like:
  // - Relevant context menu.
  // - cmd/ctrl+c shortcut to copy.s
  // - cmd/ctrl+a to select all.
  // - Changing the selection using a physical keyboard.
  bool shouldCreateInputConnection() {
    return kIsWeb || !state.config.readOnly;
  }

  // Returns `true` if there is open input connection.
  bool get hasConnection {
    return _textInputConnection != null && _textInputConnection!.attached;
  }

  // Start TextInputClient implementation
  TextEditingValue? get currentTextEditingValue {
    return state.input.prevPlainText;
  }

  // Autofill is not needed
  AutofillScope? get currentAutofillScope {
    return null;
  }

  // Opens or closes input connection based on the current state of focusNode and value.
  void openOrCloseConnection(TextEditingValue plainText) {
    final focusNode = state.refs.focusNode;

    if (focusNode.hasFocus && focusNode.consumeKeyboardToken()) {
      openConnectionIfNeeded(plainText);
    } else if (!focusNode.hasFocus) {
      closeConnectionIfNeeded();
    }
  }

  // Establishes a connection to the input used by the platform (android, ios)
  void openConnectionIfNeeded(TextEditingValue plainText) {
    if (!shouldCreateInputConnection()) {
      return;
    }

    if (!hasConnection) {
      state.input.prevPlainText = plainText;
      _textInputConnection = TextInput.attach(
        state.refs.widget,
        TextInputConfiguration(
          inputType: TextInputType.multiline,
          readOnly: state.config.readOnly,
          inputAction: TextInputAction.newline,
          enableSuggestions: state.config.readOnly,
          keyboardAppearance: state.config.keyboardAppearance,
          textCapitalization: state.config.textCapitalization,
        ),
      );

      _updateSizeAndTransform();
      _textInputConnection!.setEditingState(state.input.prevPlainText);
    }

    _textInputConnection!.show();
  }

  // Updates remote value based on current state of document and selection.
  // This method may not actually send an update to native side if it thinks remote value is up to date or identical.
  void updateRemoteValueIfNeeded(TextEditingValue plainText) {
    if (!hasConnection) {
      return;
    }

    // Since we don't keep track of the composing range in value provided by the Controller
    // we need to add it here manually before comparing with the last known remote value.
    // It is important to prevent excessive remote updates as it can cause race conditions.
    final newPlainText = plainText.copyWith(
      composing: state.input.prevPlainText.composing,
    );

    if (newPlainText == state.input.prevPlainText) {
      return;
    }

    state.input.prevPlainText = newPlainText;

    _textInputConnection!.setEditingState(
      // Set composing to (-1, -1).
      // Otherwise an exception will be thrown if the values are different.
      newPlainText.copyWith(
        composing: const TextRange(
          start: -1,
          end: -1,
        ),
      ),
    );
  }

  // Closes input connection if it's currently open.
  // Otherwise does nothing.
  // TODO Merge these 2 methods in a generic method
  void closeConnectionIfNeeded() {
    if (!hasConnection) {
      return;
    }

    _textInputConnection!.close();
    _textInputConnection = null;
    state.input.prevPlainText = TextEditingValue();
  }

  void connectionClosed() {
    if (!hasConnection) {
      return;
    }

    _textInputConnection!.connectionClosedReceived();
    _textInputConnection = null;
    state.input.prevPlainText = TextEditingValue();
  }

  // === PRIVATE ===

  TextInputConnection? get _textInputConnection {
    return state.input.textInputConnection;
  }

  set _textInputConnection(TextInputConnection? connection) {
    state.input.textInputConnection = connection;
  }

  void _updateSizeAndTransform() {
    if (hasConnection) {
      // Asking for editorRenderer.size here can cause errors if layout hasn't occurred yet.
      // So we schedule a post frame callback instead.
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (!state.refs.widget.mounted) {
          return;
        }

        final size = state.refs.renderer.size;
        final transform = state.refs.renderer.getTransformTo(null);
        _textInputConnection?.setEditableSizeAndTransform(size, transform);
      });
    }
  }
}
