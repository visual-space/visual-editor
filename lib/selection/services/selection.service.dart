import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../cursor/services/caret.service.dart';
import '../../doc-tree/services/coordinates.service.dart';
import '../../document/models/history/change-source.enum.dart';
import '../../document/models/nodes/style.model.dart';
import '../../document/services/nodes/node.utils.dart';
import '../../editor/services/editor.service.dart';
import '../../editor/services/run-build.service.dart';
import '../../inputs/services/keyboard.service.dart';
import '../../shared/state/editor.state.dart';
import '../../toolbar/services/toolbar.service.dart';
import 'selection-handles.service.dart';
import 'selection-renderer.service.dart';

typedef UpdateSelectionCallback = void Function(
  TextSelection selection,
  ChangeSource source,
);

// Provides methods for moving the cursor to arbitrary positions.
// Hosts the text gestures (tapDown, tapUp) which were mapped to selection commands by the TextGesturesService.
class SelectionService {
  late final RunBuildService _runBuildService;
  late final CaretService _caretService;
  late final CoordinatesService _coordinatesService;
  late final SelectionRendererService _selectionRendererService;
  late final SelectionHandlesService _selectionHandlesService;
  late final KeyboardService _keyboardService;
  late final ToolbarService _toolbarService;
  final _nodeUtils = NodeUtils();

  final EditorState state;

  SelectionService(this.state) {
    _runBuildService = RunBuildService(state);
    _caretService = CaretService(state);
    _coordinatesService = CoordinatesService(state);
    _selectionRendererService = SelectionRendererService(state);
    _selectionHandlesService = SelectionHandlesService(state);
    _keyboardService = KeyboardService(state);
    _toolbarService = ToolbarService(state);
  }

  // === MOVE CURSOR ===

  // Caches the selection, updates the GUI elements and triggers build().
  void moveCursorToPosition(int position) {
    cacheSelectionAndRunBuild(
      TextSelection.collapsed(offset: position),
      ChangeSource.LOCAL,
    );
  }

  // Caches the selection, updates the GUI elements and triggers build().
  void moveCursorToStart() {
    cacheSelectionAndRunBuild(
      TextSelection.collapsed(offset: 0),
      ChangeSource.LOCAL,
    );
  }

  // Caches the selection, updates the GUI elements and triggers build().
  void moveCursorToEnd(TextEditingValue plainText) {
    cacheSelectionAndRunBuild(
      TextSelection.collapsed(offset: plainText.text.length),
      ChangeSource.LOCAL,
    );
  }

  // === SELECT TEXT ===

  // Selects the set words of a paragraph in a given range of global positions.
  // The first and last endpoints of the selection will always be at the beginning and end of a word respectively.
  // Caches the selection, updates the GUI elements and triggers build().
  void selectWordsInRange(
    Offset from,
    Offset? to,
    SelectionChangedCause cause,
  ) {
    final firstPosition = _coordinatesService.getPositionForOffset(from);
    final firstWord = _selectionRendererService.getWordAtPosition(
      firstPosition,
    );
    final lastWord = to == null
        ? firstWord
        : _selectionRendererService.getWordAtPosition(
            _coordinatesService.getPositionForOffset(to),
          );

    final newSelection = TextSelection(
      baseOffset: firstWord.base.offset,
      extentOffset: lastWord.extent.offset,
      affinity: firstWord.affinity,
    );

    // Cache selection + Trigger Build
    cacheSelectionAndUpdGuiElems(newSelection, cause);
  }

  // Move the selection to the beginning or end of a word.
  // Caches the selection, updates the GUI elements and triggers build().
  void selectWordEdge(SelectionChangedCause cause) {
    assert(state.lastTapDown.position != null);

    final position = _coordinatesService.getPositionForOffset(
      state.lastTapDown.position!,
    );
    final child = _coordinatesService.childAtPosition(position);
    final nodeOffset = _nodeUtils.getOffset(child.container);
    final localPosition = TextPosition(
      offset: position.offset - nodeOffset,
      affinity: position.affinity,
    );
    final localWord = child.getWordBoundary(localPosition);
    final word = TextRange(
      start: localWord.start + nodeOffset,
      end: localWord.end + nodeOffset,
    );
    late final TextSelection newSelection;

    if (position.offset - word.start <= 1) {
      newSelection = TextSelection.collapsed(
        offset: word.start,
      );
    } else {
      newSelection = TextSelection.collapsed(
        offset: word.end,
        affinity: TextAffinity.upstream,
      );
    }

    // Cache selection + Trigger Build
    cacheSelectionAndUpdGuiElems(newSelection, cause);
  }

  // Returns the new selection or null if no change occurred.
  // Caches the selection, updates the GUI elements and triggers build().
  TextSelection? selectPositionAt({
    required Offset from,
    required SelectionChangedCause cause,
    Offset? to,
  }) {
    final fromPosition = _coordinatesService.getPositionForOffset(from);
    final toPosition = to == null ? null : _coordinatesService.getPositionForOffset(to);
    var baseOffset = fromPosition.offset;
    var extentOffset = fromPosition.offset;

    if (toPosition != null) {
      baseOffset = math.min(fromPosition.offset, toPosition.offset);
      extentOffset = math.max(fromPosition.offset, toPosition.offset);
    }

    final newSelection = TextSelection(
      baseOffset: baseOffset,
      extentOffset: extentOffset,
      affinity: fromPosition.affinity,
    );

    // Cache selection + Trigger Build
    cacheSelectionAndUpdGuiElems(newSelection, cause);

    return newSelection;
  }

