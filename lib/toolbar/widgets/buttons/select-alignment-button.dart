import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../controller/services/editor-controller.dart';
import '../../../documents/models/attribute.model.dart';
import '../../../documents/models/style.model.dart';
import '../../../shared/models/editor-icon-theme.model.dart';
import '../toolbar.dart';

class SelectAlignmentButton extends StatefulWidget {
  final EditorController controller;
  final double iconSize;
  final EditorIconThemeM? iconTheme;
  final bool? showLeftAlignment;
  final bool? showCenterAlignment;
  final bool? showRightAlignment;
  final bool? showJustifyAlignment;

  const SelectAlignmentButton({
    required this.controller,
    this.iconSize = defaultIconSize,
    this.iconTheme,
    this.showLeftAlignment,
    this.showCenterAlignment,
    this.showRightAlignment,
    this.showJustifyAlignment,
    Key? key,
  }) : super(key: key);

  @override
  _SelectAlignmentButtonState createState() => _SelectAlignmentButtonState();
}

class _SelectAlignmentButtonState extends State<SelectAlignmentButton> {
  AttributeM? _value;

  StyleM get _selectionStyle => widget.controller.getSelectionStyle();

  @override
  void initState() {
    super.initState();
    setState(() {
      _value = _selectionStyle.attributes[AttributeM.align.key] ??
          AttributeM.leftAlignment;
    });
    widget.controller.addListener(_didChangeEditingValue);
  }

  @override
  Widget build(BuildContext context) {
    final _valueToText = <AttributeM, String>{
      if (widget.showLeftAlignment!)
        AttributeM.leftAlignment: AttributeM.leftAlignment.value!,
      if (widget.showCenterAlignment!)
        AttributeM.centerAlignment: AttributeM.centerAlignment.value!,
      if (widget.showRightAlignment!)
        AttributeM.rightAlignment: AttributeM.rightAlignment.value!,
      if (widget.showJustifyAlignment!)
        AttributeM.justifyAlignment: AttributeM.justifyAlignment.value!,
    };

    final _valueAttribute = <AttributeM>[
      if (widget.showLeftAlignment!) AttributeM.leftAlignment,
      if (widget.showCenterAlignment!) AttributeM.centerAlignment,
      if (widget.showRightAlignment!) AttributeM.rightAlignment,
      if (widget.showJustifyAlignment!) AttributeM.justifyAlignment
    ];
    final _valueString = <String>[
      if (widget.showLeftAlignment!) AttributeM.leftAlignment.value!,
      if (widget.showCenterAlignment!) AttributeM.centerAlignment.value!,
      if (widget.showRightAlignment!) AttributeM.rightAlignment.value!,
      if (widget.showJustifyAlignment!) AttributeM.justifyAlignment.value!,
    ];

    final theme = Theme.of(context);

    final buttonCount = ((widget.showLeftAlignment!) ? 1 : 0) +
        ((widget.showCenterAlignment!) ? 1 : 0) +
        ((widget.showRightAlignment!) ? 1 : 0) +
        ((widget.showJustifyAlignment!) ? 1 : 0);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(buttonCount, (index) {
        return Padding(
          // ignore: prefer_const_constructors
          padding: EdgeInsets.symmetric(horizontal: !kIsWeb ? 1.0 : 5.0),
          child: ConstrainedBox(
            constraints: BoxConstraints.tightFor(
              width: widget.iconSize * iconButtonFactor,
              height: widget.iconSize * iconButtonFactor,
            ),
            child: RawMaterialButton(
              hoverElevation: 0,
              highlightElevation: 0,
              elevation: 0,
              visualDensity: VisualDensity.compact,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                      widget.iconTheme?.borderRadius ?? 2)),
              fillColor: _valueToText[_value] == _valueString[index]
                  ? (widget.iconTheme?.iconSelectedFillColor ??
                      theme.toggleableActiveColor)
                  : (widget.iconTheme?.iconUnselectedFillColor ??
                      theme.canvasColor),
              onPressed: () => _valueAttribute[index] == AttributeM.leftAlignment
                  ? widget.controller
                      .formatSelection(AttributeM.clone(AttributeM.align, null))
                  : widget.controller.formatSelection(_valueAttribute[index]),
              child: Icon(
                _valueString[index] == AttributeM.leftAlignment.value
                    ? Icons.format_align_left
                    : _valueString[index] == AttributeM.centerAlignment.value
                        ? Icons.format_align_center
                        : _valueString[index] == AttributeM.rightAlignment.value
                            ? Icons.format_align_right
                            : Icons.format_align_justify,
                size: widget.iconSize,
                color: _valueToText[_value] == _valueString[index]
                    ? (widget.iconTheme?.iconSelectedColor ??
                        theme.primaryIconTheme.color)
                    : (widget.iconTheme?.iconUnselectedColor ??
                        theme.iconTheme.color),
              ),
            ),
          ),
        );
      }),
    );
  }

  void _didChangeEditingValue() {
    setState(() {
      _value = _selectionStyle.attributes[AttributeM.align.key] ??
          AttributeM.leftAlignment;
    });
  }

  @override
  void didUpdateWidget(covariant SelectAlignmentButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_didChangeEditingValue);
      widget.controller.addListener(_didChangeEditingValue);
      _value = _selectionStyle.attributes[AttributeM.align.key] ??
          AttributeM.leftAlignment;
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_didChangeEditingValue);
    super.dispose();
  }
}
