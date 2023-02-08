import 'package:flutter/material.dart';

import '../../document/models/nodes/block.model.dart';
import '../../shared/state/editor.state.dart';
import '../models/vertical-spacing.model.dart';
import 'editable-text-block-box-renderer.dart';

// ignore: must_be_immutable
class EditableTextBlockWidgetRenderer extends MultiChildRenderObjectWidget {
  final BlockM block;
  final TextDirection textDirection;
  final VerticalSpacing padding;
  final Decoration decoration;
  final bool isCodeBlock;
  late EditorState _state;

  EditableTextBlockWidgetRenderer({
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
    _cacheStateStore(state);
  }

  EdgeInsets get _padding => EdgeInsets.only(
        top: padding.top,
        bottom: padding.bottom,
      );

  @override
  EditableTextBlockBoxRenderer createRenderObject(BuildContext context) =>
      EditableTextBlockBoxRenderer(
        block: block,
        textDirection: textDirection,
        padding: _padding,
        decoration: decoration,
        isCodeBlock: isCodeBlock,
        state: _state,
      );

  @override
  void updateRenderObject(
    BuildContext context,
    covariant EditableTextBlockBoxRenderer renderObject,
  ) {
    renderObject
      ..setContainer(block)
      ..textDirection = textDirection
      ..decoration = decoration;
  }

  void _cacheStateStore(EditorState state) {
    _state = state;
  }
}
