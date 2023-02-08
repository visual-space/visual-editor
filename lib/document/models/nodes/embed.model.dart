import '../../services/nodes/embed.utils.dart';

final _embedUtils = EmbedUtils();

// EmbedM is data which can be decoded or encoded into a delta document.
// Provides a standard model to insert and retrieve embeddable data from the document.
// Read EmbedNodeM comment for the whole explanation.
class EmbedM {
  // The type of this object.
  final String type;

  // The data payload of this object.
  final dynamic payload;

  const EmbedM(this.type, [
    this.payload = '',
  ]);

  // Used for explicit type conversion
  factory EmbedM.fromObject(Object? obj) => _embedUtils.fromObject(obj);

  Map<String, dynamic> toJson() =>
      {
        type: payload,
      };
}
