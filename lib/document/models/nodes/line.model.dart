import '../../services/nodes/line.utils.dart';
import 'container.model.dart';
import 'embed-node.model.dart';
import 'leaf.model.dart';
import 'node.model.dart';
import 'text.model.dart';

final _lineUtils = LineUtils();

// A line of rich text in a Editor document.
// Line serves as a container for Leafs, like Text and Embed.
// When a line contains an embed, it fully occupies the line, no other embeds or text nodes are allowed.
// Lines of text are fragmented into children.
// Children are fragments containing a unique combination of attributes.
class LineM extends ContainerM<LeafM?> {
  @override
  LeafM get defaultChild => TextM();

  @override
  int get charsNum => super.charsNum + 1;

  bool get hasEmbed => children.any((child) => child is EmbedNodeM);

  @override
  NodeM newInstance() => LineM();

  @override
  String toPlainText() => '${super.toPlainText()}\n';

  @override
  String toString() => _lineUtils.lineToString(this);
}
