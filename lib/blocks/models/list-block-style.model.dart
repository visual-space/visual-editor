import 'package:flutter/material.dart';

import 'editor-checkbox-builder.model.dart';
import 'text-block-style.model.dart';
import 'vertical-spacing.model.dart';

class ListBlockStyle extends TextBlockStyleM {
  final EditorCheckboxBuilder? checkboxUIBuilder;

  ListBlockStyle(
    TextStyle style,
    VerticalSpacing blockSpacing,
    VerticalSpacing lineSpacing,
    BoxDecoration? decoration,
    this.checkboxUIBuilder,
  ) : super(style, blockSpacing, lineSpacing, decoration);
}
