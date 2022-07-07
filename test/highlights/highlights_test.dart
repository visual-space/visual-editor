import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:visual_editor/documents/models/document.model.dart';

var SIMPLE_TEXT_MOCK = '''[
  {
    "insert": "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. \\n",
  }
]''';

void main() {
  late DocumentM document;

  setUp(() {
    document = DocumentM.fromJson(jsonDecode(SIMPLE_TEXT_MOCK));
    document;
  });

  group('Highlights', () {
    test('Adds highlights', () {});
    test('Removes highlights', () {});
    test('Hovers highlights', () {});
  });
}
