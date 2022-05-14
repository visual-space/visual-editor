import 'package:flutter/material.dart';

import '../../../controller/services/editor-controller.dart';
import '../../../documents/models/attribute.dart';
import '../../../documents/models/style.dart';
import '../../../shared/models/editor-icon-theme.model.dart';
import '../../models/toggle-style-button-builder.type.dart';
import '../toolbar.dart';

class ToggleCheckListButton extends StatefulWidget {
  final IconData icon;
  final double iconSize;
  final Color? fillColor;
  final EditorController controller;
  final ToggleStyleButtonBuilder childBuilder;
  final Attribute attribute;
  final EditorIconThemeM? iconTheme;

  const ToggleCheckListButton({
    required this.icon,
    required this.controller,
    required this.attribute,
    this.iconSize = kDefaultIconSize,
    this.fillColor,
    this.childBuilder = defaultToggleStyleButtonBuilder,
    this.iconTheme,
    Key? key,
  }) : super(key: key);

  @override
  _ToggleCheckListButtonState createState() => _ToggleCheckListButtonState();
}

class _ToggleCheckListButtonState extends State<ToggleCheckListButton> {
  bool? _isToggled;

  Style get _selectionStyle => widget.controller.getSelectionStyle();

  void _didChangeEditingValue() {
    setState(() {
      _isToggled =
          _getIsToggled(widget.controller.getSelectionStyle().attributes);
    });
  }

  @override
  void initState() {
    super.initState();
    _isToggled = _getIsToggled(_selectionStyle.attributes);
    widget.controller.addListener(_didChangeEditingValue);
  }

  bool _getIsToggled(Map<String, Attribute> attrs) {
    var attribute = widget.controller.toolbarButtonToggler[Attribute.list.key];

    if (attribute == null) {
      attribute = attrs[Attribute.list.key];
    } else {
      // checkbox tapping causes controller.selection to go to offset 0
      widget.controller.toolbarButtonToggler.remove(Attribute.list.key);
    }

    if (attribute == null) {
      return false;
    }
    return attribute.value == Attribute.unchecked.value ||
        attribute.value == Attribute.checked.value;
  }

  @override
  void didUpdateWidget(covariant ToggleCheckListButton oldWidget) {
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

  @override
  Widget build(BuildContext context) {
    return widget.childBuilder(
      context,
      Attribute.unchecked,
      widget.icon,
      widget.fillColor,
      _isToggled,
      _toggleAttribute,
      widget.iconSize,
      widget.iconTheme,
    );
  }

  void _toggleAttribute() {
    widget.controller.formatSelection(
      _isToggled!
          ? Attribute.clone(Attribute.unchecked, null)
          : Attribute.unchecked,
    );
  }
}
