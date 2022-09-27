import 'dart:async';

import '../../controller/models/paste-style.model.dart';
import '../../rules/controllers/rules.controller.dart';
import '../../rules/models/rule-type.enum.dart';
import '../../rules/models/rule.model.dart';
import 'attribute.model.dart';
import 'change-source.enum.dart';
import 'delta/delta-changes.model.dart';
import 'delta/delta.model.dart';
import 'delta/operation.model.dart';
import 'history.model.dart';
import 'nodes/block-embed.model.dart';
import 'nodes/block.model.dart';
import 'nodes/child-query.model.dart';
import 'nodes/embeddable.model.dart';
import 'nodes/leaf.model.dart';
import 'nodes/line.model.dart';
import 'nodes/revert-operations.model.dart';
import 'nodes/root.model.dart';
import 'nodes/segment-leaf-node.model.dart';
import 'style.model.dart';

// The rich text document
class DocumentM {
  // Creates new empty document.
  DocumentM() : _delta = DeltaM()..insert('\n') {
    _initDocument(_delta);
  }

  // Creates new document from provided JSON `data`.
  DocumentM.fromJson(List data) : _delta = _transform(DeltaM.fromJson(data)) {
    _initDocument(_delta);
  }

  // Creates new document from provided `delta`.
  // Delta is the converted json string to dart json data.
  DocumentM.fromDelta(DeltaM delta) : _delta = delta {
    _initDocument(delta);
  }

  // The root node of the document tree
  // Delta operation (json data) are converted to Nodes (models)
  final RootM _root = RootM();

  RootM get root => _root;

  // Length of this document.
  int get length => _root.length;

  DeltaM _delta;

  // Returns contents of this document as [DeltaM].
  DeltaM toDelta() => DeltaM.from(_delta);

  // Each document instance has it's own set of rules
  final RulesController _rules = RulesController.getInstance();

  void setCustomRules(List<RuleM> customRules) {
    _rules.setCustomRules(customRules);
  }

  final StreamController<DeltaChangeM> _observer = StreamController.broadcast();

  final HistoryM _history = HistoryM();

  bool get hasUndo => _history.hasUndo;

  bool get hasRedo => _history.hasRedo;

  // Stream of Changes applied to this document.
  Stream<DeltaChangeM> get changes => _observer.stream;

  // Inserts data in this document at specified index.
  // The `data` parameter can be either a String or an instance of Embeddable.
  // Applies heuristic rules before modifying this document and
  // produces a change event with its source set to ChangeSource.local.
  // Returns an instance of DeltaM actually composed into this document.
  DeltaM insert(int index, Object? data, {int replaceLength = 0}) {
    assert(index >= 0);
    assert(data is String || data is EmbeddableM);

    if (data is EmbeddableM) {
      data = data.toJson();
    } else if ((data as String).isEmpty) {
      return DeltaM();
    }

    final delta = _rules.apply(
      RuleTypeE.INSERT,
      this,
      index,
      data: data,
      len: replaceLength,
    );

    compose(delta, ChangeSource.LOCAL);

    return delta;
  }

  // Deletes length of characters from this document starting at index.
  // This method applies heuristic rules before modifying this document and
  // produces a Change with source set to ChangeSource.local.
  // Returns an instance of DeltaM actually composed into this document.
  DeltaM delete(int index, int len) {
    assert(index >= 0 && len > 0);

    final delta = _rules.apply(
      RuleTypeE.DELETE,
      this,
      index,
      len: len,
    );

    if (delta.isNotEmpty) {
      compose(delta, ChangeSource.LOCAL);
    }

    return delta;
  }

