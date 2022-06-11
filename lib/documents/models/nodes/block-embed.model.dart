import 'embeddable.model.dart';

// There are two built-in embed types supported by Quill documents, however the document models itself does not make
// any assumptions about the types of embedded objects and allows users to define their own types.
class BlockEmbedM extends EmbeddableM {
  const BlockEmbedM(String type, String data) : super(type, data);

  static const String imageType = 'image';

  static BlockEmbedM image(String imageUrl) => BlockEmbedM(imageType, imageUrl);

  static const String videoType = 'video';

  static BlockEmbedM video(String videoUrl) => BlockEmbedM(videoType, videoUrl);
}
