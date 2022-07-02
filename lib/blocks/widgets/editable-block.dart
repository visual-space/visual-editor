import 'package:flutter/material.dart';
import 'package:tuple/tuple.dart';

import '../../documents/models/nodes/block.model.dart';
import '../../shared/state/editor.state.dart';
import 'editable-text-block-renderer.dart';

// ignore: must_be_immutable
class EditableBlock extends MultiChildRenderObjectWidget {
  final BlockM block;
  final TextDirection textDirection;
  final Tuple2<double, double> padding;
  final Decoration decoration;
  final bool isCodeBlock;

  // Used internally to retrieve the state from the EditorController instance to which this button is linked to.
  // Can't be accessed publicly (by design) to avoid exposing the internals of the library.
  late EditorState _state;

  void setState(EditorState state) {
    _state = state;
  }

  EditableBlock({
    required this.block,
    required this.textDirection,
    required this.padding,
    required this.decoration,
    required this.isCodeBlock,
    required EditorState state,
    required List<Widget> children,
    Key? key,
  }) : super(
          key: key,
          children: children,
        ) {
    setState(state);
  }

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
      state: _state,
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
