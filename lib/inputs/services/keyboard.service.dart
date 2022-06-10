import 'package:flutter/services.dart';

import '../../editor/services/input-connection.service.dart';
import '../../editor/services/raw-editor.utils.dart';
import '../../editor/state/focus-node.state.dart';
import '../../editor/widgets/raw-editor.dart';
import '../state/keyboard-visible.state.dart';

class KeyboardService {
  final _textConnectionService = TextConnectionService();
  final _focusNodeState = FocusNodeState();
  final _keyboardVisibleState = KeyboardVisibleState();

  factory KeyboardService() => _instance;

  static final _instance = KeyboardService._privateConstructor();

  KeyboardService._privateConstructor();

  // Express interest in interacting with the keyboard.
  // If this control is already attached to the keyboard, this function will request that the keyboard become visible.
  // Otherwise, this function will ask the focus system that it become focused.
  // If successful in acquiring focus, the control will then attach to the keyboard and
  // request that the keyboard become visible.
  void requestKeyboard(RawEditorUtils _rawEditorUtils) {
    if (_focusNodeState.node.hasFocus) {
      _textConnectionService.openConnectionIfNeeded();
      _rawEditorUtils.showCaretOnScreen();
    } else {
      _focusNodeState.node.requestFocus();
    }
  }

  // KeyboardVisibilityController only checks for keyboards that adjust the screen size.
  // Also watch for hardware keyboards that don't alter the screen (i.e. Chromebook, Android tablet
  // and any hardware keyboards from an OS not listed in isKeyboardOS())
  bool hardwareKeyboardEvent(
    RawEditorState _rawEditorState,
    RawEditorUtils _rawEditorUtils,
  ) {
    if (!_keyboardVisibleState.isVisible) {
      // Hardware keyboard key pressed. Set visibility to true
      _keyboardVisibleState.setKeyboardVisible(true);

      // Update the editor
      _rawEditorUtils.onChangeTextEditingValue(!_focusNodeState.node.hasFocus);
    }

    // Remove the key handler - it's no longer needed.
    // If KeyboardVisibilityController clears visibility, it wil also enable it when appropriate.
    HardwareKeyboard.instance.removeHandler(
      _rawEditorState.hardwareKeyboardEvent,
    );

    // we didn't handle the event, just needed to know a key was pressed
    return false;
  }
}
