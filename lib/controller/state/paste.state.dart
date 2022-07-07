import '../models/paste-style.model.dart';

class PasteState {
  List<PasteStyleM> _pasteStyle = [];
  String _pastePlainText = '';

  List<PasteStyleM> get pasteStyle => _pasteStyle;

  String get pastePlainText => _pastePlainText;

  void setPasteStyle(List<PasteStyleM> pasteStyle) {
    _pasteStyle = pasteStyle;
  }

  void setPastePlainText(String pastePlainText) {
    _pastePlainText = pastePlainText;
  }
}
