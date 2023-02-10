import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/rendering.dart';

import '../../cursor/controllers/cursor.controller.dart';
import '../../document/models/nodes/container.model.dart' as container_node;
import '../../document/models/nodes/line.model.dart';
import '../../document/services/nodes/node.utils.dart';
import '../../headings/models/heading.model.dart';
import '../../highlights/models/highlight.model.dart';
import '../../markers/models/marker.model.dart';
import '../../shared/models/content-proxy-box-renderer.model.dart';
import '../../shared/models/editable-box-renderer.model.dart';
import '../../shared/models/selection-rectangles.model.dart';
import '../../shared/state/editor.state.dart';
import '../../shared/utils/platform.utils.dart';
import '../../shared/utils/shared.utils.dart';
import '../../styles/models/doc-tree/inline-code-style.model.dart';
import '../models/text-line-slot.enum.dart';
import '../models/text-paint-cfg.model.dart';
import '../services/lines/editable-text-paint.service.dart';
import '../services/rectangles.service.dart';

// Over the basic rich text made from spans it adds additional layouting or styling
// For example:
// - checkboxes for todos
// - colored backgrounds for code doc-tree
// - bullets for bullets lists
// Additionally it renders as an overlay the text selection or highlights and markers boxes.
class EditableTextLineBoxRenderer extends EditableBoxRenderer {
  late final RectanglesService _rectanglesService;
  late final EditableTextPaintService _editableTextPaintService;
  final _nodeUtils = NodeUtils();

  RenderBox? _leading;
  RenderContentProxyBox? _underlyingText;
  LineM line;
  TextDirection textDirection;
  TextSelection selection;
  List<HighlightM> highlights;
  List<HighlightM> hoveredHighlights;
  List<HighlightM> _prevHighlights = [];
  List<HighlightM> _prevHoveredHighlights = [];
  List<MarkerM> hoveredMarkers;
  List<MarkerM> _prevHoveredMarkers = [];
  double devicePixelRatio;
  EdgeInsetsGeometry padding;
  late CursorController cursorController;
  EdgeInsets? _resolvedPadding;
  bool? _containsCursor;
  List<TextBox>? _selectedRects;
  Rect _caretPrototype = Rect.zero;
  InlineCodeStyle inlineCodeStyle;
  final Map<TextLineSlot, RenderBox> children = <TextLineSlot, RenderBox>{};
  late StreamSubscription _cursorState$L;
  late StreamSubscription _toggleMarkers$L;
  late StreamSubscription _toggleMarkersByTypes$L;
  Offset _cachedOffset = Offset(0, 0);
  void Function(List<MarkerM> markers)
      cacheRenderedMarkersCoordinatesInStateStore;
  late EditorState _state;

  // Creates new editable paragraph render box.
  EditableTextLineBoxRenderer({
    required this.line,
    required this.textDirection,
    required this.selection,
    required this.highlights,
    required this.hoveredHighlights,
    required this.hoveredMarkers,
    required this.devicePixelRatio,
    required this.padding,
    required this.inlineCodeStyle,
    required this.cacheRenderedMarkersCoordinatesInStateStore,
    required EditorState state,
  }) {
    _rectanglesService = RectanglesService(state);
    _editableTextPaintService = EditableTextPaintService(state);

    cacheStateStore(state);
    // Because the highlights array is provided as reference from the store we need to
    // shallow clone the contents to make sure we can compare old vs new on update.
    _prevHighlights = [...highlights];
    _prevHoveredHighlights = [...hoveredHighlights];
    _prevHoveredMarkers = [...hoveredMarkers];
    cursorController = state.refs.cursorController;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    _cachedOffset = offset;

    _editableTextPaintService.paint(
      TextPaintCfgM(
        context,
        offset,
        _leading,
        _underlyingText,
        inlineCodeStyle,
        line,
        containsCursor,
        selection,
        _lineContainsSelection,
        _selectedRects,
        _caretPrototype,
        devicePixelRatio,
      ),
    );
  }

