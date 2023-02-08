import 'package:flutter/rendering.dart';

import '../../document/models/nodes/block.model.dart';
import '../../document/services/nodes/container.utils.dart';
import '../../document/services/nodes/node.utils.dart';
import '../../selection/services/selection-renderer.service.dart';
import '../../shared/models/editable-box-renderer.model.dart';
import '../../shared/state/editor.state.dart';
import '../../shared/widgets/multiline-text-area-renderer.dart';
import '../services/coordinates.service.dart';

// Handles the rendering of background areas such as the code block background.
// Also contains helper methods for calculating the text selection.
class EditableTextBlockBoxRenderer extends MultilineTextAreaRenderer
    implements EditableBoxRenderer {
  late final CoordinatesService _coordinatesService;
  late final SelectionRendererService _selectionUtils;
  final _contUtils = ContainerUtils();
  final _nodeUtils = NodeUtils();

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

  EditableTextBlockBoxRenderer({
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
    _coordinatesService = CoordinatesService(state);
    _selectionUtils = SelectionRendererService(state);

    _contentPadding = isCodeBlock ? const EdgeInsets.all(16) : EdgeInsets.zero;
  }

  @override
  TextRange getLineBoundary(TextPosition position) {
    final childAtPosition = _coordinatesService.childAtPosition(position, this);
    final rangeInChild = childAtPosition.getLineBoundary(
      TextPosition(
        offset: position.offset - _getOffset(childAtPosition),
        affinity: position.affinity,
      ),
    );

    return TextRange(
      start: rangeInChild.start + _getOffset(childAtPosition),
      end: rangeInChild.end + _getOffset(childAtPosition),
    );
  }

  @override
  Offset getOffsetForCaret(TextPosition position) {
    final childAtPosition = _coordinatesService.childAtPosition(position, this);

    return childAtPosition.getOffsetForCaret(
          TextPosition(
            offset: position.offset - _getOffset(childAtPosition),
            affinity: position.affinity,
          ),
        ) +
        (childAtPosition.parentData as BoxParentData).offset;
  }

  @override
  TextPosition getPositionForOffset(Offset offset) {
    final childAtOffset = _coordinatesService.childAtOffset(offset, this);
    final parentData = childAtOffset.parentData as BoxParentData;
    final localPosition = childAtOffset.getPositionForOffset(
      offset - parentData.offset,
    );

    return TextPosition(
      offset:
          localPosition.offset + _nodeUtils.getOffset(childAtOffset.container),
      affinity: localPosition.affinity,
    );
  }

  @override
  TextRange getWordBoundary(TextPosition position) {
    final childAtPosition = _coordinatesService.childAtPosition(position, this);
    final nodeOffset = _getOffset(childAtPosition);
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
    assert(position.offset < container.charsNum);

    final childAtPosition = _coordinatesService.childAtPosition(position, this);
    final childLocalPosition = TextPosition(
      offset: position.offset - _getOffset(childAtPosition),
    );
    final result = childAtPosition.getPositionAbove(childLocalPosition);

    if (result != null) {
      return TextPosition(
        offset: result.offset + _getOffset(childAtPosition),
      );
    }

    final sibling = childBefore(childAtPosition);

    if (sibling == null) {
      return null;
    }

    final caretOffset = childAtPosition.getOffsetForCaret(childLocalPosition);
    final testPosition = TextPosition(offset: sibling.container.charsNum - 1);
    final testOffset = sibling.getOffsetForCaret(testPosition);
    final finalOffset = Offset(caretOffset.dx, testOffset.dy);

    return TextPosition(
      offset: _nodeUtils.getOffset(sibling.container) +
          sibling.getPositionForOffset(finalOffset).offset,
    );
  }

  @override
  TextPosition? getPositionBelow(TextPosition position) {
    assert(position.offset < container.charsNum);

    final childAtPosition = _coordinatesService.childAtPosition(position, this);
    final childLocalPosition = TextPosition(
      offset: position.offset - _getOffset(childAtPosition),
    );
    final result = childAtPosition.getPositionBelow(childLocalPosition);

    if (result != null) {
      return TextPosition(
        offset: result.offset + _getOffset(childAtPosition),
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
      offset: _nodeUtils.getOffset(sibling.container) +
          sibling.getPositionForOffset(finalOffset).offset,
    );
  }

  @override
  double preferredLineHeight(TextPosition position) {
    final childAtPosition = _coordinatesService.childAtPosition(position, this);

    return childAtPosition.preferredLineHeight(
      TextPosition(
        offset: position.offset - _getOffset(childAtPosition),
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

    final base = _contUtils.queryChild(container, selection.start, false);
    var baseChild = firstChild;

    while (baseChild != null) {
      if (baseChild.container == base.node) {
        break;
      }
      baseChild = childAfter(baseChild);
    }

    assert(baseChild != null);

    final basePoint = baseChild!.getBaseEndpointForSelection(
      _selectionUtils.getLocalSelection(baseChild.container, selection, true),
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

    final extent = _contUtils.queryChild(container, selection.end, false);
    var extentChild = firstChild;

    while (extentChild != null) {
      if (extentChild.container == extent.node) {
        break;
      }
      extentChild = childAfter(extentChild);
    }

    assert(extentChild != null);

    final extentPoint = extentChild!.getExtentEndpointForSelection(
      _selectionUtils.getLocalSelection(
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
    final debugSaveCount = context.canvas.getSaveCount();
    final filledConfiguration = configuration.copyWith(
      size: decorationPadding.deflateSize(size),
    );
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
      throw '${_decoration.runtimeType} painter had mismatching save and restore calls.';
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
    final childAtPosition = _coordinatesService.childAtPosition(position, this);
    final parentData = childAtPosition.parentData as BoxParentData;
    final localPosition = TextPosition(
      offset: position.offset - _getOffset(childAtPosition),
      affinity: position.affinity,
    );

    return childAtPosition
        .getLocalRectForCaret(localPosition)
        .shift(parentData.offset);
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
  Rect getCaretPrototype(TextPosition position) {
    final childAtPosition = _coordinatesService.childAtPosition(position, this);
    final localPosition = TextPosition(
      offset: position.offset - _getOffset(childAtPosition),
      affinity: position.affinity,
    );

    return childAtPosition.getCaretPrototype(localPosition);
  }

  int _getOffset(EditableBoxRenderer child) =>
      _nodeUtils.getOffset(child.container);
}
