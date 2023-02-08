import 'leaf.model.dart';
import 'node.model.dart';

// A span of formatted text within a line in a Quill document.
// Text is a leaf node of a document tree.
// Parent of a text node is always a Line, and as a consequence text
// node's value cannot contain any line-break characters.
class TextM extends LeafM {
  TextM([String text = ''])
      : assert(!text.contains('\n')),
        super.val(text);

  @override
  NodeM newInstance() => TextM(value);

  @override
  String get value => super.value as String;

  @override
  String toPlainText() => value;
}