  // We need the markers rectangles coordinates as rendered against the actual lines of text after build().
  // One way would be to tap into the paint() method (as attempted initially).
  // The paint() method is triggered by the insertion of new chars and by the pulsating caret animation (30-60 fps).
  // Each time the paint() method runs we had to cache the rectangles and the offset of their parent lines.
  // This means we are wastefully updating the state store 30-60 times per second with mostly the same info.
  // Another issue when using the paint() method is that after the first render
  // we get only the markers from the paragraphs that are clicked.
  // This happens because the Flutter change detection runs the paint() method
  // only for the paragraphs that are clicked/interacted with.
  // To avoid the above issues we made the effort of splitting the code that
  // generates the markers rectangles from the code that paints them.
  // FYI: Markers are already split as styles between lines and their extents trimmed to fit the line.
  // Therefore for makers we are not getting duplicate rectangles, that's why we can extract them right away.
  // TODO Could be merged with getHighlightsCoordinates(), there's no "separate concern" for this method
  List<MarkerM> getMarkersWithCoordinates() {
    var markers = <MarkerM>[];

    if (_underlyingText != null) {
      final parentData = _underlyingText!.parentData as BoxParentData;
      final effectiveOffset = _cachedOffset + parentData.offset;

      // Markers
      markers = _rectanglesService.getMarkersToRender(
        effectiveOffset,
        line,
        _underlyingText,
      );
    }

    return markers;
  }

  // We need the coordinates of every header stored
  // They will be useful for custom features such as scroll to tapped heading
  HeadingM? getRenderedHeadingCoordinates() {
    HeadingM? heading;

    if (_underlyingText != null) {
      final parentData = _underlyingText!.parentData as BoxParentData;
      final effectiveOffset = _cachedOffset + parentData.offset;

      heading = _rectanglesService.getHeadingToRender(
        effectiveOffset,
        line,
        _underlyingText,
      );
    }

    return heading;
  }

  // We need the highlights rectangles coordinates as rendered against the actual lines of text after build().
  // Because highlights can span multiple lines we want only the rectangles of the current line.
  // Read the doc comment for the getRenderedMarkersCoordinates() method to learn more.
  SelectionRectanglesM? getHighlightCoordinates(HighlightM highlight) {
    SelectionRectanglesM? rectangles;

    if (_underlyingText != null) {
      final parentData = _underlyingText!.parentData as BoxParentData;
      final effectiveOffset = _cachedOffset + parentData.offset;

      // Highlights
      rectangles = _rectanglesService.getSelectionCoordinates(
        highlight.textSelection,
        effectiveOffset,
        line,
        _underlyingText!,
      );
    }

    return rectangles;
  }

  // We need the selection rectangles coordinates as rendered against the actual lines of text after build().
  // Because a selection can span multiple lines we want only the rectangles of the current line.
  // Read the doc comment for the getRenderedMarkersCoordinates() method to learn more.
  SelectionRectanglesM? getSelectionCoordinates() {
    SelectionRectanglesM? rectangles;

    if (_underlyingText != null) {
      final parentData = _underlyingText!.parentData as BoxParentData;
      final effectiveOffset = _cachedOffset + parentData.offset;

      // Selection
      rectangles = _rectanglesService.getSelectionCoordinates(
        _state.selection.selection,
        effectiveOffset,
        line,
        _underlyingText!,
      );
    }

    return rectangles;
  }

  SelectionRectanglesM? getSelectedLinkRectangles() {
    SelectionRectanglesM? rectangles;

    if (_underlyingText != null) {
      // Selected Link
      rectangles = _rectanglesService.getSelectedLinkRectangles(
        _state.selection.selection,
        line,
        _state,
        _underlyingText!,
      );
    }

    return rectangles;
  }

