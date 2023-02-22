import 'package:flutter/material.dart';

import '../../document/models/attributes/attribute.model.dart';

class ToggleTextStyleIntent extends Intent {
  final AttributeM attribute;

  const ToggleTextStyleIntent(this.attribute);
}