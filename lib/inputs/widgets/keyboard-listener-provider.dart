import 'package:flutter/material.dart';

import '../services/pressed-keys-state.dart';

// Provides the pressedKeys down the widgets tree to the widgets listening for keys (text lines)
// Will be replaced by a far simpler mechanism (a simple stream in a singleton)
class PressedKeysStateProvider extends InheritedWidget {
  const PressedKeysStateProvider({
    required this.pressedKeys,
    required Widget child,
    Key? key,
  }) : super(key: key, child: child);

  final PressedKeysState pressedKeys;

  @override
  bool updateShouldNotify(covariant PressedKeysStateProvider oldWidget) {
    return false;
    // Seems to always return false
    // return oldWidget.pressedKeys != pressedKeys;
  }
}
