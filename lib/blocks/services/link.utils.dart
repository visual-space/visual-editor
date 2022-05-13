import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../documents/models/attribute.dart';
import '../../../documents/models/nodes/node.dart';

TextRange getLinkRange(Node node) {
  var start = node.documentOffset;
  var length = node.length;
  var prev = node.previous;
  final linkAttr = node.style.attributes[Attribute.link.key]!;
  while (prev != null) {
    if (prev.style.attributes[Attribute.link.key] == linkAttr) {
      start = prev.documentOffset;
      length += prev.length;
      prev = prev.previous;
    } else {
      break;
    }
  }

  var next = node.next;
  while (next != null) {
    if (next.style.attributes[Attribute.link.key] == linkAttr) {
      length += next.length;
      next = next.next;
    } else {
      break;
    }
  }
  return TextRange(start: start, end: start + length);
}
