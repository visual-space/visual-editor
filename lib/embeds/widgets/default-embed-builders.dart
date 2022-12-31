import '../models/embed-builder.model.dart';
import '../services/builders/image-embed.builder.dart';
import '../services/builders/video-embed.builder.dart';

// All standard embeds will have a default embed builder that has to be present here.
// For now, image and video are the only standard embeds present in the editor.
const List<EmbedBuilderM> defaultEmbedBuilders = [
  ImageEmbedBuilder(),
  VideoEmbedBuilder(),
];