  // Replaces length of characters starting at index with data.
  // This method applies heuristic rules before modifying this document and
  // produces a change event with its source set to ChangeSource.local.
  // Returns an instance of DeltaM actually composed into this document.
  DeltaM replace(int index, int len, Object? data) {
    assert(index >= 0);
    assert(data is String || data is EmbeddableM);

    final dataIsNotEmpty = (data is String) ? data.isNotEmpty : true;

    assert(dataIsNotEmpty || len > 0);

    var delta = DeltaM();

    // We have to insert before applying delete rules.
    // Otherwise delete would be operating on stale document snapshot.
    if (dataIsNotEmpty) {
      delta = insert(index, data, replaceLength: len);
    }

    if (len > 0) {
      final deleteDelta = delete(index, len);
      delta = delta.compose(deleteDelta);
    }

    return delta;
  }

  // Formats segment of this document with specified attribute.
  // Applies heuristic rules before modifying this document and
  // produces a change event with its source set to ChangeSource.local.
  // Returns an instance of DeltaM actually composed into this document.
  // The returned DeltaM may be empty in which case this document remains
  // unchanged and no change event is published to the changes stream.
  DeltaM format(int index, int len, AttributeM? attribute) {
    assert(index >= 0 && len >= 0 && attribute != null);

    var delta = DeltaM();

    final formatDelta = _rules.apply(
      RuleTypeE.FORMAT,
      this,
      index,
      len: len,
      attribute: attribute,
    );

    if (formatDelta.isNotEmpty) {
      compose(formatDelta, ChangeSource.LOCAL);
      delta = delta.compose(formatDelta);
    }

    return delta;
  }

  // Composes change Delta into this document.
  // Use this method with caution as it does not apply heuristic rules to the change.
  // It is callers responsibility to ensure that the change conforms to the document
  // models semantics and can be composed with the current state of this document.
  // In case the change is invalid, behavior of this method is unspecified.
  void compose(DeltaM delta, ChangeSource changeSource) {
    assert(!_observer.isClosed);
    delta.trim();
    assert(delta.isNotEmpty);

    var offset = 0;
    delta = _transform(delta);
    final originalDelta = toDelta();

    for (final op in delta.toList()) {
      final style =
          op.attributes != null ? StyleM.fromJson(op.attributes) : null;

      if (op.isInsert) {
        // Must normalize data before inserting into the document, makes sure
        // that any embedded objects are converted into EmbeddableObject type.
        _root.insert(offset, _normalize(op.data), style);
      } else if (op.isDelete) {
        _root.delete(offset, op.length);
      } else if (op.attributes != null) {
        _root.retain(offset, op.length, style);
      }

      if (!op.isDelete) {
        offset += op.length!;
      }
    }

    try {
      _delta = _delta.compose(delta);
    } catch (e) {
      throw '_delta compose failed';
    }

    // TODO This error might be overkill since the markers have been added.
    // IT's possible to successfully add a new marker without changing the number of attributes.
    // We need to evaluate if we can either improve the error (ideal) or remove it completely (not ideal).
    //
    // (!) Apparently this was the source of a silent failure
    // When inserting any character in an editor with markers inlined in the text the editor would not update.
    // It appears that this condition fails silently (no trace in the console).
    // Until this condition is fixed I have disabled completely.
    // It does not seem to be essential, much rather a safety measure.
    // However it would be nice to restore this safety measure.
    // if (_delta != _root.toDelta()) {
    //   throw 'Compose failed';
    // }

    final change = DeltaChangeM(originalDelta, delta, changeSource);

    _observer.add(change);
    _history.handleDocChange(change);
  }

  RevertOperationM undo() {
    return _history.undo(this);
  }

  RevertOperationM redo() {
    return _history.redo(this);
  }

  void close() {
    _observer.close();
    _history.clear();
  }

  // Returns plain text representation of this document.
  String toPlainText() => _root.children.map((e) => e.toPlainText()).join();

  bool isEmpty() {
    if (root.children.length != 1) {
      return false;
    }

    final node = root.children.first;

    if (!node.isLast) {
      return false;
    }

    final delta = node.toDelta();

    return delta.length == 1 &&
        delta.first.data == '\n' &&
        delta.first.key == 'insert';
  }

