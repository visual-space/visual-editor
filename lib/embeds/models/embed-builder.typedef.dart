import 'package:flutter/material.dart';

import '../../controller/controllers/editor-controller.dart';
import '../../document/models/nodes/embed-node.model.dart';

typedef EmbedsBuilder = Widget Function(
    BuildContext context,
    EditorController controller,
    EmbedNodeM embed,
    bool readOnly,
    );