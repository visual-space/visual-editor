import 'package:flutter/material.dart';

import 'default-text-block-style.model.dart';
import 'editor-checkbox-builder.model.dart';
import 'vertical-spacing.model.dart';

class DefaultListBlockStyle extends DefaultTextBlockStyle {
  final EditorCheckboxBuilder? checkboxUIBuilder;

  DefaultListBlockStyle(
    TextStyle style,
    VerticalSpacing blockSpacing,
    VerticalSpacing lineSpacing,
    BoxDecoration? decoration,
    this.checkboxUIBuilder,
  ) : super(style, blockSpacing, lineSpacing, decoration);
}
