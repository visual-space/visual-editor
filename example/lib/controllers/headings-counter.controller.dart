import 'dart:async';

import 'package:flutter/material.dart';
import 'package:visual_editor/headings/models/heading-type.enum.dart';
import 'package:visual_editor/headings/models/heading.model.dart';
import 'package:visual_editor/visual-editor.dart';

import '../models/character-counter.model.dart';

const CHARACTERS_LIMIT = 30;

// Each heading has a 30-character limit.
// If the limit is exceeded the extra characters will be highlighted and a counter
// of the extra characters will be displayed near the header.
// To display these counters we need to calculate their position.
// Every counter has a raw position, the position of the last header's rectangle in the document.
// To get the correct position of the header we have to add to the raw position the height of widgets
// above the document (if there are any) and the current scroll offset.
// Every time the page is scrolled we update the scroll offset and the counter's positions.
class HeadingsCounterController {
  final _counters$ = StreamController<List<CharacterCounterM>>.broadcast();

  Stream<List<CharacterCounterM>> counters$() => _counters$.stream;

  late EditorController _controller;
  List<HeadingM> _headingsList = [];
  final List<CharacterCounterM> _counters = [];

  void init(
    EditorController controller,
    double scrollControllerOffset,
  ) {
    _controller = controller;
    final headings = _controller.getHeadingsByType(
      types: [HeadingTypeE.h1],
    );

    if (_headersHaveChanged(headings)) {
      _headingsList = headings;
      _checkIfHeaderExceedLimitAndCreateCounters(scrollControllerOffset);
    }
  }

  void updateCountersPositions(double scrollControllerOffset) {
    final updatedCountersList = <CharacterCounterM>[];
    const textHeight = 15;

    _counters.forEach((counter) {
      updatedCountersList.add(
        counter.copyWith(
          yPosition: counter.yPosition! - textHeight - scrollControllerOffset,
        ),
      );
    });

    _counters$.add(updatedCountersList);
  }

  // === PRIVATE ===

  void _checkIfHeaderExceedLimitAndCreateCounters(
    double scrollControllerOffset,
  ) {
    _counters.clear();
    _clearHighlights();

    _headingsList.forEach((heading) {
      // The editor returns an additional invisible char ('\n') so we have to subtract it
      final headerLength = (heading.text?.length ?? 0) - 1;

      // Check if headers exceed the limit and create counters
      if (headerLength > CHARACTERS_LIMIT) {
        final baseOffset = heading.selection?.baseOffset ?? 0;
        final extentOffset = heading.selection?.extentOffset ?? 0;
        // The position of the counter in the delta document without any additional dimension
        final rawPosition =
            heading.docRelPosition!.dy + (heading.rectangles?.last.bottom ?? 0);

        _counters.add(
          CharacterCounterM(
            count: headerLength - CHARACTERS_LIMIT,
            yPosition: rawPosition,
          ),
        );

        _highlightExceededCharacters(baseOffset, extentOffset);
      }
    });

    updateCountersPositions(scrollControllerOffset);
  }

  void _highlightExceededCharacters(int baseOffset, int extentOffset) {
    _controller.addHighlight(
      HighlightM(
        id: 'id',
        color: Colors.red.withOpacity(0.3),
        hoverColor: Colors.red.withOpacity(0.3),
        textSelection: TextSelection(
          baseOffset: baseOffset + CHARACTERS_LIMIT,
          extentOffset: extentOffset,
        ),
      ),
    );
  }

  void _clearHighlights() {
    _controller.removeAllHighlights();
  }

  // We compare only the selection and the document relative position
  // of the headers because it is more likely to be modified
  // (every time a new character is typed or the screen resizes)
  bool _headersHaveChanged(List<HeadingM> headings) {
    var hasChanged = false;

    if (_headingsList.length != headings.length) {
      return true;
    }

    _headingsList.forEach((element) {
      final index = _headingsList.indexOf(element);

      if (_headingsList[index].selection != headings[index].selection ||
          _headingsList[index].docRelPosition !=
              headings[index].docRelPosition) {
        hasChanged = true;
      }
    });

    return hasChanged;
  }
}
