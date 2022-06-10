import '../services/cursor.controller.dart';

class CursorControllerState {
  factory CursorControllerState() => _instance;
  static final _instance = CursorControllerState._privateConstructor();

  CursorControllerState._privateConstructor();

  late CursorController _controller;

  CursorController get controller => _controller;

  void setController(CursorController controller) {
    _controller = controller;
  }
}
