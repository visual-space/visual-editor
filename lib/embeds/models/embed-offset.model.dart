import 'package:flutter/material.dart';

import '../../document/models/nodes/embed-node.model.dart';

// Embeds are represented as nodes
// Offset is represented as the number of characters of this node relative to its parent node.
@immutable
class EmbedOffsetM {
  final int offset;
  final EmbedNodeM embed;

  EmbedOffsetM({
    required this.offset,
    required this.embed,
  });
}
