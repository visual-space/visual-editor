import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

import '../../../controller/services/editor-controller.dart';
import '../../../documents/models/attribute.model.dart';
import '../../../documents/models/style.model.dart';
import '../../../documents/models/styling-attributes.dart';
import '../../../shared/models/editor-icon-theme.model.dart';
import '../../../shared/translations/toolbar.i18n.dart';
import '../../../shared/utils/color.utils.dart';
import '../toolbar.dart';

// Controls color styles.
// When pressed, this button displays overlay buttons with buttons for each color.
class ColorButton extends StatefulWidget {
  final IconData icon;
  final double iconSize;
  final bool background;
  final EditorController controller;
  final EditorIconThemeM? iconTheme;

  const ColorButton({
    required this.icon,
    required this.controller,
    required this.background,
    this.iconSize = defaultIconSize,
    this.iconTheme,
    Key? key,
  }) : super(key: key);

  @override
  _ColorButtonState createState() => _ColorButtonState();
}

class _ColorButtonState extends State<ColorButton> {
  late bool _isToggledColor;
  late bool _isToggledBackground;
  late bool _isWhite;
  late bool _isWhiteBackground;
  late final StreamSubscription _updateListener;

  StyleM get _selectionStyle => widget.controller.getSelectionStyle();

  @override
  void initState() {
    super.initState();
    _isToggledColor = _getIsToggledColor(_selectionStyle.attributes);
    _isToggledBackground = _getIsToggledBackground(_selectionStyle.attributes);
    _isWhite = _isToggledColor &&
        _selectionStyle.attributes['color']!.value == '#ffffff';
    _isWhiteBackground = _isToggledBackground &&
        _selectionStyle.attributes['background']!.value == '#ffffff';
    _updateListener = widget.controller.editorState.updateEditor$.listen(
      (_) => _didChangeEditingValue,
    );
  }

  bool _getIsToggledColor(Map<String, AttributeM> attrs) {
    return attrs.containsKey(AttributeM.color.key);
  }

  bool _getIsToggledBackground(Map<String, AttributeM> attrs) {
    return attrs.containsKey(AttributeM.background.key);
  }

  @override
  void dispose() {
    _updateListener.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconColor = _isToggledColor && !widget.background && !_isWhite
        ? stringToColor(_selectionStyle.attributes['color']!.value)
        : (widget.iconTheme?.iconUnselectedColor ?? theme.iconTheme.color);

    final iconColorBackground =
        _isToggledBackground && widget.background && !_isWhiteBackground
            ? stringToColor(_selectionStyle.attributes['background']!.value)
            : (widget.iconTheme?.iconUnselectedColor ?? theme.iconTheme.color);

    final fillColor = _isToggledColor && !widget.background && _isWhite
        ? stringToColor('#ffffff')
        : (widget.iconTheme?.iconUnselectedFillColor ?? theme.canvasColor);
    final fillColorBackground =
        _isToggledBackground && widget.background && _isWhiteBackground
            ? stringToColor('#ffffff')
            : (widget.iconTheme?.iconUnselectedFillColor ?? theme.canvasColor);

    return IconBtn(
      highlightElevation: 0,
      hoverElevation: 0,
      size: widget.iconSize * iconButtonFactor,
      icon: Icon(
        widget.icon,
        size: widget.iconSize,
        color: widget.background ? iconColorBackground : iconColor,
      ),
      fillColor: widget.background ? fillColorBackground : fillColor,
      borderRadius: widget.iconTheme?.borderRadius ?? 2,
      onPressed: _showColorPicker,
    );
  }

  // === PRIVATE ===

  void _didChangeEditingValue() {
    setState(() {
      _isToggledColor = _getIsToggledColor(
        widget.controller.getSelectionStyle().attributes,
      );
      _isToggledBackground = _getIsToggledBackground(
        widget.controller.getSelectionStyle().attributes,
      );
      _isWhite = _isToggledColor &&
          _selectionStyle.attributes['color']!.value == '#ffffff';
      _isWhiteBackground = _isToggledBackground &&
          _selectionStyle.attributes['background']!.value == '#ffffff';
    });
  }

  void _changeColor(BuildContext context, Color color) {
    var hex = color.value.toRadixString(16);

    if (hex.startsWith('ff')) {
      hex = hex.substring(2);
    }

    hex = '#$hex';
    widget.controller.formatSelection(
      widget.background ? BackgroundAttributeM(hex) : ColorAttributeM(hex),
    );
    Navigator.of(context).pop();
  }

  void _showColorPicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Select Color'.i18n),
        backgroundColor: Theme.of(context).canvasColor,
        content: SingleChildScrollView(
          child: MaterialPicker(
            pickerColor: const Color(0x00000000),
            onColorChanged: (color) => _changeColor(context, color),
          ),
        ),
      ),
    );
  }
}