  void setTextSelection(TextSelection _selection) {
    if (selection == _selection) {
      return;
    }

    final containsSelection = _lineContainsSelection(selection);

    if (_attachedToCursorController) {
      _cursorState$L.cancel();
      cursorController.color.removeListener(safeMarkNeedsPaint);
      _attachedToCursorController = false;
    }

    selection = _selection;
    _selectedRects = null;
    _containsCursor = null;

    if (attached && containsCursor()) {
      _cursorState$L = _state.cursor.paintCursor$.listen((_) {
        markNeedsLayout();
      });
      cursorController.color.addListener(safeMarkNeedsPaint);
      _attachedToCursorController = true;
    }

    // TODO Review, seems to be the same code
    if (containsSelection || _lineContainsSelection(selection)) {
      safeMarkNeedsPaint();
    }
  }

  // If new highlights are detected then we trigger widget repaint
  void setHighlights(List<HighlightM> _highlights) {
    final sameHighlights = areListsEqual(_prevHighlights, _highlights);

    if (sameHighlights) {
      return;
    }

    _prevHighlights = [..._highlights];
    safeMarkNeedsPaint();
  }

  // If any highlight is hovered then we trigger widget repaint
  void setHoveredHighlights(List<HighlightM> _hoveredHighlights) {
    final sameHighlights = areListsEqual(
      _prevHoveredHighlights,
      _hoveredHighlights,
    );

    if (sameHighlights) {
      return;
    }

    _prevHoveredHighlights = [..._hoveredHighlights];
    safeMarkNeedsPaint();
  }

  // If any marker is hovered then we trigger widget repaint
  void setHoveredMarkers(List<MarkerM> _hoveredMarkers) {
    final sameMarkers = areListsEqual(_prevHoveredMarkers, _hoveredMarkers);

    if (sameMarkers) {
      return;
    }

    _prevHoveredMarkers = [..._hoveredMarkers];
    safeMarkNeedsPaint();
  }

  // If a new line is detected then we trigger widget repaint
  void setLine(LineM _line) {
    if (line == _line) {
      return;
    }

    line = _line;
    _containsCursor = null;
    markNeedsLayout();
  }

  void setPadding(EdgeInsetsGeometry _padding) {
    assert(_padding.isNonNegative);

    if (padding == _padding) {
      return;
    }

    padding = _padding;
    _resolvedPadding = null;
    markNeedsLayout();
  }

  void setLeading(RenderBox? leading) {
    _leading = _updateChild(_leading, leading, TextLineSlot.LEADING);
  }

  void setBody(RenderContentProxyBox? proxyBox) {
    _underlyingText = _updateChild(
      _underlyingText,
      proxyBox,
      TextLineSlot.UNDERLYING_TEXT,
    ) as RenderContentProxyBox?;
  }

  void safeMarkNeedsPaint() {
    if (!attached) {
      // Should not paint if it was unattached.
      return;
    }

    markNeedsPaint();
  }

  // === SELECTION ===

  bool containsCursor() {
    return _containsCursor ??= cursorController.isFloatingCursorActive
        ? _nodeUtils.containsOffset(
            line,
            cursorController.floatingCursorTextPosition.value!.offset,
          )
        : selection.isCollapsed &&
            _nodeUtils.containsOffset(line, selection.baseOffset);
  }

  @override
  TextSelectionPoint getBaseEndpointForSelection(TextSelection selection) {
    return _getEndpointForSelection(selection, true);
  }

  @override
  TextSelectionPoint getExtentEndpointForSelection(TextSelection selection) {
    return _getEndpointForSelection(selection, false);
  }

  TextSelectionPoint _getEndpointForSelection(
    TextSelection selection,
    bool first,
  ) {
    if (selection.isCollapsed) {
      return TextSelectionPoint(
        Offset(0, preferredLineHeight(selection.extent)) +
            getOffsetForCaret(selection.extent),
        null,
      );
    }

    final boxes = _getBoxes(selection);
    assert(boxes.isNotEmpty);
    final targetBox = first ? boxes.first : boxes.last;

    return TextSelectionPoint(
      Offset(first ? targetBox.start : targetBox.end, targetBox.bottom),
      targetBox.direction,
    );
  }

