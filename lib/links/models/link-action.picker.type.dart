import 'package:flutter/material.dart';

import '../../document/models/nodes/node.model.dart';
import 'link-action-menu.enum.dart';

// Used internally by widget layer.
typedef LinkActionPicker = Future<LinkMenuAction> Function(NodeM linkNode);

typedef LinkActionPickerDelegate = Future<LinkMenuAction> Function(
  BuildContext context,
  String link,
  NodeM node,
);
