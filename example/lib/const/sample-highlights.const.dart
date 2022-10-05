import 'package:flutter/material.dart';
import 'package:visual_editor/visual-editor.dart';

final SAMPLE_HIGHLIGHTS = [
  HighlightM(
    id: '1245913488987450',
    textSelection: const TextSelection(
      baseOffset: 183,
      extentOffset: 280,
    ),
    onEnter: (highlight) {
      // print('Entering highlight 1');
    },
    onHover: (highlight) {
      // print('Hovering highlight 1');
    },
    onExit: (highlight) {
      // print('Leaving highlight 1');
    },
    onSingleTapUp: (highlight) {
      print('Highlight tapped ${highlight.id}');
    },
  ),
  HighlightM(
    id: '1255915688987000',
    textSelection: const TextSelection(
      baseOffset: 387,
      extentOffset: 450,
    ),
    onEnter: (highlight) {
      // print('Entering highlight 2');
    },
    onHover: (highlight) {
      // print('Hovering highlight 2');
    },
    onExit: (highlight) {
      // print('Leaving highlight 2');
    },
    onSingleTapUp: (highlight) {
      print('Highlight tapped ${highlight.id}');
    },
  ),
];
