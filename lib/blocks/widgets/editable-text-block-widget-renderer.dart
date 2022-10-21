import 'package:flutter/material.dart';

import '../../documents/models/nodes/block.model.dart';
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

  // Used internally to retrieve the state from the EditorController instance to which this button is linked to.
  // Can't be accessed publicly (by design) to avoid exposing the internals of the library.
  late EditorState _state;

  void setState(EditorState state) {
    _state = state;
  }

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
    setState(state);
  }

  EdgeInsets get _padding => EdgeInsets.only(
        top: padding.top,
        bottom: padding.bottom,
      );

  @override
  EditableTextBlockBoxRenderer createRenderObject(BuildContext context) {
    return EditableTextBlockBoxRenderer(
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
    covariant EditableTextBlockBoxRenderer renderObject,
  ) {
    renderObject
      ..setContainer(block)
      ..textDirection = textDirection
      ..decoration = decoration;
  }
}
