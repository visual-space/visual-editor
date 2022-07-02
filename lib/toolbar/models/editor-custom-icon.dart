import 'package:flutter/material.dart';

// Custom button to be displayed in the Editor Toolbar.
// It is displayed at the end of the button list.
class EditorCustomButton {
  final IconData? icon;
  final VoidCallback? onTap;

  const EditorCustomButton({
    this.icon,
    this.onTap,
  });
}
