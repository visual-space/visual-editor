import 'dart:convert';
import 'dart:io' as io;
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:string_validator/string_validator.dart';

import '../../controller/controllers/editor-controller.dart';
import '../../documents/models/attribute.model.dart';
import '../../documents/models/nodes/embed.model.dart';
import '../../documents/models/style.model.dart';
import '../const/image-file-extensions.const.dart';
import '../models/image-node.model.dart';

bool isImageBase64(String imageUrl) {
  return !imageUrl.startsWith('http') && isBase64(imageUrl);
}

ImageNodeM getImageNode(EditorController controller, int offset) {
  var offset = controller.selection.start;
  var imageNode = controller.queryNode(offset);
  if (imageNode == null || !(imageNode is EmbedM)) {
    offset = max(0, offset - 1);
    imageNode = controller.queryNode(offset);
  }
  if (imageNode != null && imageNode is EmbedM) {
    return ImageNodeM(offset, imageNode);
  }

  return throw 'Image node not found by offset $offset';
}

String getImageStyleString(EditorController controller) {
  final String? s = controller
      .getAllSelectionStyles()
      .firstWhere((s) => s.attributes.containsKey(AttributeM.style.key),
          orElse: () => StyleM())
      .attributes[AttributeM.style.key]
      ?.value;
  return s ?? '';
}

Image imageByUrl(String imageUrl,
    {double? width,
    double? height,
    AlignmentGeometry alignment = Alignment.center}) {
  if (isImageBase64(imageUrl)) {
    return Image.memory(base64.decode(imageUrl),
        width: width, height: height, alignment: alignment);
  }

  if (imageUrl.startsWith('http')) {
    return Image.network(
      imageUrl,
      width: width,
      height: height,
      alignment: alignment,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Center(
          child: CircularProgressIndicator(
            value: loadingProgress.expectedTotalBytes != null
                ? loadingProgress.cumulativeBytesLoaded /
                    loadingProgress.expectedTotalBytes!
                : null,
          ),
        );
      },
      errorBuilder: (context, exception, stackTrace) {
        return Row(
          children: [
            Icon(Icons.error, color: Colors.redAccent),
            SizedBox(width: 16),
            Text(exception.toString()),
          ],
        );
      },
    );
  }
  return Image.file(io.File(imageUrl),
      width: width, height: height, alignment: alignment);
}

String standardizeMediaUrl(String url) {
  if (url.contains('base64')) {
    return url.split(',')[1];
  }

  // Process image URL to embed.

  // Processes Google Drive image to correct format.
  if (url.contains('https://drive.google.com/file/d/')) {
    url = url.replaceAll(
        'https://drive.google.com/file/d/', 'https://drive.google.com/uc?id=');
  }

  // Changes Discord domain
  if (url.contains('cdn.discordapp.com')) {
    url = url.replaceAll('cdn.discordapp.com', 'media.discordapp.net');
  }

  // Uses CORS proxy for web
  if (kIsWeb) {
    return 'https://corsproxy.garvshah.workers.dev/?$url';
  } else {
    return url;
  }
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
