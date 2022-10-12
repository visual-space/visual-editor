import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../documents/models/attribute-scope.enum.dart';
import '../../documents/models/attribute.model.dart';
import '../../documents/models/attributes/attributes.model.dart';
import '../../documents/models/nodes/line.model.dart';
import '../../documents/models/nodes/node.model.dart';
import '../../headings/models/heading-type.enum.dart';
import '../../headings/models/heading.model.dart';
import '../../markers/models/marker.model.dart';
import '../../selection/services/text-selection.utils.dart';
import '../../shared/models/content-proxy-box-renderer.model.dart';
import '../../shared/models/selection-rectangles.model.dart';
import '../../shared/state/editor.state.dart';

// TODO Move internally in the class
final _textSelectionUtils = TextSelectionUtils();

// TODO Convert back from static methods to regular methods
class TextLinesUtils {
  static final _instance = TextLinesUtils._privateConstructor();

  factory TextLinesUtils() => _instance;

  TextLinesUtils._privateConstructor();

  // === EXTRACT HIGHLIGHTS ===

  // Highlights are painted as rectangles on top of a canvas overlaid on top of the raw text.
  // The underlying text is the text (text spans) bellow the highlights.
  // (!) Almost identical to markers with slight differences.
  // (!) We avoided code sharing to avoid bug sharing and to enable them to evolve separately.
  static SelectionRectanglesM? getSelectionCoordinates(
    TextSelection textSelection,
    Offset effectiveOffset,
    LineM line,
    EditorState state,
    RenderContentProxyBox underlyingText,
  ) {
    // Highlight rectangles
    SelectionRectanglesM? rectangles;

    // Scroll offset
    var scrollOffset = 0.0;
    if (state.editorConfig.config.scrollable == true) {
      scrollOffset = state.refs.scrollController.offset;
    }

    // Iterate trough all the children of a line.
    // Children are fragments containing a unique combination of attributes.
    // If one of these fragments contains highlights then we extract the rectangles.
    final lineContainsHighlight = _lineContainsSelection(
      line,
      textSelection,
    );

    if (lineContainsHighlight) {
      final local = _textSelectionUtils.getLocalSelection(
        line,
        textSelection,
        false,
      );
      final nodeRectangles = underlyingText.getBoxesForSelection(local);

      final documentNodePos = underlyingText.localToGlobal(
        // Regardless of the current state of the scroll we want the offset
        // relative to the beginning of document.
        Offset(0, scrollOffset),
      );

      rectangles = SelectionRectanglesM(
        textSelection: local,
        rectangles: nodeRectangles,
        docRelPosition: documentNodePos,
      );
    }

    return rectangles;
  }

  // === EXTRACT MARKERS ===

  // Markers are painted as rectangles on top of a canvas overlaid on top of the raw text.
  // The underlying text is the text (text spans) bellow the markers.
  // TODO Maybe it's better to move this method in the /markers module
  //
  // Technical note
  // The markers could have been extracted once on document init (loading json) and then again at update (marker insert).
  // If the markers are available early, then we can use the same method as for highlights and also have the markers ready earlier in the callstack.
  // So far we did not do this because we realised a bit late in the game what would be the optimal solution.
  // And also at teh moment it's not that big of a problem. Maybe we will improve in the future.
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

      // Markers rectangles
      // (!) Each styleFragment (node) is fully aligned with a markers.
      // Which means the boundaries of a node are the boundaries of a marker as well.
      // ignore: avoid_types_on_closure_parameters
      markers.forEach((marker) {
        final rectangles = getRectanglesFromNode(node, underlyingText);

        var scrollOffset = 0.0;
        if (state.editorConfig.config.scrollable == true) {
          scrollOffset = state.refs.scrollController.offset;
        }

        final documentNodePos = underlyingText?.localToGlobal(
          // Regardless of the current state of the scroll we want the offset
          // relative to the beginning of document.
          Offset(0, scrollOffset),
        );
        final renderedMarker = marker.copyWith(
          // For markers that have been extracted at init we already have the text selection.
          // However, for markers that are freshly generated we don't have the text selection defined as a property on the marker.
          // And actually it is not needed. We only need this information when going out of the library to the client code.
          // While inside the library code we always have access to the text selection data by studying the information provided in the node.
          // When a new marker is inserted it is passed to the format() method, then to the rules and then to composes().
          // Once compose completes, it then calls the refreshEditor() which means a new build() cycle starts.
          // During the build we always have access to the selection values, once again by looking at the document data.
          textSelection: TextSelection(
            baseOffset: node.documentOffset,
            extentOffset: node.documentOffset + node.length,
          ),
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
    return node.style.attributes?.values
        .firstWhere(
          (attribute) => attribute.key == AttributesM.markers.key,
          orElse: () => AttributeM('', AttributeScope.INLINE, null),
        )
        .value;
  }

  // === HEADINGS ===

  static HeadingM? getHeadingToRender(
    Offset effectiveOffset,
    LineM line,
    EditorState state,
    RenderContentProxyBox? underlyingText,
  ) {
    HeadingM? _heading;
    final hasAttrs = line.style.attributes != null;

    if (hasAttrs) {
      final headingAttr = line.style.attributes!.values.firstWhere(
        (attribute) => attribute.key == AttributesM.header.key,
        orElse: () => AttributeM('', AttributeScope.INLINE, null),
      );
      final hasHeading = _headingIsCorrectType(headingAttr, state);

      if (hasHeading) {
        final heading = HeadingM(
          text: line.toPlainText(),
        );

        var scrollOffset = 0.0;
        if (state.editorConfig.config.scrollable == true) {
          scrollOffset = state.refs.scrollController.offset;
        }

        final documentNodePos = underlyingText?.localToGlobal(
          // Regardless off the current state of the scroll we want the offset
          // relative to the beginning of document.
          Offset(0, scrollOffset),
        );
        final textSelection = TextSelection(
          baseOffset: line.documentOffset,
          extentOffset: line.documentOffset + line.length,
        );
        final rectangles = underlyingText?.getBoxesForSelection(textSelection);
        final renderedHeading = heading.copyWith(
          docRelPosition: documentNodePos,
          rectangles: rectangles,
        );

        _heading = renderedHeading;
      }
    }

    return _heading;
  }

  static bool _headingIsCorrectType(
    AttributeM<dynamic> headingAttr,
    EditorState state,
  ) {
    var isCorrectType = false;

    state.headings.headingsTypes.forEach((type) {
      if (type == HeadingTypeE.h1) {
        if (headingAttr.value == 1) {
          isCorrectType = true;
        }
      }
      if (type == HeadingTypeE.h2) {
        if (headingAttr.value == 2) {
          isCorrectType = true;
        }
      }
      if (type == HeadingTypeE.h3) {
        if (headingAttr.value == 3) {
          isCorrectType = true;
        }
      }
    });

    return isCorrectType;
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

  bool isRectangleHovered(TextBox area, Offset pointer) {
    final xHovered = area.left < pointer.dx && pointer.dx < area.right;
    final yHovered = area.top < pointer.dy && pointer.dy < area.bottom;
    return xHovered && yHovered;
  }

  // === PRIVATE ===

  static bool _lineContainsSelection(LineM line, TextSelection selection) {
    return line.documentOffset <= selection.end &&
        selection.start <= line.documentOffset + line.length - 1;
  }
}