  @override
  TextRange getLineBoundary(TextPosition position) {
    final lineDy = getOffsetForCaret(position)
        .translate(0, 0.5 * preferredLineHeight(position))
        .dy;
    final lineBoxes = _getBoxes(
      TextSelection(
        baseOffset: 0,
        extentOffset: line.charsNum - 1,
      ),
    )
        .where((element) => element.top < lineDy && element.bottom > lineDy)
        .toList(growable: false);

    return TextRange(
      start: getPositionForOffset(Offset(lineBoxes.first.left, lineDy)).offset,
      end: getPositionForOffset(Offset(lineBoxes.last.right, lineDy)).offset,
    );
  }

  @override
  Offset getOffsetForCaret(TextPosition position) {
    return _underlyingText!.getOffsetForCaret(position, _caretPrototype) +
        (_underlyingText!.parentData as BoxParentData).offset;
  }

  @override
  TextPosition? getPositionAbove(TextPosition position) {
    return _getPosition(position, -0.5);
  }

  @override
  TextPosition? getPositionBelow(TextPosition position) {
    return _getPosition(position, 1.5);
  }

  @override
  bool get isRepaintBoundary => true;

  @override
  TextPosition getPositionForOffset(Offset offset) {
    return _underlyingText!.getPositionForOffset(
      offset - (_underlyingText!.parentData as BoxParentData).offset,
    );
  }

  @override
  TextRange getWordBoundary(TextPosition position) {
    return _underlyingText!.getWordBoundary(position);
  }

  @override
  double preferredLineHeight(TextPosition position) {
    return _underlyingText!.preferredLineHeight;
  }

  @override
  container_node.ContainerM get container => line;

  double get cursorWidth => cursorController.style.width;

  double get cursorHeight =>
      cursorController.style.height ??
      preferredLineHeight(const TextPosition(offset: 0));

  // === RENDER BOX OVERRIDES ===

  bool _attachedToCursorController = false;

  @override
  void attach(covariant PipelineOwner owner) {
    super.attach(owner);

    for (final child in _children) {
      child.attach(owner);
    }

    cursorController.floatingCursorTextPosition.addListener(
      _onFloatingCursorChange,
    );

    if (containsCursor()) {
      _cursorState$L = _state.cursor.paintCursor$.listen((_) {
        markNeedsLayout();
      });
      cursorController.color.addListener(safeMarkNeedsPaint);
      _attachedToCursorController = true;
    }

    // Toggle markers
    _toggleMarkers$L = _state.markersVisibility.toggleMarkers$.listen((_) {
      markNeedsPaint();
    });

    _toggleMarkersByTypes$L =
        _state.markersTypes.toggleMarkersByTypes$.listen((_) {
      markNeedsPaint();
    });
  }

  @override
  void detach() {
    super.detach();

    for (final child in _children) {
      child.detach();
    }

    cursorController.floatingCursorTextPosition.removeListener(
      _onFloatingCursorChange,
    );

    if (_attachedToCursorController) {
      _cursorState$L.cancel();
      cursorController.color.removeListener(safeMarkNeedsPaint);
      _attachedToCursorController = false;
    }

    _toggleMarkers$L.cancel();
    _toggleMarkersByTypes$L.cancel();
  }

  @override
  void redepthChildren() {
    _children.forEach(redepthChild);
  }

  @override
  void visitChildren(RenderObjectVisitor visitor) {
    _children.forEach(visitor);
  }

  @override
  List<DiagnosticsNode> debugDescribeChildren() {
    final value = <DiagnosticsNode>[];

    void add(RenderBox? child, String name) {
      if (child != null) {
        value.add(child.toDiagnosticsNode(name: name));
      }
    }

    add(_leading, 'leading');
    add(_underlyingText, 'underlyingText');

    return value;
  }

  @override
  bool get sizedByParent => false;

