import 'package:flutter/cupertino.dart';

import '../services/builders/image-embed.builder.dart';
import '../services/builders/video-embed.builder.dart';

// The editor supports by default several embed types.
@immutable
class DefaultEmbedBuilders {
  final ImageEmbedBuilder? image;
  final VideoEmbedBuilder? video;

  DefaultEmbedBuilders({
    this.image,
    this.video,
  });
}
