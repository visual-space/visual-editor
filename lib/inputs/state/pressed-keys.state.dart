import 'dart:async';

import 'package:flutter/services.dart';

// Stores the keystrokes and provides a stream of keystrokes.
class PressedKeysState {
  factory PressedKeysState() => _instance;
  static final _instance = PressedKeysState._privateConstructor();

  PressedKeysState._privateConstructor();

  late Set<LogicalKeyboardKey> _pressedKeys;
  bool _metaPressed = false;
  bool _controlPressed = false;

  final _pressedKeys$ = StreamController<Set<LogicalKeyboardKey>>.broadcast();

  Stream<Set<LogicalKeyboardKey>> get pressedKeys$ => _pressedKeys$.stream;

  bool get metaPressed => _metaPressed;

  bool get controlPressed => _controlPressed;

  Set<LogicalKeyboardKey> get pressedKeys => _pressedKeys;

  // Emits only when the modifier keys are pressed or released
  void emitPressedKeys(Set<LogicalKeyboardKey> pressedKeys) {
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
