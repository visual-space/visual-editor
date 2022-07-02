import 'package:flutter/material.dart';

class ExtendSelectionState {

  // === EXTEND SELECTION ===

  // Used on Desktop (mouse and keyboard enabled platforms) as base offset
  // for extending selection, either with combination of `Shift` + Click or by dragging.
  TextSelection? _origin;

  TextSelection? get origin => _origin;

  void setOrigin(TextSelection? origin) => _origin = origin;
}
