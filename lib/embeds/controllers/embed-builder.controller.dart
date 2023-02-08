import '../../document/models/nodes/embed-node.model.dart';
import '../models/embed-builder.model.dart';
import '../models/embed-builder.typedef.dart';

// Handles builder selection based on embed types.
// This class was built as a controller because it keeps the available embed builders as internal state.
class EmbedBuilderController {
  final List<EmbedBuilderM> builders;

  // Set the controller's embed builders list from the state of the editor config
  const EmbedBuilderController({required this.builders});

  EmbedsBuilder getBuilderByEmbed(EmbedNodeM embed) {
    // Selects the builder based on the type of the embed.
    // Compares the key of the embed with the keys of the submitted embed builders.
    for (final builder in builders) {
      if (builder.type == embed.value.type) {
        return builder.build;
      }
    }

    // No embed builder match
    throw UnimplementedError(
      'Embed of type "${embed.value.type}" is not supported by the supplied embed builders. '
      'You must pass your own builder function to embedBuilders property of VisualEditor.',
    );
  }
}
