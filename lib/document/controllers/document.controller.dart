import 'package:flutter/material.dart';

import '../../rules/controllers/rules.controller.dart';
import '../../rules/models/rule-type.enum.dart';
import '../../rules/models/rule.model.dart';
import '../models/attributes/attribute.model.dart';
import '../models/attributes/paste-style.model.dart';
import '../models/delta-doc.model.dart';
import '../models/delta/delta-changes.model.dart';
import '../models/delta/delta.model.dart';
import '../models/history/change-source.enum.dart';
import '../models/nodes/block.model.dart';
import '../models/nodes/embed.model.dart';
import '../models/nodes/leaf.model.dart';
import '../models/nodes/line-leaf.model.dart';
import '../models/nodes/line.model.dart';
import '../models/nodes/node-position.model.dart';
import '../models/nodes/root.model.dart';
import '../models/nodes/style.model.dart';
import '../services/delta.utils.dart';
import '../services/document.utils.dart';
import '../services/nodes/container.utils.dart';
import '../services/nodes/line.utils.dart';
import '../services/nodes/node.utils.dart';
import '../services/nodes/styles.utils.dart';
import 'history.controller.dart';

final _stylesUtils = StylesUtils();

// Handles the initialisation and the subsequent edit operations of the document.
// Document models can be initialised empty or from json data or delta models.
// Internally, in the editor controller there exists an additional representation: nodes.
// Nodes is a list of objects that represent each individual fragment of text with unique styling.
// Islands made of nodes of identical styling get merged in one single continuous chunk.
// When a document is initialised, the delta operations are converted to nodes and attached to the root node.
// The build() process maps the document nodes to styled text spans in the widget tree.
// All document editing operations are computed using the rules middleware.
// The rules are split in three categories: insert, delete, retain.
// Rules identify patterns in the document and perform mutations (ex: closing bullet if if enter is pressed twice).
// After the rules are executed a new updated delta is generated.
// This delta is then passed to document.compose() which in turn maps it to nodes.
// If successful compose then maps again the bodes to delta and stores this last one in the document for later use.
// All document editing methods return change deltas to be streamed for coop editing.
// The complete history of changes is stored in memory during the editing process.
// To maintain a condensed API Method names have been kept short.
// We decided to maintain pure data models, to make it easier to read the code (methods and data segregated).
// Therefore for advanced users that need to modify the docs outside
// of the EditorController we have exposed the DocumentController class.
// @@@ TODO Copy to docs
//
// Doc Mutations:
// - insert()
// - delete()
// - replace()
// - format()
// - compose()
//
// Doc Queries:
// - isEmpty
// - getPlainText()
// - queryChild()
// - queryNode()
// - collectStyle()
// - collectAllIndividualStyles()
// - collectAllStyles()
//
// Architecture
// In the initial Quill architecture (before forking) the Document models had a large number of methods.
// This made them really hard to understand because code and data were mixed together.
// We made a large effort to convert all models to pure data models (simplifying the effort needed to understand them).
// This means we transitioned from OOP API design (methods attached to document)
// to a pure functional API design (pure data models and utils).
// This approach is suitable for us for 2 reasons:
// - It makes it far easier for new lib contributors to understand the architecture.
// - Only advanced users manipulate the document outside of the editor controller.
// Therefore there's less need to have an OOP style API design (for ease of use).
// However we still retain the short naming style (fluent API) for potential 3rd party library authors.
// TODO Demo how to use these methods to manipulate the document.
class DocumentController {
  final _documentUtils = DocumentUtils();
  final _contUtils = ContainerUtils();
  final _nodeUtils = NodeUtils();
  final _du = DeltaUtils();
  final _lineUtils = LineUtils();

  // Rules for parsing text styles and blocks.
  // Ex: closing bullet if if enter is pressed twice.
  final _rulesController = RulesController();

