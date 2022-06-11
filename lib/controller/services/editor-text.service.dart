import 'package:flutter/material.dart';

import '../../delta/services/delta.utils.dart';
import '../../documents/models/change-source.enum.dart';
import '../../documents/models/nodes/embed.model.dart';
import '../state/document.state.dart';
import '../state/editor-controller.state.dart';
import '../state/paste.state.dart';

// Reads and the text value of the editor input.
// When setting the text value we take in account the current selection and styles.
class EditorTextService {
  final _editorControllerState = EditorControllerState();
  final _documentState = DocumentState();
  final _pasteState = PasteState();

  static final _instance = EditorTextService._privateConstructor();

  factory EditorTextService() => _instance;

  EditorTextService._privateConstructor();

  TextEditingValue get textEditingValue {
    return _editorControllerState.controller.plainTextEditingValue;
  }

  set textEditingValue(TextEditingValue value) {
    final cursorPosition = value.selection.extentOffset;
    final oldText = _documentState.document.toPlainText();
    final newText = value.text;
    final diff = getDiff(oldText, newText, cursorPosition);

    if (diff.deleted == '' && diff.inserted == '') {
      // Only changing selection range
      _editorControllerState.controller.updateSelection(
        value.selection,
        ChangeSource.LOCAL,
      );
      return;
    }

    final insertedText = _adjustInsertedText(diff.inserted);

    _editorControllerState.controller.replaceText(
      diff.start,
      diff.deleted.length,
      insertedText,
      value.selection,
    );

    _applyPasteStyle(insertedText, diff.start);
  }

  void userUpdateTextEditingValue(
    TextEditingValue value,
    SelectionChangedCause cause,
  ) {
    textEditingValue = value;
  }

  void _applyPasteStyle(String insertedText, int start) {
    if (insertedText == _pasteState.pastePlainText &&
        _pasteState.pastePlainText != '') {
      final pos = start;

      for (var i = 0; i < _pasteState.pasteStyle.length; i++) {
        final offset = _pasteState.pasteStyle[i].item1;
        final style = _pasteState.pasteStyle[i].item2;

        _editorControllerState.controller.formatTextStyle(
          pos + offset,
          i == _pasteState.pasteStyle.length - 1
              ? _pasteState.pastePlainText.length - offset
              : _pasteState.pasteStyle[i + 1].item1,
          style,
        );
      }
    }
  }

  String _adjustInsertedText(String text) {
    // For clip from editor, it may contain image, a.k.a 65532 or '\uFFFC'.
    // For clip from browser, image is directly ignore.
    // Here we skip image when pasting.
    if (!text.codeUnits.contains(EmbedM.kObjectReplacementInt)) {
      return text;
    }

    final buffer = StringBuffer();

    for (var i = 0; i < text.length; i++) {
      if (text.codeUnitAt(i) == EmbedM.kObjectReplacementInt) {
        continue;
      }

      buffer.write(text[i]);
    }

    return buffer.toString();
  }
}
