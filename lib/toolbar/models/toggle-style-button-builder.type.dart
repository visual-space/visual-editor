import 'package:flutter/material.dart';

import '../../documents/models/attribute.model.dart';
import '../../shared/models/editor-icon-theme.model.dart';

typedef ToggleStyleButtonBuilder = Widget Function(
  BuildContext context,
  AttributeM attribute,
  IconData icon,
  double buttonsSpacing,
  Color? fillColor,
  bool? isToggled,
  VoidCallback? onPressed, [
  double iconSize,
  EditorIconThemeM? iconTheme,
]);
