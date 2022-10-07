import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/services.dart';

import '../../documents/models/attribute-scope.enum.dart';
import '../../documents/models/attribute.model.dart';
import '../../documents/models/attributes/attributes.model.dart';
import '../../documents/models/change-source.enum.dart';
import '../../documents/models/delta/delta-changes.model.dart';
import '../../documents/models/delta/delta.model.dart';
import '../../documents/models/document.model.dart';
import '../../documents/models/nodes/embeddable.model.dart';
import '../../documents/models/nodes/leaf.model.dart';
import '../../documents/models/style.model.dart';
import '../../documents/services/attribute.utils.dart';
import '../../documents/services/delta.utils.dart';
import '../../embeds/models/image.model.dart';
import '../../highlights/models/highlight.model.dart';
import '../../markers/const/default-marker-type.const.dart';
import '../../markers/models/marker-type.model.dart';
import '../../markers/models/marker.model.dart';
import '../../shared/models/selection-rectangles.model.dart';
import '../../shared/state/editor-state-receiver.dart';
import '../../shared/state/editor.state.dart';
import '../../shared/utils/string.utils.dart';
import '../models/paste-style.model.dart';

// Return false to ignore the event.
typedef ReplaceTextCallback = bool Function(int index, int len, Object? data);
typedef DeleteCallback = void Function(int cursorPosition, bool forward);
typedef SelectionCompleteCallback = void Function(
  List<SelectionRectanglesM?> rectanglesByLines,
);
typedef SelectionChangedCallback = void Function(
  TextSelection textSelection,
  List<SelectionRectanglesM?> rectanglesByLines,
);

// Controller object which establishes a link between a rich text document and this editor.
// EditorController stores the the state of the Document and the current TextSelection.
// Both EditorEditor and the EditorToolbar use the  controller to synchronize their state.
// The controller defines several properties that represent the state of the document and the state of the editor,
// plus several methods that notify the listeners.
//
// For ex, when users interact with the document the updateSelection() method is invoked.
// The method itself is one of the many that trigger the updateEditor$ stream.
// Most of the listeners that subscribe to the state changes of the controller are located in the
// EditorToolbar and are directly controlling the state of the buttons.
//
// Example: The EditorToolbar listens the notifications emitted by the controller class.
// If the current text selection has the bold attribute then  the EditorToolbar react by highlighting the bold button.
//
// The most important listener is located in the VisualEditorState in the initState() and didUpdateWidget() methods.
// This listener triggers  _onChangeTextEditingValue() which in turn has several duties, such as
// - Updating the state of the overlay selection.
// - Reconnecting to the remote  input.
// However by far the most important step is to trigger a render by invoking setState().
// Once a new build() is running then the _Editor starts rendering the new state of the Editor Editor.
// From here the entire rendering process starts executing again.
// In short summary, the document is parsed and converted into rendering elements, lines of text and blocks.
// Each line of text handles it's own styling and highlights rendering.
//
// Properties:
// selection - The text selection can be configured on init
// highlights - Multiple HighlightMs can be rendered on top of the document text.
// The highlights are independent of the DeltaM and can be used for tasks such as
// - Temporarily rendering a marker over important text.
// - Rendering the text selection where a custom tooltip will be placed.
// keepStyleOnNewLine - Will perpetuate the text styles when starting a new line.
//
// Callbacks:
// onReplaceText - Callback executed after inserting blocks on top of existing  blocks.
// Multiple operations can trigger this behavior: copy/paste, inserting embeds, etc.
// onDelete - Callback executed after deleting characters.
// onSelectionCompleted - Custom behavior to be executed after completing a text selection
class EditorController {
  // Stores the entire state of an editor instance.
  // We create this in the controller to be able to pass the same
  // state instance to both the editor and the toolbar.
  final _state = EditorState();

  final DocumentM document;
  final bool keepStyleOnNewLine;
  TextSelection selection;
  List<HighlightM> highlights;
  List<MarkerTypeM> markerTypes;

