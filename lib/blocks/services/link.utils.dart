import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../documents/models/attribute.model.dart';
import '../../../documents/models/nodes/node.model.dart';

TextRange getLinkRange(NodeM node) {
  var start = node.documentOffset;
  var length = node.length;
  var prev = node.previous;
  final linkAttr = node.style.attributes[AttributeM.link.key]!;

  while (prev != null) {
    if (prev.style.attributes[AttributeM.link.key] == linkAttr) {
      start = prev.documentOffset;
      length += prev.length;
      prev = prev.previous;
    } else {
      break;
    }
  }

  var next = node.next;

  while (next != null) {
    if (next.style.attributes[AttributeM.link.key] == linkAttr) {
      length += next.length;
      next = next.next;
    } else {
      break;
    }
  }

  return TextRange(start: start, end: start + length);
}
