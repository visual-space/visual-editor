import 'dart:convert';
import 'dart:io' as io;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:string_validator/string_validator.dart';

import '../../document/models/attributes/attributes.model.dart';
import '../../document/models/nodes/embed.model.dart';
import '../../document/models/nodes/style.model.dart';
import '../../editor/services/editor.service.dart';
import '../../selection/services/selection.service.dart';
import '../../shared/state/editor.state.dart';
import '../../shared/translations/toolbar.i18n.dart';
import '../../shared/utils/platform.utils.dart';
import '../../styles/services/styles.service.dart';
import '../../toolbar/models/media-pick.enum.dart';
import '../../toolbar/models/media-picker.type.dart';
import '../const/embeds.const.dart';
import '../const/image-file-extensions.const.dart';

// Handles loading of images and videos.
class MediaLoaderService {
  late final SelectionService _selectionService;
  late final EditorService _editorService;
  late final StylesService _stylesService;

  final EditorState state;

  MediaLoaderService(this.state) {
    _selectionService = SelectionService(state);
    _editorService = EditorService(state);
    _stylesService = StylesService(state);
  }

  bool isImageBase64(String imageUrl) {
    return !imageUrl.startsWith('http') && isBase64(imageUrl);
  }

  String getImageStyleString() {
    final String? styles = _stylesService
        .getAllSelectionStyles()
        .firstWhere((s) => s.attributes.containsKey(AttributesM.style.key),
            orElse: () => StyleM())
        .attributes[AttributesM.style.key]
        ?.value;

    return styles ?? '';
  }

  Image getImageByUrl(
    String imageUrl, {
    double? width,
    double? height,
    AlignmentGeometry alignment = Alignment.center,
  }) {
    if (isImageBase64(imageUrl)) {
      return Image.memory(base64.decode(imageUrl),
          width: width, height: height, alignment: alignment);
    }

    if (imageUrl.startsWith('http')) {
      return Image.network(imageUrl,
          width: width, height: height, alignment: alignment);
    }

    return Image.file(io.File(imageUrl),
        width: width, height: height, alignment: alignment);
  }

  String standardizeImageUrl(String url) {
    if (url.contains('base64')) {
      return url.split(',')[1];
    }

    return url;
  }

  // This is a bug of Gallery Saver Package.
  // It can not save image that's filename does not end with it's file extension like below.
  // "https://firebasestorage.googleapis.com/v0/b/eventat-4ba96.appspot.com/o/
  // 2019-Metrology-Events.jpg?alt=media&token=bfc47032-5173-4b3f-86bb-9659f46b362a"
  // If imageUrl does not end with it's file extension, file extension is added to image url for saving.
  String appendFileExtensionToImageUrl(String url) {
    final endsWithImageFileExtension = imageFileExtensions
        .firstWhere((s) => url.toLowerCase().endsWith(s), orElse: () => '');

    if (endsWithImageFileExtension.isNotEmpty) {
      return url;
    }

    final imageFileExtension = imageFileExtensions
        .firstWhere((s) => url.toLowerCase().contains(s), orElse: () => '');

    return url + imageFileExtension;
  }

  Future<MediaPickSettingE?> selectMediaPickSetting(BuildContext context) =>
      showDialog<MediaPickSettingE>(
        context: context,
        builder: (ctx) => AlertDialog(
          contentPadding: EdgeInsets.zero,
          backgroundColor: Colors.transparent,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton.icon(
                icon: const Icon(
                  Icons.collections,
                  color: Colors.orangeAccent,
                ),
                label: Text('Gallery'.i18n),
                onPressed: () => Navigator.pop(ctx, MediaPickSettingE.Gallery),
              ),
              TextButton.icon(
                icon: const Icon(
                  Icons.link,
                  color: Colors.cyanAccent,
                ),
                label: Text('Link'.i18n),
                onPressed: () => Navigator.pop(ctx, MediaPickSettingE.Link),
              )
            ],
          ),
        ),
      );

  // For image picking logic
  Future<void> pickImage(
    BuildContext context,
    ImageSource imageSource,
    OnImagePickCallback onImagePickCallback, {
    FilePickImpl? filePickImpl,
    WebImagePickImpl? webImagePickImpl,
  }) async {
    final index = _selectionService.selection.baseOffset;
    final length = _selectionService.selection.extentOffset - index;
    String? imageUrl;

    if (kIsWeb) {
      assert(
        webImagePickImpl != null,
        'Please provide webImagePickImpl for Web (check out example directory for how to do it)',
      );
      imageUrl = await webImagePickImpl!(onImagePickCallback);
    } else if (isMobile()) {
      imageUrl = await _pickImage(
        imageSource,
        onImagePickCallback,
      );
    } else {
      assert(filePickImpl != null, 'Desktop must provide filePickImpl');
      imageUrl = await _pickImageDesktop(
        context,
        filePickImpl!,
        onImagePickCallback,
      );
    }

    if (imageUrl != null) {
      final embed = EmbedM(IMAGE_EMBED_TYPE, imageUrl);
      _editorService.replaceText(index, length, embed, null);
    }
  }

  // For video picking logic
  Future<void> insertVideo(
    BuildContext context,
    ImageSource videoSource,
    OnVideoPickCallback onVideoPickCallback, {
    FilePickImpl? filePickImpl,
    WebVideoPickImpl? webVideoPickImpl,
  }) async {
    final index = _selectionService.selection.baseOffset;
    final length = _selectionService.selection.extentOffset - index;

    String? videoUrl;
    if (kIsWeb) {
      assert(
        webVideoPickImpl != null,
        'Please provide webVideoPickImpl for Web (check out example directory for how to do it)',
      );

      videoUrl = await webVideoPickImpl!(onVideoPickCallback);
    } else if (isMobile()) {
      videoUrl = await _pickVideo(videoSource, onVideoPickCallback);
    } else {
      assert(filePickImpl != null, 'Desktop must provide filePickImpl');

      videoUrl = await _pickVideoDesktop(
        context,
        filePickImpl!,
        onVideoPickCallback,
      );
    }

    if (videoUrl != null) {
      final embed = EmbedM(VIDEO_EMBED_TYPE, videoUrl);
      _editorService.replaceText(index, length, embed, null);
    }
  }

  // === PRIVATE ===

  static Future<String?> _pickImage(
    ImageSource source,
    OnImagePickCallback onImagePickCallback,
  ) async {
    final pickedFile = await ImagePicker().pickImage(source: source);

    if (pickedFile == null) {
      return null;
    }

    return onImagePickCallback(
      io.File(pickedFile.path),
    );
  }

  static Future<String?> _pickImageDesktop(
    BuildContext context,
    FilePickImpl filePickImpl,
    OnImagePickCallback onImagePickCallback,
  ) async {
    final filePath = await filePickImpl(context);

    if (filePath == null || filePath.isEmpty) {
      return null;
    }

    final file = io.File(filePath);

    return onImagePickCallback(file);
  }

  static Future<String?> _pickVideo(
    ImageSource source,
    OnVideoPickCallback onVideoPickCallback,
  ) async {
    final pickedFile = await ImagePicker().pickVideo(source: source);

    if (pickedFile == null) {
      return null;
    }

    return onVideoPickCallback(
      io.File(pickedFile.path),
    );
  }

  static Future<String?> _pickVideoDesktop(
    BuildContext context,
    FilePickImpl filePickImpl,
    OnVideoPickCallback onVideoPickCallback,
  ) async {
    final filePath = await filePickImpl(context);

    if (filePath == null || filePath.isEmpty) {
      return null;
    }

    final file = io.File(filePath);

    return onVideoPickCallback(file);
  }
}
