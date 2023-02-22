import 'package:flutter/material.dart';

import '../../document/models/attributes/attribute.model.dart';

class ApplyHeaderIntent extends Intent {
  final AttributeM header;

  const ApplyHeaderIntent(this.header);
}