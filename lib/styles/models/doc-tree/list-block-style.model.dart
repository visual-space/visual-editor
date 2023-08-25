import 'package:flutter/material.dart';

import '../../../doc-tree/models/editor-checkbox-builder.model.dart';
import '../../../doc-tree/models/vertical-spacing.model.dart';
import 'text-block-style.model.dart';

class ListBlockStyle extends TextBlockStyleM {
  final EditorCheckboxBuilder? checkboxUIBuilder;

  ListBlockStyle(
    TextStyle style,
    VerticalSpacing blockSpacing,
    VerticalSpacing lineSpacing,
    VerticalSpacing lastLineSpacing,
    BoxDecoration? decoration,
    this.checkboxUIBuilder,
  ) : super(
          style,
          blockSpacing,
          lineSpacing,
          lastLineSpacing,
          decoration,
        );
}
