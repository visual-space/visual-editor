import 'package:flutter/material.dart';
import 'package:visual_editor/controller/controllers/editor-controller.dart';
import 'package:visual_editor/document/models/nodes/embed-node.model.dart';
import 'package:visual_editor/embeds/models/embed-builder.model.dart';

import '../../../embeds/const/demo-embeds.const.dart';

// Builds a simple text surrounded by an yellow container.
// Just to demonstrate the simplest custom widget one could embed in a document.
//
// Delta json demo:
//  {
//     "insert": {
//       "basicEmbed": ""
//     }
//  }
class BasicEmbedBuilder implements EmbedBuilderM {
  const BasicEmbedBuilder();

  @override
  final String type = BASIC_EMBED_TYPE;

  @override
  Widget build(
    BuildContext context,
    EditorController controller,
    EmbedNodeM embed,
    bool readOnly,
  ) =>
      Container(
        height: 100,
        width: 300,
        color: Colors.amber,
        child: Center(
          child: Text(
            'Test demo custom embed',
          ),
        ),
      );
}