  // Only attributes applied to all characters within this range are included in the result.
  StyleM collectStyle(int index, int len) {
    final res = queryChild(index);
    return (res.node as LineM).collectStyle(res.offset, len);
  }

  // Returns all styles for each node within selection
  List<PasteStyleM> collectAllIndividualStyles(int index, int len) {
    final res = queryChild(index);
    return (res.node as LineM).collectAllIndividualStyles(res.offset, len);
  }

  // Returns all styles for any character within the specified text range.
  List<StyleM> collectAllStyles(int index, int len) {
    final res = queryChild(index);
    return (res.node as LineM).collectAllStyles(res.offset, len);
  }

  // Returns plain text within the specified text range.
  String getPlainText(int index, int len) {
    final res = queryChild(index);
    return (res.node as LineM).getPlainText(res.offset, len);
  }

  // Returns [Line] located at specified character [offset].
  ChildQueryM queryChild(int offset) {
    // TODO: prevent user from moving caret after last line-break.
    final res = _root.queryChild(offset, true);

    if (res.node is LineM) {
      return res;
    }

    final block = res.node as BlockM;

    return block.queryChild(res.offset, true);
  }

  // Given offset, find its leaf node in document
  SegmentLeafNodeM querySegmentLeafNode(int offset) {
    final result = queryChild(offset);

    if (result.node == null) {
      return SegmentLeafNodeM(null, null);
    }

    final line = result.node as LineM;
    final segmentResult = line.queryChild(result.offset, false);

    if (segmentResult.node == null) {
      return SegmentLeafNodeM(line, null);
    }

    final segment = segmentResult.node as LeafM;

    return SegmentLeafNodeM(line, segment);
  }

  // === PRIVATE ===

  // Runs several validation checks.
  // Adds the nodes and styles to the root.
  void _initDocument(DeltaM delta) {
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

      // Init styles
      final style = operation.attributes != null
          ? StyleM.fromJson(operation.attributes)
          : null;
      final data = _normalize(operation.data);

      // Add to root
      _root.insert(offset, data, style);
      offset += operation.length!;
    }

    final lastNode = _root.last;

    // Remove last empty line
    if (lastNode is LineM &&
        lastNode.parent is! BlockM &&
        lastNode.style.isEmpty &&
        _root.childCount > 1) {
      _root.remove(lastNode);
    }
  }

  Object _normalize(Object? data) {
    if (data is String) {
      return data;
    }

    if (data is EmbeddableM) {
      return data;
    }

    return EmbeddableM.fromJson(data as Map<String, dynamic>);
  }

  static DeltaM _transform(DeltaM delta) {
    final res = DeltaM();
    final ops = delta.toList();

    for (var i = 0; i < ops.length; i++) {
      final op = ops[i];
      res.push(op);
      _autoAppendNewlineAfterEmbeddable(i, ops, op, res, BlockEmbedM.videoType);
    }

    return res;
  }

  static void _autoAppendNewlineAfterEmbeddable(
    int i,
    List<OperationM> ops,
    OperationM op,
    DeltaM res,
    String type,
  ) {
    final nextOpIsEmbed = i + 1 < ops.length &&
        ops[i + 1].isInsert &&
        ops[i + 1].data is Map &&
        (ops[i + 1].data as Map).containsKey(type);

    if (nextOpIsEmbed &&
        op.data is String &&
        (op.data as String).isNotEmpty &&
        !(op.data as String).endsWith('\n')) {
      res.push(OperationM.insert('\n'));
    }

    // Embed could be image or video
    final opInsertEmbed =
        op.isInsert && op.data is Map && (op.data as Map).containsKey(type);
    final nextOpIsLineBreak = i + 1 < ops.length &&
        ops[i + 1].isInsert &&
        ops[i + 1].data is String &&
        (ops[i + 1].data as String).startsWith('\n');

    if (opInsertEmbed && (i + 1 == ops.length - 1 || !nextOpIsLineBreak)) {
      // Automatically append '\n' for embeddable
      res.push(OperationM.insert('\n'));
    }
  }
}
