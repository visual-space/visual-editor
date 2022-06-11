import 'package:flutter/material.dart';

import '../../../controller/services/editor-controller.dart';
import '../../../documents/models/attribute.model.dart';
import '../../../documents/models/style.model.dart';
import '../../../shared/models/editor-icon-theme.model.dart';
import '../../models/toggle-style-button-builder.type.dart';
import '../toolbar.dart';

class ToggleStyleButton extends StatefulWidget {
  final AttributeM attribute;
  final IconData icon;
  final double iconSize;
  final Color? fillColor;
  final EditorController controller;
  final ToggleStyleButtonBuilder childBuilder;
  final EditorIconThemeM? iconTheme;

  const ToggleStyleButton({
    required this.attribute,
    required this.icon,
    required this.controller,
    this.iconSize = defaultIconSize,
    this.fillColor,
    this.childBuilder = defaultToggleStyleButtonBuilder,
    this.iconTheme,
    Key? key,
  }) : super(key: key);

  @override
  _ToggleStyleButtonState createState() => _ToggleStyleButtonState();
}

class _ToggleStyleButtonState extends State<ToggleStyleButton> {
  bool? _isToggled;

  StyleM get _selectionStyle => widget.controller.getSelectionStyle();

  @override
  void initState() {
    super.initState();
    _isToggled = _getIsToggled(_selectionStyle.attributes);
    widget.controller.addListener(_didChangeEditingValue);
  }

  @override
  Widget build(BuildContext context) {
    return widget.childBuilder(
      context,
      widget.attribute,
      widget.icon,
      widget.fillColor,
      _isToggled,
      _toggleAttribute,
      widget.iconSize,
      widget.iconTheme,
    );
  }

  @override
  void didUpdateWidget(covariant ToggleStyleButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_didChangeEditingValue);
      widget.controller.addListener(_didChangeEditingValue);
      _isToggled = _getIsToggled(_selectionStyle.attributes);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_didChangeEditingValue);
    super.dispose();
  }

  void _didChangeEditingValue() {
    setState(() => _isToggled = _getIsToggled(_selectionStyle.attributes));
  }

  bool _getIsToggled(Map<String, AttributeM> attrs) {
    if (widget.attribute.key == AttributeM.list.key) {
      final attribute = attrs[widget.attribute.key];
      if (attribute == null) {
        return false;
      }
      return attribute.value == widget.attribute.value;
    }
    return attrs.containsKey(widget.attribute.key);
  }

  void _toggleAttribute() {
    widget.controller.formatSelection(_isToggled!
        ? AttributeM.clone(widget.attribute, null)
        : widget.attribute);
  }
}

Widget defaultToggleStyleButtonBuilder(
  BuildContext context,
  AttributeM attribute,
  IconData icon,
  Color? fillColor,
  bool? isToggled,
  VoidCallback? onPressed, [
  double iconSize = defaultIconSize,
  EditorIconThemeM? iconTheme,
]) {
  final theme = Theme.of(context);
  final isEnabled = onPressed != null;
  final iconColor = isEnabled
      ? isToggled == true
          ? (iconTheme?.iconSelectedColor ??
              theme
                  .primaryIconTheme.color) //You can specify your own icon color
          : (iconTheme?.iconUnselectedColor ?? theme.iconTheme.color)
      : (iconTheme?.disabledIconColor ?? theme.disabledColor);
  final fill = isEnabled
      ? isToggled == true
          ? (iconTheme?.iconSelectedFillColor ??
              theme.toggleableActiveColor) //Selected icon fill color
          : (iconTheme?.iconUnselectedFillColor ??
              theme.canvasColor) //Unselected icon fill color :
      : (iconTheme?.disabledIconFillColor ??
          (fillColor ?? theme.canvasColor)); //Disabled icon fill color
  return IconBtn(
    highlightElevation: 0,
    hoverElevation: 0,
    size: iconSize * iconButtonFactor,
    icon: Icon(icon, size: iconSize, color: iconColor),
    fillColor: fill,
    onPressed: onPressed,
    borderRadius: iconTheme?.borderRadius ?? 2,
  );
}
