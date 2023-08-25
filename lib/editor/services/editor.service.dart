import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../document/models/attributes/attributes.model.dart';
import '../../document/models/attributes/styling-attributes.dart';
import '../../document/models/delta-doc.model.dart';
import '../../document/models/delta/delta-changes.model.dart';
import '../../document/models/delta/delta.model.dart';
import '../../document/models/history/change-source.enum.dart';
import '../../document/models/nodes/embed-node.model.dart';
import '../../document/models/nodes/embed.model.dart';
import '../../document/models/nodes/line-leaf.model.dart';
import '../../document/models/nodes/style.model.dart';
import '../../document/services/delta.utils.dart';
import '../../document/services/nodes/styles.utils.dart';
import '../../headings/models/heading-type.enum.dart';
import '../../headings/models/heading.model.dart';
import '../../links/services/links.service.dart';
import '../../rules/models/rule.model.dart';
import '../../selection/services/selection.service.dart';
import '../../shared/state/editor.state.dart';
import '../../styles/services/styles.service.dart';
import '../../toolbar/models/link-button.model.dart';
import 'run-build.service.dart';

typedef RemoveSpecialCharsAndUpdateDocTextAndStyleCallback = void Function(
  TextEditingValue plainText,
  SelectionChangedCause cause,
);

typedef ReplaceTextCallback = void Function(
  int index,
  int len,
  Object? data,
  TextSelection? textSelection, {
  bool emitEvent,
  bool ignoreFocus,
});

final _stylesUtils = StylesUtils();

// Contains the logic that orchestrates the editor UI systems with the DocumentController (pure data editing).
// Does not contain the document mutation logic. It delegates this logic to the DocumentController.
// This means that methods from the service are concerned with:
// - updates all systems of the editor (selection, focus, scroll, markers, menus, etc).
// - invokes the callbacks provided by the client code.
// - triggers the build cycle.
//
// (!) The actual document (pure data) editing happens by calling compose() or other methods from the documentController level.
// Since both of these are public APIs (service and controller) we had to use short names (less expressive).
// Therefore to solve the confusion between editorController.compose() and documentController.compose() remember
// that the editor level has to coordinate more systems along with the updates of the document.
// Which means that the actual pure data editing of the document content happens in documentController.
class EditorService {
  late final RunBuildService _runBuildService;
  late final SelectionService _selectionService;
  late final StylesService _stylesService;
  late final LinksService _linksService;
  final _du = DeltaUtils();

  final EditorState state;

  EditorService(this.state) {
    _runBuildService = RunBuildService(state);
    _selectionService = SelectionService(state);
    _stylesService = StylesService(state);
    _linksService = LinksService(state);
  }

  // === QUERIES ===

  DeltaDocM get document {
    return state.document.document;
  }

  Stream<DocAndChangeM> get changes$ {
    return state.document.changes$;
  }

  // Get plain text and selection
  int get docLength {
    return state.refs.documentController.docCharsNum;
  }

  // Get plain text and selection
  // TODO This is a potential place for improvement, Many places call on this method. It should return a cached answer.
  TextEditingValue get plainText {
    return TextEditingValue(
      text: state.refs.documentController.toPlainText(),
      selection: state.selection.selection,
    );
  }

  // Returns plain text for each node within selection
  String getSelectionPlainText() {
    final selection = state.selection.selection;
    final text = state.refs.documentController.getPlainTextAtRange(
      selection.start,
      selection.end - selection.start,
    );

    return text;
  }

  // === EDIT OPERATIONS ===

  // Update editor with a new document. (mutates the doc)
  // Use ignoreFocus if you want to avoid the caret to be positioned and activate when changing the doc.
  void update(
    DeltaM delta, {
    bool ignoreFocus = false,
    bool emitEvent = true,
  }) {
    clear(
      ignoreFocus: ignoreFocus,
      emitEvent: emitEvent,
    );
    var currDocDelta = state.refs.documentController.document.delta;
    compose(
      delta,
      const TextSelection.collapsed(offset: 0),
      ChangeSource.LOCAL,
      emitEvent,
      overrideRootNode: true,
    );
  }