  // Fires when characters are added or removed from the document.
  // (!) Does not fire on style changes.
  // Return false to ignore the event.
  ReplaceTextCallback? onReplaceText;
  DeleteCallback? onDelete;
  SelectionChangedCallback? onSelectionChanged;
  SelectionCompleteCallback? onSelectionCompleted;

  // Called each time when the editor is updated via the refreshEditor$ stream.
  // This signal can be used to update the placement of attachments using the latest rectangles data (after any text editing operation).
  // It happens after the build has completed to ensure that we have access to the latest rectangles.
  void Function()? onBuildComplete;
  void Function()? onScroll;

  // TODO Move to dedicated state
  // Store any styles attribute that got toggled by the tap of a button and that has not been applied yet.
  // It gets reset after each format action within the document.
  StyleM toggledStyle = StyleM();

  // Stream the changes of every document.
  Stream<DeltaChangeM> get changes => document.changes;

  // Clipboard for image url and its corresponding style item1 is url and item2 is style string.
  // TODO Review this, it seems like a workaround (not yet refactored)
  ImageM? _copiedImageUrl;

  ImageM? get copiedImageUrl => _copiedImageUrl;

  set copiedImageUrl(ImageM? imgUrl) {
    _copiedImageUrl = imgUrl;
    Clipboard.setData(const ClipboardData(text: ''));
  }

  // Notify buttons buttons directly with attributes.
  Map<String, AttributeM> toolbarButtonToggler = {};

  TextEditingValue get plainTextEditingValue => TextEditingValue(
        text: document.toPlainText(),
        selection: selection,
      );

  bool get hasUndo => document.hasUndo;

  bool get hasRedo => document.hasRedo;

  EditorController({
    required this.document,
    this.selection = const TextSelection.collapsed(offset: 0),
    this.highlights = const [],
    this.markerTypes = const [],
    this.keepStyleOnNewLine = false,
    this.onReplaceText,
    this.onDelete,
    this.onSelectionCompleted,
    this.onSelectionChanged,
    this.onBuildComplete,
    this.onScroll,
  }) {
    _state.document.setDocument(document);
    _state.highlights.setHighlights(highlights);

    if (markerTypes.isNotEmpty) {
      _state.markersTypes.setMarkersTypes(markerTypes);
    }
  }

  // TODO Deprecate (no longer needed)
  factory EditorController.basic() => EditorController(
        document: DocumentM(),
      );

  // Safely pass the state from the controller to the buttons without the public having access to the state.
  // Read more in EditorStateReceiver doc comment.
  void setStateInEditorStateReceiver(EditorStateReceiver receiver) {
    receiver.setState(_state);
  }

  // === HISTORY ===

  void undo() {
    final tup = document.undo();

    if (tup.applyChanges) {
      _handleHistoryChange(tup.offset);
    }
  }

  void redo() {
    final tup = document.redo();

    if (tup.applyChanges) {
      _handleHistoryChange(tup.offset);
    }
  }

  // === DOCUMENT ===

  // Returns plain text for each node within selection
  String getPlainText() {
    final text = document.getPlainText(
      selection.start,
      selection.end - selection.start,
    );

    return text;
  }

  // Update editor with a new document.
  // Use ignoreFocus if you want to avoid the caret to be position and activated when changing the doc.
  void update(
    DeltaM delta, {
    bool ignoreFocus = false,
  }) {
    clear(
      ignoreFocus: ignoreFocus,
    );
    compose(
      delta,
      const TextSelection.collapsed(offset: 0),
      ChangeSource.LOCAL,
    );
  }

  // Clear editor
  // Use ignoreFocus if you want to avoid the caret to be position and activated when changing the doc.
  void clear({bool ignoreFocus = false}) {
    replaceText(
      0,
      plainTextEditingValue.text.length - 1,
      '',
      const TextSelection.collapsed(
        offset: 0,
      ),
      ignoreFocus: ignoreFocus,
    );
  }

