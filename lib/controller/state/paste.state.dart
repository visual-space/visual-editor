import 'package:tuple/tuple.dart';

import '../../documents/models/style.model.dart';

class PasteState {
  List<Tuple2<int, StyleM>> _pasteStyle = [];
  String _pastePlainText = '';

  List<Tuple2<int, StyleM>> get pasteStyle => _pasteStyle;

  String get pastePlainText => _pastePlainText;

  void setPasteStyle(List<Tuple2<int, StyleM>> pasteStyle) {
    _pasteStyle = pasteStyle;
  }

  void setPastePlainText(String pastePlainText) {
    _pastePlainText = pastePlainText;
  }
}