  // Expert users might decide to operate changes on the documents outside of the EditorController.
  // Therefore, the HistoryController is initialised inside of the DocumentsController to ensure that
  // any new instance of DocumentController will be able to record document history changes.
  late HistoryController historyController;

  DeltaDocM document;
  final Function(DocAndChangeM change)? _emitDocChange;

  // Nodes are document fragments with unique styling attributes.
  final rootNode = RootM();

  DocumentController(
    this.document,
    this._emitDocChange,
    final Function(DeltaM deltaRes, int? length, bool emitEvent)?
        _composeCacheSelectionAndRunBuild,
  ) {
    historyController = HistoryController(
      document,
      _composeCacheSelectionAndRunBuild,
    );

    initDocument(document.delta);
  }

  // === DOCUMENT UPDATES (MUTATIONS) ===

  // Inserts data in this document at specified index. (mutates the doc)
  // The `data` parameter can be either a String or an instance of Embeddable.
  // Applies heuristic rules before modifying this document and
  // produces a change event with its source set to ChangeSource.local.
  // Returns an instance of DeltaM actually composed into this document.
  DeltaM insert(
    int index,
    Object? data,
    bool emitEvent, {
    int replaceLength = 0,
  }) {
    assert(index >= 0);
    assert(data is String || data is EmbedM);

    // Stringify Embed
    if (data is EmbedM) {
      data = data.toJson();
    } else if ((data as String).isEmpty) {
      return DeltaM();
    }

    // Insert rules
    final changeDelta = _rulesController.apply(
      RuleTypeE.INSERT,
      document,
      index,
      data: data,
      len: replaceLength,
      plainText: toPlainText(),
    );

    // Update nodes
    compose(changeDelta, ChangeSource.LOCAL, emitEvent);

    return changeDelta;
  }

  // Deletes length of characters from this document starting at index. (mutates the doc)
  // This method applies heuristic rules before modifying this document and
  // produces a Change with source set to ChangeSource.local.
  // Returns an instance of DeltaM actually composed into this document.
  DeltaM delete(int index, int len, bool emitEvent) {
    assert(index >= 0 && len > 0);

    // Delete rules
    final changeDelta = _rulesController.apply(
      RuleTypeE.DELETE,
      document,
      index,
      len: len,
      plainText: toPlainText(),
    );

    // Update nodes
    if (changeDelta.isNotEmpty) {
      compose(changeDelta, ChangeSource.LOCAL, emitEvent);
    }

    return changeDelta;
  }

  // Replaces length of characters starting at index with data (mutates the doc via insert).
  // This method applies heuristic rules before modifying this document and
  // produces a change event with its source set to ChangeSource.local.
  // Returns an instance of DeltaM actually composed into this document.
  DeltaM replace(int index, int length, Object? data, bool emitEvent) {
    assert(index >= 0);
    assert(data is String || data is EmbedM);

    final dataIsNotEmpty = (data is String) ? data.isNotEmpty : true;

    assert(dataIsNotEmpty || length > 0);

    var changeDelta = DeltaM();

    // Insert new text
    if (dataIsNotEmpty) {
      // We have to insert before applying delete rules.
      // Otherwise delete would be operating on stale document snapshot.
      changeDelta = insert(
        index,
        data,
        emitEvent,
        replaceLength: length,
      );
    }

    // Delete replaced text
    // (in change delta, the nodes have been already deleted, no need to call ctrl.compose again)
    final shouldDelete = length > 0;

    if (shouldDelete) {
      final deleteDelta = delete(index, length, emitEvent);

      changeDelta = _du.compose(changeDelta, deleteDelta);
    }

    return changeDelta;
  }

