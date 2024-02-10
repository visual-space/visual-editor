import 'dart:ui';

import '../../../document/models/attributes/attributes-aliases.model.dart';
import '../../../document/models/attributes/attributes.model.dart';
import '../../../document/models/nodes/node.model.dart';

class DocTreeUtils {
  TextDirection getDirectionOfNode(NodeM node) {
    final direction = node.style.attributes[AttributesM.direction.key];

    if (direction == AttributesAliasesM.rtl) {
      return TextDirection.rtl;
    }

    return TextDirection.ltr;
  }
}
