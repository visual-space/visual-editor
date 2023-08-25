import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:visual_editor/document/models/delta-doc.model.dart';

var SIMPLE_TEXT_MOCK = '''[
  {
    "insert": "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. \\n",
  }
]''';

void main() {
  late DeltaDocM document;

  setUp(() {
    document = DeltaDocM.fromJson(jsonDecode(SIMPLE_TEXT_MOCK));
    document;
  });

  group('Highlights', () {
    test('Adds highlights', () {});
    test('Removes highlights', () {});
    test('Hovers highlights', () {});
  });
}