  @override
  double computeMinIntrinsicWidth(double height) {
    _resolvePadding();

    final horizontalPadding = _resolvedPadding!.left + _resolvedPadding!.right;
    final verticalPadding = _resolvedPadding!.top + _resolvedPadding!.bottom;
    final leadingWidth = _leading == null
        ? 0
        : _leading!.getMinIntrinsicWidth(height - verticalPadding).ceil();
    final underlyingTextWidth = _underlyingText == null
        ? 0
        : _underlyingText!
            .getMinIntrinsicWidth(
              math.max(0, height - verticalPadding),
            )
            .ceil();

    return horizontalPadding + leadingWidth + underlyingTextWidth;
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    _resolvePadding();

    final horizontalPadding = _resolvedPadding!.left + _resolvedPadding!.right;
    final verticalPadding = _resolvedPadding!.top + _resolvedPadding!.bottom;
    final leadingWidth = _leading == null
        ? 0
        : _leading!.getMaxIntrinsicWidth(height - verticalPadding).ceil();
    final underlyingTextWidth = _underlyingText == null
        ? 0
        : _underlyingText!
            .getMaxIntrinsicWidth(
              math.max(0, height - verticalPadding),
            )
            .ceil();

    return horizontalPadding + leadingWidth + underlyingTextWidth;
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    _resolvePadding();

    final horizontalPadding = _resolvedPadding!.left + _resolvedPadding!.right;
    final verticalPadding = _resolvedPadding!.top + _resolvedPadding!.bottom;

    if (_underlyingText != null) {
      return _underlyingText!.getMinIntrinsicHeight(
            math.max(0, width - horizontalPadding),
          ) +
          verticalPadding;
    }

    return verticalPadding;
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    _resolvePadding();
    final horizontalPadding = _resolvedPadding!.left + _resolvedPadding!.right;
    final verticalPadding = _resolvedPadding!.top + _resolvedPadding!.bottom;

    if (_underlyingText != null) {
      return _underlyingText!.getMaxIntrinsicHeight(
            math.max(0, width - horizontalPadding),
          ) +
          verticalPadding;
    }

    return verticalPadding;
  }

  @override
  double computeDistanceToActualBaseline(TextBaseline baseline) {
    _resolvePadding();
    return _underlyingText!.getDistanceToActualBaseline(baseline)! +
        _resolvedPadding!.top;
  }

  @override
  void performLayout() {
    final constraints = this.constraints;
    _selectedRects = null;

    _resolvePadding();
    assert(_resolvedPadding != null);

    if (_underlyingText == null && _leading == null) {
      size = constraints.constrain(
        Size(
          _resolvedPadding!.left + _resolvedPadding!.right,
          _resolvedPadding!.top + _resolvedPadding!.bottom,
        ),
      );
      return;
    }

    final innerConstraints = constraints.deflate(_resolvedPadding!);
    final indentWidth = textDirection == TextDirection.ltr
        ? _resolvedPadding!.left
        : _resolvedPadding!.right;

    _underlyingText!.layout(innerConstraints, parentUsesSize: true);
    (_underlyingText!.parentData as BoxParentData).offset = Offset(
      _resolvedPadding!.left,
      _resolvedPadding!.top,
    );

    if (_leading != null) {
      final leadingConstraints = innerConstraints.copyWith(
        minWidth: indentWidth,
        maxWidth: indentWidth,
        maxHeight: _underlyingText!.size.height,
      );
      _leading!.layout(leadingConstraints, parentUsesSize: true);
      (_leading!.parentData as BoxParentData).offset = Offset(
        0,
        _resolvedPadding!.top,
      );
    }

    size = constraints.constrain(
      Size(
        _resolvedPadding!.left +
            _underlyingText!.size.width +
            _resolvedPadding!.right,
        _resolvedPadding!.top +
            _underlyingText!.size.height +
            _resolvedPadding!.bottom,
      ),
    );

    _computeCaretPrototype();
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    if (_leading != null) {
      final childParentData = _leading!.parentData as BoxParentData;
      final isHit = result.addWithPaintOffset(
        offset: childParentData.offset,
        position: position,
        hitTest: (result, transformed) {
          assert(transformed == position - childParentData.offset);

          return _leading!.hitTest(result, position: transformed);
        },
      );

      if (isHit) {
        return true;
      }
    }

    if (_underlyingText == null) {
      return false;
    }

    final parentData = _underlyingText!.parentData as BoxParentData;

    return result.addWithPaintOffset(
      offset: parentData.offset,
      position: position,
      hitTest: (result, position) {
        return _underlyingText!.hitTest(
          result,
          position: position,
        );
      },
    );
  }