  // Selects all text, brings into view and triggers build().
  void selectAll(
    SelectionChangedCause cause,
    RemoveSpecialCharsAndUpdateDocTextAndStyleCallback removeSpecialCharsAndUpdateDocTextAndStyle,
  ) {
    removeSpecialCharsAndUpdateDocTextAndStyle(
      _plainText.copyWith(
        selection: TextSelection(
          baseOffset: 0,
          extentOffset: _plainText.text.length,
        ),
      ),
      cause,
    );

    if (cause == SelectionChangedCause.toolbar) {
      _caretService.bringIntoView(_plainText.selection.extent);
    }
  }

  // Extends current selection to the position closest to specified offset.
  // Caches the selection, updates the GUI elements and triggers build().
  void extendSelection(
    Offset to, {
    required SelectionChangedCause cause,
  }) {
    final selOrigin = state.selection.origin;

    // The below logic does not exactly match the native version because
    // we do not allow swapping of base and extent positions.
    if (selOrigin == null) {
      return;
    }

    final selection = state.selection.selection;
    final toPosition = _coordinatesService.getPositionForOffset(to);
    var newSelection = TextSelection.collapsed(offset: 0);

    // From extent offset
    if (toPosition.offset < selOrigin.baseOffset) {
      newSelection = TextSelection(
        baseOffset: toPosition.offset,
        extentOffset: selOrigin.extentOffset,
        affinity: selection.affinity,
      );

      // From base offset
    } else if (toPosition.offset > selOrigin.extentOffset) {
      newSelection = TextSelection(
        baseOffset: selOrigin.baseOffset,
        extentOffset: toPosition.offset,
        affinity: selection.affinity,
      );
    }

    // Cache selection + Trigger Build
    cacheSelectionAndUpdGuiElems(newSelection, cause);
  }

  // === UPDATE GUI ===

  // Invoked when a new selection is made.
  // Prevents duplicate selection render.
  // Caches the new selection in the state store.
  // Runs the build cycle to update the document widgets tree.
  // Displays the selection handles.
  // Requests the keyboard.
  // Brings the caret into view by scrolling the viewport.
  // TODO Double check if the floating cursor still works fine after merging the duplication
  //  prevention code in one single method (Adrian Ian 2023).
  void cacheSelectionAndUpdGuiElems(TextSelection newSelection, SelectionChangedCause cause) {
    // Prevent duplicate selection render
    final focusingEmpty = newSelection.baseOffset == 0 && newSelection.extentOffset == 0 && !state.refs.focusNode.hasFocus;
    final sameSelectionFromKb = newSelection == state.selection.selection && cause != SelectionChangedCause.keyboard;
    final duplicateSelection = !focusingEmpty && sameSelectionFromKb;

    if (duplicateSelection) {
      return;
    }

    final oldSelection = state.selection.selection;

    // Cache Selection + Run Build
    cacheSelectionAndRunBuild(newSelection, ChangeSource.LOCAL);

    // Show Selection Handles
    state.refs.widget.selectionHandlesController?.handlesVisible = _selectionHandlesService.shouldShowSelectionHandles();

    // Request Keyboard
    if (!state.keyboard.isVisible) {
      // Displays the keyboard for all selection changes on the editor,
      // not just changes triggered by user gestures.
      _keyboardService.requestKeyboard();
    }

    // Bring into view
    if (cause == SelectionChangedCause.drag) {
      // When user updates the selection while dragging make sure to bring
      // the updated position (base or extent) into view.
      if (oldSelection.baseOffset != newSelection.baseOffset) {
        _caretService.bringIntoView(newSelection.base);
      } else if (oldSelection.extentOffset != newSelection.extentOffset) {
        _caretService.bringIntoView(newSelection.extent);
      }
    }
  }

  // === SELECTION ===

  TextSelection get selection {
    return state.selection.selection;
  }

  // Store the new selection extent values and runs the build to update the document widget tree.
  void cacheSelectionAndRunBuild(TextSelection textSelection, ChangeSource source) {
    cacheSelection(textSelection, source);
    _toggleStylingButtonsIfCodeSelection();
    _runBuildService.runBuild();
    callOnSelectionChanged();
  }

  // Store the new selection extent values
  void cacheSelection(TextSelection _selection, ChangeSource source) {
    state.selection.selection = _selection;
    final end = state.refs.documentController.docCharsNum - 1;
    final selection = state.selection.selection;
    state.selection.selection = selection.copyWith(
      baseOffset: math.min(selection.baseOffset, end),
      extentOffset: math.min(selection.extentOffset, end),
    );
    state.styles.toggledStyle = StyleM();
  }

  // === CALLBACKS ===

  // Client defined callback
  void callOnSelectionChanged() {
    final onSelectionChanged = state.config.onSelectionChanged;

    if (onSelectionChanged != null) {
      onSelectionChanged(state.selection.selection);
    }
  }

  // Client defined callback
  void callOnSelectionCompleted() {
    state.config.onSelectionCompleted?.call(
      state.selection.selectionRectangles,
    );
  }

  // === PRIVATE ===

  // State store accessor duplicated from DocumentsService to avoid circular references.
  // Helps us avoid needles drill-down of the plainText.
  // Also keeps the public API of the SelectionService simpler.
  TextEditingValue get _plainText {
    return TextEditingValue(
      text: state.refs.documentController.toPlainText(),
      selection: state.selection.selection,
    );
  }

  // === PRIVATE ===

  // We disable the styling options if the selection contains inline code or code blocks.
  void _toggleStylingButtonsIfCodeSelection() {
    final selectionIsCodeBlock = state.refs.controller.selectionStyle().attributes.containsKey('code-block');
    final selectionIsInlineCode = state.refs.controller.selectionStyle().attributes.containsKey('code');
    final isCodeSelected = selectionIsCodeBlock || selectionIsInlineCode;

    _toolbarService.toggleStylingButtons(!isCodeSelected);
  }
}
