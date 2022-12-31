// EmbedM is data which can be decoded or encoded into a delta document.
// Provides a standard model to insert and retrieve embeddable data from the document.
// Read EmbedNodeM comment for the whole explanation.
class EmbedM {
  // The type of this object.
  final String type;

  // The data payload of this object.
  final dynamic payload;

  const EmbedM(
    this.type, [
    this.payload = '',
  ]);

  // Used for explicit type conversion
  factory EmbedM.fromObject(Object? obj) {
    if (obj is Map<String, dynamic>) {
      assert(obj.length == 1, 'Embeddable map must only have one key');

      return EmbedM(
        obj.keys.first,
        obj.values.first,
      );
    } else {
      throw UnimplementedError(
        '$obj is not compatible with type of Map<String, dynamic>.'
        'Cannot cast object $obj into EmbedM.',
      );
    }
  }

  Map<String, dynamic> toJson() => {
        type: payload,
      };
}