  @override
  Rect getLocalRectForCaret(TextPosition position) {
    final caretOffset = getOffsetForCaret(position);
    var rect = Rect.fromLTWH(
      0,
      0,
      cursorWidth,
      cursorHeight,
    ).shift(caretOffset);
    final cursorOffset = cursorController.style.offset;

    // Add additional cursor offset (generally only if on iOS).
    if (cursorOffset != null) {
      rect = rect.shift(cursorOffset);
    }

    return rect;
  }

  @override
  TextPosition globalToLocalPosition(TextPosition position) {
    assert(
      _nodeUtils.containsOffset(container, position.offset),
      'The provided text position is not in the current node',
    );

    return TextPosition(
      offset: position.offset - _nodeUtils.getDocumentOffset(container),
      affinity: position.affinity,
    );
  }

  @override
  Rect getCaretPrototype(TextPosition position) => _caretPrototype;

  Iterable<RenderBox> get _children sync* {
    if (_leading != null) {
      yield _leading!;
    }
    if (_underlyingText != null) {
      yield _underlyingText!;
    }
  }

  void cacheStateStore(EditorState state) {
    _state = state;
  }

  // === PRIVATE ===

  RenderBox? _updateChild(
    RenderBox? old,
    RenderBox? newChild,
    TextLineSlot slot,
  ) {
    if (old != null) {
      dropChild(old);
      children.remove(slot);
    }

    if (newChild != null) {
      children[slot] = newChild;
      adoptChild(newChild);
    }

    return newChild;
  }

  List<TextBox> _getBoxes(TextSelection textSelection) {
    final parentData = _underlyingText!.parentData as BoxParentData?;

    return _underlyingText!.getBoxesForSelection(textSelection).map((box) {
      return TextBox.fromLTRBD(
        box.left + parentData!.offset.dx,
        box.top + parentData.offset.dy,
        box.right + parentData.offset.dx,
        box.bottom + parentData.offset.dy,
        box.direction,
      );
    }).toList(growable: false);
  }

  void _resolvePadding() {
    if (_resolvedPadding != null) {
      return;
    }

    _resolvedPadding = padding.resolve(textDirection);

    assert(_resolvedPadding!.isNonNegative);
  }

  TextPosition? _getPosition(TextPosition textPosition, double dyScale) {
    assert(textPosition.offset < line.charsNum);
    final offset = getOffsetForCaret(textPosition)
        .translate(0, dyScale * preferredLineHeight(textPosition));
    if (_underlyingText!.size.contains(
      offset - (_underlyingText!.parentData as BoxParentData).offset,
    )) {
      return getPositionForOffset(offset);
    }
    return null;
  }

  // TODO: This is no longer producing the highest-fidelity caret
  // heights for Android, especially when non-alphabetic languages are involved.
  // The current implementation overrides the height set here with the full measured height of the
  // text on Android which looks superior (subjectively and in terms of fidelity) in _paintCaret.
  // We should rework this properly to once again match the platform.
  // The constant _kCaretHeightOffset scales poorly for small font sizes.
  // On iOS, the cursor is taller than the cursor on Android.
  // The height of the cursor for iOS is approximate and obtained through an eyeball comparison.
  void _computeCaretPrototype() {
    if (isAppleOS()) {
      _caretPrototype = Rect.fromLTWH(0, 0, cursorWidth, cursorHeight + 2);
    } else {
      _caretPrototype = Rect.fromLTWH(0, 2, cursorWidth, cursorHeight - 4.0);
    }
  }

  void _onFloatingCursorChange() {
    _containsCursor = null;
    markNeedsPaint();
  }

  bool _lineContainsSelection(TextSelection selection) {
    final lineOffset = _nodeUtils.getDocumentOffset(line);
    return lineOffset <= selection.end &&
        selection.start <= lineOffset + line.charsNum - 1;
  }
}
