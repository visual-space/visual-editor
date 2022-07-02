import 'package:flutter/material.dart';

import '../../documents/models/nodes/node.model.dart';
import '../../shared/state/editor.state.dart';
import 'link-action-menu.enum.dart';

// Used internally by widget layer.
typedef LinkActionPicker = Future<LinkMenuAction> Function(
  NodeM linkNode,
  EditorState state,
);

typedef LinkActionPickerDelegate = Future<LinkMenuAction> Function(
  BuildContext context,
  String link,
  NodeM node,
);
