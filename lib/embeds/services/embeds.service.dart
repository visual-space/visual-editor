import 'dart:math';

import '../../document/models/nodes/embed-node.model.dart';
import '../../document/models/nodes/embed.model.dart';
import '../../editor/services/editor.service.dart';
import '../../selection/services/selection.service.dart';
import '../../shared/state/editor.state.dart';
import '../const/embeds.const.dart';
import '../controllers/embed-builder.controller.dart';
import '../models/embed-offset.model.dart';
import 'builders/image-embed.builder.dart';
import 'builders/video-embed.builder.dart';

// Provides methods to insert various embeds in the document
class EmbedsService {
  late final EditorService _editorService;
  late final SelectionService _selectionService;

  final EditorState state;

  EmbedsService(this.state) {
    _editorService = EditorService(state);
    _selectionService = SelectionService(state);
  }

  // Initialises the embed builder controller with the default types (image. video).
  // The controller reference is stored in the state store for easy access.
  // Custom embed builders can be provided.
  void initAndCacheEmbedBuilderController() {
    final overrides = state.config.overrideEmbedBuilders;
    final image = overrides?.image ?? ImageEmbedBuilder(state);
    final video = overrides?.video ?? VideoEmbedBuilder(state);
    final custom = state.config.customEmbedBuilders;

    state.refs.embedBuilderController = EmbedBuilderController(
      builders: [image, video, ...custom],
    );
  }

  void insertInSelectionImageViaUrl(String? imageUrl) {
    if (imageUrl != null && imageUrl.isNotEmpty) {
      final selection = _selectionService.selection;
      final index = selection.baseOffset;
      final length = selection.extentOffset - index;
      final image = EmbedM(IMAGE_EMBED_TYPE, imageUrl);

      _editorService.replace(index, length, image, null);
    }
  }

  void insertInSelectionVideoViaUrl(String? videoUrl) {
    if (videoUrl != null && videoUrl.isNotEmpty) {
      final selection = _selectionService.selection;
      final index = selection.baseOffset;
      final length = selection.extentOffset - index;

      _editorService.replace(
        index,
        length,
        EmbedM(VIDEO_EMBED_TYPE, videoUrl),
        null,
      );
    }
  }

  // TODO Document and review if it would be useful to add it to the controller public API.
  EmbedOffsetM getEmbedOffset() {
    var offset = _selectionService.selection.start;
    var embedNode = _editorService.queryNode(offset).leaf;

    if (embedNode == null || !(embedNode is EmbedNodeM)) {
      offset = max(0, offset - 1);
      embedNode = _editorService.queryNode(offset).leaf;
    }

    if (embedNode != null && embedNode is EmbedNodeM) {
      return EmbedOffsetM(
        offset: offset,
        embed: embedNode,
      );
    }

    return throw 'Embed node not found by offset $offset';
  }
}