  // Use ignoreFocus if you want to avoid the caret to be position and activated when changing the doc.
  void replaceText(
    int index,
    int len,
    Object? data,
    TextSelection? textSelection, {
    bool ignoreFocus = false,
  }) {
    assert(data is String || data is EmbeddableM);

    if (onReplaceText != null && !onReplaceText!(index, len, data)) {
      return;
    }

    DeltaM? delta;

    if (len > 0 || data is! String || data.isNotEmpty) {
      delta = document.replace(index, len, data);
      var shouldRetainDelta = toggledStyle.isNotEmpty &&
          delta.isNotEmpty &&
          delta.length <= 2 &&
          delta.last.isInsert;

      if (shouldRetainDelta &&
          toggledStyle.isNotEmpty &&
          delta.length == 2 &&
          delta.last.data == '\n') {
        // If all attributes are inline, shouldRetainDelta should be false
        final anyAttributeNotInline = toggledStyle.values.any(
          (attr) => !attr.isInline,
        );

        if (!anyAttributeNotInline) {
          shouldRetainDelta = false;
        }
      }

      if (shouldRetainDelta) {
        final retainDelta = DeltaM()
          ..retain(index)
          ..retain(
            data is String ? data.length : 1,
            toggledStyle.toJson(),
          );
        document.compose(retainDelta, ChangeSource.LOCAL);
      }
    }

    if (keepStyleOnNewLine) {
      final style = getSelectionStyle();
      final notInlineStyle = style.attributes.values.where((s) => !s.isInline);
      toggledStyle = style.removeAll(notInlineStyle.toSet());
    } else {
      toggledStyle = StyleM();
    }

    if (textSelection != null) {
      if (delta == null || delta.isEmpty) {
        _cacheSelection(textSelection, ChangeSource.LOCAL);
      } else {
        final user = DeltaM()
          ..retain(index)
          ..insert(data)
          ..delete(len);
        final positionDelta = getPositionDelta(user, delta);

        _cacheSelection(
          textSelection.copyWith(
            baseOffset: textSelection.baseOffset + positionDelta,
            extentOffset: textSelection.extentOffset + positionDelta,
          ),
          ChangeSource.LOCAL,
        );
      }
    }

    _state.refreshEditor.refreshEditorWithoutCaretPlacement();

    if (textSelection != null) {
      _selectionChangedCallback();
    }
  }

  void compose(
    DeltaM delta,
    TextSelection textSelection,
    ChangeSource source,
  ) {
    if (delta.isNotEmpty) {
      document.compose(delta, source);
    }

    textSelection = selection.copyWith(
      baseOffset: delta.transformPosition(
        selection.baseOffset,
        force: false,
      ),
      extentOffset: delta.transformPosition(
        selection.extentOffset,
        force: false,
      ),
    );

    final sameSelection = selection == textSelection;
    if (!sameSelection) {
      _cacheSelection(textSelection, source);
    }

    _state.refreshEditor.refreshEditor();

    if (!sameSelection) {
      _selectionChangedCallback();
    }
  }

  // Called in two cases:
  // forward == false && textBefore.isEmpty
  // forward == true && textAfter.isEmpty
  // Android only
  // See https://github.com/singerdmx/flutter-quill/discussions/514
  void handleDelete(int cursorPosition, bool forward) =>
      onDelete?.call(cursorPosition, forward);

  // === TEXT STYLES ===

  void formatTextStyle(int index, int len, StyleM style) {
    style.attributes.forEach((key, attr) {
      formatText(index, len, attr);
    });
  }

