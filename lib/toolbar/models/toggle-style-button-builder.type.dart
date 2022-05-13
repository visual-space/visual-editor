import 'package:flutter/material.dart';

import '../../documents/models/attribute.dart';
import '../../shared/models/quill-icon-theme.model.dart';

typedef ToggleStyleButtonBuilder = Widget Function(
  BuildContext context,
  Attribute attribute,
  IconData icon,
  Color? fillColor,
  bool? isToggled,
  VoidCallback? onPressed, [
  double iconSize,
  QuillIconThemeM? iconTheme,
]);
