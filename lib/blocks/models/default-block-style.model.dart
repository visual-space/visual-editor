import 'package:flutter/material.dart';
import 'package:tuple/tuple.dart';

import 'default-text-block-style.model.dart';
import 'quill-checkbox-builder.model.dart';

class DefaultListBlockStyle extends DefaultTextBlockStyle {
  final QuillCheckboxBuilder? checkboxUIBuilder;

  DefaultListBlockStyle(
    TextStyle style,
    Tuple2<double, double> verticalSpacing,
    Tuple2<double, double> lineSpacing,
    BoxDecoration? decoration,
    this.checkboxUIBuilder,
  ) : super(style, verticalSpacing, lineSpacing, decoration);
}
