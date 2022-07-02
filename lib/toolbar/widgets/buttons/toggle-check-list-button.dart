import 'dart:async';

import 'package:flutter/material.dart';

import '../../../controller/controllers/editor-controller.dart';
import '../../../documents/models/attribute.model.dart';
import '../../../documents/models/style.model.dart';
import '../../../shared/models/editor-icon-theme.model.dart';
import '../../../shared/state/editor-state-receiver.dart';
import '../../../shared/state/editor.state.dart';
import '../../models/toggle-style-button-builder.type.dart';
import '../toolbar.dart';

// ignore: must_be_immutable
class ToggleCheckListButton extends StatefulWidget with EditorStateReceiver {
  final IconData icon;
  final double iconSize;
  final Color? fillColor;
  final EditorController controller;
  final ToggleStyleButtonBuilder childBuilder;
  final AttributeM attribute;
  final EditorIconThemeM? iconTheme;

  // Used internally to retrieve the state from the EditorController instance to which this button is linked to.
  // Can't be accessed publicly (by design) to avoid exposing the internals of the library.
  late EditorState _state;

  @override
  void setState(EditorState state) {
    _state = state;
  }

  ToggleCheckListButton({
    required this.icon,
    required this.controller,
    required this.attribute,
    this.iconSize = defaultIconSize,
    this.fillColor,
    this.childBuilder = defaultToggleStyleButtonBuilder,
    this.iconTheme,
    Key? key,
  }) : super(key: key) {
    controller.setStateInEditorStateReceiver(this);
  }

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
    _updateListener = widget._state.refreshEditor.updateEditor$.listen(
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
