import 'package:flutter/material.dart';
import 'package:visual_editor/controller/controllers/editor-controller.dart';
import 'package:visual_editor/document/models/nodes/embed-node.model.dart';
import 'package:visual_editor/embeds/models/embed-builder.model.dart';

import '../../../embeds/const/demo-embeds.const.dart';

// Builds a simple album container.
// Just to demonstrate a custom widget that has some basic functionality and data storing needs.
class AlbumEmbedBuilder implements EmbedBuilderM {
  @override
  final String type = ALBUM_EMBED_TYPE;

  @override
  Widget build(
    BuildContext context,
    EditorController controller,
    EmbedNodeM embed,
    bool readOnly,
  ) {
    // TODO Why dynamic works instead of String list? (there's a ticket in Github)
    final imageUrls = embed.value.payload;

    return _grid(
      children: [
        for (final url in imageUrls) _image(url),
      ],
    );
  }

  Widget _image(dynamic imageUrl) => Image.network(
        imageUrl,
        width: 100,
        height: 100,
      );

  Widget _grid({required List<Widget> children}) => Container(
        height: 500,
        child: GridView.count(
          primary: false,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          crossAxisCount: 2,
          children: children,
        ),
      );
}
