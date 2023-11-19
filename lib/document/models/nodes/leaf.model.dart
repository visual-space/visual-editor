import '../../services/nodes/leaf.utils.dart';
import 'line.model.dart';
import 'node.model.dart';
import 'style.model.dart';

final _leafUtils = LeafUtils();

// A leaf in Visual Editor document tree.
// Contents of this node, either a String if this is a Text or an Embed if this is an BlockEmbed.
abstract base class LeafM extends NodeM {
  Object value;

  factory LeafM(Object data) => _leafUtils.newLeaf(data);

  LeafM.val(Object val) : value = val;

  @override
  void applyStyle(StyleM value) {
    assert(
      value.isInline || value.isIgnored || value.isEmpty,
      'Unable to apply Style to leaf: $value',
    );
    super.applyStyle(value);
  }

  @override
  LineM? get parent => super.parent as LineM?;

  @override
  int get charsNum => _leafUtils.getCharsNumber(this);

  @override
  String toString() => _leafUtils.leafToString(this);
}
