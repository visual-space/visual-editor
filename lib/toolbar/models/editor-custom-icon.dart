import 'package:flutter/material.dart';

// Defines the icon and behavior of an icon used in the buttons
class EditorCustomIcon {
  final IconData? icon;
  final VoidCallback? onTap;

  const EditorCustomIcon({
    this.icon,
    this.onTap,
  });
}
