import 'package:flutter/material.dart';
import 'package:tuple/tuple.dart';

import '../../documents/models/nodes/line.model.dart';
import '../models/default-styles.model.dart';
import 'editable-text-line-renderer.dart';
import 'text-line-element-renderer.dart';

class EditableTextLine extends RenderObjectWidget {
  final LineM line;
  final Widget? leading;
  final Widget body;
  final double indentWidth;
  final Tuple2 verticalSpacing;
  final TextDirection textDirection;
  final TextSelection textSelection;
  final bool hasFocus;
  final double devicePixelRatio;

  const EditableTextLine({
    required this.line,
    required this.leading,
    required this.body,
    required this.indentWidth,
    required this.verticalSpacing,
    required this.textDirection,
    required this.textSelection,
    required this.hasFocus,
    required this.devicePixelRatio,
  });

  @override
  RenderObjectElement createElement() {
    return TextLineElementRenderer(this);
  }

  @override
  RenderObject createRenderObject(BuildContext context) {
    final defaultStyles = DefaultStyles.getInstance(context);

    return EditableTextLineRenderer(
      line: line,
      textDirection: textDirection,
      textSelection: textSelection,
      devicePixelRatio: devicePixelRatio,
      padding: _getPadding(),
      inlineCodeStyle: defaultStyles.inlineCode!,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    covariant EditableTextLineRenderer renderObject,
  ) {
    renderObject
      ..setLine(line)
      ..setTextSelection(textSelection);
  }

  EdgeInsetsGeometry _getPadding() {
    return EdgeInsetsDirectional.only(
      start: indentWidth,
      top: verticalSpacing.item1,
      bottom: verticalSpacing.item2,
    );
  }
}
