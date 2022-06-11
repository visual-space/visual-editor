import 'package:flutter/material.dart';

import '../../controller/services/editor-controller.dart';
import '../../documents/models/attribute.model.dart';
import '../../documents/models/nodes/embed.model.dart';

typedef EmbedBuilder = Widget Function(
  BuildContext context,
  EditorController controller,
  EmbedM node,
  bool readOnly,
);

typedef CustomStyleBuilder = TextStyle Function(AttributeM attribute);
