import 'package:flutter/material.dart';

import '../../documents/models/nodes/node.dart';
import 'link-action-menu.enum.dart';

// Used internally by widget layer.
typedef LinkActionPicker = Future<LinkMenuAction> Function(Node linkNode);

typedef LinkActionPickerDelegate = Future<LinkMenuAction> Function(
  BuildContext context,
  String link,
  Node node,
);
