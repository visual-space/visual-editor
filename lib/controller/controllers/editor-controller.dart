import 'package:flutter/src/services/text_editing.dart';

import '../../document/models/document.model.dart';
import '../../editor/services/editor.service.dart';
import '../../embeds/services/embeds.service.dart';
import '../../highlights/services/highlights.service.dart';
import '../../inputs/services/keyboard.service.dart';
import '../../links/services/links.service.dart';
import '../../markers/services/markers.service.dart';
import '../../selection/services/selection.service.dart';
import '../../shared/state/editor-state-receiver.dart';
import '../../shared/state/editor.state.dart';
import '../../styles/services/styles.service.dart';

// Encapsulates the state of the editor and shares it with the paired toolbar/buttons.
// The state is protected from public access to avoid client code dependencies to the internal architecture.
// Provides public APIs for the document, styles, text selection, markers, highlights, history and cursor.
// Note that each controller has it's own independent state.
// This setup enables multiple editor instances in the same page.
// Basically the controller wraps all the publicly available methods from various services
// and passes the state store as a param to the wrapped methods.
// The legacy Quill architecture did not segregate the methods in services,
// thus the code base was difficult to navigate.
// A few useful properties:
// - document - The delta document itself
// - selection - The currently selected text
// - update() - Replaces with new delta operations the content of the document (updates the document)
// - clear() - Empties the document
// - replaceText() - Replaces a range of text with the new text or an embed
// - formatSelection() - Applies custom styles to the selected text
// Full documentation in controller.md and state-store.md
class EditorController {
  late final EditorService _editorService;
  late final StylesService _stylesService;
  late final SelectionService _selectionService;
  late final HighlightsService _highlightsService;
  late final MarkersService _markersService;
  late final EmbedsService _embedsService;
  late final KeyboardService _keyboardService;
  late final LinksService _linksService;

  final _state = EditorState();

  EditorController({DocumentM? document}) {
    _state.document.document = document ?? DocumentM();

    _editorService = EditorService(_state);
    _stylesService = StylesService(_state);
    _selectionService = SelectionService(_state);
    _highlightsService = HighlightsService(_state);
    _markersService = MarkersService(_state);
    _embedsService = EmbedsService(_state);
    _keyboardService = KeyboardService(_state);
    _linksService = LinksService(_state);
  }

  // === DOCUMENT ===

  late final document = _editorService.document;
  late final changes$ = _editorService.changes$;
  late final plainText = _editorService.plainText;
  late final docLength = _editorService.docLength;
  late final selectionPlainText = _editorService.getSelectionPlainText;
  late final update = _editorService.update;
  late final clear = _editorService.clear;
  late final replaceText = _editorService.replaceText;
  late final compose = _editorService.compose;
  late final addLinkToSelection = _editorService.addLinkToSelection;
  late final getSelectionLinkAttributeValue = _editorService.getSelectionLinkAttributeValue;
  late final getHeadingsByType = _editorService.getHeadingsByType;
  late final queryNode = _editorService.queryNode;
  late final close = _editorService.close;
  late final isClosed = _editorService.isClosed;
  late final setCustomRules = _editorService.setCustomRules;

  // === TEXT STYLES ===

  late final formatSelectedTextByStyle = _stylesService.formatSelectedTextByStyle;
  late final formatSelectedText = _stylesService.formatSelectedText;
  late final formatSelection = _stylesService.formatSelection;
  late final selectionStyle = _stylesService.getSelectionStyle;
  late final getAllIndividualSelectionStyles = _stylesService.getAllIndividualSelectionStyles;
  late final getAllSelectionStyles = _stylesService.getAllSelectionStyles;
  late final isAttributeToggledInSelection = _stylesService.isAttributeToggledInSelection;
  late final toggleAttributeInSelection = _stylesService.toggleAttributeInSelection;
  late final clearSelectionFormatting = _stylesService.clearSelectionFormatting;
  late final updateSelectedTextFontSize = _stylesService.updateSelectionFontSize;
  late final changeSelectionColor = _stylesService.changeSelectionColor;
  late final indentSelection = _stylesService.indentSelection;

  // === CURSOR / SELECTION ===

  TextSelection get selection => _selectionService.selection;
  late final moveCursorToPosition = _selectionService.moveCursorToPosition;
  late final moveCursorToStart = _selectionService.moveCursorToStart;
  late final moveCursorToEnd = _selectionService.moveCursorToEnd;
  late final selectWordsInRange = _selectionService.selectWordsInRange;
  late final selectWordEdge = _selectionService.selectWordEdge;
  late final selectPositionAt = _selectionService.selectPositionAt;
  late final selectAll = _selectionService.selectAll;
  late final extendSelection = _selectionService.extendSelection;

  // === HIGHLIGHTS ===

  late final addHighlight = _highlightsService.addHighlight;
  late final removeHighlight = _highlightsService.removeHighlight;
  late final removeHighlightsById = _highlightsService.removeHighlightsById;
  late final removeAllHighlights = _highlightsService.removeAllHighlights;

  // === MARKERS ===

  late final addMarker = _markersService.addMarker;
  late final deleteMarkerById = _markersService.deleteMarkerById;
  late final toggleMarkers = _markersService.toggleMarkers;
  late final toggleMarkerByTypeId = _markersService.toggleMarkerByTypeId;
  late final getMarkersVisibility = _markersService.getMarkersVisibility;
  late final isMarkerTypeVisible = _markersService.isMarkerTypeVisible;
  late final getAllMarkers = _markersService.getAllMarkers;

  // === HISTORY ===

  late final hasUndo = _state.refs.historyController.hasUndo;
  late final hasRedo = _state.refs.historyController.hasRedo;
  late final undo = _state.refs.historyController.undo;
  late final redo = _state.refs.historyController.redo;
  late final clearHistory = _state.refs.historyController.clearHistory;

  // === EMBEDS ===

  late final insertInSelectionImageViaUrl = _embedsService.insertInSelectionImageViaUrl;
  late final insertInSelectionVideoViaUrl = _embedsService.insertInSelectionVideoViaUrl;

  // === LINKS ===

  late final getLinkRange = _linksService.getLinkRange;

  // === KEYBOARD ===

  late final requestKeyboard = _keyboardService.requestKeyboard;

  // === UTILS ===

  // Safely pass the state from the controller to the buttons without the public having access to the state.
  // Read more in EditorStateReceiver doc comment.
  void setStateInEditorStateReceiver(EditorStateReceiver receiver) {
    receiver.cacheStateStore(_state);
  }
}
