import 'package:flutter/material.dart';

class LastTapDownState {
  factory LastTapDownState() => _instance;
  static final _instance = LastTapDownState._privateConstructor();

  LastTapDownState._privateConstructor();

  late Offset _position;

  Offset? get position => _position;

  void setLastTapDown(Offset position) {
    _position = position;
  }
}
