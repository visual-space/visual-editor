import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../cursor/controllers/cursor.controller.dart';
import '../../cursor/widgets/cursor-painter.dart';
import '../../documents/models/attributes/attributes.model.dart';
import '../../documents/models/nodes/container.model.dart' as container_node;
import '../../documents/models/nodes/line.model.dart';
import '../../documents/models/nodes/text.model.dart';
import '../../highlights/models/highlight.model.dart';
import '../../selection/services/text-selection.utils.dart';
import '../../shared/models/content-proxy-box-renderer.model.dart';
import '../../shared/models/editable-box-renderer.model.dart';
import '../../shared/state/editor.state.dart';
import '../../shared/utils/platform.utils.dart';
import '../models/inline-code-style.model.dart';
import '../models/text-line-slot.enum.dart';
import '../services/teyt-lines.utils.dart';

class EditableTextLineRenderer extends EditableBoxRenderer {
  final _textSelectionUtils = TextSelectionUtils();

  RenderBox? _leading;
  RenderContentProxyBox? _body;
  LineM line;
  TextDirection textDirection;
  TextSelection textSelection;
  double devicePixelRatio;
  EdgeInsetsGeometry padding;
  late CursorController cursorController;
  EdgeInsets? _resolvedPadding;
  bool? _containsCursor;
  List<TextBox>? _selectedRects;
  Rect _caretPrototype = Rect.zero;
  InlineCodeStyle inlineCodeStyle;
  final Map<TextLineSlot, RenderBox> children = <TextLineSlot, RenderBox>{};
  late StreamSubscription _cursorStateListener;
  late StreamSubscription _toggleMarkersListener;

  // Used internally to retrieve the state from the EditorController instance to which this button is linked to.
  // Can't be accessed publicly (by design) to avoid exposing the internals of the library.
  late EditorState _state;

  void setState(EditorState state) {
    _state = state;
  }

  // Creates new editable paragraph render box.
  EditableTextLineRenderer({
    required this.line,
    required this.textDirection,
    required this.textSelection,
    required this.devicePixelRatio,
    required this.padding,
    required this.inlineCodeStyle,
    required EditorState state,
  }) {
    setState(state);
    cursorController = state.refs.cursorController;
  }

  void setTextSelection(TextSelection selection) {
    if (textSelection == selection) {
      return;
    }

    final containsSelection = _lineContainsSelection(textSelection);

    if (_attachedToCursorController) {
      _cursorStateListener.cancel();
      cursorController.color.removeListener(safeMarkNeedsPaint);
      _attachedToCursorController = false;
    }

    textSelection = selection;
    _selectedRects = null;
    _containsCursor = null;

    if (attached && containsCursor()) {
      _cursorStateListener = _state.cursor.updateCursor$.listen((_) {
        markNeedsLayout();
      });
      cursorController.color.addListener(safeMarkNeedsPaint);
      _attachedToCursorController = true;
    }

    if (containsSelection || _lineContainsSelection(textSelection)) {
      safeMarkNeedsPaint();
    }
  }

  void setLine(LineM _line) {
    if (line == _line) {
      return;
    }

    line = _line;
    _containsCursor = null;
    markNeedsLayout();
  }

  void setLeading(RenderBox? leading) {
    _leading = _updateChild(_leading, leading, TextLineSlot.LEADING);
  }

  void setBody(RenderContentProxyBox? b) {
    _body = _updateChild(_body, b, TextLineSlot.BODY) as RenderContentProxyBox?;
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
        ? line.containsOffset(
            cursorController.floatingCursorTextPosition.value!.offset,
          )
        : textSelection.isCollapsed &&
            line.containsOffset(textSelection.baseOffset);
  }

  @override
  TextSelectionPoint getBaseEndpointForSelection(
    TextSelection textSelection,
  ) {
    return _getEndpointForSelection(textSelection, true);
  }

  @override
  TextSelectionPoint getExtentEndpointForSelection(
    TextSelection textSelection,
  ) {
    return _getEndpointForSelection(textSelection, false);
  }

  TextSelectionPoint _getEndpointForSelection(
    TextSelection textSelection,
    bool first,
  ) {
    if (textSelection.isCollapsed) {
      return TextSelectionPoint(
        Offset(0, preferredLineHeight(textSelection.extent)) +
            getOffsetForCaret(textSelection.extent),
        null,
      );
    }

    final boxes = _getBoxes(textSelection);
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
      TextSelection(baseOffset: 0, extentOffset: line.length - 1),
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
    return _body!.getOffsetForCaret(position, _caretPrototype) +
        (_body!.parentData as BoxParentData).offset;
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
    return _body!.getPositionForOffset(
      offset - (_body!.parentData as BoxParentData).offset,
    );
  }

