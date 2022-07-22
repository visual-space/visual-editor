import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../blocks/models/editable-box-renderer.model.dart';
import '../../blocks/services/lines-blocks.service.dart';
import '../../shared/state/editor.state.dart';
import '../../shared/utils/platform.utils.dart';
import '../controllers/selection-actions.controller.dart';
import 'text-selection.utils.dart';

class SelectionActionsService {
  final _textSelectionUtils = TextSelectionUtils();
  final _linesBlocksService = LinesBlocksService();

  static final _instance = SelectionActionsService._privateConstructor();

  factory SelectionActionsService() => _instance;

  SelectionActionsService._privateConstructor();

  // Returns the local coordinates of the endpoints of the given selection.
  // If the selection is collapsed (and therefore occupies a single point), the returned list is of length one.
  // Otherwise, the selection is not collapsed and the returned list is of length two. In this case, however, the two
  // points might actually be co-located (e.g., because of a bidirectional
  // selection that contains some text but whose ends meet in the middle).
  List<TextSelectionPoint> getEndpointsForSelection(
    TextSelection textSelection,
    EditorState state,
  ) {
    if (textSelection.isCollapsed) {
      final child = _linesBlocksService.childAtPosition(
        textSelection.extent,
        state,
      );
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

    final renderer = state.refs.renderer;
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
    EditableBoxRenderer? extentChild = baseChild;

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

  // Shows the selection buttons at the location of the current cursor.
  // Returns `false` if a buttons couldn't be shown.
  // When the buttons is already shown, or when no text selection currently exists.
  // Web is using native dom elements to enable clipboard functionality of the buttons: copy, paste, select, cut.
  // It might also provide additional functionality depending on the browser (such as translate).
  // Due to this we should not show Flutter buttons for the editable text elements.
  bool showToolbar(EditorState state) {
    if (kIsWeb) {
      return false;
    }

    final selectionActions = state.refs.editorState.selectionActionsController;

    final hasSelection = selectionActions == null;
    final hasToolbarAlready = selectionActions!.toolbar != null;

    if (hasSelection || hasToolbarAlready) {
      return false;
    }

    selectionActions.update(state.refs.editorState.textEditingValue);
    selectionActions.showToolbar();

    return true;
  }

  void hideToolbar(
    EditorState state, [
    bool hideHandles = true,
  ]) {
    final selectionActions = state.refs.editorState.selectionActionsController;

    // If the buttons is currently visible.
    if (selectionActions?.toolbar != null) {
      hideHandles ? selectionActions?.hide() : selectionActions?.hideToolbar();
    }
  }

  void updateOrDisposeSelectionOverlayIfNeeded(EditorState state) {
    final selectionActions = state.refs.editorState.selectionActionsController;

    if (selectionActions != null) {
      if (!state.refs.focusNode.hasFocus ||
          state.refs.editorController.plainTextEditingValue.selection
              .isCollapsed) {
        selectionActions.dispose();
        state.refs.editorState.selectionActionsController = null;
      } else {
        selectionActions.update(
          state.refs.editorController.plainTextEditingValue,
        );
      }
    } else if (state.refs.focusNode.hasFocus) {
      final editor = state.refs.editorState;

      state.refs.editorState.selectionActionsController =
          SelectionActionsController(
        value: state.refs.editorController.plainTextEditingValue,
        debugRequiredFor: state.refs.editor,
        renderObject: state.refs.renderer,
        textSelectionControls: state.editorConfig.config.textSelectionControls,
        selectionDelegate: editor,
        clipboardStatus: editor.clipboardStatus,
        state: state,
      );

      // TODO This code's null safety makes no sense. Review and refactor.
      selectionActions!.handlesVisible = shouldShowSelectionHandles(state);
      selectionActions.showHandles();
    }
  }

  bool shouldShowSelectionHandles(EditorState state) {
    final context = state.refs.editorState.context;
    // Whether to show selection handles.
    // When a selection is active, there will be two handles at each side of boundary,
    // or one handle if the selection is collapsed.
    // The handles can be dragged to adjust the selection.
    final showSelectionHandles = isMobile(Theme.of(context).platform);

    return showSelectionHandles &&
        !state.refs.editorController.selection.isCollapsed;
  }
}
