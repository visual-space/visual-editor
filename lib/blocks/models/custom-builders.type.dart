import 'package:flutter/material.dart';

import '../../controller/services/editor-controller.dart';
import '../../documents/models/attribute.dart';
import '../../documents/models/nodes/leaf.dart';

typedef EmbedBuilder = Widget Function(
  BuildContext context,
  EditorController controller,
  Embed node,
  bool readOnly,
);

typedef CustomStyleBuilder = TextStyle Function(Attribute attribute);
