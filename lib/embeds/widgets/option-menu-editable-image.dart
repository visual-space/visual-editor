import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../controller/controllers/editor-controller.dart';
import '../../documents/models/attributes/styling-attributes.dart';
import '../../shared/translations/toolbar.i18n.dart';
import '../../shared/utils/string.utils.dart';
import '../models/content-size.model.dart';
import '../models/image.model.dart';
import '../services/embed.utils.dart';
import '../services/image.utils.dart';
import 'image-resizer.dart';
import 'simple-dialog-item.dart';

// Option menu for editable images that can: resize, copy or remove the image
class OptionMenuEditableImage extends StatelessWidget {
  final _imageUtils = ImageUtils();
  final _embedUtils = EmbedUtils();

  final EditorController controller;
  final Widget child;

  OptionMenuEditableImage({
    required this.controller,
    required this.child,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () => showDialog(
          context: context,
          builder: (context) => _dialog(
            children: [
              _resizeDialogItem(context),
              _copyDialogItem(context),
              _removeDialogItem(context),
            ],
          ),
        ),
        child: child,
      );

  Widget _dialog({required List<Widget> children}) => Padding(
        padding: const EdgeInsets.fromLTRB(50, 0, 50, 0),
        child: SimpleDialog(
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(10)),
            ),
            children: children),
      );

  Widget _resizeDialogItem(BuildContext context) => SimpleDialogItem(
        icon: Icons.settings_outlined,
        color: Colors.lightBlueAccent,
        text: 'Resize'.i18n,
        onPressed: () {
          Navigator.pop(context);
          showCupertinoModalPopup<void>(
            context: context,
            builder: (context) {
              final _screenSize = MediaQuery.of(context).size;
              final _imageSize = _getImageSize();

              return ImageResizer(
                onImageResize: (width, height) {
                  final res = _embedUtils.getEmbedOffset(
                    controller: controller,
                  );
                  final attr = replaceStyleString(
                    _imageUtils.getImageStyleString(controller),
                    width,
                    height,
                  );
                  controller.formatText(
                    res.offset,
                    1,
                    StyleAttributeM(attr),
                  );
                },
                imageWidth: _imageSize.width,
                imageHeight: _imageSize.height,
                maxWidth: _screenSize.width,
                maxHeight: _screenSize.height,
              );
            },
          );
        },
      );

  Widget _copyDialogItem(BuildContext context) => SimpleDialogItem(
        icon: Icons.copy_all_outlined,
        color: Colors.cyanAccent,
        text: 'Copy'.i18n,
        onPressed: () {
          final imageNode = _embedUtils
              .getEmbedOffset(
                controller: controller,
              )
              .embed;

          final imageUrl = imageNode.value.payload;

          controller.copiedImageUrl = ImageM(
            imageUrl,
            _imageUtils.getImageStyleString(controller),
          );

          Navigator.pop(context);
        },
      );

  Widget _removeDialogItem(BuildContext context) => SimpleDialogItem(
        icon: Icons.delete_forever_outlined,
        color: Colors.red.shade200,
        text: 'Remove'.i18n,
        onPressed: () {
          final offset =
              _embedUtils.getEmbedOffset(controller: controller).offset;

          controller.replaceText(
            offset,
            1,
            '',
            TextSelection.collapsed(offset: offset),
          );

          Navigator.pop(context);
        },
      );

  ContentSizeM _getImageSize() {
    final _child = child;

    if (_child is Image && _child.width != null && _child.height != null) {
      return ContentSizeM(
        _child.width!,
        _child.height!,
      );
    } else {
      throw UnimplementedError(
        'Cannot get the size of the image.'
        'The child supplied is not compatible with the widget type Image.',
      );
    }
  }
}
