import 'dart:async';

class KeyboardService {

  // +++ Get rid of this improvisation
  final requestKeyboard$ = StreamController<void>.broadcast();

  factory KeyboardService() => _instance;

  static final _instance = KeyboardService._privateConstructor();

  KeyboardService._privateConstructor();

  // +++ Use the original method and split it in services.
  // Express interest in interacting with the keyboard.
  // If this control is already attached to the keyboard, this function will request that the keyboard become visible.
  // Otherwise, this function will ask the focus system that it become focused.
  // If successful in acquiring focus, the control will then attach to the keyboard and
  // request that the keyboard become visible.
  void requestKeyboard() {
    requestKeyboard$.add(null);
  }
}
