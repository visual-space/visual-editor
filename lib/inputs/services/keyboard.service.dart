import 'package:flutter/services.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';

import '../../cursor/services/caret.service.dart';
import '../../editor/services/text-value.service.dart';
import '../../shared/state/editor.state.dart';
import '../../shared/utils/platform.utils.dart';
import 'input-connection.service.dart';

class KeyboardService {
  final _textConnectionService = TextConnectionService();
  final _caretService = CaretService();

  factory KeyboardService() => _instance;

  static final _instance = KeyboardService._privateConstructor();

  KeyboardService._privateConstructor();

  // TextValueService is provided via input to avoid circular reference issues.
  void initKeyboard(TextValueService _textValueService, EditorState state) {
    if (isKeyboardOS()) {
      state.keyboardVisible.setKeyboardVisible(true);
    } else {
      final editor = state.refs.editorState;

      // Treat iOS Simulator like a keyboard OS
      isIOSSimulator().then((isIosSimulator) {
        if (isIosSimulator) {
          state.keyboardVisible.setKeyboardVisible(true);
        } else {
          editor.keyboardVisibilityCtrl = KeyboardVisibilityController();
          state.keyboardVisible.setKeyboardVisible(
            editor.keyboardVisibilityCtrl!.isVisible,
          );

          editor.keyboardVisibilitySub =
              editor.keyboardVisibilityCtrl?.onChange.listen((visible) {
            state.keyboardVisible.setKeyboardVisible(visible);

            if (visible) {
              _textValueService.onChangeTextEditingValue(
                !state.refs.focusNode.hasFocus,
                state,
              );
            }
          });

          HardwareKeyboard.instance.addHandler(
            state.refs.editorState.hardwareKeyboardEvent,
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
  void requestKeyboard(EditorState state) {
    if (state.refs.focusNode.hasFocus) {
      _textConnectionService.openConnectionIfNeeded(state);
      _caretService.showCaretOnScreen(state);
    } else {
      state.refs.focusNode.requestFocus();
    }
  }

  // KeyboardVisibilityController only checks for keyboards that adjust the screen size.
  // Also watch for hardware keyboards that don't alter the screen (i.e. Chromebook, Android tablet
  // and any hardware keyboards from an OS not listed in isKeyboardOS()).
  // TextValueService is provided via input to avoid circular reference issues.
  bool hardwareKeyboardEvent(TextValueService _textValueService, EditorState state) {
    if (!state.keyboardVisible.isVisible) {
      // Hardware keyboard key pressed. Set visibility to true
      state.keyboardVisible.setKeyboardVisible(true);

      // Update the editor
      _textValueService.onChangeTextEditingValue(
        !state.refs.focusNode.hasFocus,
        state,
      );
    }

    // Remove the key handleR. It's no longer needed.
    // If KeyboardVisibilityController clears visibility, it wil also enable it when appropriate.
    HardwareKeyboard.instance.removeHandler(
      state.refs.editorState.hardwareKeyboardEvent,
    );

    // We didn't handle the event, just needed to know a key was pressed
    return false;
  }
}
