import 'package:flutter/material.dart';

import '../../../controller/controllers/editor-controller.dart';
import '../../../document/models/nodes/embed-node.model.dart';
import '../../../shared/state/editor.state.dart';
import '../../const/embeds.const.dart';
import '../../models/embed-builder.model.dart';
import '../../widgets/video-app.dart';
import '../../widgets/youtube-video-app.dart';

// Default builder for video embeds.
// Note there are 2 types of video players:
// youtube video player and an all purpose video player
class VideoEmbedBuilder implements EmbedBuilderM {
  final EditorState _state;

  const VideoEmbedBuilder(this._state);

  @override
  final String type = VIDEO_EMBED_TYPE;

  @override
  Widget build(
    BuildContext context,
    EditorController controller,
    EmbedNodeM embed,
    bool readOnly,
  ) {
    final _videoUrl = embed.value.payload;
    final _isYoutubeVideo =
        _videoUrl.contains('youtube.com') || _videoUrl.contains('youtu.be');

    if (_isYoutubeVideo) {
      return YoutubeVideoApp(
        videoUrl: _videoUrl,
        context: context,
        readOnly: readOnly,
        state: _state,
      );
    }

    return VideoApp(
      videoUrl: _videoUrl,
      context: context,
      readOnly: readOnly,
      state: _state,
    );
  }
}
