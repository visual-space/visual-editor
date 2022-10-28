import 'package:flutter/material.dart';

import '../../documents/models/nodes/line.model.dart';
import '../../headings/models/heading.model.dart';
import '../../highlights/models/highlight.model.dart';
import '../../markers/models/marker.model.dart';
import '../../shared/models/selection-rectangles.model.dart';
import '../../shared/state/editor.state.dart';
import '../models/vertical-spacing.model.dart';
import '../services/styles.utils.dart';
import 'editable-text-line-box-renderer.dart';
import 'editable-text-line-leading-and-body.dart';

// Receives as a child a regular life of text made of text spans.
// Over the basic rich text made from spans it adds additional layouting or styling
// For example:
// - checkboxes for todos
// - colored backgrounds for code blocks
// - bullets for bullets lists
// Additionally it renders as an overlay the text selection or highlights and markers boxes.
//
// Some key things to note about the type of RenderObject a widget would extend:
// - If a widget has zero number of children, it extends LeafRenderObjectWidget
// - If it has one child, it extends SingleChildRenderObjectWidget
// - If it has two or more children, it extends MultiChildRenderObjectWidget
// Al of them inherit from RenderObjectWidget.
//
// UNCLEAR SO FAR
// This widget was not properly documented when it was first created.
// Traced back in the git log and there's not explanation why this way created this way.
// This renderer seems to be a custom implementation of RenderObjectWidget
// because none of the above RendererObjects don't fit the needs of this particular one (not sure what are the needs).
// As of Oct 2022 it's unclear why we needed this particular setup.
// I can't see why we don't have a MultiChildRenderObjectWidget instead of this particular setup.
// So far I can see that there are 2 widgets provided depending which node generates this widget (line or block).
// Blocks do provide a leading widget (bullet, checkbox, etc), lines don't.
// It appears that EditableTextLineLeadingAndBody is used to register 2 distinct widgets (leading and body) in the slots of a Render.
// However it's a complete mistery why we need this setup.
// There's no comment about this choice, not in Quill, not in Zefyr.
// I assumed it might be either:
// - Perf - But they seem to update at once, so no perf benefit
// - Needing to render 2 widgets in one paint area.
//       - It's possible to do this with one renderer
//       - There's no clear need why we need to render leading and body at once.
// The current action is to contact the original author and ask him directly. Hopefully we get an answer. (will update after)
// ignore: must_be_immutable
class EditableTextLineWidgetRenderer extends RenderObjectWidget {
  final LineM line;
  final Widget? leading;
  final Widget underlyingText;
  final double indentWidth;
  final VerticalSpacing verticalSpacing;
  final TextDirection textDirection;
  final TextSelection textSelection;
  final List<HighlightM> highlights;
  final List<HighlightM> hoveredHighlights;
  final List<MarkerM> hoveredMarkers;
  final bool hasFocus;
  final double devicePixelRatio;

  // We need to cache the renderer so we can query for markers rectangles coordinates after the build cycle.
  EditableTextLineBoxRenderer? _renderer;

  // Used internally to retrieve the state from the EditorController instance to which this button is linked to.
  // Can't be accessed publicly (by design) to avoid exposing the internals of the library.
  late EditorState _state;

  void setState(EditorState state) {
    _state = state;
  }

  EditableTextLineWidgetRenderer({
    required this.line,
    required this.leading,
    required this.underlyingText,
    required this.indentWidth,
    required this.verticalSpacing,
    required this.textDirection,
    required this.textSelection,
    required this.highlights,
    required this.hoveredHighlights,
    required this.hoveredMarkers,
    required this.hasFocus,
    required this.devicePixelRatio,
    required EditorState state,
  }) {
    setState(state);
  }

  // An element is an instantiation of a widget in the widget tree. (RenderObjectElement)
  @override
  RenderObjectElement createElement() {
    return EditableTextLineLeadingAndBody(this);
  }

  @override
  RenderObject createRenderObject(BuildContext context) {
    final defaultStyles = getDefaultStyles(context); // TODO Use from state

    // Type of EditableBoxRenderer
    _renderer = EditableTextLineBoxRenderer(
      line: line,
      textDirection: textDirection,
      textSelection: textSelection,
      highlights: highlights,
      hoveredHighlights: hoveredHighlights,
      hoveredMarkers: hoveredMarkers,
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
    covariant EditableTextLineBoxRenderer renderObject,
  ) {
    _renderer = renderObject;

    // Calling these setters is essential.
    // They do the diff checking to figure out if we want to invoke safeMarkNeedsPaint()
    // TODO Some values are missing because I was not fully aware how this works when I did the migration.
    // They will be restored on a need to have basis.
    renderObject
      ..setState(_state)
      ..setLine(line)
      ..setPadding(_getPadding())
      ..setTextSelection(textSelection)
      // TODO Must be restored
      // ..setTextDirection(textDirection)
      // ..setColor(color)
      // ..setEnableInteractiveSelection(enableInteractiveSelection)
      // ..setInlineCodeStyle(defaultStyles.inlineCode!)
      ..setHighlights(highlights)
      ..setHoveredHighlights(hoveredHighlights)
      ..setHoveredMarkers(hoveredMarkers);
  }

  // Avoids exposing the private renderer, it only collects the markers.
  List<MarkerM> getMarkersWithCoordinates() {
    return _renderer?.getMarkersWithCoordinates() ?? [];
  }

  // Avoids exposing the private renderer, it only collects the highlights.
  SelectionRectanglesM? getHighlightCoordinates(HighlightM highlight) {
    return _renderer?.getHighlightCoordinates(highlight);
  }

  // Avoids exposing the private renderer, it only collects the selection.
  SelectionRectanglesM? getSelectionCoordinates() {
    return _renderer?.getSelectionCoordinates();
  }

  // Avoids exposing the private renderer, it only collects the headings.
  HeadingM? getRenderedHeadingCoordinates() {
    return _renderer?.getRenderedHeadingCoordinates();
  }

  EdgeInsetsGeometry _getPadding() {
    return EdgeInsetsDirectional.only(
      start: indentWidth,
      top: verticalSpacing.top,
      bottom: verticalSpacing.bottom,
    );
  }
}
