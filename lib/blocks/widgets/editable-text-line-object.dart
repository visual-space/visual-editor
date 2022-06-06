import 'package:flutter/material.dart';
import 'package:tuple/tuple.dart';

import '../../controller/services/editor-controller.dart';
import '../../cursor/widgets/cursor.dart';
import '../../documents/models/nodes/line.dart';
import '../services/default-styles.utils.dart';
import 'editable-text-line-renderer.dart';
import 'text-line-element-renderer.dart';

class EditableTextLine extends RenderObjectWidget {
  const EditableTextLine({
    required this.controller,
    required this.line,
    required this.leading,
    required this.body,
    required this.indentWidth,
    required this.verticalSpacing,
    required this.textDirection,
    required this.textSelection,
    required this.color,
    required this.enableInteractiveSelection,
    required this.hasFocus,
    required this.devicePixelRatio,
    required this.cursorCont,
  });

  final EditorController controller;
  final Line line;
  final Widget? leading;
  final Widget body;
  final double indentWidth;
  final Tuple2 verticalSpacing;
  final TextDirection textDirection;
  final TextSelection textSelection;
  final Color color;
  final bool enableInteractiveSelection;
  final bool hasFocus;
  final double devicePixelRatio;
  final CursorCont cursorCont;

  @override
  RenderObjectElement createElement() {
    return TextLineElement(this);
  }

  @override
  RenderObject createRenderObject(BuildContext context) {
    final defaultStyles = DefaultStyles.getInstance(context);

    return RenderEditableTextLine(
      controller,
      line,
      textDirection,
      textSelection,
      enableInteractiveSelection,
      hasFocus,
      devicePixelRatio,
      _getPadding(),
      color,
      cursorCont,
      defaultStyles.inlineCode!,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    covariant RenderEditableTextLine renderObject,
  ) {
    final defaultStyles = DefaultStyles.getInstance(context);

    renderObject
      ..setLine(line)
      ..setPadding(_getPadding())
      ..setTextDirection(textDirection)
      ..setTextSelection(textSelection)
      ..setColor(color)
      ..setEnableInteractiveSelection(enableInteractiveSelection)
      ..hasFocus = hasFocus
      ..setDevicePixelRatio(devicePixelRatio)
      ..setCursorCont(cursorCont)
      ..setInlineCodeStyle(defaultStyles.inlineCode!);
  }

  EdgeInsetsGeometry _getPadding() {
    return EdgeInsetsDirectional.only(
      start: indentWidth,
      top: verticalSpacing.item1,
      bottom: verticalSpacing.item2,
    );
  }
}
