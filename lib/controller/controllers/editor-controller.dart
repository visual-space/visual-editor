import 'package:flutter/material.dart';
import '../../doc-tree/services/coordinates.service.dart';
import '../../document/controllers/document.controller.dart';
import '../../document/models/delta-doc.model.dart';
import '../../editor/services/editor.service.dart';
import '../../embeds/services/embeds.service.dart';
import '../../highlights/services/highlights.service.dart';
import '../../inputs/services/keyboard.service.dart';
import '../../links/services/links.service.dart';
import '../../markers/services/markers.service.dart';
import '../../selection/services/selection-renderer.service.dart';
import '../../selection/services/selection.service.dart';
import '../../shared/state/editor-state-receiver.dart';
import '../../shared/state/editor.state.dart';
import '../../styles/services/styles.service.dart';
import '../../toolbar/services/toolbar.service.dart';

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
// - replace() - Replaces a range of text with the new text or an embed
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
  late final CoordinatesService _coordinatesService;
  late final LinksService _linksService;
  late final SelectionRendererService _selectionRendererService;
  late final ToolbarService _toolbarService;

  final _state = EditorState();

  EditorController({DeltaDocM? document}) {
    // Document
    _state.document.document = document ?? DeltaDocM();

    // Services
    _editorService = EditorService(_state);
    _stylesService = StylesService(_state);
    _selectionService = SelectionService(_state);
    _highlightsService = HighlightsService(_state);
    _markersService = MarkersService(_state);
    _embedsService = EmbedsService(_state);
    _keyboardService = KeyboardService(_state);
    _linksService = LinksService(_state);
    _coordinatesService = CoordinatesService(_state);
    _selectionRendererService = SelectionRendererService(_state);
    _toolbarService = ToolbarService(_state);

    // Controllers
    _initControllersAndCacheControllersRefs();
  }

  // === DOCUMENT ===

  DeltaDocM get document => _editorService.document;
  late final changes$ = _editorService.changes$;
  TextEditingValue get plainText => _editorService.plainText;
  int get docLength => _editorService.docLength;
  late final selectionPlainText = _editorService.getSelectionPlainText;
  late final update = _editorService.update;
  late final clear = _editorService.clear;
  late final replace = _editorService.replace;
  late final compose = _editorService.compose;
  late final addLinkToSelection = _editorService.addLinkToSelection;
  late final getSelectionLinkAttributeValue = _editorService.getSelectionLinkAttributeValue;
  late final queryNode = _editorService.queryNode;
  late final close = _editorService.close;
  late final isClosed = _editorService.isClosed;
  late final setCustomRules = _editorService.setCustomRules;

  // === TEXT STYLES ===

  late final formatSelectedTextByStyle = _stylesService.formatTextRangeWithStyle;
  late final formatTextRange = _stylesService.formatTextRange;
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
  late final getHeadingsByType = _editorService.getHeadingsByType;

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
  late final toggleMarkerHighlightVisibilityByTypeId = _markersService.toggleMarkerHighlightVisibilityByTypeId;
  late final toggleMarkerTextVisibilityByTypeId = _markersService.toggleMarkerTextVisibilityByTypeId;
  late final toggleMarkerTextVisibilityByMarkerId = _markersService.toggleMarkerTextVisibilityByMarkerId;
  late final getMarkersVisibility = _markersService.getMarkersVisibility;
  late final isMarkerTypeHighlightVisible = _markersService.isMarkerTypeHighlightVisible;
  late final isMarkerTypeTextVisible = _markersService.isMarkerTypeTextVisible;
  late final getAllMarkers = _markersService.getAllMarkers;

  // === HISTORY ===

  bool get hasUndo => _state.refs.historyController.hasUndo;
  bool get hasRedo => _state.refs.historyController.hasRedo;
  late final undo = _state.refs.historyController.undo;
  late final redo = _state.refs.historyController.redo;
  late final clearHistory = _state.refs.historyController.clearHistory;

  // === EMBEDS ===

  late final insertInSelectionImageViaUrl = _embedsService.insertInSelectionImageViaUrl;
  late final insertInSelectionVideoViaUrl = _embedsService.insertInSelectionVideoViaUrl;

  // === LINKS ===

  late final getLinkRange = _linksService.getLinkRange;
  late final removeSelectionLink = _linksService.removeSelectionLink;
  late final getOffsetForLinkMenu = _linksService.getOffsetForLinkMenu;

  // === TOOLBAR ===

  late final toggleStylingButtons = _toolbarService.toggleStylingButtons;

  // === KEYBOARD ===

  late final requestKeyboard = _keyboardService.requestKeyboard;

  // === DEV UTILS ===

  late final getPositionForOffset = _coordinatesService.getPositionForOffset;
  late final getWordAtPosition = _selectionRendererService.getWordAtPosition;

  // === UTILS ===

  // Safely pass the state from the controller to the buttons without the public having access to the state.
  // Read more in EditorStateReceiver doc comment.
  void setStateInEditorStateReceiver(EditorStateReceiver receiver) {
    receiver.cacheStateStore(_state);
  }

  // Document related controllers
  // Editor controller uses other children controllers to delegate various tasks.
  // Ex: DocumentController controls the document model.
  void _initControllersAndCacheControllersRefs() {
    // Document Controller
    _state.refs.documentController = DocumentController(
      _state.document.document,
      _state.document.emitChange,
      _editorService.composeCacheSelectionAndRunBuild,
    );
    _state.refs.documentControllerInitialised = true;

    // History Controller
    _state.refs.historyController =
        _state.refs.documentController.historyController;
    _state.refs.historyControllerInitialised = true;
  }
}
