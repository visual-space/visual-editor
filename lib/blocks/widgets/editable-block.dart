import 'package:flutter/material.dart';
import 'package:tuple/tuple.dart';

import '../../documents/models/nodes/block.model.dart';
import 'editable-text-block-renderer.dart';

class EditableBlock extends MultiChildRenderObjectWidget {
  final BlockM block;
  final TextDirection textDirection;
  final Tuple2<double, double> padding;
  final Decoration decoration;
  final bool isCodeBlock;

  EditableBlock({
    required this.block,
    required this.textDirection,
    required this.padding,
    required this.decoration,
    required this.isCodeBlock,
    required List<Widget> children,
    Key? key,
  }) : super(
          key: key,
          children: children,
        );

  EdgeInsets get _padding => EdgeInsets.only(
        top: padding.item1,
        bottom: padding.item2,
      );

  @override
  EditableTextBlockRenderer createRenderObject(BuildContext context) {
    return EditableTextBlockRenderer(
      block: block,
      textDirection: textDirection,
      padding: _padding,
      decoration: decoration,
      isCodeBlock: isCodeBlock,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    covariant EditableTextBlockRenderer renderObject,
  ) {
    renderObject
      ..setContainer(block)
      ..textDirection = textDirection
      ..decoration = decoration;
  }
}
