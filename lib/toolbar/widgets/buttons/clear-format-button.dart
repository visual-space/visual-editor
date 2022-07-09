import 'package:flutter/material.dart';

import '../../../controller/controllers/editor-controller.dart';
import '../../../documents/models/attribute.model.dart';
import '../../../shared/models/editor-icon-theme.model.dart';
import '../toolbar.dart';

class ClearFormatButton extends StatefulWidget {
  final IconData icon;
  final double iconSize;
  final EditorController controller;
  final EditorIconThemeM? iconTheme;
  final double buttonsSpacing;

  const ClearFormatButton({
    required this.icon,
    required this.buttonsSpacing,
    required this.controller,
    this.iconSize = defaultIconSize,
    this.iconTheme,
    Key? key,
  }) : super(key: key);

  @override
  _ClearFormatButtonState createState() => _ClearFormatButtonState();
}

class _ClearFormatButtonState extends State<ClearFormatButton> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconColor =
        widget.iconTheme?.iconUnselectedColor ?? theme.iconTheme.color;
    final fillColor =
        widget.iconTheme?.iconUnselectedFillColor ?? theme.canvasColor;
    return IconBtn(
        highlightElevation: 0,
        hoverElevation: 0,
        size: widget.iconSize * iconButtonFactor,
        icon: Icon(
          widget.icon,
          size: widget.iconSize,
          color: iconColor,
        ),
        buttonsSpacing: widget.buttonsSpacing,
        fillColor: fillColor,
        borderRadius: widget.iconTheme?.borderRadius ?? 2,
        onPressed: () {
          final attrs = <AttributeM>{};
          for (final style in widget.controller.getAllSelectionStyles()) {
            for (final attr in style.attributes.values) {
              attrs.add(attr);
            }
          }
          for (final attr in attrs) {
            widget.controller.formatSelection(
              AttributeM.clone(attr, null),
            );
          }
        });
  }
}
