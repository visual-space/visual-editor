import 'dart:convert';
import 'dart:io' as io;
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:string_validator/string_validator.dart';
import 'package:tuple/tuple.dart';

import '../../controller/services/editor-controller.dart';
import '../../documents/models/attribute.model.dart';
import '../../documents/models/nodes/embed.model.dart';
import '../../documents/models/style.model.dart';
import '../const/image-file-extensions.const.dart';

bool isImageBase64(String imageUrl) {
  return !imageUrl.startsWith('http') && isBase64(imageUrl);
}

Tuple2<int, EmbedM> getImageNode(EditorController controller, int offset) {
  var offset = controller.selection.start;
  var imageNode = controller.queryNode(offset);
  if (imageNode == null || !(imageNode is EmbedM)) {
    offset = max(0, offset - 1);
    imageNode = controller.queryNode(offset);
  }
  if (imageNode != null && imageNode is EmbedM) {
    return Tuple2(offset, imageNode);
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
