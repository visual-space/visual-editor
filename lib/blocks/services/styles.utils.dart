import 'package:flutter/material.dart';

import '../../shared/utils/platform.utils.dart';
import '../../visual-editor.dart';
import '../models/inline-code-style.model.dart';
import '../models/list-block-style.model.dart';
import '../models/vertical-spacing.model.dart';

EditorStylesM getDefaultStyles(BuildContext context) {
  final themeData = Theme.of(context);
  final defaultTextStyle = DefaultTextStyle.of(context);
  final baseStyle = defaultTextStyle.style.copyWith(
    fontSize: 16,
    height: 1.3,
  );
  final baseSpacing = VerticalSpacing(top: 6, bottom: 0);
  String fontFamily;

  if (isAppleOS(themeData.platform)) {
    fontFamily = 'Menlo';
  } else {
    fontFamily = 'Roboto Mono';
  }

  final inlineCodeStyle = TextStyle(
    fontSize: 14,
    color: themeData.colorScheme.primary.withOpacity(0.8),
    fontFamily: fontFamily,
  );

  return EditorStylesM(
    h1: TextBlockStyleM(
      defaultTextStyle.style.copyWith(
        fontSize: 34,
        color: defaultTextStyle.style.color!.withOpacity(0.70),
        height: 1.15,
        fontWeight: FontWeight.w300,
      ),
      VerticalSpacing(top: 16, bottom: 0),
      VerticalSpacing(top: 0, bottom: 0),
      null,
    ),
    h2: TextBlockStyleM(
      defaultTextStyle.style.copyWith(
        fontSize: 24,
        color: defaultTextStyle.style.color!.withOpacity(0.70),
        height: 1.15,
        fontWeight: FontWeight.normal,
      ),
      VerticalSpacing(top: 8, bottom: 0),
      VerticalSpacing(top: 0, bottom: 0),
      null,
    ),
    h3: TextBlockStyleM(
      defaultTextStyle.style.copyWith(
        fontSize: 20,
        color: defaultTextStyle.style.color!.withOpacity(0.70),
        height: 1.25,
        fontWeight: FontWeight.w500,
      ),
      VerticalSpacing(top: 8, bottom: 0),
      VerticalSpacing(top: 0, bottom: 0),
      null,
    ),
    paragraph: TextBlockStyleM(
      baseStyle,
      VerticalSpacing(top: 0, bottom: 0),
      VerticalSpacing(top: 0, bottom: 0),
      null,
    ),
    bold: const TextStyle(
      fontWeight: FontWeight.bold,
    ),
    italic: const TextStyle(
      fontStyle: FontStyle.italic,
    ),
    small: const TextStyle(
      fontSize: 12,
      color: Colors.black45,
    ),
    underline: const TextStyle(
      decoration: TextDecoration.underline,
    ),
    strikeThrough: const TextStyle(
      decoration: TextDecoration.lineThrough,
    ),
    inlineCode: InlineCodeStyle(
      backgroundColor: Colors.grey.shade100,
      radius: const Radius.circular(3),
      style: inlineCodeStyle,
      header1: inlineCodeStyle.copyWith(
        fontSize: 32,
        fontWeight: FontWeight.w300,
      ),
      header2: inlineCodeStyle.copyWith(
        fontSize: 22,
      ),
      header3: inlineCodeStyle.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.w500,
      ),
    ),
    link: TextStyle(
      color: themeData.colorScheme.secondary,
      decoration: TextDecoration.underline,
    ),
    placeHolder: TextBlockStyleM(
      defaultTextStyle.style.copyWith(
        fontSize: 20,
        height: 1.5,
        color: Colors.grey.withOpacity(0.6),
      ),
      VerticalSpacing(top: 0, bottom: 0),
      VerticalSpacing(top: 0, bottom: 0),
      null,
    ),
    lists: ListBlockStyle(
      baseStyle,
      baseSpacing,
      VerticalSpacing(top: 0, bottom: 6),
      null,
      null,
    ),
    quote: TextBlockStyleM(
      TextStyle(
        color: baseStyle.color!.withOpacity(0.6),
      ),
      baseSpacing,
      VerticalSpacing(top: 6, bottom: 2),
      BoxDecoration(
        border: Border(
          left: BorderSide(
            width: 4,
            color: Colors.grey.shade300,
          ),
        ),
      ),
    ),
    code: TextBlockStyleM(
      TextStyle(
        color: Colors.blue.shade900.withOpacity(0.9),
        fontFamily: fontFamily,
        fontSize: 13,
        height: 1.15,
      ),
      baseSpacing,
      VerticalSpacing(top: 0, bottom: 0),
      BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(2),
      ),
    ),
    indent: TextBlockStyleM(
      baseStyle,
      baseSpacing,
      VerticalSpacing(top: 0, bottom: 6),
      null,
    ),
    align: TextBlockStyleM(
      baseStyle,
      VerticalSpacing(top: 0, bottom: 0),
      VerticalSpacing(top: 0, bottom: 0),
      null,
    ),
    leading: TextBlockStyleM(
      baseStyle,
      VerticalSpacing(top: 0, bottom: 0),
      VerticalSpacing(top: 0, bottom: 0),
      null,
    ),
    sizeSmall: const TextStyle(
      fontSize: 10,
    ),
    sizeLarge: const TextStyle(
      fontSize: 18,
    ),
    sizeHuge: const TextStyle(
      fontSize: 22,
    ),
  );
}
