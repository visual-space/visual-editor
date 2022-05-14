import 'package:flutter/material.dart';
import 'package:tuple/tuple.dart';

import 'default-text-block-style.model.dart';
import 'editor-checkbox-builder.model.dart';

class DefaultListBlockStyle extends DefaultTextBlockStyle {
  final EditorCheckboxBuilder? checkboxUIBuilder;

  DefaultListBlockStyle(
    TextStyle style,
    Tuple2<double, double> verticalSpacing,
    Tuple2<double, double> lineSpacing,
    BoxDecoration? decoration,
    this.checkboxUIBuilder,
  ) : super(style, verticalSpacing, lineSpacing, decoration);
}
