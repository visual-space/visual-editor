import 'package:flutter/rendering.dart';

import '../../document/models/attributes/attribute-scope.enum.dart';
import '../../document/models/attributes/attribute.model.dart';
import '../../document/models/attributes/attributes.model.dart';
import '../../document/models/nodes/line.model.dart';
import '../../document/models/nodes/node.model.dart';
import '../../document/services/nodes/node.utils.dart';
import '../../headings/models/heading-type.enum.dart';
import '../../headings/models/heading.model.dart';
import '../../markers/models/marker.model.dart';
import '../../selection/services/selection-renderer.service.dart';
import '../../shared/models/content-proxy-box-renderer.model.dart';
import '../../shared/models/selection-rectangles.model.dart';
import '../../shared/state/editor.state.dart';
import '../models/text-paint-cfg.model.dart';

// Extracts rectangles from highlights, markers, etc.
// Draws the vector shapes of the generated rectangles.
// Rectangles are used to draw boxes over precise text coordinates
// or to link overlaid text elements over the text.
class RectanglesService {
  late final SelectionRendererService _selectionRendererService;
  final _nodeUtils = NodeUtils();

  final EditorState state;

  RectanglesService(this.state) {
    _selectionRendererService = SelectionRendererService(state);
  }

  // === EXTRACT HIGHLIGHTS ===

  // Highlights are painted as rectangles on top of a canvas overlaid on top of the raw text.
  // The underlying text is the text (text spans) bellow the highlights.
  // (!) Almost identical to markers with slight differences.
  // (!) We avoided code sharing to avoid bug sharing and to enable them to evolve separately.
  SelectionRectanglesM? getSelectionCoordinates(
    TextSelection selection,
    Offset effectiveOffset,
    LineM line,
    RenderContentProxyBox underlyingText,
  ) {
    SelectionRectanglesM? rectangles;

    // Iterate trough all the children of a line.
    // Children are fragments containing a unique combination of attributes.
    // If one of these fragments contains highlights then we extract the rectangles.
    final lineContainsHighlight = _lineContainsSelection(line, selection);

    if (lineContainsHighlight) {
      final local = _selectionRendererService.getLocalSelection(line, selection, false);
      final nodeRectangles = underlyingText.getBoxesForSelection(local);
      final docRelPosition = underlyingText.localToGlobal(const Offset(0, 0), ancestor: state.refs.renderer);
      rectangles = SelectionRectanglesM(
        textSelection: local,
        rectangles: nodeRectangles,
        docRelPosition: docRelPosition,
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
  // And also at the moment it's not that big of a problem. Maybe we will improve in the future.
  List<MarkerM> getMarkersToRender(
    Offset effectiveOffset,
    LineM line,
    RenderContentProxyBox? underlyingText,
  ) {
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
        final docRelPosition = underlyingText?.localToGlobal(const Offset(0, 0), ancestor: state.refs.renderer);
        final nodeOffset = _nodeUtils.getDocumentOffset(node);
        final renderedMarker = marker.copyWith(
          // For markers that have been extracted at init we already have the text selection.
          // However, for markers that are freshly generated we don't have the text selection defined as a property on the marker.
          // And actually it is not needed. We only need this information when going out of the library to the client code.
          // While inside the library code we always have access to the text selection data by studying the information provided in the node.
          // When a new marker is inserted it is passed to the format() method, then to the rules and then to composes().
          // Once compose completes, it then calls the runBuild() which means a new build() cycle starts.
          // During the build we always have access to the selection values, once again by looking at the document data.
          textSelection: TextSelection(baseOffset: nodeOffset, extentOffset: nodeOffset + node.charsNum),
          rectangles: rectangles,
          docRelPosition: docRelPosition,
        );

        // Collect markers and pixel coordinates
        allMarkers.add(renderedMarker);
      });
    }

    return allMarkers;
  }

  // A node can host multiple attributes, one of them is the markers attribute.
  List<MarkerM> _getTheMarkersAttributeFromNode(NodeM node) {
    return node.style.attributes.values
        .firstWhere(
          (attribute) => attribute.key == AttributesM.markers.key,
          orElse: () => AttributeM('', AttributeScope.INLINE, null),
        )
        .value;
  }

  // === HEADINGS ===

