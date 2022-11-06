import 'package:flutter/material.dart';
import 'package:visual_editor/blocks/models/editor-styles.model.dart';
import 'package:visual_editor/blocks/models/list-block-style.model.dart';
import 'package:visual_editor/blocks/models/text-block-style.model.dart';
import 'package:visual_editor/blocks/models/vertical-spacing.model.dart';

const VERTICAL_SPACING_EMPTY = VerticalSpacing(top: 0, bottom: 0);
const VERTICAL_BASE_SPACING = VerticalSpacing(top: 6, bottom: 0);

// Demo custom styles created for editors found in Custom Styles page.
const headings = EditorStylesM(
  h1: TextBlockStyleM(
    TextStyle(
      fontSize: 34,
      color: Colors.grey,
      height: 1.15,
      fontWeight: FontWeight.w300,
    ),
    VerticalSpacing(top: 16, bottom: 0),
    VERTICAL_SPACING_EMPTY,
    null,
  ),
  h2: TextBlockStyleM(
    TextStyle(
      fontSize: 24,
      color: Colors.amber,
      height: 1.15,
      fontWeight: FontWeight.w900,
      fontStyle: FontStyle.italic,
    ),
    VerticalSpacing(top: 8, bottom: 0),
    VERTICAL_SPACING_EMPTY,
    null,
  ),
  h3: TextBlockStyleM(
    TextStyle(
      fontSize: 23,
      color: Colors.blue,
      height: 1.25,
      fontWeight: FontWeight.w200,
    ),
    VerticalSpacing(top: 10, bottom: 10),
    VERTICAL_SPACING_EMPTY,
    null,
  ),
);

const paragraphsAndTypography = EditorStylesM(
  h1: TextBlockStyleM(
    TextStyle(
      fontSize: 34,
      color: Colors.black87,
      height: 1.15,
      fontWeight: FontWeight.w300,
    ),
    VerticalSpacing(top: 16, bottom: 10),
    VERTICAL_SPACING_EMPTY,
    null,
  ),
  paragraph: TextBlockStyleM(
    TextStyle(
      fontSize: 16,
      height: 1.8,
    ),
    VERTICAL_SPACING_EMPTY,
    VERTICAL_SPACING_EMPTY,
    null,
  ),
  bold: TextStyle(
    fontWeight: FontWeight.bold,
    color: Colors.green,
  ),
  italic: TextStyle(
    fontStyle: FontStyle.italic,
    color: Colors.greenAccent,
    fontSize: 18,
  ),
  underline: TextStyle(
    decoration: TextDecoration.underline,
    fontStyle: FontStyle.italic,
    color: Colors.red,
  ),
  strikeThrough: TextStyle(
    decoration: TextDecoration.lineThrough,
    color: Colors.blue,
  ),
);

// Ordered, unordered lists, quotes and snippets
final listQuotesAndSnippets = EditorStylesM(
  leading: TextBlockStyleM(
    TextStyle(color: Colors.blue),
    VERTICAL_SPACING_EMPTY,
    VERTICAL_SPACING_EMPTY,
    null,
  ),
  lists: ListBlockStyle(
    // TODO Seems to be inactive
    TextStyle(
      fontSize: 16,
      height: 1.3,
    ),
    VerticalSpacing(top: 0, bottom: 60),
    VerticalSpacing(top: 0, bottom: 6),
    null,
    null,
  ),
  quote: TextBlockStyleM(
    TextStyle(
      color: Colors.blue.shade200,
    ),
    VERTICAL_BASE_SPACING,
    VerticalSpacing(top: 6, bottom: 10),
    BoxDecoration(
        border: Border(
            left: BorderSide(
      width: 4,
      color: Colors.grey,
    ))),
  ),
);