  // Clear editor
  // Use ignoreFocus if you want to avoid the caret to be position and activated when changing the doc.
  void clear({
    bool ignoreFocus = false,
    bool emitEvent = true,
  }) {
    final len = plainText.text.length - 1;
    const collapseSel = TextSelection.collapsed(offset: 0);

    replace(
      0,
      len,
      '',
      collapseSel,
      emitEvent: emitEvent,
      ignoreFocus: ignoreFocus,
    );
  }

  // Update the text of the document by replacing selection text with new text.
  // If the option is enabled it can preserve the styles of the prev line of text on the new line that is created.
  // Updates the selection depending on the changes made in text.
  // Unlike update() it only update part of the existing document.
  // Calls client code callbacks.
  // index - At which character to start
  // length - How many characters to replace
  // data - Content to be inserted (text, embed)
  // textSelection - Text selection after the update
  // ignoreFocus - Avoid the caret to be position and activated when changing the doc.
  void replace(
    int index,
    int len,
    Object? data,
    TextSelection? selection, {
    bool ignoreFocus = false,
    bool emitEvent = true,
  }) {
    assert(
      data is String || data is EmbedM,
      'Expected node data type to be either String or Embed.',
    );

    // Callback
    final onReplaceText = state.config.onReplaceText;

    if (onReplaceText != null &&
        emitEvent &&
        !onReplaceText(index, len, data)) {
      return;
    }

    // Replace Text Compose + Apply Toggled Style
    final changeDelta = _replaceTextAndApplyToggledStyles(
      len,
      data,
      index,
      emitEvent,
    );

    // Retain styles on new line
    _keepStylesOnNewLine();

    // Cache changed selection
    _cacheSelectionUpdatedAfterEdit(selection, changeDelta, index, data, len);

    // Run build
    state.runBuild.runBuildWithoutCaretPlacement();

    // Callbacks
    if (selection != null) {
      _selectionService.callOnSelectionChanged();
    }

    if (emitEvent) {
      callOnTextReplaceComplete();
    }
  }

  // Applies the change in the document model by invoking compose() from the controller.
  // Additionally it updates the selection in the state store.
  // Triggers the build() cycle to update the document widgets tree update.
  // Invokes client code callbacks.
  // The changes$ stream can be inhibited on demand via the emitEvent: false flag.
  // This is useful when we need to setup the editor without notifying
  // other subscribed components of the initial changes.
  // TODO Improve newSelection param handling. Looks like we are always overwriting (exactly as forked from Quill)
  void compose(
    DeltaM delta,
    TextSelection newSelection,
    ChangeSource source,
    bool emitEvent, {
    bool overrideRootNode = false,
  }) {
    // Update doc model
    if (delta.isNotEmpty) {
      state.refs.documentController.compose(
        delta,
        source,
        emitEvent,
        overrideRootNode,
      );
    }

    // Cache new selection
    final selection = state.selection.selection;
    newSelection = selection.copyWith(
      baseOffset: _du.transformPosition(
        delta,
        selection.baseOffset,
        force: false,
      ),
      extentOffset: _du.transformPosition(
        delta,
        selection.extentOffset,
        force: false,
      ),
    );

    final sameSelection = selection == newSelection;

    if (!sameSelection) {
      _selectionService.cacheSelection(newSelection, source);
    }

    // Update Layout
    _runBuildService.runBuild();

    // Callback
    if (!sameSelection) {
      _selectionService.callOnSelectionChanged();
    }
  }

  // Executed when the user interacts with the editor via system menus (usually clipboard ops on mobile).
  // After the document is updated the next step will be the update gui and build() calls.
  // The new value is treated as user input and thus may subject to input formatting.
  // If no changes, collapses the selection and hide the buttons and handles.
  // Invoked on mobile devices.
  // TODO Figure out how copy pasting works on web, document.
  void removeSpecialCharsAndUpdateDocTextAndStyle(
    TextEditingValue plainText,
    SelectionChangedCause cause,
  ) {
    final cursorPosition = plainText.selection.extentOffset;
    final oldText = state.refs.documentController.toPlainText();
    final newText = plainText.text;
    final diff = _du.getDiff(oldText, newText, cursorPosition);

    if (diff.deleted == '' && diff.inserted == '') {
      // Only changing selection range
      _selectionService.cacheSelectionAndRunBuild(
        plainText.selection,
        ChangeSource.LOCAL,
      );

      return;
    }

    final insertedText = _removeSpecialObjectCharsFromText(diff.inserted);

    replace(
      diff.start,
      diff.deleted.length,
      insertedText,
      plainText.selection,
    );

    _applyPasteStyle(insertedText, diff.start);
  }