  @override
  TextRange getWordBoundary(TextPosition position) {
    return _body!.getWordBoundary(position);
  }

  @override
  double preferredLineHeight(TextPosition position) {
    return _body!.preferredLineHeight;
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
      _cursorStateListener = _state.cursor.updateCursor$.listen((_) {
        markNeedsLayout();
      });
      cursorController.color.addListener(safeMarkNeedsPaint);
      _attachedToCursorController = true;
    }

    // Toggle markers
    _toggleMarkersListener = _state.markersVisibility.toggleMarkers$.listen((_) {
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
      _cursorStateListener.cancel();
      cursorController.color.removeListener(safeMarkNeedsPaint);
      _attachedToCursorController = false;
    }

    _toggleMarkersListener.cancel();
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
    add(_body, 'body');

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
    final bodyWidth = _body == null
        ? 0
        : _body!
            .getMinIntrinsicWidth(
              math.max(0, height - verticalPadding),
            )
            .ceil();

    return horizontalPadding + leadingWidth + bodyWidth;
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    _resolvePadding();

    final horizontalPadding = _resolvedPadding!.left + _resolvedPadding!.right;
    final verticalPadding = _resolvedPadding!.top + _resolvedPadding!.bottom;
    final leadingWidth = _leading == null
        ? 0
        : _leading!.getMaxIntrinsicWidth(height - verticalPadding).ceil();
    final bodyWidth = _body == null
        ? 0
        : _body!
            .getMaxIntrinsicWidth(
              math.max(0, height - verticalPadding),
            )
            .ceil();

    return horizontalPadding + leadingWidth + bodyWidth;
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    _resolvePadding();

    final horizontalPadding = _resolvedPadding!.left + _resolvedPadding!.right;
    final verticalPadding = _resolvedPadding!.top + _resolvedPadding!.bottom;

    if (_body != null) {
      return _body!.getMinIntrinsicHeight(
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
    if (_body != null) {
      return _body!.getMaxIntrinsicHeight(
            math.max(0, width - horizontalPadding),
          ) +
          verticalPadding;
    }
    return verticalPadding;
  }

  @override
  double computeDistanceToActualBaseline(TextBaseline baseline) {
    _resolvePadding();
    return _body!.getDistanceToActualBaseline(baseline)! +
        _resolvedPadding!.top;
  }

  @override
  void performLayout() {
    final constraints = this.constraints;
    _selectedRects = null;

    _resolvePadding();
    assert(_resolvedPadding != null);

    if (_body == null && _leading == null) {
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

    _body!.layout(innerConstraints, parentUsesSize: true);
    (_body!.parentData as BoxParentData).offset = Offset(
      _resolvedPadding!.left,
      _resolvedPadding!.top,
    );

    if (_leading != null) {
      final leadingConstraints = innerConstraints.copyWith(
        minWidth: indentWidth,
        maxWidth: indentWidth,
        maxHeight: _body!.size.height,
      );
      _leading!.layout(leadingConstraints, parentUsesSize: true);
      (_leading!.parentData as BoxParentData).offset = Offset(
        0,
        _resolvedPadding!.top,
      );
    }

    size = constraints.constrain(
      Size(
        _resolvedPadding!.left + _body!.size.width + _resolvedPadding!.right,
        _resolvedPadding!.top + _body!.size.height + _resolvedPadding!.bottom,
      ),
    );

    _computeCaretPrototype();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    // Leading (bullets, checkboxes)
    if (_leading != null) {
      final parentData = _leading!.parentData as BoxParentData;
      final effectiveOffset = offset + parentData.offset;
      context.paintChild(_leading!, effectiveOffset);
    }

    if (_body != null) {
      final parentData = _body!.parentData as BoxParentData;
      final effectiveOffset = offset + parentData.offset;

      // Code
      if (inlineCodeStyle.backgroundColor != null) {
        for (final node in line.children) {
          final isInlineCodeOrCodeBlock = node is! TextM ||
              !node.style.containsKey(AttributesM.inlineCode.key);

          if (isInlineCodeOrCodeBlock) {
            continue;
          }

          TextLinesUtils.drawRectFromNode(node, effectiveOffset, context,
              inlineCodeStyle.backgroundColor!, inlineCodeStyle.radius, _body);
        }
      }

      // Markers
      if (_state.markersVisibility.visibility == true) {
        TextLinesUtils.renderMarkers(
          effectiveOffset,
          context,
          line,
          _state,
          _body,
        );
      }

      // Cursor above text (iOS)
      if (_state.refs.focusNode.hasFocus &&
          cursorController.show.value &&
          containsCursor() &&
          !cursorController.style.paintAboveText) {
        _paintCursor(context, effectiveOffset, line.hasEmbed);
      }

      // TextLine
      // The raw text, no highlights, only TextSpans with styling
      context.paintChild(_body!, effectiveOffset);

      // Cursor bellow text (Android)
      if (_state.refs.focusNode.hasFocus &&
          cursorController.show.value &&
          containsCursor() &&
          cursorController.style.paintAboveText) {
        _paintCursor(context, effectiveOffset, line.hasEmbed);
      }

      final selectionIsWithinDocBounds = _lineContainsSelection(
        textSelection,
      );

      if (_state.editorConfig.config.enableInteractiveSelection &&
          selectionIsWithinDocBounds) {
        final local = _textSelectionUtils.getLocalSelection(
          line,
          textSelection,
          false,
        );
        _selectedRects ??= _body!.getBoxesForSelection(local);
        _paintSelection(context, effectiveOffset);
      }

      // Highlights
      _state.highlights.highlights.forEach((highlight) {
        final highlightIsWithinDocBounds = _lineContainsSelection(
          highlight.textSelection,
        );

        if (highlightIsWithinDocBounds) {
          final local = _textSelectionUtils.getLocalSelection(
            line,
            highlight.textSelection,
            false,
          );
          final _highlightedRects = _body!.getBoxesForSelection(local);
          _paintHighlights(
            highlight,
            _highlightedRects,
            context,
            effectiveOffset,
          );
        }
      });
    }
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

    if (_body == null) {
      return false;
    }

    final parentData = _body!.parentData as BoxParentData;

    return result.addWithPaintOffset(
      offset: parentData.offset,
      position: position,
      hitTest: (result, position) {
        return _body!.hitTest(
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
    container.containsOffset(position.offset),
    'The provided text position is not in the current node',
    );

    return TextPosition(
      offset: position.offset - container.documentOffset,
      affinity: position.affinity,
    );
  }

  @override
  Rect getCaretPrototype(TextPosition position) => _caretPrototype;

  Iterable<RenderBox> get _children sync* {
    if (_leading != null) {
      yield _leading!;
    }
    if (_body != null) {
      yield _body!;
    }
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
    final parentData = _body!.parentData as BoxParentData?;

    return _body!.getBoxesForSelection(textSelection).map((box) {
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
    assert(textPosition.offset < line.length);
    final offset = getOffsetForCaret(textPosition)
        .translate(0, dyScale * preferredLineHeight(textPosition));
    if (_body!.size
        .contains(offset - (_body!.parentData as BoxParentData).offset)) {
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

  CursorPainter get _cursorPainter => CursorPainter(
    editable: _body,
    style: cursorController.style,
    prototype: _caretPrototype,
    color: cursorController.isFloatingCursorActive
        ? cursorController.style.backgroundColor
        : cursorController.color.value,
    devicePixelRatio: devicePixelRatio,
  );

  bool _lineContainsSelection(TextSelection selection) {
    return line.documentOffset <= selection.end &&
        selection.start <= line.documentOffset + line.length - 1;
  }

  void _paintSelection(
    PaintingContext context,
    Offset effectiveOffset,
  ) {
    assert(_selectedRects != null);

    final paint = Paint()..color = _state.platformStyles.styles.selectionColor;

    for (final box in _selectedRects!) {
      context.canvas.drawRect(box.toRect().shift(effectiveOffset), paint);
    }
  }

  void _paintHighlights(
    HighlightM highlight,
    List<TextBox> highlightedRects,
    PaintingContext context,
    Offset effectiveOffset,
  ) {
    assert(highlightedRects.isNotEmpty);
    // final isHovered = _hoveredHighlights.contains(highlight); RESTORE
    const isHovered = false;
    final paint = Paint()
      ..color = isHovered ? highlight.hoverColor : highlight.color;

    for (final box in highlightedRects) {
      context.canvas.drawRect(
        box.toRect().shift(effectiveOffset),
        paint,
      );
    }
  }

  void _paintCursor(
    PaintingContext context,
    Offset effectiveOffset,
    bool lineHasEmbed,
  ) {
    final position = cursorController.isFloatingCursorActive
        ? TextPosition(
            offset: cursorController.floatingCursorTextPosition.value!.offset -
                line.documentOffset,
            affinity:
                cursorController.floatingCursorTextPosition.value!.affinity,
          )
        : TextPosition(
            offset: textSelection.extentOffset - line.documentOffset,
            affinity: textSelection.base.affinity,
          );

    _cursorPainter.paint(
      context.canvas,
      effectiveOffset,
      position,
      lineHasEmbed,
    );
  }
}
