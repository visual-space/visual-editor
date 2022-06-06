import 'dart:async';

import 'package:flutter/material.dart';

class ScrollControllerState {
  factory ScrollControllerState() => _instance;
  static final _instance = ScrollControllerState._privateConstructor();

  ScrollControllerState._privateConstructor();

  final _controller$ = StreamController<ScrollController>.broadcast();
  late ScrollController _controller;

  Stream<ScrollController> get controller$ => _controller$.stream;

  ScrollController get controller => _controller;

  void setController(ScrollController controller) {
    _controller = controller;
    _controller$.sink.add(controller);
  }
}
