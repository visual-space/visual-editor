import '../../models/nodes/embed.model.dart';

class EmbedUtils {
  EmbedM fromObject(Object? obj) {
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
}
