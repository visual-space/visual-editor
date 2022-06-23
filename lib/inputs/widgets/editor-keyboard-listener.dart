import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../state/pressed-keys.state.dart';

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
  final _pressedKeysState = PressedKeysState();

  @override
  void initState() {
    super.initState();
    _subscribeToKeystrokes();
  }

  @override
  void dispose() {
    _unsubscribeToKeystrokes();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;

  // === PRIVATE ===

  void _subscribeToKeystrokes() {
    HardwareKeyboard.instance.addHandler(_emitPressedKeyHandler);
  }

  void _unsubscribeToKeystrokes() {
    HardwareKeyboard.instance.removeHandler(_emitPressedKeyHandler);
  }

  bool _emitPressedKeyHandler(KeyEvent event) {
    _pressedKeysState.emitPressedKeys(
      HardwareKeyboard.instance.logicalKeysPressed,
    );

    return false;
  }

}
