import 'package:flutter/material.dart';

import '../../../../shared/models/editor-icon-theme.model.dart';
import '../../toolbar.dart';

// A generic toggle button with styles can be overridden (color and fill).
// If no callback is provided the button is considered disabled and renders as so.
// ignore: must_be_immutable
class ToggleButton extends StatelessWidget {
  final BuildContext context;
  final IconData icon;
  final double buttonsSpacing;
  final Color? fillColor;
  final bool? isToggled;
  final VoidCallback? onPressed;
  final double iconSize;
  final EditorIconThemeM? iconTheme;
  late ThemeData _theme;

  ToggleButton({
    required this.context,
    required this.icon,
    required this.buttonsSpacing,
    this.fillColor,
    this.isToggled,
    this.onPressed,
    this.iconSize = defaultIconSize,
    this.iconTheme,
  });

  @override
  Widget build(BuildContext context) {
    _theme = Theme.of(context);
    final isEnabled = onPressed != null;
    final iconColor = isEnabled ? _getToggleColor() : _getDisableToggleColor();
    final fill = isEnabled ? _getFillColor() : _getDisabledFillColor();

    return IconBtn(
      highlightElevation: 0,
      hoverElevation: 0,
      buttonsSpacing: buttonsSpacing,
      size: iconSize * iconButtonFactor,
      icon: Icon(
        icon,
        size: iconSize,
        color: iconColor,
      ),
      fillColor: fill,
      onPressed: onPressed,
      borderRadius: iconTheme?.borderRadius ?? 2,
    );
  }

  // === UTILS ===

  Color? _getToggleColor() => isToggled == true
      ? (iconTheme?.iconSelectedColor ?? _theme.primaryIconTheme.color)
      : (iconTheme?.iconUnselectedColor ?? _theme.iconTheme.color);

  Color _getDisableToggleColor() =>
      iconTheme?.disabledIconColor ?? _theme.disabledColor;

  Color _getFillColor() => isToggled == true
      ? (iconTheme?.iconSelectedFillColor ?? _theme.colorScheme.secondary)
      : (iconTheme?.iconUnselectedFillColor ?? _theme.canvasColor);

  Color _getDisabledFillColor() =>
      iconTheme?.disabledIconFillColor ?? (fillColor ?? _theme.canvasColor);
}
