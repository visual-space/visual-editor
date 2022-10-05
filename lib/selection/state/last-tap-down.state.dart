import 'package:flutter/material.dart';

// TODO Merge into selection state
class LastTapDownState {
  late Offset _position;

  Offset? get position => _position;

  void setLastTapDown(Offset position) {
    _position = position;
  }
}
