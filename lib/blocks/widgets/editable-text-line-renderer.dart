import 'dart:math' as math;

import 'package:flutter/rendering.dart';

import '../../controller/services/editor-controller.dart';
import '../../cursor/services/cursor.controller.dart';
import '../../cursor/widgets/cursor-painter.dart';
import '../../documents/models/attribute.dart';
import '../../documents/models/nodes/container.dart' as container_node;
import '../../documents/models/nodes/leaf.dart' as leaf;
import '../../documents/models/nodes/line.dart';
import '../../editor/state/platform-styles.state.dart';
import '../../highlights/models/highlight.model.dart';
import '../../selection/services/text-selection.utils.dart';
import '../../shared/utils/platform.utils.dart';
import '../models/content-proxy-box-renderer.model.dart';
import '../models/editable-box-renderer.model.dart';
import '../models/inline-code-style.model.dart';
import '../models/text-line-slot.enum.dart';

class EditableTextLineRenderer extends RenderEditableBox {
  final _textSelectionUtils = TextSelectionUtils();
  final _platformStylesState = PlatformStylesState();

  EditorController controller;
  RenderBox? _leading;
  RenderContentProxyBox? _body;
  Line line;
  TextDirection textDirection;
  TextSelection textSelection;
  bool enableInteractiveSelection;
  bool hasFocus = false;
  double devicePixelRatio;
  EdgeInsetsGeometry padding;
  CursorController cursorController;
  EdgeInsets? _resolvedPadding;
  bool? _containsCursor;
  List<TextBox>? _selectedRects;
  late Rect _caretPrototype;
  InlineCodeStyle inlineCodeStyle;
  final Map<TextLineSlot, RenderBox> children = <TextLineSlot, RenderBox>{};

  // Creates new editable paragraph render box.
  EditableTextLineRenderer({
    required this.controller,
    required this.line,
    required this.textDirection,
    required this.textSelection,
    required this.enableInteractiveSelection,
    required this.hasFocus,
    required this.devicePixelRatio,
    required this.padding,
    required this.cursorController,
    required this.inlineCodeStyle,
  });

  Iterable<RenderBox> get _children sync* {
    if (_leading != null) {
      yield _leading!;
    }
    if (_body != null) {
      yield _body!;
    }
  }

  void setCursorController(CursorController controller) {
    if (cursorController == controller) {
      return;
    }
    cursorController = controller;
    markNeedsLayout();
  }

  void setDevicePixelRatio(double d) {
    if (devicePixelRatio == d) {
      return;
    }
    devicePixelRatio = d;
    markNeedsLayout();
  }

  void setEnableInteractiveSelection(bool val) {
    if (enableInteractiveSelection == val) {
      return;
    }

    markNeedsLayout();
    markNeedsSemanticsUpdate();
  }

  void setTextSelection(TextSelection t) {
    if (textSelection == t) {
      return;
    }

    final containsSelection = _lineContainsSelection(textSelection);
    if (_attachedToCursorController) {
      cursorController.removeListener(markNeedsLayout);
      cursorController.color.removeListener(safeMarkNeedsPaint);
      _attachedToCursorController = false;
    }

    textSelection = t;
    _selectedRects = null;
    _containsCursor = null;
    if (attached && containsCursor()) {
      cursorController.addListener(markNeedsLayout);
      cursorController.color.addListener(safeMarkNeedsPaint);
      _attachedToCursorController = true;
    }

    if (containsSelection || _lineContainsSelection(textSelection)) {
      safeMarkNeedsPaint();
    }
  }

  void setTextDirection(TextDirection t) {
    if (textDirection == t) {
      return;
    }
    textDirection = t;
    _resolvedPadding = null;
    markNeedsLayout();
  }

  void setLine(Line l) {
    if (line == l) {
      return;
    }
    line = l;
    _containsCursor = null;
    markNeedsLayout();
  }

  void setPadding(EdgeInsetsGeometry p) {
    assert(p.isNonNegative);
    if (padding == p) {
      return;
    }
    padding = p;
    _resolvedPadding = null;
    markNeedsLayout();
  }

  void setLeading(RenderBox? l) {
    _leading = _updateChild(_leading, l, TextLineSlot.LEADING);
  }

  void setBody(RenderContentProxyBox? b) {
    _body = _updateChild(_body, b, TextLineSlot.BODY) as RenderContentProxyBox?;
  }

