import 'package:flutter/material.dart';

import '../../../controller/controllers/editor-controller.dart';
import '../../../documents/models/attribute.model.dart';
import '../../../shared/models/editor-icon-theme.model.dart';
import '../toolbar.dart';

class IndentButton extends StatefulWidget {
  final IconData icon;
  final double iconSize;
  final EditorController controller;
  final bool isIncrease;
  final EditorIconThemeM? iconTheme;
  final double buttonsSpacing;

  const IndentButton({
    required this.icon,
    required this.controller,
    required this.buttonsSpacing,
    required this.isIncrease,
    this.iconSize = defaultIconSize,
    this.iconTheme,
    Key? key,
  }) : super(key: key);

  @override
  _IndentButtonState createState() => _IndentButtonState();
}

class _IndentButtonState extends State<IndentButton> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final iconColor =
        widget.iconTheme?.iconUnselectedColor ?? theme.iconTheme.color;
    final iconFillColor =
        widget.iconTheme?.iconUnselectedFillColor ?? theme.canvasColor;
    return IconBtn(
      highlightElevation: 0,
      hoverElevation: 0,
      size: widget.iconSize * 1.77,
      icon: Icon(
        widget.icon,
        size: widget.iconSize,
        color: iconColor,
      ),
      buttonsSpacing: widget.buttonsSpacing,
      fillColor: iconFillColor,
      borderRadius: widget.iconTheme?.borderRadius ?? 2,
      onPressed: () {
        final indent = widget.controller
            .getSelectionStyle()
            .attributes[AttributeM.indent.key];
        if (indent == null) {
          if (widget.isIncrease) {
            widget.controller.formatSelection(AttributeM.indentL1);
          }
          return;
        }
        if (indent.value == 1 && !widget.isIncrease) {
          widget.controller.formatSelection(
            AttributeM.clone(AttributeM.indentL1, null),
          );
          return;
        }
        if (widget.isIncrease) {
          widget.controller.formatSelection(
            AttributeM.getIndentLevel(indent.value + 1),
          );
          return;
        }
        widget.controller
            .formatSelection(AttributeM.getIndentLevel(indent.value - 1));
      },
    );
  }
}
