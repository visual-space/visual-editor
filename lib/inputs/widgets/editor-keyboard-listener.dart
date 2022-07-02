import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../shared/state/editor.state.dart';

// Wraps the editor and connects it to the hardware keyboard.
// Creates a state class to store and stream keystrokes.
// Passes this class down the hierarchy to the widgets that need the keystrokes.
// ignore: must_be_immutable
class EditorKeyboardListener extends StatefulWidget {

  // Used internally to retrieve the state from the EditorController instance to which this button is linked to.
  // Can't be accessed publicly (by design) to avoid exposing the internals of the library.
  late EditorState _state;

  void setState(EditorState state) {
    _state = state;
  }

  EditorKeyboardListener({
    required this.child,
    required EditorState state,
    Key? key,
  }) : super(key: key) {
    setState(state);
  }

  final Widget child;

  @override
  EditorKeyboardListenerState createState() => EditorKeyboardListenerState();
}

class EditorKeyboardListenerState extends State<EditorKeyboardListener> {

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
    widget._state.pressedKeys.emitPressedKeys(
      HardwareKeyboard.instance.logicalKeysPressed,
    );

    return false;
  }
}
