import 'dart:async';

import 'package:flutter/material.dart';

class LastTapDownState {
  factory LastTapDownState() => _instance;
  static final _instance = LastTapDownState._privateConstructor();

  LastTapDownState._privateConstructor();

  final _position$ = StreamController<Offset>.broadcast();
  late Offset _position;

  Stream<Offset> get lastTapDownPosition$ => _position$.stream;

  Offset? get position => _position;

  void setLastTapDown(Offset position) {
    _position = position;
    _position$.sink.add(position);
  }
}
