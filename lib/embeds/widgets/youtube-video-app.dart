import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import '../../shared/state/editor.state.dart';
import '../../styles/services/styles-cfg.service.dart';

class YoutubeVideoApp extends StatefulWidget {
  late final EditorState _state;

  YoutubeVideoApp({
    required this.videoUrl,
    required this.context,
    required this.readOnly,
    required EditorState state,
  }) {
    _state = state;
  }

  final String videoUrl;
  final BuildContext context;
  final bool readOnly;

  @override
  _YoutubeVideoAppState createState() => _YoutubeVideoAppState();
}

class _YoutubeVideoAppState extends State<YoutubeVideoApp> {
  late final StylesCfgService _stylesCfgService;

  var _youtubeController;

  @override
  void initState() {
    _stylesCfgService = StylesCfgService(widget._state);

    super.initState();
    final videoId = YoutubePlayer.convertUrlToId(widget.videoUrl);

    if (videoId != null) {
      _youtubeController = YoutubePlayerController(
        initialVideoId: videoId,
        flags: const YoutubePlayerFlags(
          autoPlay: false,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // TODO Use from state
    final defaultStyles = _stylesCfgService.getDefaultStyles(context);

    if (_youtubeController == null) {
      if (widget.readOnly) {
        return RichText(
          text: TextSpan(
            text: widget.videoUrl,
            style: defaultStyles.link,
            recognizer: TapGestureRecognizer()
              ..onTap = () => launchUrl(Uri.parse(widget.videoUrl)),
          ),
        );
      }

      return RichText(
        text: TextSpan(
          text: widget.videoUrl,
          style: defaultStyles.link,
        ),
      );
    }

    return Container(
      height: 300,
      child: YoutubePlayerBuilder(
        player: YoutubePlayer(
          controller: _youtubeController,
          showVideoProgressIndicator: true,
        ),
        builder: (context, player) {
          return Column(
            children: [
              // some widgets
              player,
              //some other widgets
            ],
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
    _youtubeController.dispose();
  }
}