  void setInlineCodeStyle(InlineCodeStyle newStyle) {
    if (inlineCodeStyle == newStyle) return;
    inlineCodeStyle = newStyle;
    markNeedsLayout();
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
  container_node.Container get container => line;

  double get cursorWidth => cursorController.style.width;

  double get cursorHeight =>
      cursorController.style.height ??
      preferredLineHeight(const TextPosition(offset: 0));

  // TODO: This is no longer producing the highest-fidelity caret
  // heights for Android, especially when non-alphabetic languages
  // are involved. The current implementation overrides the height set
  // here with the full measured height of the text on Android which looks
  // superior (subjectively and in terms of fidelity) in _paintCaret. We
  // should rework this properly to once again match the platform. The constant
  // _kCaretHeightOffset scales poorly for small font sizes.
  //
  // On iOS, the cursor is taller than the cursor on Android. The height
  // of the cursor for iOS is approximate and obtained through an eyeball
  // comparison.
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

  // === RENDER BOX OVERRIDES ===

  bool _attachedToCursorController = false;

  @override
  void attach(covariant PipelineOwner owner) {
    super.attach(owner);
    for (final child in _children) {
      child.attach(owner);
    }
    cursorController.floatingCursorTextPosition.addListener(_onFloatingCursorChange);
    if (containsCursor()) {
      cursorController.addListener(markNeedsLayout);
      cursorController.color.addListener(safeMarkNeedsPaint);
      _attachedToCursorController = true;
    }
  }

  @override
  void detach() {
    super.detach();
    for (final child in _children) {
      child.detach();
    }
    cursorController.floatingCursorTextPosition
        .removeListener(_onFloatingCursorChange);
    if (_attachedToCursorController) {
      cursorController.removeListener(markNeedsLayout);
      cursorController.color.removeListener(safeMarkNeedsPaint);
      _attachedToCursorController = false;
    }
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
            .getMinIntrinsicWidth(math.max(0, height - verticalPadding))
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
            .getMaxIntrinsicWidth(math.max(0, height - verticalPadding))
            .ceil();
    return horizontalPadding + leadingWidth + bodyWidth;
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    _resolvePadding();
    final horizontalPadding = _resolvedPadding!.left + _resolvedPadding!.right;
    final verticalPadding = _resolvedPadding!.top + _resolvedPadding!.bottom;
    if (_body != null) {
      return _body!
              .getMinIntrinsicHeight(math.max(0, width - horizontalPadding)) +
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
      return _body!
              .getMaxIntrinsicHeight(math.max(0, width - horizontalPadding)) +
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

  CursorPainter get _cursorPainter => CursorPainter(
        editable: _body,
        style: cursorController.style,
        prototype: _caretPrototype,
        color: cursorController.isFloatingCursorActive
            ? cursorController.style.backgroundColor
            : cursorController.color.value,
        devicePixelRatio: devicePixelRatio,
      );

  @override
  void paint(PaintingContext context, Offset offset) {
    if (_leading != null) {
      final parentData = _leading!.parentData as BoxParentData;
      final effectiveOffset = offset + parentData.offset;
      context.paintChild(_leading!, effectiveOffset);
    }

    if (_body != null) {
      final parentData = _body!.parentData as BoxParentData;
      final effectiveOffset = offset + parentData.offset;

      // Inline code
      if (inlineCodeStyle.backgroundColor != null) {
        for (final item in line.children) {
          if (item is! leaf.Text ||
              !item.style.containsKey(
                Attribute.inlineCode.key,
              )) {
            continue;
          }
          final textRange = TextSelection(
            baseOffset: item.offset,
            extentOffset: item.offset + item.length,
          );
          final rects = _body!.getBoxesForSelection(textRange);
          final paint = Paint()..color = inlineCodeStyle.backgroundColor!;
          for (final box in rects) {
            final rect = box.toRect().translate(0, 1).shift(effectiveOffset);
            if (inlineCodeStyle.radius == null) {
              final paintRect = Rect.fromLTRB(
                rect.left - 2,
                rect.top,
                rect.right + 2,
                rect.bottom,
              );
              context.canvas.drawRect(paintRect, paint);
            } else {
              final paintRect = RRect.fromLTRBR(
                rect.left - 2,
                rect.top,
                rect.right + 2,
                rect.bottom,
                inlineCodeStyle.radius!,
              );
              context.canvas.drawRRect(paintRect, paint);
            }
          }
        }
      }

      // Cursor above text (iOS)
      if (hasFocus &&
          cursorController.show.value &&
          containsCursor() &&
          !cursorController.style.paintAboveText) {
        _paintCursor(context, effectiveOffset, line.hasEmbed);
      }

      context.paintChild(_body!, effectiveOffset);

      // Cursor bellow text (Android)
      if (hasFocus &&
          cursorController.show.value &&
          containsCursor() &&
          cursorController.style.paintAboveText) {
        _paintCursor(context, effectiveOffset, line.hasEmbed);
      }

      final selectionIsWithinDocBounds = _lineContainsSelection(
        textSelection,
      );

      if (enableInteractiveSelection && selectionIsWithinDocBounds) {
        final local = _textSelectionUtils.getLocalSelection(
          line,
          textSelection,
          false,
        );
        _selectedRects ??= _body!.getBoxesForSelection(local);
        _paintSelection(context, effectiveOffset);
      }

      // Highlights
      controller.highlights.forEach((highlight) {
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

  bool _lineContainsSelection(TextSelection selection) {
    return line.documentOffset <= selection.end &&
        selection.start <= line.documentOffset + line.length - 1;
  }

  void _paintSelection(
    PaintingContext context,
    Offset effectiveOffset,
  ) {
    assert(_selectedRects != null);

    final paint = Paint()..color = _platformStylesState.styles!.selectionColor;

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
    // final isHovered = _hoveredHighlights.contains(highlight); RESTORE +++
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
            affinity: cursorController.floatingCursorTextPosition.value!.affinity,
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
      if (isHit) return true;
    }

    if (_body == null) return false;
    final parentData = _body!.parentData as BoxParentData;

    return result.addWithPaintOffset(
      offset: parentData.offset,
      position: position,
      hitTest: (result, position) {
        return _body!.hitTest(result, position: position);
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
    if (cursorOffset != null) rect = rect.shift(cursorOffset);

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

  void safeMarkNeedsPaint() {
    if (!attached) {
      // Should not paint if it was unattached.
      return;
    }

    markNeedsPaint();
  }

  @override
  Rect getCaretPrototype(TextPosition position) => _caretPrototype;
}
