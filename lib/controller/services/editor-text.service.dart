import 'package:flutter/material.dart';

import '../../documents/models/change-source.enum.dart';
import '../../documents/models/nodes/embed.model.dart';
import '../../documents/services/delta.utils.dart';
import '../../shared/state/editor.state.dart';

// Reads and the text value of the editor input.
// When setting the text value we take in account the current selection and styles.
class EditorTextService {

  static final _instance = EditorTextService._privateConstructor();

  factory EditorTextService() => _instance;

  EditorTextService._privateConstructor();

  // TextEditingValue get textEditingValue {
  //   return state.refs.editorController.plainTextEditingValue;
  // }

  void setTextEditingValue(TextEditingValue value, EditorState state) {
    final cursorPosition = value.selection.extentOffset;
    final oldText = state.document.document.toPlainText();
    final newText = value.text;
    final diff = getDiff(oldText, newText, cursorPosition);

    if (diff.deleted == '' && diff.inserted == '') {
      // Only changing selection range
      state.refs.editorController.updateSelection(
        value.selection,
        ChangeSource.LOCAL,
      );
      return;
    }

    final insertedText = _adjustInsertedText(diff.inserted);

    state.refs.editorController.replaceText(
      diff.start,
      diff.deleted.length,
      insertedText,
      value.selection,
    );

    _applyPasteStyle(insertedText, diff.start, state);
  }

  void userUpdateTextEditingValue(
    TextEditingValue value,
    SelectionChangedCause cause,
    EditorState state,
  ) {
    setTextEditingValue(value, state);
  }

  void _applyPasteStyle(String insertedText, int start, EditorState state ) {
    if (insertedText == state.paste.pastePlainText &&
        state.paste.pastePlainText != '') {
      final pos = start;

      for (var i = 0; i < state.paste.pasteStyle.length; i++) {
        final offset = state.paste.pasteStyle[i].item1;
        final style = state.paste.pasteStyle[i].item2;

        state.refs.editorController.formatTextStyle(
          pos + offset,
          i == state.paste.pasteStyle.length - 1
              ? state.paste.pastePlainText.length - offset
              : state.paste.pasteStyle[i + 1].item1,
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
