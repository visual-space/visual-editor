import 'package:flutter/material.dart';
import 'package:tuple/tuple.dart';

import '../../controller/services/editor-controller.dart';
import '../../cursor/services/cursor.controller.dart';
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
    required this.enableInteractiveSelection,
    required this.hasFocus,
    required this.devicePixelRatio,
    required this.cursorController,
  });

  final EditorController controller;
  final Line line;
  final Widget? leading;
  final Widget body;
  final double indentWidth;
  final Tuple2 verticalSpacing;
  final TextDirection textDirection;
  final TextSelection textSelection;
  final bool enableInteractiveSelection;
  final bool hasFocus;
  final double devicePixelRatio;
  final CursorController cursorController;

  @override
  RenderObjectElement createElement() {
    return TextLineElement(this);
  }

  @override
  RenderObject createRenderObject(BuildContext context) {
    final defaultStyles = DefaultStyles.getInstance(context);

    return EditableTextLineRenderer(
      controller: controller,
      line: line,
      textDirection: textDirection,
      textSelection: textSelection,
      enableInteractiveSelection: enableInteractiveSelection,
      hasFocus: hasFocus,
      devicePixelRatio: devicePixelRatio,
      padding: _getPadding(),
      cursorController: cursorController,
      inlineCodeStyle: defaultStyles.inlineCode!,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    covariant EditableTextLineRenderer renderObject,
  ) {
    final defaultStyles = DefaultStyles.getInstance(context);

    renderObject
      ..setLine(line)
      ..setPadding(_getPadding())
      ..setTextDirection(textDirection)
      ..setTextSelection(textSelection)
      ..setEnableInteractiveSelection(enableInteractiveSelection)
      ..hasFocus = hasFocus
      ..setDevicePixelRatio(devicePixelRatio)
      ..setCursorController(cursorController)
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
