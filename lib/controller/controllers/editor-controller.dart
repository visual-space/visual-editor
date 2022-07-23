import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import '../../documents/models/attribute.model.dart';
import '../../documents/models/change-source.enum.dart';
import '../../documents/models/delta/delta-changes.model.dart';
import '../../documents/models/delta/delta.model.dart';
import '../../documents/models/document.model.dart';
import '../../documents/models/nodes/embeddable.model.dart';
import '../../documents/models/nodes/leaf.model.dart';
import '../../documents/models/nodes/node.model.dart';
import '../../documents/models/style.model.dart';
import '../../documents/services/delta.utils.dart';
import '../../embeds/models/image.model.dart';
import '../../highlights/models/highlight.model.dart';
import '../../shared/state/editor-state-receiver.dart';
import '../../shared/state/editor.state.dart';
import '../models/paste-style.model.dart';

// Return false to ignore the event.
typedef ReplaceTextCallback = bool Function(int index, int len, Object? data);
typedef DeleteCallback = void Function(int cursorPosition, bool forward);

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
  ReplaceTextCallback? onReplaceText;
  DeleteCallback? onDelete;
  void Function()? onSelectionCompleted;
  void Function(TextSelection textSelection)? onSelectionChanged;
  void Function()? onPreLayout;
  void Function(RenderBox renderer, NodeM block)? onLayoutParagraph;
  bool ignoreFocusOnTextChange = false;

  // Store any styles attribute that got toggled by the tap of a button and that has not been applied yet.
  // It gets reset after each format action within the document.
  StyleM toggledStyle = StyleM();

  // Stream the changes of every document
  Stream<DeltaChangeM> get changes => document.changes;

  // Clipboard for image url and its corresponding style item1 is url and item2 is style string
  ImageM? _copiedImageUrl;

  ImageM? get copiedImageUrl => _copiedImageUrl;

  set copiedImageUrl(ImageM? imgUrl) {
    _copiedImageUrl = imgUrl;
    Clipboard.setData(const ClipboardData(text: ''));
  }

  // Notify buttons buttons directly with attributes
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
    this.keepStyleOnNewLine = false,
    this.onReplaceText,
    this.onDelete,
    this.onSelectionCompleted,
    this.onSelectionChanged,
    this.onPreLayout,
    this.onLayoutParagraph,
  }) {
    _state.document.setDocument(document);
  }

  // Todo Deprecate (no longer needed)
  factory EditorController.basic() => EditorController(
        document: DocumentM(),
      );

  void setStateInEditorStateReceiver(EditorStateReceiver receiver) {
    receiver.setState(_state);
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

  // Returns plain text for each node within selection
  String getPlainText() {
    final text = document.getPlainText(
      selection.start,
      selection.end - selection.start,
    );

    return text;
  }

  // Returns all styles for any character within the specified text range.
  List<StyleM> getAllSelectionStyles() {
    final styles = document.collectAllStyles(
      selection.start,
      selection.end - selection.start,
    )..add(toggledStyle);

    return styles;
  }

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

  // Update editor with a new document
  void update(DeltaM delta) {
    clear();
    compose(
      delta,
      const TextSelection.collapsed(offset: 0),
      ChangeSource.LOCAL,
    );
  }

  // Clear editor
  void clear() {
    replaceText(
      0,
      plainTextEditingValue.text.length - 1,
      '',
      const TextSelection.collapsed(
        offset: 0,
      ),
    );
  }

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
        _updateSelection(textSelection, ChangeSource.LOCAL);
      } else {
        final user = DeltaM()
          ..retain(index)
          ..insert(data)
          ..delete(len);
        final positionDelta = getPositionDelta(user, delta);

        _updateSelection(
          textSelection.copyWith(
            baseOffset: textSelection.baseOffset + positionDelta,
            extentOffset: textSelection.extentOffset + positionDelta,
          ),
          ChangeSource.LOCAL,
        );
      }
    }

    if (ignoreFocus) {
      ignoreFocusOnTextChange = true;
    }

    _state.refreshEditor.refreshEditor();
    ignoreFocusOnTextChange = false;
  }

  // Called in two cases:
  // forward == false && textBefore.isEmpty
  // forward == true && textAfter.isEmpty
  // Android only
  // See https://github.com/singerdmx/flutter-quill/discussions/514
  void handleDelete(int cursorPosition, bool forward) =>
      onDelete?.call(cursorPosition, forward);

  void formatTextStyle(int index, int len, StyleM style) {
    style.attributes.forEach((key, attr) {
      formatText(index, len, attr);
    });
  }

  void formatText(
    int index,
    int len,
    AttributeM? attribute,
  ) {
    if (len == 0 &&
        attribute!.isInline &&
        attribute.key != AttributeM.link.key) {
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

    if (selection != adjustedSelection) {
      _updateSelection(
        adjustedSelection,
        ChangeSource.LOCAL,
      );
    }

    _state.refreshEditor.refreshEditor();
  }

  void formatSelection(AttributeM? attribute) {
    formatText(
      selection.start,
      selection.end - selection.start,
      attribute,
    );
  }

  void moveCursorToStart() {
    updateSelection(
      const TextSelection.collapsed(offset: 0),
      ChangeSource.LOCAL,
    );
  }

  void moveCursorToPosition(int position) {
    updateSelection(
      TextSelection.collapsed(offset: position),
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

  void updateSelection(
    TextSelection textSelection,
    ChangeSource source,
  ) {
    _updateSelection(textSelection, source);
    _state.refreshEditor.refreshEditor();
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

    if (selection != textSelection) {
      _updateSelection(textSelection, source);
    }

    _state.refreshEditor.refreshEditor();
  }

  // Given offset, find its leaf node in document
  LeafM? queryNode(int offset) {
    return document.querySegmentLeafNode(offset).leaf;
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

  void _updateSelection(TextSelection textSelection, ChangeSource source) {
    selection = textSelection;
    final end = document.length - 1;
    selection = selection.copyWith(
      baseOffset: math.min(selection.baseOffset, end),
      extentOffset: math.min(selection.extentOffset, end),
    );
    toggledStyle = StyleM();

    onSelectionChanged?.call(textSelection);
  }
}
