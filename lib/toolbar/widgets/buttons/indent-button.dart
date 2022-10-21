import 'package:flutter/material.dart';

import '../../../controller/controllers/editor-controller.dart';
import '../../../documents/models/attributes/attributes-aliases.model.dart';
import '../../../documents/models/attributes/attributes.model.dart';
import '../../../documents/services/attribute.utils.dart';
import '../../../shared/models/editor-icon-theme.model.dart';
import '../toolbar.dart';

class IndentButton extends StatefulWidget {
  final IconData icon;
  final double iconSize;
  final EditorController controller;
  // TODO enum
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
      onPressed: _indent,
    );
  }

  void _indent() {
    final indent = widget.controller
        .getSelectionStyle()
        .attributes?[AttributesM.indent.key];

    // No Styling
    if (indent == null) {
      if (widget.isIncrease) {
        widget.controller.formatSelection(AttributesAliasesM.indentL1);
      }
      return;
    }

    // Prevent decrease bellow 1
    if (indent.value == 1 && !widget.isIncrease) {
      widget.controller.formatSelection(
        AttributeUtils.clone(AttributesAliasesM.indentL1, null),
      );
      return;
    }

    // Increase
    if (widget.isIncrease) {
      widget.controller.formatSelection(
        AttributeUtils.getIndentLevel(indent.value + 1),
      );
      return;
    }

    // Decrease
    widget.controller.formatSelection(
      AttributeUtils.getIndentLevel(indent.value - 1),
    );
  }
}
