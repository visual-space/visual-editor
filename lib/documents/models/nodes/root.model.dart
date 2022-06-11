import '../../../delta/models/delta.model.dart';
import 'container.model.dart';
import 'line.model.dart';
import 'node.model.dart';

// Root node of document tree.
class RootM extends ContainerM<ContainerM<NodeM?>> {
  @override
  NodeM newInstance() => RootM();

  @override
  ContainerM<NodeM?> get defaultChild => LineM();

  @override
  DeltaM toDelta() => children
      .map((child) => child.toDelta())
      .fold(DeltaM(), (a, b) => a.concat(b));
}
