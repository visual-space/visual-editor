import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter-quill.dart';

final SAMPLE_HIGHLIGHTS = [
  Highlight(
      textSelection: const TextSelection(
        baseOffset: 183,
        extentOffset: 280,
      ),
      onEnter: (_) {
        print('Entering highlight 1');
      },
      onLeave: (_) {
        print('Leaving highlight 1');
      },
      onSingleTapUp: (_) {
        print('Tapped highlight 1');
      }
  ),
  Highlight(
    textSelection: const TextSelection(
      baseOffset: 387,
      extentOffset: 450,
    ),
    onEnter: (_) {
      print('Entering highlight 2');
    },
    onLeave: (_) {
      print('Leaving highlight 2');
    },
    onSingleTapUp: (_) {
      print('Tapped highlight 2');
    },
  ),
];