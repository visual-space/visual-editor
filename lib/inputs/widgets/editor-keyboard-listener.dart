import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/pressed-keys-state.dart';
import 'keyboard-listener-provider.dart';

// Wraps the editor and connects it to the hardware keyboard.
// Creates a state class to store and stream keystrokes.
// Passes this class down the hierarchy to the widgets that need the keystrokes.
class EditorKeyboardListener extends StatefulWidget {
  const EditorKeyboardListener({
    required this.child,
    Key? key,
  }) : super(key: key);

  final Widget child;

  @override
  EditorKeyboardListenerState createState() => EditorKeyboardListenerState();
}

class EditorKeyboardListenerState extends State<EditorKeyboardListener> {
  final PressedKeysState _pressedKeys = PressedKeysState();

  @override
  void initState() {
    super.initState();
    _subscribeToKeystrokes();
    _emitPressedKeys();
  }

  @override
  void dispose() {
    _unsubscribeToKeystrokes();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PressedKeysStateProvider(
      pressedKeys: _pressedKeys,
      child: widget.child,
    );
  }

  // === PRIVATE ===

  void _subscribeToKeystrokes() {
    HardwareKeyboard.instance.addHandler(_emitPressedKeyHandler);
  }

  void _unsubscribeToKeystrokes() {
    HardwareKeyboard.instance.removeHandler(_emitPressedKeyHandler);
    _pressedKeys.dispose();
  }

  bool _emitPressedKeyHandler(KeyEvent event) {
    _emitPressedKeys();
    return false;
  }

  void _emitPressedKeys() {
    _pressedKeys.emitPressedKeys(
      HardwareKeyboard.instance.logicalKeysPressed,
    );
  }
}
