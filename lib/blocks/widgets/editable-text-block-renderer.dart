import 'package:flutter/rendering.dart';

import '../../documents/models/nodes/block.model.dart';
import '../../selection/services/text-selection.utils.dart';
import '../../shared/models/editable-box-renderer.model.dart';
import '../../shared/state/editor.state.dart';
import '../../shared/widgets/multiline-text-area-renderer.dart';
import '../services/lines-blocks.service.dart';

class EditableTextBlockRenderer extends MultilineTextAreaRenderer
    implements EditableBoxRenderer {
  final _linesBlocksService = LinesBlocksService();
  final _textSelectionUtils = TextSelectionUtils();

  // Used internally to retrieve the state from the EditorController instance to which this button is linked to.
  // Can't be accessed publicly (by design) to avoid exposing the internals of the library.
  late EditorState _state;

  void setState(EditorState state) {
    _state = state;
  }

  EdgeInsets _contentPadding = EdgeInsets.zero;
  BoxPainter? _painter;

  Decoration get decoration => _decoration;
  Decoration _decoration;

  set decoration(Decoration value) {
    if (value == _decoration) {
      return;
    }

    _painter?.dispose();
    _painter = null;
    _decoration = value;
    markNeedsPaint();
  }

  ImageConfiguration get configuration => _configuration;
  ImageConfiguration _configuration;

  set configuration(ImageConfiguration value) {
    if (value == _configuration) {
      return;
    }

    _configuration = value;
    markNeedsPaint();
  }

  EditableTextBlockRenderer({
    required BlockM block,
    required TextDirection textDirection,
    required EdgeInsetsGeometry padding,
    required Decoration decoration,
    required bool isCodeBlock,
    required EditorState state,
    List<EditableBoxRenderer>? children,
  })  : _decoration = decoration,
        _configuration = ImageConfiguration(
          textDirection: textDirection,
        ),
        super(
          children: children,
          container: block,
          textDirection: textDirection,
          padding: padding.add(
            isCodeBlock ? const EdgeInsets.all(16) : EdgeInsets.zero,
          ),
        ) {
    setState(state);
    _contentPadding = isCodeBlock ? const EdgeInsets.all(16) : EdgeInsets.zero;
  }

  @override
  TextRange getLineBoundary(TextPosition position) {
    final childAtPosition = _linesBlocksService.childAtPosition(
      position,
      _state,
      this,
    );
    final rangeInChild = childAtPosition.getLineBoundary(
      TextPosition(
        offset: position.offset - childAtPosition.container.offset,
        affinity: position.affinity,
      ),
    );

    return TextRange(
      start: rangeInChild.start + childAtPosition.container.offset,
      end: rangeInChild.end + childAtPosition.container.offset,
    );
  }

  @override
  Offset getOffsetForCaret(TextPosition position) {
    final childAtPosition = _linesBlocksService.childAtPosition(
      position,
      _state,
      this,
    );

    return childAtPosition.getOffsetForCaret(
          TextPosition(
            offset: position.offset - childAtPosition.container.offset,
            affinity: position.affinity,
          ),
        ) +
        (childAtPosition.parentData as BoxParentData).offset;
  }

  @override
  TextPosition getPositionForOffset(Offset offset) {
    final childAtOffset = _linesBlocksService.childAtOffset(
      offset,
      _state,
      this,
    );
    final parentData = childAtOffset.parentData as BoxParentData;
    final localPosition = childAtOffset.getPositionForOffset(
      offset - parentData.offset,
    );

    return TextPosition(
      offset: localPosition.offset + childAtOffset.container.offset,
      affinity: localPosition.affinity,
    );
  }

  @override
  TextRange getWordBoundary(TextPosition position) {
    final childAtPosition = _linesBlocksService.childAtPosition(
      position,
      _state,
      this,
    );
    final nodeOffset = childAtPosition.container.offset;
    final childWord = childAtPosition.getWordBoundary(
      TextPosition(offset: position.offset - nodeOffset),
    );

    return TextRange(
      start: childWord.start + nodeOffset,
      end: childWord.end + nodeOffset,
    );
  }

  @override
  TextPosition? getPositionAbove(TextPosition position) {
    assert(position.offset < container.length);

    final childAtPosition = _linesBlocksService.childAtPosition(
      position,
      _state,
      this,
    );
    final childLocalPosition = TextPosition(
      offset: position.offset - childAtPosition.container.offset,
    );
    final result = childAtPosition.getPositionAbove(childLocalPosition);

    if (result != null) {
      return TextPosition(
        offset: result.offset + childAtPosition.container.offset,
      );
    }

    final sibling = childBefore(childAtPosition);

    if (sibling == null) {
      return null;
    }

    final caretOffset = childAtPosition.getOffsetForCaret(childLocalPosition);
    final testPosition = TextPosition(offset: sibling.container.length - 1);
    final testOffset = sibling.getOffsetForCaret(testPosition);
    final finalOffset = Offset(caretOffset.dx, testOffset.dy);

    return TextPosition(
      offset: sibling.container.offset +
          sibling.getPositionForOffset(finalOffset).offset,
    );
  }

  @override
  TextPosition? getPositionBelow(TextPosition position) {
    assert(position.offset < container.length);

    final childAtPosition = _linesBlocksService.childAtPosition(
      position,
      _state,
      this,
    );
    final childLocalPosition = TextPosition(
      offset: position.offset - childAtPosition.container.offset,
    );
    final result = childAtPosition.getPositionBelow(childLocalPosition);

    if (result != null) {
      return TextPosition(
        offset: result.offset + childAtPosition.container.offset,
      );
    }

    final sibling = childAfter(childAtPosition);

    if (sibling == null) {
      return null;
    }

    final caretOffset = childAtPosition.getOffsetForCaret(childLocalPosition);
    final testOffset = sibling.getOffsetForCaret(
      const TextPosition(offset: 0),
    );
    final finalOffset = Offset(caretOffset.dx, testOffset.dy);

    return TextPosition(
      offset: sibling.container.offset +
          sibling.getPositionForOffset(finalOffset).offset,
    );
  }

  @override
  double preferredLineHeight(TextPosition position) {
    final childAtPosition = _linesBlocksService.childAtPosition(
      position,
      _state,
      this,
    );

    return childAtPosition.preferredLineHeight(
      TextPosition(
        offset: position.offset - childAtPosition.container.offset,
      ),
    );
  }

  @override
  TextSelectionPoint getBaseEndpointForSelection(TextSelection selection) {
    if (selection.isCollapsed) {
      return TextSelectionPoint(
        Offset(0, preferredLineHeight(selection.extent)) +
            getOffsetForCaret(selection.extent),
        null,
      );
    }

    final baseNode = container.queryChild(selection.start, false).node;
    var baseChild = firstChild;

    while (baseChild != null) {
      if (baseChild.container == baseNode) {
        break;
      }
      baseChild = childAfter(baseChild);
    }

    assert(baseChild != null);

    final basePoint = baseChild!.getBaseEndpointForSelection(
      _textSelectionUtils.getLocalSelection(
          baseChild.container, selection, true),
    );

    return TextSelectionPoint(
      basePoint.point + (baseChild.parentData as BoxParentData).offset,
      basePoint.direction,
    );
  }

  @override
  TextSelectionPoint getExtentEndpointForSelection(TextSelection selection) {
    if (selection.isCollapsed) {
      return TextSelectionPoint(
        Offset(0, preferredLineHeight(selection.extent)) +
            getOffsetForCaret(selection.extent),
        null,
      );
    }

    final extentNode = container.queryChild(selection.end, false).node;
    var extentChild = firstChild;

    while (extentChild != null) {
      if (extentChild.container == extentNode) {
        break;
      }
      extentChild = childAfter(extentChild);
    }

    assert(extentChild != null);

    final extentPoint = extentChild!.getExtentEndpointForSelection(
      _textSelectionUtils.getLocalSelection(
        extentChild.container,
        selection,
        true,
      ),
    );

    return TextSelectionPoint(
      extentPoint.point + (extentChild.parentData as BoxParentData).offset,
      extentPoint.direction,
    );
  }

  @override
  void detach() {
    _painter?.dispose();
    _painter = null;
    super.detach();
    markNeedsPaint();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    _paintDecoration(context, offset);
    defaultPaint(context, offset);
  }

  void _paintDecoration(PaintingContext context, Offset offset) {
    _painter ??= _decoration.createBoxPainter(markNeedsPaint);

    final decorationPadding = resolvedPadding! - _contentPadding;

    final filledConfiguration = configuration.copyWith(
      size: decorationPadding.deflateSize(size),
    );
    final debugSaveCount = context.canvas.getSaveCount();

    final decorationOffset = offset.translate(
      decorationPadding.left,
      decorationPadding.top,
    );

    _painter!.paint(
      context.canvas,
      decorationOffset,
      filledConfiguration,
    );

    if (debugSaveCount != context.canvas.getSaveCount()) {
      throw '${_decoration.runtimeType} painter had mismatching save and  '
          'restore calls.';
    }

    if (decoration.isComplex) {
      context.setIsComplexHint();
    }
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    return defaultHitTestChildren(result, position: position);
  }

  @override
  Rect getLocalRectForCaret(TextPosition position) {
    final childAtPosition = _linesBlocksService.childAtPosition(
      position,
      _state,
      this,
    );
    final localPosition = TextPosition(
      offset: position.offset - childAtPosition.container.offset,
      affinity: position.affinity,
    );
    final parentData = childAtPosition.parentData as BoxParentData;

    return childAtPosition
        .getLocalRectForCaret(localPosition)
        .shift(parentData.offset);
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
  Rect getCaretPrototype(TextPosition position) {
    final childAtPosition = _linesBlocksService.childAtPosition(
      position,
      _state,
      this,
    );
    final localPosition = TextPosition(
      offset: position.offset - childAtPosition.container.offset,
      affinity: position.affinity,
    );

    return childAtPosition.getCaretPrototype(localPosition);
  }
}