  // Formats segment of this document with specified attribute (mutates the doc).
  // Applies heuristic rules before modifying this document and
  // produces a change event with its source set to ChangeSource.local.
  // Returns an instance of DeltaM actually composed into this document.
  // The returned DeltaM may be empty in which case this document remains
  // unchanged and no change event is published to the changes stream.
  DeltaM format(
    int index,
    int len,
    AttributeM? attribute,
    bool emitEvent,
  ) {
    assert(index >= 0 && len >= 0 && attribute != null);

    var deltaRes = DeltaM();

    final changeDelta = _rulesController.apply(
      RuleTypeE.FORMAT,
      document,
      index,
      len: len,
      attribute: attribute,
      plainText: toPlainText(),
    );

    if (changeDelta.isNotEmpty) {
      compose(changeDelta, ChangeSource.LOCAL, emitEvent);

      // Append to Delta
      deltaRes = _du.compose(deltaRes, changeDelta);
    }

    return deltaRes;
  }

  // All the heavy lifting of updating the document model (nodes) happens here.
  // We don't usually directly call compose, we call other methods that perform additional necessary ops before composing the doc.
  // Applies the changes from the new delta model (operations) to update the document model (nodes). (mutates the doc)
  // All other ops use compose: insert(), delete(), format(), replace(). all mutate the document.
  // For each operation in the new delta we execute changes in the nodes starting with index 0.
  // Finally the nodes are mapped back to delta and the delta is stored for later use.
  // Delta changes are stored in the history object.
  // The changes$ stream can be inhibited on demand via the emitEvent: false flag.
  // This is useful when we need to setup the editor without notifying
  // other subscribed components of the initial changes.
  //
  // (!) Note
  // The editor will always call compose() only after applying the rules to the delta.
  // compose() is the last operation in the text editing callstack that finally applies the changes to the document.
  // Use this method with caution as it does not apply heuristic rules (rules middleware) to the document change.
  // It is callers responsibility to ensure that the change conforms to the document model's
  // semantics and can be composed with the current state of this document.
  // In case the change is invalid, behavior of this method is unspecified.
  void compose(
    DeltaM changeDelta,
    ChangeSource changeSource,
    bool emitEvent, [
    bool overrideRootNode = false,
  ]) {
    // Cleanup
    // TODO Restore this check using the changes stream. Right now it's not urgent but should be restored.
    // assert(!_changesStreamIsClosed);
    _du.trim(changeDelta);

    assert(changeDelta.isNotEmpty);

    var offset = 0;
    final deltaRes = _documentUtils.mapAndAddNewLineBeforeAndAfterVideoEmbed(
      changeDelta,
    );
    final originalDelta = document.delta;

    // Nodes Operations
    for (final operation in deltaRes.toList()) {
      // Styles
      final style = operation.attributes != null
          ? _stylesUtils.fromJson(operation.attributes)
          : null;

      // Apply the changes from the new delta model (operations)
      // to modify the document model (nodes).
      if (operation.isInsert) {
        final opWithEmbed = _documentUtils.mapEmbedsToModels(operation.data);
        _contUtils.insert(rootNode, offset, opWithEmbed, style);
      } else if (operation.isDelete) {
        _contUtils.delete(rootNode, offset, operation.length);
      } else if (operation.attributes != null) {
        _contUtils.retain(rootNode, offset, operation.length, style);
      }

      // Chars counter
      if (!operation.isDelete) {
        offset += operation.length!;
      }
    }

    // (!) Calling update() will trigger two operations: clear() and compose()
    // clear() will use replace() to cleanup the entire document until we are left with [{"insert":"\n"}].
    // compose() will then use the new delta to append it to the document.
    // documentController.compose() will trigger an insert on the rootNode (nodes list).
    // Reminder: clear() has updated both the delta and rootNode to contain an empty line with a simple break line inside.
    // This means we are adding empty rootNode "\n" + new data: "abc\n" and we will get "abc\n\n"
    // Attempt1: Deleting in the controller delta the new line \n character such that we can do "" + "abc\n".
    // This approach has some serious after effects because the delta and the rootNode go out of sync.
    // Attempt2: Deleting the newline in the rootNode after the insert. However first time it was done the wrong way.
    // I was removing the first child in the list thus leaving the document empty regardless of the delta provided by update()
    // This seems to work fine when you have just an empty field being updated with empty doc.
    // However it no longer works when you attempt to update with a regular document that has chars.
    // Another issue was that I did not update the internal delta of the controller to match the new state of the rootNode.
    // Once again things were going crazy with further interactions due to the mismatch between internal delta and rootNode.
    // Final Attempt: I realised that I need to delete the last line of the rootNode.
    // Also, we need to make sure this is done ONLY when compose() is called from clear()
    // That's why I created the overrideRootNode param.
    // This entire setup might look like a hack, but there's simply no way to get rid of the double \n\n when updating the doc.
    // The entire nodes manipulation code is built under the assumption that a document line will always end with \n.
    // Therefore there's no simple way of getting rid of the initial \n of an empty doc.
    // Thus we are left only with the option presented here: to remove the double \n if we now it was generated by update()
    if (overrideRootNode) {
      _contUtils.remove(rootNode, rootNode.children.last);
    }

    // Apply Change To Doc Delta + Cache New Delta
    try {
      document.delta = overrideRootNode
          ? changeDelta
          : _du.compose(document.delta, changeDelta);
    } catch (e) {
      throw 'Delta compose failed.';
    }

    // TODO This validation might be overkill since the markers have been added.
    // IT's possible to successfully add a new marker without changing the number of attributes.
    // We need to evaluate if we can either improve the error (ideal) or remove it completely (not ideal).
    //
    // (!) Apparently this was the source of a silent failure
    // When inserting any character in an editor with markers inlined in the text the editor would not update.
    // It appears that this condition fails silently (no trace in the console).
    // Until this condition is fixed I have disabled completely.
    // It does not seem to be essential, much rather a safety measure.
    // However it would be nice to restore this safety measure.
    // if (_delta != root.toDelta()) {
    //   throw 'Compose failed';
    // }

    // Changes
    final change = DocAndChangeM(originalDelta, changeDelta, changeSource);

    if (emitEvent) {
      _emitDocChange?.call(change);
    }
    historyController.updateHistoryStacks(change);
  }

