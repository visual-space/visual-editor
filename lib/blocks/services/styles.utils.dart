import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../visual-editor.dart';
import '../models/inline-code-style.model.dart';
import '../models/list-block-style.model.dart';
import '../models/vertical-spacing.model.dart';

const VERTICAL_SPACING_EMPTY = VerticalSpacing(top: 0, bottom: 0);
const VERTICAL_BASE_SPACING = VerticalSpacing(top: 6, bottom: 0);

EditorStylesM getDefaultStyles(BuildContext context) {
  final themeData = Theme.of(context);
  final defaultTextStyle = DefaultTextStyle.of(context);
  final baseStyle = defaultTextStyle.style.copyWith(
    fontSize: 16,
    height: 1.3,
  );

  final inlineCodeStyle = GoogleFonts.robotoMono(
    color: Colors.blue.shade900.withOpacity(0.9),
    fontSize: 13,
    height: 1.15,
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
      VERTICAL_SPACING_EMPTY,
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
      VERTICAL_SPACING_EMPTY,
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
      VERTICAL_SPACING_EMPTY,
      null,
    ),
    paragraph: TextBlockStyleM(
      baseStyle,
      VERTICAL_SPACING_EMPTY,
      VERTICAL_SPACING_EMPTY,
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
      VERTICAL_SPACING_EMPTY,
      VERTICAL_SPACING_EMPTY,
      null,
    ),
    lists: ListBlockStyle(
      baseStyle,
      VERTICAL_BASE_SPACING,
      VerticalSpacing(top: 0, bottom: 6),
      null,
      null,
    ),
    quote: TextBlockStyleM(
      TextStyle(
        color: baseStyle.color!.withOpacity(0.6),
      ),
      VERTICAL_BASE_SPACING,
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
      GoogleFonts.robotoMono(
        color: Colors.blue.shade900.withOpacity(0.9),
        fontSize: 13,
        height: 1.15,
      ),
      VERTICAL_BASE_SPACING,
      VERTICAL_SPACING_EMPTY,
      BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(2),
      ),
    ),
    indent: TextBlockStyleM(
      baseStyle,
      VERTICAL_BASE_SPACING,
      VerticalSpacing(top: 0, bottom: 6),
      null,
    ),
    align: TextBlockStyleM(
      baseStyle,
      VERTICAL_SPACING_EMPTY,
      VERTICAL_SPACING_EMPTY,
      null,
    ),
    leading: TextBlockStyleM(
      baseStyle,
      VERTICAL_SPACING_EMPTY,
      VERTICAL_SPACING_EMPTY,
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
