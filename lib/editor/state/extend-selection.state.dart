import 'package:flutter/material.dart';

// Used on Desktop (mouse and keyboard enabled platforms) as base offset
// for extending selection, either with combination of `Shift` + Click or by dragging
class ExtendSelectionState {
  factory ExtendSelectionState() => _instance;
  static final _instance = ExtendSelectionState._privateConstructor();

  ExtendSelectionState._privateConstructor();

  TextSelection? _origin;

  TextSelection? get origin => _origin;

  void setOrigin(TextSelection? origin) => _origin = origin;
}
