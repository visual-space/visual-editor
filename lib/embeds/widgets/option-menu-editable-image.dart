import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../controller/controllers/editor-controller.dart';
import '../../document/models/attributes/styling-attributes.dart';
import '../../editor/services/editor.service.dart';
import '../../inputs/services/clipboard.service.dart';
import '../../shared/state/editor-state-receiver.dart';
import '../../shared/state/editor.state.dart';
import '../../shared/translations/toolbar.i18n.dart';
import '../../shared/utils/string.utils.dart';
import '../../styles/services/styles.service.dart';
import '../models/content-size.model.dart';
import '../models/image.model.dart';
import '../services/embeds.service.dart';
import '../services/media-loader.service.dart';
import 'image-resizer.dart';
import 'simple-dialog-item.dart';

// Option menu for editable images that can: resize, copy or remove the image
// ignore: must_be_immutable
class OptionMenuEditableImage extends StatelessWidget implements EditorStateReceiver {
  late final EditorService _editorService;
  late final ClipboardService _clipboardService;
  late final StylesService _stylesService;
  late final MediaLoaderService _mediaLoaderService;
  late final EmbedsService _embedsService;

  final EditorController controller;
  final Widget child;
  late EditorState _state;

  OptionMenuEditableImage({
    required this.controller,
    required this.child,
    Key? key,
  }) : super(key: key) {
    controller.setStateInEditorStateReceiver(this);
    _editorService = EditorService(_state);
    _clipboardService = ClipboardService(_state);
    _stylesService = StylesService(_state);
    _mediaLoaderService = MediaLoaderService(_state);
    _embedsService = EmbedsService(_state);
  }

  @override
  void cacheStateStore(EditorState state) {
    _state = state;
  }

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
                  final res = _embedsService.getEmbedOffset();
                  final attr = replaceStyleString(
                    _mediaLoaderService.getImageStyleString(),
                    width,
                    height,
                  );
                  final style = StyleAttributeM(attr);

                  _stylesService.formatTextRange(res.offset, 1, style);
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
          final imgNode = _embedsService.getEmbedOffset().embed;
          final imgUrl = imgNode.value.payload;
          final imgStyle = _mediaLoaderService.getImageStyleString();
          final image = ImageM(imgUrl, imgStyle);

          _clipboardService.setCopiedImageUrl(image);

          Navigator.pop(context);
        },
      );

  Widget _removeDialogItem(BuildContext context) => SimpleDialogItem(
        icon: Icons.delete_forever_outlined,
        color: Colors.red.shade200,
        text: 'Remove'.i18n,
        onPressed: () {
          final offset = _embedsService.getEmbedOffset().offset;
          final newSelection = TextSelection.collapsed(offset: offset);

          _editorService.replace(offset, 1, '', newSelection);
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