  // === DOC QUERIES ===

  int get docCharsNum {
    return rootNode.charsNum;
  }

  // Checks teh generated nodes.
  // An insert and a delete in delta results in an empty nodes list.
  bool isEmpty() {
    if (rootNode.children.length != 1) {
      return false;
    }

    final node = rootNode.children.first;

    if (!node.isLast) {
      return false;
    }

    final currDelta = _nodeUtils.toDelta(node);

    return currDelta.length == 1 &&
        currDelta.first.data == '\n' &&
        currDelta.first.key == 'insert';
  }

  // Returns plain text within the specified text range.
  String getPlainTextAtRange(int index, int len) {
    final nodePos = queryChild(index);
    final line = nodePos.node as LineM;

    return _lineUtils.getPlainText(line, nodePos.offset, len);
  }

  // Get plain text for the entire doc
  String toPlainText() {
    return rootNode.children.map((node) => node.toPlainText()).join();
  }

  // === QUERY NODES ===

  // Returns Line located at specified character offset.
  NodePositionM queryChild(int offset) {
    // TODO: prevent user from moving caret after last line-break.
    final nodePos = _contUtils.queryChild(rootNode, offset, true);
    
    // If the node is null, we return the rootNode's `NodeM`.
    if (nodePos.node == null) {
      return NodePositionM(rootNode.defaultChild, 0);
    }

    if (nodePos.node is LineM) {
      return nodePos;
    }

    final block = nodePos.node as BlockM;

    return _contUtils.queryChild(block, nodePos.offset, true);
  }

  // Given offset, find its leaf node in document.
  // Returns both the line and the leaf (node).
  LineLeafM queryNode(int offset) {
    final nodePos = queryChild(offset);

    if (nodePos.node == null) {
      return LineLeafM(null, null);
    }

    final line = nodePos.node as LineM;
    final segmentResult = _contUtils.queryChild(line, nodePos.offset, false);

    if (segmentResult.node == null) {
      return LineLeafM(line, null);
    }

    final segment = segmentResult.node as LeafM;

    return LineLeafM(line, segment);
  }

