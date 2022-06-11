import '../../../delta/models/delta.model.dart';
import 'container.model.dart';
import 'line.model.dart';
import 'node.model.dart';

// Represents a group of adjacent [Line]s with the same block style.
// Block elements are:
// - Blockquote
// - Header
// - Indent
// - List
// - Text Alignment
// - Text Direction
// - Code Block
class BlockM extends ContainerM<LineM?> {
  // Creates new unmounted [Block].
  @override
  NodeM newInstance() => BlockM();

  @override
  LineM get defaultChild => LineM();

  @override
  DeltaM toDelta() {
    // Line nodes take care of incorporating block style into their delta.
    return children
        .map((child) => child.toDelta())
        .fold(DeltaM(), (a, b) => a.concat(b));
  }

  @override
  void adjust() {
    if (isEmpty) {
      final sibling = previous;
      unlink();

      if (sibling != null) {
        sibling.adjust();
      }

      return;
    }

    var block = this;
    final prev = block.previous;

    // Merging it with previous block if style is the same
    if (!block.isFirst &&
        block.previous is BlockM &&
        prev!.style == block.style) {
      block
        ..moveChildToNewParent(prev as ContainerM<NodeM?>?)
        ..unlink();
      block = prev as BlockM;
    }

    final next = block.next;
    // merging it with next block if style is the same

    if (!block.isLast && block.next is BlockM && next!.style == block.style) {
      (next as BlockM).moveChildToNewParent(block);
      next.unlink();
    }
  }

  @override
  String toString() {
    final block = style.attributes.toString();
    final buffer = StringBuffer('§ {$block}\n');

    for (final child in children) {
      final tree = child.isLast ? '└' : '├';
      buffer.write('  $tree $child');
      if (!child.isLast) buffer.writeln();
    }

    return buffer.toString();
  }
}
