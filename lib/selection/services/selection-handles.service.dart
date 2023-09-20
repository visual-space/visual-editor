import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../doc-tree/services/coordinates.service.dart';
import '../../document/services/nodes/container.utils.dart';
import '../../document/services/nodes/node.utils.dart';
import '../../shared/models/editable-box-renderer.model.dart';
import '../../shared/state/editor.state.dart';
import '../../shared/utils/platform.utils.dart';
import '../controllers/selection-handles.controller.dart';
import 'selection-renderer.service.dart';

typedef HideToolbarCallback = void Function([bool hideHandles]);

// Controls the handles rendered on mobile when the selection menu is visible.
class SelectionHandlesService {
  late final SelectionRendererService _selectionRendererService;
  late final CoordinatesService _coordinatesService;
  final _contUtils = ContainerUtils();
  final _nodeUtils = NodeUtils();

  final EditorState state;

  SelectionHandlesService(this.state) {
    _selectionRendererService = SelectionRendererService(state);
    _coordinatesService = CoordinatesService(state);
  }

  // Returns the local coordinates of the endpoints of the given selection.
  // If the selection is collapsed (and therefore occupies a single point), the returned list is of length one.
  // Otherwise, the selection is not collapsed and the returned list is of length two. In this case, however, the two
  // points might actually be co-located (e.g., because of a bidirectional
  // selection that contains some text but whose ends meet in the middle).
  List<TextSelectionPoint> getEndpointsForSelection(
    TextSelection textSelection,
  ) {
    if (textSelection.isCollapsed) {
      final child = _coordinatesService.childAtPosition(textSelection.extent);
      final nodeOffset = _nodeUtils.getOffset(child.container);
      final localPosition = TextPosition(
        offset: textSelection.extentOffset - nodeOffset,
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

    final renderer = state.refs.renderer;
    final baseNode = _contUtils
        .queryChild(
          renderer.containerRef,
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
    final baseSelection = _selectionRendererService.getLocalSelection(
      baseChild.container,
      textSelection,
      true,
    );
    var basePoint = baseChild.getBaseEndpointForSelection(baseSelection);
    basePoint = TextSelectionPoint(
      basePoint.point + baseParentData.offset,
      basePoint.direction,
    );

    final extentNode = _contUtils
        .queryChild(
          renderer.containerRef,
          textSelection.end,
          false,
        )
        .node;
    EditableBoxRenderer? extentChild = baseChild;

    while (extentChild != null) {
      if (extentChild.container == extentNode) {
        break;
      }

      extentChild = renderer.childAfter(extentChild);
    }

    assert(extentChild != null);

    final extentParentData = extentChild!.parentData as BoxParentData;
    final extentSelection = _selectionRendererService.getLocalSelection(
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

  // Shows the selection buttons at the location of the current cursor.
  // Returns `false` if a buttons couldn't be shown.
  // When the buttons is already shown, or when no text selection currently exists.
  // Web is using native dom elements to enable clipboard functionality of the buttons: copy, paste, select, cut.
  // It might also provide additional functionality depending on the browser (such as translate).
  // Due to this we should not show Flutter buttons for the editable text elements.
  bool showToolbar() {
    if (kIsWeb) {
      return false;
    }

    final controller = state.refs.widget.selectionHandlesController;
    final hasSelection = controller == null;
    final hasToolbarAlready = hasSelection ? true : controller!.toolbar != null;

    if (hasSelection || hasToolbarAlready) {
      return false;
    }

    controller.update(state.refs.widget.textEditingValue);
    controller.showToolbar();

    return true;
  }

  void hideToolbar([bool hideHandles = true]) {
    final controller = state.refs.widget.selectionHandlesController;

    // If the buttons is currently visible.
    if (controller?.toolbar != null) {
      hideHandles ? controller?.hide() : controller?.hideToolbar();
    }
  }

  void updateOrDisposeSelectionHandlesIfNeeded(TextEditingValue plainText) {
    final selHandles = state.refs.widget.selectionHandlesController;
    final hasFocus = state.refs.focusNode.hasFocus;
    final selectionIsCollapsed = plainText.selection.isCollapsed;

    if (selHandles != null) {
      if (!hasFocus || selectionIsCollapsed) {
        selHandles.dispose();
        state.refs.widget.selectionHandlesController = null;
      } else {
        selHandles.update(plainText);
      }
    } else if (state.refs.focusNode.hasFocus) {
      final editor = state.refs.widget;

      state.refs.widget.selectionHandlesController = SelectionHandlesController(
        plainText: plainText,
        debugRequiredFor: state.refs.widget.widget,
        renderObject: state.refs.renderer,
        textSelectionControls: state.config.textSelectionControls,
        selectionDelegate: editor,
        clipboardStatus: editor.clipboardStatus,
        state: state,
      );

      final selHandles = state.refs.widget.selectionHandlesController;
      selHandles!.handlesVisible = shouldShowSelectionHandles();
      selHandles.showHandles();
    }
  }

  bool shouldShowSelectionHandles() {
    final context = state.refs.widget.context;
    // Whether to show selection handles.
    // When a selection is active, there will be two handles at each side of boundary,
    // or one handle if the selection is collapsed.
    // The handles can be dragged to adjust the selection.
    final showSelectionHandles = isMobile(Theme.of(context).platform);

    return showSelectionHandles && !state.selection.selection.isCollapsed;
  }
}
