import 'package:flutter/material.dart';
import 'package:visual_editor/highlights/models/highlight.model.dart';

final DEMO_HIGHLIGHTS = [
  HighlightM(
    id: '1255915685987000',
    textSelection: const TextSelection(
      baseOffset: 183,
      extentOffset: 280,
    ),
    onEnter: (highlight) {},
    onHover: (highlight) {},
    onExit: (highlight) {},
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
    onEnter: (highlight) {},
    onHover: (highlight) {},
    onExit: (highlight) {},
    onSingleTapUp: (highlight) {
      print('Highlight tapped ${highlight.id}');
    },
  ),
  HighlightM(
    id: '1255915683987000',
    textSelection: const TextSelection(
      baseOffset: 487,
      extentOffset: 550,
    ),
    color: Colors.green.withOpacity(0.3),
    hoverColor: Colors.green.withOpacity(0.5),
    onEnter: (highlight) {},
    onHover: (highlight) {},
    onExit: (highlight) {},
    onSingleTapUp: (highlight) {
      print('Highlight tapped ${highlight.id}');
    },
  ),
  HighlightM(
    id: '1255915683987000',
    textSelection: const TextSelection(
      baseOffset: 700,
      extentOffset: 724,
    ),
    color: Colors.green.withOpacity(0.3),
    hoverColor: Colors.green.withOpacity(0.5),
    onEnter: (highlight) {},
    onHover: (highlight) {},
    onExit: (highlight) {},
    onSingleTapUp: (highlight) {
      print('Highlight tapped ${highlight.id}');
    },
  ),
];
