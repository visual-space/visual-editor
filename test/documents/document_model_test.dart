import 'package:flutter_test/flutter_test.dart';

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
  // late DeltaDocM document;

  setUp(() {
    // document = DeltaDocM.fromJson(jsonDecode(MARKERS_MOCK));
  });

  group('Document Model', () {
    test('Markers, converts json to document styles', () {
      // final markerStyle = document.root.children.first.style.attributes?[AttributesM.markers.key];
      // expect(markerStyle?.key, AttributesM.markers.key);
      // expect(markerStyle?.scope, AttributeScope.INLINE);
      // expect(markerStyle?.value['type'], 'expert');
      // expect(markerStyle?.value['id'], 'b53d8d53');
    });
  });
}
