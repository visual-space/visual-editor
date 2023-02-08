import 'package:flutter/material.dart';

import '../../controller/controllers/editor-controller.dart';
import '../../document/models/nodes/embed-node.model.dart';

// Embed builders are classes that generate widgets based on the delta document embed operations.
// The type string is used to match the builder with the embed delta operation type.
// If the editor is configured as readonly the embed builders can adapt to this state.
// Since embeds are middleware we don't expose the state store trough them
// to avoid dependencies to our internal architecture.
abstract class EmbedBuilderM {
  String get type;

  Widget build(
    BuildContext context,
    EditorController controller,
    EmbedNodeM embed,
    bool readOnly,
  );
}
