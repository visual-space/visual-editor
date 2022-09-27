import 'package:flutter/material.dart';

import '../../documents/models/nodes/line.model.dart';
import '../../markers/models/marker.model.dart';
import '../../shared/state/editor.state.dart';
import '../models/vertical-spacing.model.dart';
import '../services/styles.utils.dart';
import 'editable-text-line-element.dart';
import 'editable-text-line-renderer.dart';

// Receives as a child a regular life of text made of text spans.
// Over the basic rich text made from spans it adds additional layouting or styling
// For example:
// - checkboxes for todos
// - colored backgrounds for code blocks
// - bullets for bullets lists
// Additionally it renders as an overlay the text selection or highlights and markers boxes.
// ignore: must_be_immutable
class EditableTextLine extends RenderObjectWidget {
  final LineM line;
  final Widget? leading;
  final Widget underlyingText;
  final double indentWidth;
  final VerticalSpacing verticalSpacing;
  final TextDirection textDirection;
  final TextSelection textSelection;
  final bool hasFocus;
  final double devicePixelRatio;

  // We need to cache the renderer so we can query for markers rectangles coordinates after the build cycle.
  EditableTextLineRenderer? _renderer;

  // Used internally to retrieve the state from the EditorController instance to which this button is linked to.
  // Can't be accessed publicly (by design) to avoid exposing the internals of the library.
  late EditorState _state;

  void setState(EditorState state) {
    _state = state;
  }

  EditableTextLine({
    required this.line,
    required this.leading,
    required this.underlyingText,
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

  // An element is an instantiation of a widget in the widget tree. (RenderObjectElement)
  @override
  RenderObjectElement createElement() {
    return EditableTextLineElement(this);
  }

  @override
  RenderObject createRenderObject(BuildContext context) {
    final defaultStyles = getDefaultStyles(context); // TODO Use from state

    // Type of EditableBoxRenderer
    _renderer = EditableTextLineRenderer(
      line: line,
      textDirection: textDirection,
      textSelection: textSelection,
      devicePixelRatio: devicePixelRatio,
      padding: _getPadding(),
      inlineCodeStyle: defaultStyles.inlineCode!,
      state: _state,
      cacheRenderedMarkersCoordinatesInStateStore: (_) {},
    );

    return _renderer!;
  }

  @override
  void updateRenderObject(
    BuildContext context,
    covariant EditableTextLineRenderer renderObject,
  ) {
    _renderer = renderObject;
    renderObject
      ..setState(_state)
      ..setLine(line)
      ..setTextSelection(textSelection);
  }

  // Avoids exposing the private renderer, it only collects the markers.
  List<MarkerM> getRenderedMarkersCoordinates() {
    return _renderer?.getRenderedMarkersCoordinates() ?? [];
  }

  EdgeInsetsGeometry _getPadding() {
    return EdgeInsetsDirectional.only(
      start: indentWidth,
      top: verticalSpacing.top,
      bottom: verticalSpacing.bottom,
    );
  }
}