  HeadingM? getHeadingToRender(
    Offset effectiveOffset,
    LineM line,
    RenderContentProxyBox? underlyingText,
  ) {
    HeadingM? _heading;

    final headingAttr = line.style.attributes.values.firstWhere(
      (attribute) => attribute.key == AttributesM.header.key,
      orElse: () => AttributeM('', AttributeScope.INLINE, null),
    );
    final hasHeading = _headingIsCorrectType(headingAttr);

    if (hasHeading) {
      final heading = HeadingM(
        text: line.toPlainText(),
      );
      final docRelPosition = underlyingText?.localToGlobal(
        const Offset(0, 0),
        ancestor: state.refs.renderer,
      );

      // Text selection in every line
      final selection = TextSelection(baseOffset: 0, extentOffset: line.charsNum);

      // Text selection in the entire document
      final lineOffset = _nodeUtils.getDocumentOffset(line);
      final docTextSelection = TextSelection(
        baseOffset: lineOffset,
        extentOffset: lineOffset + line.charsNum,
      );
      final rectangles = underlyingText?.getBoxesForSelection(selection);
      final renderedHeading = heading.copyWith(
        docRelPosition: docRelPosition,
        rectangles: rectangles,
        selection: docTextSelection,
      );

      _heading = renderedHeading;
    }

    return _heading;
  }

  bool _headingIsCorrectType(AttributeM<dynamic> headingAttr) {
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

  // === SELECTED LINK ===

  SelectionRectanglesM? getSelectedLinkRectangles(
    TextSelection textSelection,
    LineM line,
    EditorState state,
    RenderContentProxyBox underlyingText,
  ) {
    SelectionRectanglesM? rectangles;

    // Iterate trough all the children of a line.
    // Children are fragments containing a unique combination of attributes.
    final lineContainsSelection = _lineContainsSelection(
      line,
      textSelection,
    );

    for (final node in line.children) {
      final hasLink = node.style.containsKey(AttributesM.link.key);

      if (hasLink) {
        if (lineContainsSelection) {
          final hasSelectedNode = _nodeUtils.containsOffset(node, textSelection.baseOffset);

          if (hasSelectedNode) {
            final local = _selectionRendererService.getLocalSelection(line, textSelection, false);
            final docRelPosition = underlyingText.localToGlobal(const Offset(0, 0), ancestor: state.refs.renderer);
            final nodeRectangles = getRectanglesFromNode(node, underlyingText);

            rectangles = SelectionRectanglesM(
              docRelPosition: docRelPosition,
              rectangles: nodeRectangles,
              textSelection: local,
            );
          }
        }
      }
    }

    return rectangles;
  }

  // === DRAW SHAPES ===

  // Draws a rectangle around the margins of the node.
  // Border radius can be defined.
  void drawRectanglesFromNode(
    TextPaintCfgM cfg,
    NodeM node,
    Offset effectiveOffset,
  ) {
    final rectangles = getRectanglesFromNode(node, cfg.underlyingText);

    drawRectangles(
      rectangles,
      effectiveOffset,
      cfg.context,
      cfg.inlineCodeStyle.backgroundColor!,
      cfg.inlineCodeStyle.radius,
    );
  }

  // Get the rectangles needed to encompass a slice of text (node).
  List<TextBox> getRectanglesFromNode(
    NodeM node,
    RenderContentProxyBox? underlyingText,
  ) {
    final textRange = TextSelection(
      baseOffset: _nodeUtils.getOffset(node),
      extentOffset: _nodeUtils.getOffset(node) + node.charsNum,
    );
    final rectangles = underlyingText!.getBoxesForSelection(textRange);

    return rectangles;
  }

  // Draws the rectangles as provided on the canvas.
  List<TextBox> drawRectangles(
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

  bool isRectangleHovered(TextBox area, Offset pointer, Offset offset) {
    final x = pointer.dx - offset.dx;
    final y = pointer.dy - offset.dy;
    final xHovered = area.left < x && x < area.right;
    final yHovered = area.top < y && y < area.bottom;
    return xHovered && yHovered;
  }

  // === PRIVATE ===

  bool _lineContainsSelection(LineM line, TextSelection selection) {
    final lineOffset = _nodeUtils.getDocumentOffset(line);
    return lineOffset <= selection.end && selection.start <= lineOffset + line.charsNum - 1;
  }
}
