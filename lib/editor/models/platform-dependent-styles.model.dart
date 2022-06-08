import 'package:flutter/material.dart';

import 'cursor-style-cfg.model.dart';

// Configures the style of the editor based on the detected platform.
@immutable
class PlatformDependentStylesM {
  final TextSelectionControls textSelectionControls;
  final Color selectionColor;
  final CursorStyleCfgM cursorStyle;

  const PlatformDependentStylesM({
    required this.textSelectionControls,
    required this.selectionColor,
    required this.cursorStyle,
  });
}
