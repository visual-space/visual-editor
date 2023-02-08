import '../../models/delta/delta.model.dart';
import '../../models/nodes/root.model.dart';
import '../delta.utils.dart';
import 'node.utils.dart';

final _du = DeltaUtils();
final _nodeUtils = NodeUtils();

class RootUtils {
  DeltaM toDelta(RootM root) =>
      root.children.map(_nodeUtils.toDelta).fold(DeltaM(), _du.concat);
}
