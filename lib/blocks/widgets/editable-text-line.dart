import 'package:flutter/material.dart';

import '../../documents/models/nodes/line.model.dart';
import '../../shared/state/editor.state.dart';
import '../models/vertical-spacing.model.dart';
import '../services/styles.utils.dart';
import 'editable-text-line-renderer.dart';
import 'text-line-element-renderer.dart';

// ignore: must_be_immutable
class EditableTextLine extends RenderObjectWidget {
  final LineM line;
  final Widget? leading;
  final Widget body;
  final double indentWidth;
  final VerticalSpacing verticalSpacing;
  final TextDirection textDirection;
  final TextSelection textSelection;
  final bool hasFocus;
  final double devicePixelRatio;

  // Used internally to retrieve the state from the EditorController instance to which this button is linked to.
  // Can't be accessed publicly (by design) to avoid exposing the internals of the library.
  late EditorState _state;

  void setState(EditorState state) {
    _state = state;
  }

  EditableTextLine({
    required this.line,
    required this.leading,
    required this.body,
    required this.indentWidth,
    required this.verticalSpacing,
    required this.textDirection,
    required this.textSelection,
    required this.hasFocus,
    required this.devicePixelRatio,
    required EditorState state,
  }) {
    setState(state);
  }

  @override
  RenderObjectElement createElement() {
    return TextLineElementRenderer(this);
  }

  @override
  RenderObject createRenderObject(BuildContext context) {
    final defaultStyles = getDefaultStyles(context); // TODO Use from state

    return EditableTextLineRenderer(
      line: line,
      textDirection: textDirection,
      textSelection: textSelection,
      devicePixelRatio: devicePixelRatio,
      padding: _getPadding(),
      inlineCodeStyle: defaultStyles.inlineCode!,
      state: _state,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    covariant EditableTextLineRenderer renderObject,
  ) {
    renderObject
      ..setState(_state)
      ..setLine(line)
      ..setTextSelection(textSelection);
  }

  EdgeInsetsGeometry _getPadding() {
    return EdgeInsetsDirectional.only(
      start: indentWidth,
      top: verticalSpacing.top,
      bottom: verticalSpacing.bottom,
    );
  }
}