  // === CALLBACKS ===

  // Called when the editor is empty of text
  // TODO Currently unused. Seems to have been removed in Quill (possibly by mistake when mass deleting code).
  void callOnDelete(int cursorPosition, bool forward) {
    final onDelete = state.config.onDelete;
    onDelete?.call(cursorPosition, forward);
  }

  // We need a callback for detecting when the document text has changed but timed to be triggered after the build.
  // Such that we can extract the latest rectangles as well.
  // The existing callbacks are not suitable to replace this callback:
  // onReplaceText() - Called way to early, even before the document.changes stream
  // document.changes - The stream emits only changes (not complete docs) before the build is completed
  // onBuildComplete() - This one emits way too often, on hovering highlights, on selection changes, etc
  void callOnTextReplaceComplete() {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      final onReplaceTextCompleted = state.config.onReplaceTextCompleted;

      if (onReplaceTextCompleted != null) {
        onReplaceTextCompleted();
      }
    });
  }

  // === LINKS ===

  // TODO Replace dynamic with a proper type
  void addLinkToSelection(dynamic value) {
    // text.isNotEmpty && link.isNotEmpty
    final text = (value as LinkButtonM).text;
    final link = value.link.trim();
    final selection = _selectionService.selection;
    var index = selection.start;
    var length = selection.end - index;

    if (getSelectionLinkAttributeValue() != null) {
      // Text should be the link's corresponding text, not selection
      final leaf = queryNode(index).leaf;

      if (leaf != null) {
        final range = _linksService.getLinkRange(leaf);
        index = range.start;
        length = range.end - range.start;
      }
    }

    replace(index, length, text, null);
    _stylesService.formatTextRange(index, text.length, LinkAttributeM(link));
  }

  String? getSelectionLinkAttributeValue() => _stylesService
      .getSelectionStyle()
      .attributes[AttributesM.link.key]
      ?.value;

  // === NODES ===

  // Given offset, find its leaf node in document
  LineLeafM queryNode(int offset) {
    return state.refs.documentController.queryNode(offset);
  }

  List<HeadingM> getHeadingsByType(List<HeadingTypeE>? types) {
    if (types != null) {
      state.headings.headingsTypes = types;
    }

    return state.headings.headings;
  }

  // === CHANGES ===

  // After a history state was restored the resulting delta is
  // passed to the DocumentController to update the nodes.
  // In case the selection changed it gets cached.
  // Finally a new build cycle is triggered.
  void composeCacheSelectionAndRunBuild(
    DeltaM deltaRes,
    int? extent,
    bool emitEvent,
  ) {
    // Update Doc
    state.refs.documentController.compose(
      deltaRes,
      ChangeSource.LOCAL,
      emitEvent,
    );

    // Cache Selection + Run Build
    if (extent! != 0) {
      final offset = state.selection.selection.baseOffset + extent;

      _selectionService.cacheSelectionAndRunBuild(
        TextSelection.collapsed(offset: offset),
        ChangeSource.LOCAL,
      );
    } else {
      // Cache Selection
      _runBuildService.runBuild();
    }
  }

  // Flushes out the history of changes.
  // Useful when you want to discard a document and to release the memory.
  void close() {
    state.document.closeChangesStream();
    state.refs.historyController.clearHistory();
  }

  // Document history was flushed nad changes tream no longer emits.
  bool isClosed() {
    return state.document.changesStreamIsClosed;
  }

  // === RULES ===

  void setCustomRules(List<RuleM> customRules) {
    state.refs.documentController.setCustomRules(customRules);
  }

  // === PRIVATE ===

  // Replaces text and applies toggled styles.
  // It executes compose (mutating the doc) and it returns the change delta.
  // Toggled styles are styles that have been enabled between 2 letters before starting typing.
  DeltaM _replaceTextAndApplyToggledStyles(
    int len,
    Object? data,
    int index,
    bool emitEvent,
  ) {
    var changeDelta = DeltaM();
    final toggledStyle = state.styles.toggledStyle;

    if (len > 0 || data is! String || data.isNotEmpty) {
      // Replace (mutates the doc)
      changeDelta = state.refs.documentController.replace(
        index,
        len,
        data,
        emitEvent,
      );

      // Check if there are toggled styles to apply in the replaced text.
      var shouldRetainDelta = toggledStyle.isNotEmpty &&
          changeDelta.isNotEmpty &&
          changeDelta.length <= 2 &&
          changeDelta.last.isInsert;

      // When pressing enter or inserting text with line breaks skip over toggled styles.
      // We don't want to apply the toggled styles to the inserted text.
      // TODO It can be helpful when we want to retain selection styling.
      if (shouldRetainDelta &&
          toggledStyle.isNotEmpty &&
          changeDelta.length == 2 &&
          changeDelta.last.data == '\n') {
        // If all attributes are inline, shouldRetainDelta should be false
        final allToggledAttributesInline = !toggledStyle.values.any(
          (attr) => !attr.isInline,
        );

        if (allToggledAttributesInline) {
          shouldRetainDelta = false;
        }
      }

      // Apply toggled styles
      if (shouldRetainDelta) {
        final retainDelta = DeltaM();

        _du.retain(retainDelta, index);
        _du.retain(
          retainDelta,
          data is String ? data.length : 1,
          toggledStyle.toJson(),
        );

        // Compose toggled styles (mutates the doc)
        state.refs.documentController.compose(
          retainDelta,
          ChangeSource.LOCAL,
          emitEvent,
        );
      }
    }

    return changeDelta;
  }

  // When a new line of text is inserted the new line can start with the styling from the prev line of text.
  void _keepStylesOnNewLine() {
    if (state.config.keepStyleOnNewLine) {
      final style = _stylesService.getSelectionStyle();
      final notInlineStyle = style.attributes.values.where((s) => !s.isInline);
      state.styles.toggledStyle = _stylesUtils.removeAll(
        style,
        notInlineStyle.toSet(),
      );
    } else {
      state.styles.toggledStyle = StyleM();
    }
  }

  // Editing the text results in a change of text selection.
  void _cacheSelectionUpdatedAfterEdit(
    TextSelection? selection,
    DeltaM? newDelta,
    int index,
    Object? data,
    int len,
  ) {
    if (selection != null) {
      if (newDelta == null || newDelta.isEmpty) {
        _selectionService.cacheSelection(selection, ChangeSource.LOCAL);
      } else {
        final user = DeltaM();

        _du.retain(user, index);
        _du.insert(user, data);
        _du.delete(user, len);

        // As of jan 2023 it's unclear when this posDelta is not 0.
        final positionDelta = _du.getPositionDelta(user, newDelta);

        _selectionService.cacheSelection(
          selection.copyWith(
            baseOffset: selection.baseOffset + positionDelta,
            extentOffset: selection.extentOffset + positionDelta,
          ),
          ChangeSource.LOCAL,
        );
      }
    }
  }

  // Applies styles from the previously copied text over the plain text that was inserted.
  // Flutter stores in the remote input the text as plain text.
  // Therefore we need to track separately the styles when copy pasting.
  void _applyPasteStyle(String insertedText, int start) {
    final styles = state.paste.styles;
    final plainText = state.paste.plainText;

    if (insertedText == plainText && plainText != '') {
      final pos = start;

      for (var i = 0; i < styles.length; i++) {
        final style = styles[i].style;
        final offset = styles[i].offset;
        final index = pos + offset;
        final length = i == styles.length - 1
            ? plainText.length - offset
            : styles[i + 1].offset;

        _stylesService.formatSelectedTextByStyle(index, length, style);
      }
    }
  }

  // TODO Document intent. It seems that objects are stored as a special char. And this method simply removes it.
  String _removeSpecialObjectCharsFromText(String text) {
    // For clip from editor, it may contain image, a.k.a 65532 or '\uFFFC'.
    // For clip from browser, image is directly ignore.
    // Here we skip image when pasting.
    if (!text.codeUnits.contains(EmbedNodeM.kObjectReplacementInt)) {
      return text;
    }

    final buffer = StringBuffer();

    for (var i = 0; i < text.length; i++) {
      if (text.codeUnitAt(i) == EmbedNodeM.kObjectReplacementInt) {
        continue;
      }

      buffer.write(text[i]);
    }

    return buffer.toString();
  }
}
