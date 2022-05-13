import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import '../../documents/models/nodes/node.dart';

// When multiple lines of text are selected at once we need to compute the
// textSelection for each one of them.
// The local selection is computed as the union between the extent of the text
// selection and the extend of the line of text.
TextSelection localSelection(Node node, TextSelection selection, fromParent) {
  final base = fromParent ? node.offset : node.documentOffset;
  assert(base <= selection.end && selection.start <= base + node.length - 1);

  final offset = fromParent ? node.offset : node.documentOffset;
  return selection.copyWith(
    baseOffset: math.max(selection.start - offset, 0),
    extentOffset: math.min(selection.end - offset, node.length - 1),
  );
}
