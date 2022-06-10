import 'package:flutter/rendering.dart';

import '../../blocks/models/editable-box-renderer.model.dart';
import '../../editor/services/editor-renderer.utils.dart';
import '../../editor/state/editor-renderer.state.dart';
import 'text-selection.utils.dart';

class SelectionActionsUtils {
  final _textSelectionUtils = TextSelectionUtils();
  final _editorRendererUtils = EditorRendererUtils();
  final _editorRendererState = EditorRendererState();
  static final _instance = SelectionActionsUtils._privateConstructor();

  factory SelectionActionsUtils() => _instance;

  SelectionActionsUtils._privateConstructor();

  // Returns the local coordinates of the endpoints of the given selection.
  // If the selection is collapsed (and therefore occupies a single point), the returned list is of length one.
  // Otherwise, the selection is not collapsed and the returned list is of length two. In this case, however, the two
  // points might actually be co-located (e.g., because of a bidirectional
  // selection that contains some text but whose ends meet in the middle).
  List<TextSelectionPoint> getEndpointsForSelection(
    TextSelection textSelection,
  ) {
    if (textSelection.isCollapsed) {
      final child = _editorRendererUtils.childAtPosition(textSelection.extent);
      final localPosition = TextPosition(
        offset: textSelection.extentOffset - child.container.offset,
      );
      final localOffset = child.getOffsetForCaret(localPosition);
      final parentData = child.parentData as BoxParentData;

      return <TextSelectionPoint>[
        TextSelectionPoint(
          Offset(0, child.preferredLineHeight(localPosition)) +
              localOffset +
              parentData.offset,
          null,
        )
      ];
    }

    final renderer = _editorRendererState.renderer;
    final baseNode = renderer.containerRef
        .queryChild(
          textSelection.start,
          false,
        )
        .node;
    var baseChild = renderer.firstChild;

    while (baseChild != null) {
      if (baseChild.container == baseNode) {
        break;
      }

      baseChild = renderer.childAfter(baseChild);
    }

    assert(baseChild != null);

    final baseParentData = baseChild!.parentData as BoxParentData;
    final baseSelection = _textSelectionUtils.getLocalSelection(
      baseChild.container,
      textSelection,
      true,
    );
    var basePoint = baseChild.getBaseEndpointForSelection(baseSelection);
    basePoint = TextSelectionPoint(
      basePoint.point + baseParentData.offset,
      basePoint.direction,
    );

    final extentNode = renderer.containerRef
        .queryChild(
          textSelection.end,
          false,
        )
        .node;
    RenderEditableBox? extentChild = baseChild;

    while (extentChild != null) {
      if (extentChild.container == extentNode) {
        break;
      }

      extentChild = renderer.childAfter(extentChild);
    }

    assert(extentChild != null);

    final extentParentData = extentChild!.parentData as BoxParentData;
    final extentSelection = _textSelectionUtils.getLocalSelection(
      extentChild.container,
      textSelection,
      true,
    );
    var extentPoint = extentChild.getExtentEndpointForSelection(
      extentSelection,
    );

    extentPoint = TextSelectionPoint(
      extentPoint.point + extentParentData.offset,
      extentPoint.direction,
    );

    return <TextSelectionPoint>[basePoint, extentPoint];
  }
}
