import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../documents/models/attributes/attributes.model.dart';
import '../../documents/models/nodes/line.model.dart';
import '../../documents/models/nodes/node.model.dart';
import '../../markers/models/marker.model.dart';
import '../../shared/models/content-proxy-box-renderer.model.dart';
import '../../shared/state/editor.state.dart';

class TextLinesUtils {
  static final _instance = TextLinesUtils._privateConstructor();

  factory TextLinesUtils() => _instance;

  TextLinesUtils._privateConstructor();

  // === EXTRACT MARKERS ===

  // Markers are painted as rectangles on top of a canvas overlaid on top of the raw text.
  // The underlying text is the text (text spans) bellow the markers.
  static List<MarkerM> getMarkersToRender(
    Offset effectiveOffset,
    LineM line,
    EditorState state,
    RenderContentProxyBox? underlyingText,
  ) {
    // Markers List
    final allMarkers = <MarkerM>[];

    // Iterate trough all the children of a line.
    // Children are fragments containing a unique combination of attributes.
    // If one of these fragments contains markers then we attempt to render the rectangles.
    for (final node in line.children) {
      final hasMarker = node.style.containsKey(AttributesM.markers.key);

      if (!hasMarker) {
        continue;
      }

      final markers = _getTheMarkersAttributeFromNode(node);

      // Render all markers
      // ignore: avoid_types_on_closure_parameters
      markers.forEach((marker) {
        final rectangles = getRectanglesFromNode(node, underlyingText);

        var scrollOffset = 0.0;
        if (state.editorConfig.config.scrollable == true) {
          scrollOffset = state.refs.scrollController.offset;
        }

        final documentNodePos = underlyingText?.localToGlobal(
          // Regardless off the current state of the scroll we want the offset
          // relative to the beginning of document.
          Offset(0, scrollOffset),
        );
        final renderedMarker = marker.copyWith(
          rectangles: rectangles,
          docRelPosition: documentNodePos,
        );

        // Collect markers and pixel coordinates
        allMarkers.add(renderedMarker);
      });
    }

    return allMarkers;
  }

  // A node can host multiple attributes, one of them is the markers attribute.
  static List<MarkerM> _getTheMarkersAttributeFromNode(NodeM node) {
    return node.style.attributes.values
        .firstWhere(
          (attribute) => attribute.key == AttributesM.markers.key,
        )
        .value;
  }

  // === DRAW SHAPES ===

  // Draws a rectangle around the margins of the node.
  // Border radius can be defined.
  static void drawRectanglesFromNode(
    NodeM node,
    Offset effectiveOffset,
    PaintingContext context,
    Color backgroundColor,
    Radius? radius,
    RenderContentProxyBox? underlyingText,
  ) {
    final rectangles = getRectanglesFromNode(node, underlyingText);

    drawRectangles(
      rectangles,
      effectiveOffset,
      context,
      backgroundColor,
      radius,
    );
  }

  // Get the rectangles needed to encompass a slice of text (node).
  // Border radius can be defined.
  static List<TextBox> getRectanglesFromNode(
    NodeM node,
    RenderContentProxyBox? underlyingText,
  ) {
    final textRange = TextSelection(
      baseOffset: node.offset,
      extentOffset: node.offset + node.length,
    );
    final rectangles = underlyingText!.getBoxesForSelection(textRange);

    return rectangles;
  }

  // Draws the rectangles as provided on the canvas.
  static List<TextBox> drawRectangles(
    List<TextBox> rectangles,
    Offset effectiveOffset,
    PaintingContext context,
    Color backgroundColor,
    Radius? radius,
  ) {
    final paint = Paint()..color = backgroundColor;

    for (final box in rectangles) {
      final rect = box.toRect().translate(0, 1).shift(effectiveOffset);

      // Square corners
      if (radius == null) {
        final paintRect = Rect.fromLTRB(
          rect.left - 2,
          rect.top,
          rect.right + 2,
          rect.bottom,
        );
        context.canvas.drawRect(paintRect, paint);

        // Rounded corners
      } else {
        final paintRect = RRect.fromLTRBR(
          rect.left - 2,
          rect.top,
          rect.right + 2,
          rect.bottom,
          radius,
        );
        context.canvas.drawRRect(paintRect, paint);
      }
    }

    return rectangles;
  }
}