  // TODO Add comment
  void formatText(
    int index,
    int len,
    AttributeM? attribute,
  ) {
    if (len == 0 &&
        attribute!.isInline &&
        attribute.key != AttributesM.link.key) {
      // Add the attribute to our toggledStyle.
      // It will be used later upon insertion.
      toggledStyle = toggledStyle.put(attribute);
    }

    final change = document.format(index, len, attribute);

    // Transform selection against the composed change and give priority to the change.
    // This is needed in cases when format operation actually inserts data into the document (e.g. embeds).
    final adjustedSelection = selection.copyWith(
      baseOffset: change.transformPosition(selection.baseOffset),
      extentOffset: change.transformPosition(selection.extentOffset),
    );

    final sameSelection = selection == adjustedSelection;

    if (!sameSelection) {
      _cacheSelection(adjustedSelection, ChangeSource.LOCAL);
    }

    _state.refreshEditor.refreshEditor();

    if (!sameSelection) {
      _selectionChangedCallback();
    }
  }

  // Applies an attribute to a selection of text
  void formatSelection(AttributeM? attribute) {
    formatText(
      selection.start,
      selection.end - selection.start,
      attribute,
    );
  }

  // Only attributes applied to all characters within this range are included in the result.
  StyleM getSelectionStyle() => document
      .collectStyle(
        selection.start,
        selection.end - selection.start,
      )
      .mergeAll(toggledStyle);

  // Returns all styles for each node within selection
  List<PasteStyleM> getAllIndividualSelectionStyles() {
    final styles = document.collectAllIndividualStyles(
      selection.start,
      selection.end - selection.start,
    );

    return styles;
  }

  // Returns all styles for any character within the specified text range.
  List<StyleM> getAllSelectionStyles() {
    final styles = document.collectAllStyles(
      selection.start,
      selection.end - selection.start,
    )..add(toggledStyle);

    return styles;
  }

  // === CURSOR ===

  void moveCursorToStart() {
    updateSelection(
      const TextSelection.collapsed(
        offset: 0,
      ),
      ChangeSource.LOCAL,
    );
  }

  void moveCursorToPosition(int position) {
    updateSelection(
      TextSelection.collapsed(
        offset: position,
      ),
      ChangeSource.LOCAL,
    );
  }

  void moveCursorToEnd() {
    updateSelection(
      TextSelection.collapsed(
        offset: plainTextEditingValue.text.length,
      ),
      ChangeSource.LOCAL,
    );
  }

  // === SELECTION ===

  void updateSelection(
    TextSelection textSelection,
    ChangeSource source,
  ) {
    _cacheSelection(textSelection, source);
    _state.refreshEditor.refreshEditor();
    _selectionChangedCallback();
  }

  // === NODES ===

  // Given offset, find its leaf node in document
  LeafM? queryNode(int offset) {
    return document.querySegmentLeafNode(offset).leaf;
  }

  // === HIGHLIGHTS ===

  void addHighlight(HighlightM highlight) {
    _state.highlights.addHighlight(highlight);
    _state.refreshEditor.refreshEditor();
  }

  void removeHighlight(HighlightM highlight) {
    _state.highlights.removeHighlight(highlight);
    _state.refreshEditor.refreshEditor();
  }

  void removeAllHighlights(HighlightM highlight) {
    _state.highlights.removeAllHighlights();
    _state.refreshEditor.refreshEditor();
  }

  // === MARKERS ===

