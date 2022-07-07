import 'package:flutter/rendering.dart';

// A common interface to render boxes which represent a piece of rich text blocks.
// See also:
// * RenderParagraphProxy implementation of this interface which wraps built-in RenderParagraph
// * RenderEmbedProxy implementation of this interface which wraps an arbitrary
//   render box representing an embeddable object.
abstract class RenderContentProxyBox implements RenderBox {
  double get preferredLineHeight;

  Offset getOffsetForCaret(TextPosition position, Rect caretPrototype);

  TextPosition getPositionForOffset(Offset offset);

  double? getFullHeightForCaret(TextPosition position);

  TextRange getWordBoundary(TextPosition position);

  // Returns a list of rects that bound the given selection.
  // A given selection might have more than one rect if this text painter
  // contains bidirectional text because logically contiguous text might not be visually contiguous.
  // Valid only after layout.
  List<TextBox> getBoxesForSelection(TextSelection textSelection);
}