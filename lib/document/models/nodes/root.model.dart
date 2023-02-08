import 'container.model.dart';
import 'line.model.dart';
import 'node.model.dart';

// Root node of document tree.
// Contains all the nodes that are generated out of the delta operations.
// Each Node is an fragment of text that has the same styling attributes.
class RootM extends ContainerM<ContainerM<NodeM?>> {
  @override
  NodeM newInstance() => RootM();

  @override
  ContainerM<NodeM?> get defaultChild => LineM();
}
