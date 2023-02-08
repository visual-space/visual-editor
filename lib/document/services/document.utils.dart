import 'package:flutter/cupertino.dart';

import '../../embeds/const/embeds.const.dart';
import '../../markers/models/marker.model.dart';
import '../models/attributes/attributes.model.dart';
import '../models/delta/delta.model.dart';
import '../models/delta/operation.model.dart';
import '../models/nodes/embed.model.dart';
import '../models/nodes/style.model.dart';
import 'delta.utils.dart';
import 'nodes/operations.utils.dart';

// Methods used to initialise the document.
// Mostly focused on the Delta operations and cleaning them up
// or extending them with additional information.
class DocumentUtils {
  final _du = DeltaUtils();
  final _opUtils = OperationsUtils();

  // Creates a new delta operations list by reading the json data
  DeltaM fromJson(List data) {
    final newDelta = _du.fromJson(data);
    final deltaRes = mapAndAddNewLineBeforeAndAfterVideoEmbed(newDelta);

    return deltaRes;
  }

  // Adds new lines before and after video embeds. (pure functional)
  DeltaM mapAndAddNewLineBeforeAndAfterVideoEmbed(DeltaM delta) {
    final deltaRes = DeltaM();
    final operations = delta.toList();

    for (var i = 0; i < operations.length; i++) {
      final operation = operations[i];

      _du.push(deltaRes, operation);
      _addNewLineBeforeAndAfterVideoEmbed(i, operations, operation, deltaRes);
    }

    return deltaRes;
  }

  // Ensures that any embedded objects are converted into EmbedM type when new content is added to the document.
  Object mapEmbedsToModels(Object? data) {
    if (data is String) {
      return data;
    } else if (data is EmbedM) {
      return data;
    }

    return EmbedM.fromObject(data);
  }

  // Add base and extent for markers (needed for delete)
  // It's more convenient to cache the extent of markers here at document init
  // rather than backtracking at runtime to retrieve the same values.
  void addBaseAndExtentToMarkers(
    StyleM? style,
    int offset,
    OperationM operation,
  ) {
    final hasMarkers = style?.attributes.keys.toList().contains(
              AttributesM.markers.key,
            ) ??
        false;

    if (hasMarkers) {
      final markers =
          style!.attributes[AttributesM.markers.key]!.value as List<MarkerM>;
      final _markers = markers
          .map(
            (marker) => marker.copyWith(
              textSelection: TextSelection(
                baseOffset: offset,
                extentOffset: offset + (operation.length ?? 0),
              ),
            ),
          )
          .toList();

      markers.clear();
      markers.addAll(_markers);
    }
  }

  // === PRIVATE ===

  // Appends new line before and after embeds of certain type as defined in params.
  // Mutates the delta received as param.
  // TODO Confirm that it is adding before as well. Apparently this is what the source code does.
  void _addNewLineBeforeAndAfterVideoEmbed(
    int i,
    List<OperationM> operations,
    OperationM operation,
    DeltaM deltaRes,
  ) {
    // Add newline before video embed
    final nextOpIsVideo = i + 1 < operations.length &&
        operations[i + 1].isInsert &&
        operations[i + 1].data is Map &&
        (operations[i + 1].data as Map).containsKey(VIDEO_EMBED_TYPE);

    if (nextOpIsVideo &&
        operation.data is String &&
        (operation.data as String).isNotEmpty &&
        !(operation.data as String).endsWith('\n')) {
      _insertNewLine(deltaRes);
    }

    // Add newline after video embed
    final opIsInsertVideo = operation.isInsert &&
        operation.data is Map &&
        (operation.data as Map).containsKey(VIDEO_EMBED_TYPE);
    final nextOpIsLineBreak = i + 1 < operations.length &&
        operations[i + 1].isInsert &&
        operations[i + 1].data is String &&
        (operations[i + 1].data as String).startsWith('\n');
    final nextOpIsLast = i + 1 == operations.length - 1;

    // Add newline after video embed
    if (opIsInsertVideo && (!nextOpIsLineBreak || nextOpIsLast)) {
      _insertNewLine(deltaRes);
    }
  }

  void _insertNewLine(DeltaM deltaRes) {
    _du.push(deltaRes, _opUtils.getInsertOp('\n'));
  }
}
