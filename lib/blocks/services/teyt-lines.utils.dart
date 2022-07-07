import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../documents/models/attributes/attributes.model.dart';
import '../../documents/models/nodes/line.model.dart';
import '../../documents/models/nodes/node.model.dart';
import '../../shared/models/content-proxy-box-renderer.model.dart';
import '../../shared/state/editor.state.dart';

class TextLinesUtils {
  static final _instance = TextLinesUtils._privateConstructor();

  factory TextLinesUtils() => _instance;

  TextLinesUtils._privateConstructor();

  static void renderMarkers(
    Offset effectiveOffset,
    PaintingContext context,
    LineM line,
    EditorState state,
      RenderContentProxyBox? body,
  ) {
    for (final node in line.children) {
      final hasMarker = !node.style.containsKey(AttributesM.markers.key);

      if (hasMarker) {
        continue;
      }

      // Render all markers
      final markers = node.style.attributes.values.firstWhere(
        (attribute) => attribute.key == AttributesM.markers.key,
      );

      markers.value.forEach((marker) {
        // Get color
        final String type = marker.values.toList()[0];

        final markerType = state.markersTypes.types.firstWhere(
          (markerType) => markerType.id == type,
        );

        drawRectFromNode(
          node,
          effectiveOffset,
          context,
          markerType.color,
          Radius.zero,
            body,
        );
      });
    }
  }

  // Draws a rectangle around the margins of the node.
  // Border radius can be defined.
  static void drawRectFromNode(
    NodeM node,
    Offset effectiveOffset,
    PaintingContext context,
    Color backgroundColor,
    Radius? radius,
    RenderContentProxyBox? body,
  ) {
    final textRange = TextSelection(
      baseOffset: node.offset,
      extentOffset: node.offset + node.length,
    );
    final rectangles = body!.getBoxesForSelection(textRange);
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
  }
}
