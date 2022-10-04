import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:visual_editor/controller/controllers/editor-controller.dart';
import 'package:visual_editor/documents/models/change-source.enum.dart';
import 'package:visual_editor/documents/models/document.model.dart';
import 'package:visual_editor/highlights/models/highlight.model.dart';

// NOTE character length of example text is about 127
var SIMPLE_TEXT_MOCK = '''[
  {
    "insert": "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. \\n"
  }
]''';

void main() {
  late DocumentM document;
  late EditorController editorController;
  setUp(() {
    document = DocumentM.fromJson(jsonDecode(SIMPLE_TEXT_MOCK));
    editorController = EditorController(document: document);
  });

  group('Highlights', () {
    // many of these tests also incidentally test the equality operators of the HighlightModelM class.
    test('Adds highlight', () {
      editorController.updateSelection(
          TextSelection(baseOffset: 5, extentOffset: 10), ChangeSource.LOCAL);
      editorController.addHighlight(HighlightM(
          textSelection: TextSelection(baseOffset: 5, extentOffset: 10)));
      expect(editorController.getHighlights(), [
        HighlightM(
            textSelection: TextSelection(baseOffset: 5, extentOffset: 10))
      ]);
    });
    test('Adds multiple getHighlights(), no overlap', () {
      editorController.updateSelection(
          TextSelection(baseOffset: 5, extentOffset: 10), ChangeSource.LOCAL);
      editorController.addHighlight(HighlightM(
          textSelection: TextSelection(baseOffset: 5, extentOffset: 10),
          color: Colors.green));
      editorController.addHighlight(HighlightM(
          textSelection: TextSelection(baseOffset: 11, extentOffset: 20),
          color: Colors.red));
      editorController.addHighlight(HighlightM(
          textSelection: TextSelection(baseOffset: 25, extentOffset: 50),
          color: Colors.blue));
      expect(editorController.getHighlights(), [
        HighlightM(
            textSelection: TextSelection(baseOffset: 5, extentOffset: 10),
            color: Colors.green),
        HighlightM(
            textSelection: TextSelection(baseOffset: 11, extentOffset: 20),
            color: Colors.red),
        HighlightM(
            textSelection: TextSelection(baseOffset: 25, extentOffset: 50),
            color: Colors.blue)
      ]);
    });
    test('Adds multiple getHighlights(), overlap', () {
      editorController.updateSelection(
          TextSelection(baseOffset: 5, extentOffset: 10), ChangeSource.LOCAL);
      editorController.addHighlight(HighlightM(
          textSelection: TextSelection(
              baseOffset: 5,
              extentOffset: 15), // overlaps with the next highlight
          color: Colors.green));
      editorController.addHighlight(HighlightM(
          textSelection: TextSelection(baseOffset: 11, extentOffset: 20),
          color: Colors.red));
      editorController.addHighlight(HighlightM(
          textSelection: TextSelection(baseOffset: 25, extentOffset: 50),
          color: Colors.blue));
      expect(editorController.getHighlights(), [
        HighlightM(
            textSelection: TextSelection(baseOffset: 5, extentOffset: 15),
            color: Colors.green),
        HighlightM(
            textSelection: TextSelection(baseOffset: 11, extentOffset: 20),
            color: Colors.red),
        HighlightM(
            textSelection: TextSelection(baseOffset: 25, extentOffset: 50),
            color: Colors.blue)
      ]);
    });
    test('Removes highlight from new equal highlight object', () {
      editorController.updateSelection(
          TextSelection(baseOffset: 5, extentOffset: 10), ChangeSource.LOCAL);
      editorController.addHighlight(HighlightM(
          textSelection: TextSelection(baseOffset: 5, extentOffset: 10)));
      editorController.removeHighlight(HighlightM(
          textSelection: TextSelection(baseOffset: 5, extentOffset: 10)));
      expect(editorController.getHighlights(), []);
    });
    test('Removes highlight via same highlight object', () {
      final highlight = HighlightM(
          textSelection: TextSelection(baseOffset: 5, extentOffset: 10));
      editorController.updateSelection(
          TextSelection(baseOffset: 5, extentOffset: 10), ChangeSource.LOCAL);
      editorController.addHighlight(highlight);
      editorController.removeHighlight(highlight);
      expect(editorController.getHighlights(), []);
    });
    test('Removes partial highlight above highlight extent via selection range',
        () {
      final highlight = HighlightM(
          textSelection: TextSelection(baseOffset: 5, extentOffset: 10));
      editorController.updateSelection(
          TextSelection(baseOffset: 7, extentOffset: 15), ChangeSource.LOCAL);
      editorController.addHighlight(highlight);
      editorController.removeHighlightInRange(
          editorController.selection.baseOffset,
          editorController.selection.extentOffset);
      expect(editorController.getHighlights(), [
        HighlightM(textSelection: TextSelection(baseOffset: 5, extentOffset: 7))
      ]);
    });
    test('Removes partial highlight below highlight extent via selection range',
        () {
      final highlight = HighlightM(
          textSelection: TextSelection(baseOffset: 5, extentOffset: 10));
      editorController.updateSelection(
          TextSelection(baseOffset: 2, extentOffset: 8), ChangeSource.LOCAL);
      editorController.addHighlight(highlight);
      editorController.removeHighlightInRange(
          editorController.selection.baseOffset,
          editorController.selection.extentOffset);
      expect(editorController.getHighlights(), [
        HighlightM(
            textSelection: TextSelection(baseOffset: 8, extentOffset: 10))
      ]);
    });
    test(
        'Removes partial highlight inside highlight extent via selection range - case where two resultant getHighlights() are required',
        () {
      final highlight = HighlightM(
          textSelection: TextSelection(baseOffset: 5, extentOffset: 30));
      editorController.updateSelection(
          TextSelection(baseOffset: 10, extentOffset: 20), ChangeSource.LOCAL);
      editorController.addHighlight(highlight);
      editorController.removeHighlightInRange(
          editorController.selection.baseOffset,
          editorController.selection.extentOffset);
      expect(editorController.getHighlights(), [
        HighlightM(
            textSelection: TextSelection(baseOffset: 5, extentOffset: 10)),
        HighlightM(
            textSelection: TextSelection(baseOffset: 20, extentOffset: 30))
      ]);
    });
    test('Removes entire highlight via selection range', () {
      final highlight = HighlightM(
          textSelection: TextSelection(baseOffset: 5, extentOffset: 10));
      editorController.updateSelection(
          TextSelection(baseOffset: 2, extentOffset: 15), ChangeSource.LOCAL);
      editorController.addHighlight(highlight);
      editorController.removeHighlightInRange(
          editorController.selection.baseOffset,
          editorController.selection.extentOffset);
      expect(editorController.getHighlights(), []);
    });
    test('Removes first highlight retrieved when two getHighlights() overlap',
        () {
      final highlight = HighlightM(
          textSelection: TextSelection(baseOffset: 5, extentOffset: 10),
          color: Colors.green);
      final highlight2 = HighlightM(
          textSelection: TextSelection(baseOffset: 5, extentOffset: 10),
          color: Colors.red);
      editorController.updateSelection(
          TextSelection(baseOffset: 2, extentOffset: 15), ChangeSource.LOCAL);
      editorController.addHighlight(highlight);
      editorController.addHighlight(highlight2);
      // NOTE this method in the HighlightsState class uses the same logic as the above, which manages the removal of getHighlights() smaller than the full size of the
      // highlight. If those work, then this should work for any case in which they work.
      editorController.removeFirstHighlightInRange(
          editorController.selection.baseOffset,
          editorController.selection.extentOffset);
      expect(editorController.getHighlights(), [highlight2]);
    });
    test('remove all getHighlights()', () {
      final highlight = HighlightM(
          textSelection: TextSelection(baseOffset: 5, extentOffset: 10),
          color: Colors.green);
      final highlight2 = HighlightM(
          textSelection: TextSelection(baseOffset: 5, extentOffset: 10),
          color: Colors.red);
      editorController.updateSelection(
          TextSelection(baseOffset: 2, extentOffset: 15), ChangeSource.LOCAL);
      editorController.addHighlight(highlight);
      editorController.addHighlight(highlight2);
      editorController.removeAllHighlights();
      expect(editorController.getHighlights(), []);
    });
    // test('Hovers getHighlights()', () {});
  });
}
