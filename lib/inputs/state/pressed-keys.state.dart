import 'dart:async';

import 'package:flutter/services.dart';

// Stores the keystrokes and provides a stream of keystrokes.
// (!) WARNING This state is not used to stream the keystrokes to the document itself.
// The document gets updates from the remote input via the InputConnectionService (Read inputs.md).
// This state is used for other needs such as figuring out if meta keys are pressed (ex: when ctrl clicking links).
class PressedKeysState {
  late Set<LogicalKeyboardKey> _pressedKeys;
  bool _metaPressed = false;
  bool _controlPressed = false;

  final _pressedKeys$ = StreamController<Set<LogicalKeyboardKey>>.broadcast();

  Stream<Set<LogicalKeyboardKey>> get pressedKeys$ => _pressedKeys$.stream;

  bool get metaPressed => _metaPressed;

  bool get controlPressed => _controlPressed;

  Set<LogicalKeyboardKey> get pressedKeys => _pressedKeys;

  // Emits only when the modifier keys are pressed or released
  void setPressedKeys(Set<LogicalKeyboardKey> pressedKeys) {
    final meta = _isMetaPressed(pressedKeys);
    final control = _isControlPressed(pressedKeys);

    if (_metaPressed != meta || _controlPressed != control) {
      _metaPressed = meta;
      _controlPressed = control;
      _pressedKeys = pressedKeys;
      _pressedKeys$.sink.add(pressedKeys);
    }
  }

  // === PRIVATE ===

  bool _isControlPressed(Set<LogicalKeyboardKey> pressedKeys) {
    return pressedKeys.contains(LogicalKeyboardKey.controlLeft) ||
        pressedKeys.contains(LogicalKeyboardKey.controlRight);
  }

  bool _isMetaPressed(Set<LogicalKeyboardKey> pressedKeys) {
    return pressedKeys.contains(LogicalKeyboardKey.metaLeft) ||
        pressedKeys.contains(LogicalKeyboardKey.metaRight);
  }
}
