import '../nodes/style.model.dart';

// Used to restore the styling when copy pasting text in the editor.
// The remote input used by flutter stores only plain text.
// Therefore we have to cache separately the styles and apply them when the text is inserted.
class PasteStyleM {
  final int offset;
  final StyleM style;

  PasteStyleM(
    this.offset,
    this.style,
  );
}