  void addMarker(String markerTypeId) {
    // Existing markers
    final style = getSelectionStyle();
    final styleAttributes = style.values.toList();

    List<MarkerM>? markers = [];

    // Get Existing Markers
    if (styleAttributes.isNotEmpty) {
      final markersMap = styleAttributes.firstWhere(
        (attribute) => attribute.key == AttributesM.markers.key,
        orElse: () => AttributeM('', AttributeScope.INLINE, null),
      );

      if (markersMap.key != '') {
        markers = markersMap.value;
      }
    }

    // On Add Callback
    // Returns the UUIDs or whatever custom data the client app desires
    // to store inline as a value of hte marker attribute.
    final markersTypes = _state.markersTypes.types;

    final MarkerTypeM? markerType = markersTypes.firstWhere(
      (type) => type.id == markerTypeId,
      orElse: () => defaultMarkerType,
    );

    var data;

    // The client app is given the option to generate a random UUID and save it in the marker on marker creation.
    // This UUID can be used to link the marker to entries from another table where you can keep additional metadata about this marker.
    // For ex: You can have a marker linked to a user profile by the user profile UUID.
    // By using UUIDs we can avoid duplicating metadata in the delta json when we copy paste markers.
    // It also keeps the delta document lightweight.
    if (markerType != null && markerType.onAddMarkerViaToolbar != null) {
      data = markerType.onAddMarkerViaToolbar!(markerType);
    }

    final marker = MarkerM(
      textSelection: selection.copyWith(),
      id: getTimeBasedId(),
      type: markerTypeId,
      data: data,
    );

    // Add the new marker
    markers?.add(marker);

    // Markers are stored as json data in the styles
    final jsonMarkers = markers?.map((marker) => marker.toJson()).toList();

    // Add to document
    formatSelection(
      AttributeUtils.fromKeyValue(AttributesM.markers.key, jsonMarkers),
    );
  }

  // Because we can have the same marker copied in different parts of the
  // document we have to delete all markers with the same id
  void deleteMarkerById(String markerId) {
    _state.markers.markers.forEach((marker) {
      if (marker.id == markerId) {
        assert(
          marker.textSelection != null,
          "Can't find text selection data on the marker. Therefore we can't remove the marker",
        );

        final index = marker.textSelection?.baseOffset ?? 0;
        final length = (marker.textSelection?.extentOffset ?? 0) -
            (marker.textSelection?.baseOffset ?? 0);

        formatText(
          index,
          length,
          AttributeUtils.fromKeyValue(AttributesM.markers.key, null),
        );
      }
    });
  }

  void toggleMarkers(bool areVisible) {
    _state.markersVisibility.toggleMarkers(areVisible);
  }

  bool getMarkersVisibility() {
    return _state.markersVisibility.visibility;
  }

  List<MarkerM> getAllMarkers() {
    return _state.markers.markers;
  }

  // === PRIVATE ===

  void _handleHistoryChange(int? length) {
    if (length! != 0) {
      updateSelection(
        TextSelection.collapsed(
          offset: selection.baseOffset + length,
        ),
        ChangeSource.LOCAL,
      );
    } else {
      // No need to move cursor
      _state.refreshEditor.refreshEditor();
    }
  }

  // Store the new selection extent values
  void _cacheSelection(TextSelection _selection, ChangeSource source) {
    selection = _selection;
    final end = document.length - 1;
    selection = selection.copyWith(
      baseOffset: math.min(selection.baseOffset, end),
      extentOffset: math.min(selection.extentOffset, end),
    );
    toggledStyle = StyleM();
  }

  // We have separated the selection callback from the selection caching code because we have to wait
  // for the build() to complete to extract the rectangles of a text selection.
  // We want to use these rectangles to give total freedom to the client devs to decide how to place their attachments.
  //
  // This means we now have 2 ways of customizing the selection menu:
  // 1) When the selection callbacks have emitted we can use the rectangles data to place any attachment anywhere
  //    Recommended when you want to place atypical looking markers related to the lines of selected text
  // 2) Standard flutter procedure using a custom TextSelectionControls
  //    Recommended when you want to display standard selection menu with custom buttons.
  //
  // Therefore (as of Oct 2022, Adrian) we decided to split the selection update cycle in two stages.
  // Stage 1
  // - First, we collect the new selection extends (as it was done until now).
  // - We wait for the build() to complete to gain access to the latest selection rectangles from the editable line renderers.
  // - We cache the rectangles by lines information in the state store
  // Stage 2
  // - Now that the build is complete and we have latest data, we call the selection callbacks
  //   that were defined in the original API, now including the rectangles data
  // It's possible that this pattern might change if we learn more after refactoring the selection handles code
  void _selectionChangedCallback() {
    if (onSelectionChanged != null) {
      final rectangles = _state.selection.selectionRectangles;
      onSelectionChanged!(selection, rectangles);
    }
  }
}
