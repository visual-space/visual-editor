import 'dart:async';

import 'package:flutter/material.dart';

import '../../../controller/services/editor-controller.dart';
import '../../../documents/models/attribute.model.dart';
import '../../../documents/models/style.model.dart';
import '../../../shared/models/editor-icon-theme.model.dart';
import '../../models/toggle-style-button-builder.type.dart';
import '../toolbar.dart';

class ToggleCheckListButton extends StatefulWidget {
  final IconData icon;
  final double iconSize;
  final Color? fillColor;
  final EditorController controller;
  final ToggleStyleButtonBuilder childBuilder;
  final AttributeM attribute;
  final EditorIconThemeM? iconTheme;

  const ToggleCheckListButton({
    required this.icon,
    required this.controller,
    required this.attribute,
    this.iconSize = defaultIconSize,
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
  late final StreamSubscription _updateListener;

  StyleM get _selectionStyle => widget.controller.getSelectionStyle();

  @override
  void initState() {
    super.initState();
    _isToggled = _getIsToggled(_selectionStyle.attributes);
    _updateListener = widget.controller.editorState.updateEditor$.listen(
      (_) => _didChangeEditingValue,
    );
  }

  @override
  void dispose() {
    _updateListener.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.childBuilder(
      context,
      AttributeM.unchecked,
      widget.icon,
      widget.fillColor,
      _isToggled,
      _toggleAttribute,
      widget.iconSize,
      widget.iconTheme,
    );
  }

  // === PRIVATE ===

  void _didChangeEditingValue() {
    setState(() {
      _isToggled =
          _getIsToggled(widget.controller.getSelectionStyle().attributes);
    });
  }

  bool _getIsToggled(Map<String, AttributeM> attrs) {
    var attribute = widget.controller.toolbarButtonToggler[AttributeM.list.key];

    if (attribute == null) {
      attribute = attrs[AttributeM.list.key];
    } else {
      // checkbox tapping causes controller.selection to go to offset 0
      widget.controller.toolbarButtonToggler.remove(AttributeM.list.key);
    }

    if (attribute == null) {
      return false;
    }
    return attribute.value == AttributeM.unchecked.value ||
        attribute.value == AttributeM.checked.value;
  }

  void _toggleAttribute() {
    widget.controller.formatSelection(
      _isToggled!
          ? AttributeM.clone(AttributeM.unchecked, null)
          : AttributeM.unchecked,
    );
  }
}
