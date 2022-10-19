import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:visual_editor/documents/models/attribute-scope.enum.dart';
import 'package:visual_editor/documents/models/document.model.dart';

var MARKERS_MOCK = '''[
  {
    "insert": "Lorem\\n",
    "attributes": {
      "bold": true,
      "markers":[
        {
          "type": "expert",
          "data": "b53d8d53"
        },
        {
          "type": "beginner",
          "data": "f36335c4"
        }
      ]
    }
  }
]''';

void main() {
  late DocumentM document;

  setUp(() {
    document = DocumentM.fromJson(jsonDecode(MARKERS_MOCK));
  });

  group('Document Model', () {
    test('Markers, converts json to document styles', () {
      final markerStyle = document.root.children.first.style.attributes['markers'];
      expect(markerStyle?.key, 'markers');
      expect(markerStyle?.scope, AttributeScope.INLINE);
      expect(markerStyle?.value['type'], 'expert');
      expect(markerStyle?.value['id'], 'b53d8d53');
    });
  });
}
