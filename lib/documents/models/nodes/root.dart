import '../../../delta/models/delta.model.dart';
import 'container.dart';
import 'line.dart';
import 'node.dart';

// Root node of document tree.
class Root extends Container<Container<Node?>> {
  @override
  Node newInstance() => Root();

  @override
  Container<Node?> get defaultChild => Line();

  @override
  DeltaM toDelta() => children
      .map((child) => child.toDelta())
      .fold(DeltaM(), (a, b) => a.concat(b));
}
