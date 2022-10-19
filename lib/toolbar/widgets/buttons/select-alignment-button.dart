import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../controller/controllers/editor-controller.dart';
import '../../../documents/models/attribute.model.dart';
import '../../../documents/models/attributes/attributes-aliases.model.dart';
import '../../../documents/models/attributes/attributes.model.dart';
import '../../../documents/models/style.model.dart';
import '../../../documents/services/attribute.utils.dart';
import '../../../shared/models/editor-icon-theme.model.dart';
import '../../../shared/state/editor-state-receiver.dart';
import '../../../shared/state/editor.state.dart';
import '../toolbar.dart';

// ignore: must_be_immutable
class SelectAlignmentButton extends StatefulWidget with EditorStateReceiver {
  final EditorController controller;
  final double iconSize;
  final EditorIconThemeM? iconTheme;
  final bool? showLeftAlignment;
  final bool? showCenterAlignment;
  final bool? showRightAlignment;
  final bool? showJustifyAlignment;
  final double buttonsSpacing;

  // Used internally to retrieve the state from the EditorController instance to which this button is linked to.
  // Can't be accessed publicly (by design) to avoid exposing the internals of the library.
  late EditorState _state;

  @override
  void setState(EditorState state) {
    _state = state;
  }

  SelectAlignmentButton({
    required this.controller,
    required this.buttonsSpacing,
    this.iconSize = defaultIconSize,
    this.iconTheme,
    this.showLeftAlignment,
    this.showCenterAlignment,
    this.showRightAlignment,
    this.showJustifyAlignment,
    Key? key,
  }) : super(key: key) {
    controller.setStateInEditorStateReceiver(this);
  }

  @override
  _SelectAlignmentButtonState createState() => _SelectAlignmentButtonState();
}

class _SelectAlignmentButtonState extends State<SelectAlignmentButton> {
  AttributeM? _value;
  StreamSubscription? _refreshListener;

  StyleM get _selectionStyle => widget.controller.getSelectionStyle();

  @override
  void initState() {
    super.initState();
    setState(() {
      _value = _selectionStyle.attributes[AttributesM.align.key] ??
          AttributesAliasesM.leftAlignment;
    });
    _subscribeToRefreshListener();
  }

  @override
  Widget build(BuildContext context) {
    final _valueToText = <AttributeM, String>{
      if (widget.showLeftAlignment!)
        AttributesAliasesM.leftAlignment:
            AttributesAliasesM.leftAlignment.value!,
      if (widget.showCenterAlignment!)
        AttributesAliasesM.centerAlignment:
            AttributesAliasesM.centerAlignment.value!,
      if (widget.showRightAlignment!)
        AttributesAliasesM.rightAlignment:
            AttributesAliasesM.rightAlignment.value!,
      if (widget.showJustifyAlignment!)
        AttributesAliasesM.justifyAlignment:
            AttributesAliasesM.justifyAlignment.value!,
    };

    final _valueAttribute = <AttributeM>[
      if (widget.showLeftAlignment!) AttributesAliasesM.leftAlignment,
      if (widget.showCenterAlignment!) AttributesAliasesM.centerAlignment,
      if (widget.showRightAlignment!) AttributesAliasesM.rightAlignment,
      if (widget.showJustifyAlignment!) AttributesAliasesM.justifyAlignment
    ];
    final _valueString = <String>[
      if (widget.showLeftAlignment!) AttributesAliasesM.leftAlignment.value!,
      if (widget.showCenterAlignment!)
        AttributesAliasesM.centerAlignment.value!,
      if (widget.showRightAlignment!) AttributesAliasesM.rightAlignment.value!,
      if (widget.showJustifyAlignment!)
        AttributesAliasesM.justifyAlignment.value!,
    ];

    final theme = Theme.of(context);

    final buttonCount = ((widget.showLeftAlignment!) ? 1 : 0) +
        ((widget.showCenterAlignment!) ? 1 : 0) +
        ((widget.showRightAlignment!) ? 1 : 0) +
        ((widget.showJustifyAlignment!) ? 1 : 0);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(buttonCount, (index) {
        return Container(
          // ignore: prefer_const_constructors
          margin: EdgeInsets.symmetric(
            horizontal: !kIsWeb ? 1.0 : widget.buttonsSpacing,
          ),
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
                borderRadius:
                    BorderRadius.circular(widget.iconTheme?.borderRadius ?? 2),
              ),
              fillColor: _valueToText[_value] == _valueString[index]
                  ? (widget.iconTheme?.iconSelectedFillColor ??
                      theme.toggleableActiveColor)
                  : (widget.iconTheme?.iconUnselectedFillColor ??
                      theme.canvasColor),
              onPressed: () => _valueAttribute[index] ==
                      AttributesAliasesM.leftAlignment
                  ? widget.controller.formatSelection(
                      AttributeUtils.clone(AttributesM.align, null),
                    )
                  : widget.controller.formatSelection(_valueAttribute[index]),
              child: Icon(
                _valueString[index] == AttributesAliasesM.leftAlignment.value
                    ? Icons.format_align_left
                    : _valueString[index] ==
                            AttributesAliasesM.centerAlignment.value
                        ? Icons.format_align_center
                        : _valueString[index] ==
                                AttributesAliasesM.rightAlignment.value
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

  @override
  void didUpdateWidget(covariant SelectAlignmentButton oldWidget) {
    super.didUpdateWidget(oldWidget);

    // If a new controller was generated by setState() in the parent
    // we need to subscribe to the new state store.
    if (oldWidget.controller != widget.controller) {
      _refreshListener?.cancel();
      widget.controller.setStateInEditorStateReceiver(widget);
      _subscribeToRefreshListener();
      _value = _selectionStyle.attributes[AttributesM.align.key] ??
          AttributesAliasesM.leftAlignment;
    }
  }

  @override
  void dispose() {
    _refreshListener?.cancel();
    super.dispose();
  }

  // === PRIVATE ===

  void _subscribeToRefreshListener() {
    _refreshListener = widget._state.refreshEditor.refreshEditor$.listen(
      (_) => _didChangeEditingValue(),
    );
  }

  void _didChangeEditingValue() {
    setState(() {
      _value = _selectionStyle.attributes[AttributesM.align.key] ??
          AttributesAliasesM.leftAlignment;
    });
  }
}
