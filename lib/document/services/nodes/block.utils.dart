import '../../models/delta/delta.model.dart';
import '../../models/nodes/block.model.dart';
import '../../models/nodes/container.model.dart';
import '../../models/nodes/node.model.dart';
import '../delta.utils.dart';
import 'container.utils.dart';
import 'node.utils.dart';

final _du = DeltaUtils();
final _contUtils = ContainerUtils();
final _nodeUtils = NodeUtils();

class BlockUtils {
  DeltaM toDelta(BlockM block) {
    // Line nodes take care of incorporating block style into their delta.
    return block.children.map(_nodeUtils.toDelta).fold(DeltaM(), _du.concat);
  }

  String blockToString(BlockM block) {
    final _block = block.style.attributes.toString();
    final buffer = StringBuffer('§ {$_block}\n');

    for (final child in block.children) {
      final tree = child.isLast ? '└' : '├';

      buffer.write('  $tree $child');

      if (!child.isLast) {
        buffer.writeln();
      }
    }

    return buffer.toString();
  }

  void mergeSimilarStyleNodes(BlockM block) {
    if (block.isEmpty) {
      final sibling = block.previous;
      block.unlink();

      if (sibling != null) {
        _nodeUtils.mergeSimilarStyleNodes(sibling);
      }

      return;
    }

    final prev = block.previous;

    // Merging it with previous block if style is the same
    if (!block.isFirst &&
        block.previous is BlockM &&
        prev!.style == block.style) {
      final _prev = prev as ContainerM<NodeM?>?;

      _contUtils.moveChildToNewParent(block, _prev);
      block.unlink();
      block = prev as BlockM;
    }

    final next = block.next;
    // merging it with next block if style is the same

    if (!block.isLast && block.next is BlockM && next!.style == block.style) {
      _contUtils.moveChildToNewParent(next as BlockM, block);
      next.unlink();
    }
  }
}
