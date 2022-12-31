import 'dart:math';

import '../../controller/controllers/editor-controller.dart';
import '../../documents/models/nodes/embed-node.model.dart';
import '../models/embed-offset.model.dart';

class EmbedUtils {
  static final _instance = EmbedUtils._privateConstructor();

  factory EmbedUtils() => _instance;

  EmbedUtils._privateConstructor();

  EmbedOffsetM getEmbedOffset({required EditorController controller}) {
    var offset = controller.selection.start;
    var embedNode = controller.queryNode(offset);

    if (embedNode == null || !(embedNode is EmbedNodeM)) {
      offset = max(0, offset - 1);
      embedNode = controller.queryNode(offset);
    }

    if (embedNode != null && embedNode is EmbedNodeM) {
      return EmbedOffsetM(
        offset: offset,
        embed: embedNode,
      );
    }

    return throw 'Embed node not found by offset $offset';
  }
}
