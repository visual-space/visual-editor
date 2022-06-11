import '../../../visual-editor.dart';
import 'node.model.dart';

// An embed node inside of a line in a Quill document.
// Embed node is a leaf node similar to [Text].
// It represents an arbitrary piece of non-textual blocks embedded into a document, such as, image,
// horizontal rule, video, or any other object with defined structure, like a tweet, for instance.
// Embed node's length is always `1` character and it is represented with
// unicode object replacement character in the document text.
// Any inline style can be applied to an embed, however this does not
// necessarily mean the embed will look according to that style. For instance,
// applying "bold" style to an image gives no effect, while adding a "link" to
// an image actually makes the image react to user's action.
class EmbedM extends LeafM {

  // Refer to https://www.fileformat.info/info/unicode/char/fffc/index.htm
  static const kObjectReplacementCharacter = '\uFFFC';
  static const kObjectReplacementInt = 65532;
  
  EmbedM(EmbeddableM data) : super.val(data);

  @override
  NodeM newInstance() => throw UnimplementedError();

  @override
  EmbeddableM get value => super.value as EmbeddableM;

  // Embed nodes are represented as unicode object replacement character in plain text.
  @override
  String toPlainText() => kObjectReplacementCharacter;

  @override
  String toString() => '${super.toString()} ${value.type}';
}
