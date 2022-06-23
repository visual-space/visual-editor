import 'package:flutter/services.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';

import '../../cursor/services/caret.service.dart';
import '../../editor/services/text-value.service.dart';
import '../../editor/state/editor-state-widget.state.dart';
import '../../editor/state/focus-node.state.dart';
import '../../shared/utils/platform.utils.dart';
import '../state/keyboard-visible.state.dart';
import 'input-connection.service.dart';

class KeyboardService {
  final _textConnectionService = TextConnectionService();
  final _focusNodeState = FocusNodeState();
  final _keyboardVisibleState = KeyboardVisibleState();
  final _editorStateWidgetState = EditorStateWidgetState();
  final _caretService = CaretService();

  factory KeyboardService() => _instance;

  static final _instance = KeyboardService._privateConstructor();

  KeyboardService._privateConstructor();

  // TextValueService is provided via input to avoid circular reference issues.
  void initKeyboard(TextValueService _textValueService) {
    if (isKeyboardOS()) {
      _keyboardVisibleState.setKeyboardVisible(true);
    } else {
      final editor = _editorStateWidgetState.editor;

      // Treat iOS Simulator like a keyboard OS
      isIOSSimulator().then((isIosSimulator) {
        if (isIosSimulator) {
          _keyboardVisibleState.setKeyboardVisible(true);
        } else {
          editor.keyboardVisibilityCtrl = KeyboardVisibilityController();
          _keyboardVisibleState.setKeyboardVisible(
            editor.keyboardVisibilityCtrl!.isVisible,
          );

          editor.keyboardVisibilitySub =
              editor.keyboardVisibilityCtrl?.onChange.listen((visible) {
            _keyboardVisibleState.setKeyboardVisible(visible);

            if (visible) {
              _textValueService.onChangeTextEditingValue(
                !_focusNodeState.node.hasFocus,
              );
            }
          });

          HardwareKeyboard.instance.addHandler(
            _editorStateWidgetState.editor.hardwareKeyboardEvent,
          );
        }
      });
    }
  }

  // Express interest in interacting with the keyboard.
  // If this control is already attached to the keyboard, this function will request that the keyboard become visible.
  // Otherwise, this function will ask the focus system that it become focused.
  // If successful in acquiring focus, the control will then attach to the keyboard and
  // request that the keyboard become visible.
  void requestKeyboard() {
    if (_focusNodeState.node.hasFocus) {
      _textConnectionService.openConnectionIfNeeded();
      _caretService.showCaretOnScreen();
    } else {
      _focusNodeState.node.requestFocus();
    }
  }

  // KeyboardVisibilityController only checks for keyboards that adjust the screen size.
  // Also watch for hardware keyboards that don't alter the screen (i.e. Chromebook, Android tablet
  // and any hardware keyboards from an OS not listed in isKeyboardOS()).
  // TextValueService is provided via input to avoid circular reference issues.
  bool hardwareKeyboardEvent(TextValueService _textValueService) {
    if (!_keyboardVisibleState.isVisible) {
      // Hardware keyboard key pressed. Set visibility to true
      _keyboardVisibleState.setKeyboardVisible(true);

      // Update the editor
      _textValueService.onChangeTextEditingValue(
        !_focusNodeState.node.hasFocus,
      );
    }

    // Remove the key handleR. It's no longer needed.
    // If KeyboardVisibilityController clears visibility, it wil also enable it when appropriate.
    HardwareKeyboard.instance.removeHandler(
      _editorStateWidgetState.editor.hardwareKeyboardEvent,
    );

    // We didn't handle the event, just needed to know a key was pressed
    return false;
  }
}
