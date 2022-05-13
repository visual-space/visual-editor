import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../widgets/keyboard-listener-provider.dart';

// Stores the keystrokes and provides a stream of keystrokes.
class PressedKeysState extends ChangeNotifier {
  static PressedKeysState of(BuildContext context) {
    final widget =
        context.dependOnInheritedWidgetOfExactType<PressedKeysStateProvider>();
    return widget!.pressedKeys;
  }

  bool _metaPressed = false;
  bool _controlPressed = false;

  bool get metaPressed => _metaPressed;

  bool get controlPressed => _controlPressed;

  // Emits only when the modifier keys are pressed or released
  void emitPressedKeys(Set<LogicalKeyboardKey> pressedKeys) {
    final meta = _isMetaPressed(pressedKeys);
    final control = _isControlPressed(pressedKeys);

    if (_metaPressed != meta || _controlPressed != control) {
      _metaPressed = meta;
      _controlPressed = control;
      notifyListeners();
    }
  }

  bool _isControlPressed(Set<LogicalKeyboardKey> pressedKeys) {
    return pressedKeys.contains(LogicalKeyboardKey.controlLeft) ||
        pressedKeys.contains(LogicalKeyboardKey.controlRight);
  }

  bool _isMetaPressed(Set<LogicalKeyboardKey> pressedKeys) {
    return pressedKeys.contains(LogicalKeyboardKey.metaLeft) ||
        pressedKeys.contains(LogicalKeyboardKey.metaRight);
  }
}
