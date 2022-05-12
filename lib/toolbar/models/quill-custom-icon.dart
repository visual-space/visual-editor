import 'package:flutter/material.dart';

/// Defines the icon and behavior of an icon used in the buttons
class QuillCustomIcon {
  final IconData? icon;
  final VoidCallback? onTap;

  const QuillCustomIcon({
    this.icon,
    this.onTap,
  });
}