  // === QUERY STYLES ===

  // Only attributes applied to all characters within this range are included in the result.
  StyleM collectStyle(int index, int length) {
    final nodePos = queryChild(index);
    final line = nodePos.node as LineM;

    return _lineUtils.collectStyle(line, nodePos.offset, length);
  }

  // Returns all styles for each node within selection.
  List<PasteStyleM> collectAllIndividualStyles(int index, int length) {
    final nodePos = queryChild(index);
    final line = nodePos.node as LineM;

    return _lineUtils.collectAllIndividualStyles(line, nodePos.offset, length);
  }

  // Returns all styles for any character within the specified text range.
  List<StyleM> collectAllStyles(int index, int length) {
    final nodePos = queryChild(index);
    final line = nodePos.node as LineM;

    return _lineUtils.collectAllStyles(line, nodePos.offset, length);
  }

  // === INIT DOC ===

  // Runs several validation checks. (does not mutate the delta, mutates the rootNode)
  // Adds the nodes and styles to the root.
  // Adds new line after video.
  // Caches selection extend for markers (for convenience).
  // Adds _delta nodes to root.
  void initDocument(DeltaM delta) {
    if (delta.isEmpty) {
      throw ArgumentError.value(delta, 'Document Delta cannot be empty.');
    }

    assert(
      (delta.last.data as String).endsWith('\n'),
      'Document delta must end with \n',
    );

    var offset = 0;

    // Add to root
    for (final operation in delta.toList()) {
      // Only insert operations
      if (!operation.isInsert) {
        throw ArgumentError.value(
          delta,
          'Document can only contain insert operations but ${operation.key} found.',
        );
      }

      // Init styles (from generic delta to models)
      final style = operation.attributes != null
          ? _stylesUtils.fromJson(operation.attributes)
          : null;

      // Embeds to models
      final data = _documentUtils.mapEmbedsToModels(operation.data);

      // Markers length
      _documentUtils.addBaseAndExtentToMarkers(style, offset, operation);

      // Add to root
      _contUtils.insert(rootNode, offset, data, style);

      // Offset
      offset += operation.length!;
    }

    final lastNode = rootNode.last;

    // Remove last empty line
    if (lastNode is LineM &&
        lastNode.parent is! BlockM &&
        lastNode.style.isEmpty &&
        rootNode.childCount > 1) {
      _contUtils.remove(rootNode, lastNode);
    }
  }

  // === RULES ===

  void setCustomRules(List<RuleM> customRules) {
    _rulesController.setCustomRules(customRules);
  }

  List<TextSelection> getSearchMatches(String searchedText) {
    final matches = <TextSelection>[];
    var prevLineLength = 0;

    for (final node in rootNode.children) {
      if (node is LineM) {
        _searchLine(
          searchedText,
          node,
          prevLineLength,
          matches,
        );
        prevLineLength += node.charsNum;
      } else if (node is BlockM) {
        for (final line in Iterable.castFrom<dynamic, LineM>(node.children)) {
          _searchLine(
            searchedText,
            line,
            prevLineLength,
            matches,
          );
          prevLineLength += line.charsNum;
        }
      }
    }

    return matches;
  }

  void _searchLine(
    String searchedText,
    LineM line,
    int prevLineLength,
    List<TextSelection> matches,
  ) {
    var index = -1;
    while (true) {
      index = line.toPlainText().toLowerCase().indexOf(
            RegExp(
              searchedText,
              caseSensitive: false,
            ),
            index + 1,
          );

      if (index < 0) {
        break;
      }

      matches.add(
        TextSelection(
          baseOffset: prevLineLength + index,
          extentOffset: prevLineLength + index + searchedText.length,
        ),
      );
    }
  }
}
