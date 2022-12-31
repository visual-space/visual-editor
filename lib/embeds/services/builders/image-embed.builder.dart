import 'package:flutter/cupertino.dart';

import '../../../controller/controllers/editor-controller.dart';
import '../../../documents/models/attribute.model.dart';
import '../../../documents/models/attributes/attributes.model.dart';
import '../../../documents/models/nodes/embed-node.model.dart';
import '../../../shared/utils/platform.utils.dart';
import '../../../shared/utils/string.utils.dart';
import '../../const/embeds.const.dart';
import '../../models/embed-builder.model.dart';
import '../../services/image.utils.dart';
import '../../widgets/option-menu-editable-image.dart';
import '../../widgets/option-menu-for-readonly-image.dart';

// Default embed builder for image embeds
class ImageEmbedBuilder implements EmbedBuilderM {
  const ImageEmbedBuilder();

  @override
  final String type = IMAGE_EMBED_TYPE;

  @override
  Widget build(
    BuildContext context,
    EditorController controller,
    EmbedNodeM embed,
    bool readOnly,
  ) {
    final imageUtils = ImageUtils();
    late Widget image;
    final imageUrl = imageUtils.standardizeImageUrl(embed.value.payload);
    final style = embed.style.attributes?['style'];

    if (isMobile() && style != null) {
      final _attributes = _getAttributes(style);

      if (_attributes.isNotEmpty) {
        image = _getStyledImage(
          attributes: _attributes,
          imageUrl: imageUrl,
        );
      }
    } else {
      // When NO attributes are present we get the content size from the widget itself
      image = imageUtils.getImageByUrl(imageUrl);
    }

    if (!readOnly && isMobile()) {
      return OptionMenuEditableImage(
        controller: controller,
        child: image,
      );
    }

    final _isImageBase64 = imageUtils.isImageBase64(imageUrl);

    if (!readOnly || !isMobile() || _isImageBase64) {
      return image;
    }

    // We provide option menu for mobile platforms excluding base64 images
    return OptionMenuForReadOnlyImage(
      imageUrl: imageUrl,
      child: image,
    );
  }

  Widget _getStyledImage({
    required Map<String, String> attributes,
    required String imageUrl,
  }) {
    final _imageUtils = ImageUtils();

    // We force the image to have a certain size, margins or alignments
    assert(
      attributes[AttributesM.mobileWidth] != null &&
          attributes[AttributesM.mobileHeight] != null,
      'mobileWidth and mobileHeight must be specified',
    );

    final width = double.parse(attributes[AttributesM.mobileWidth]!);
    final height = double.parse(attributes[AttributesM.mobileHeight]!);

    final padding = attributes[AttributesM.mobileMargin] == null
        ? 0.0
        : double.parse(attributes[AttributesM.mobileMargin]!);

    final alignment = _getAlignment(
      attributes[AttributesM.mobileAlignment],
    );

    return Padding(
      padding: EdgeInsets.all(padding),
      child: _imageUtils.getImageByUrl(
        imageUrl,
        width: width,
        height: height,
        alignment: alignment,
      ),
    );
  }

  Map<String, String> _getAttributes(AttributeM<dynamic> style) =>
      parseKeyValuePairs(
        style.value.toString(),
        {
          AttributesM.mobileWidth,
          AttributesM.mobileHeight,
          AttributesM.mobileMargin,
          AttributesM.mobileAlignment
        },
      );

  Alignment _getAlignment(String? string) {
    const defaultAlignment = Alignment.center;

    if (string == null) {
      return defaultAlignment;
    }

    final index = [
      'topLeft',
      'topCenter',
      'topRight',
      'centerLeft',
      'center',
      'centerRight',
      'bottomLeft',
      'bottomCenter',
      'bottomRight',
    ].indexOf(string);

    if (index < 0) {
      return defaultAlignment;
    }

    return [
      Alignment.topLeft,
      Alignment.topCenter,
      Alignment.topRight,
      Alignment.centerLeft,
      Alignment.center,
      Alignment.centerRight,
      Alignment.bottomLeft,
      Alignment.bottomCenter,
      Alignment.bottomRight,
    ][index];
  }
}
