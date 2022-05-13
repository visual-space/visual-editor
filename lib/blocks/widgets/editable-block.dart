import 'package:flutter/material.dart';
import 'package:tuple/tuple.dart';
import '../../documents/models/nodes/block.dart';
import 'text-block-renderer.dart';

class EditableBlock extends MultiChildRenderObjectWidget {
  final Block block;
  final TextDirection textDirection;
  final Tuple2<double, double> padding;
  final double scrollBottomInset;
  final Decoration decoration;
  final EdgeInsets? contentPadding;

  EditableBlock({
    required this.block,
    required this.textDirection,
    required this.padding,
    required this.scrollBottomInset,
    required this.decoration,
    required this.contentPadding,
    required List<Widget> children,
    Key? key,
  }) : super(key: key, children: children);

  EdgeInsets get _padding =>
      EdgeInsets.only(top: padding.item1, bottom: padding.item2);

  EdgeInsets get _contentPadding => contentPadding ?? EdgeInsets.zero;

  @override
  RenderEditableTextBlock createRenderObject(BuildContext context) {
    return RenderEditableTextBlock(
      block: block,
      textDirection: textDirection,
      padding: _padding,
      scrollBottomInset: scrollBottomInset,
      decoration: decoration,
      contentPadding: _contentPadding,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    covariant RenderEditableTextBlock renderObject,
  ) {
    renderObject
      ..setContainer(block)
      ..textDirection = textDirection
      ..scrollBottomInset = scrollBottomInset
      ..setPadding(_padding)
      ..decoration = decoration
      ..contentPadding = _contentPadding;
  }
}
