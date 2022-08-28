import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:flutter/services.dart';

import '../../controller/controllers/editor-controller.dart';
import '../../documents/models/attribute.model.dart';
import '../../documents/models/nodes/block-embed.model.dart';
import '../../documents/models/nodes/embed.model.dart';
import '../../documents/models/styling-attributes.dart';
import '../../shared/translations/toolbar.i18n.dart';
import '../../shared/utils/platform.utils.dart';
import '../../shared/utils/string.utils.dart';
import '../models/content-size.model.dart';
import '../models/image.model.dart';
import '../services/image.utils.dart';
import 'image-resizer.dart';
import 'image-tap-wrapper.dart';
import 'simple-dialog-item.dart';
import 'video-app.dart';
import 'youtube-video-app.dart';

Widget defaultEmbedBuilder(
  BuildContext context,
  EditorController controller,
  EmbedM node,
  bool readOnly,
) {
  assert(!kIsWeb, 'Please provide EmbedBuilder for Web');
  ContentSizeM? _widthHeight;

  switch (node.value.type) {
    case BlockEmbedM.imageType:
      final imageUrl = standardizeMediaUrl(node.value.data);
      var image;
      final style = node.style.attributes['style'];

      if (isMobile() && style != null) {
        final _attrs = parseKeyValuePairs(
          style.value.toString(),
          {
            AttributeM.mobileWidth,
            AttributeM.mobileHeight,
            AttributeM.mobileMargin,
            AttributeM.mobileAlignment
          },
        );

        if (_attrs.isNotEmpty) {
          assert(
              _attrs[AttributeM.mobileWidth] != null &&
                  _attrs[AttributeM.mobileHeight] != null,
              'mobileWidth and mobileHeight must be specified');

          final w = double.parse(_attrs[AttributeM.mobileWidth]!);
          final h = double.parse(_attrs[AttributeM.mobileHeight]!);
          _widthHeight = ContentSizeM(w, h);
          final m = _attrs[AttributeM.mobileMargin] == null
              ? 0.0
              : double.parse(_attrs[AttributeM.mobileMargin]!);
          final a = getAlignment(_attrs[AttributeM.mobileAlignment]);

          image = Padding(
            padding: EdgeInsets.all(m),
            child: imageByUrl(
              imageUrl,
              width: w,
              height: h,
              alignment: a,
            ),
          );
        }
      }

      if (_widthHeight == null) {
        image = imageByUrl(imageUrl);
        _widthHeight = ContentSizeM(
          (image as Image).width,
          image.height,
        );
      }

      if (!readOnly && isMobile()) {
        return GestureDetector(
          onTap: () {
            showDialog(
                context: context,
                builder: (context) {
                  final resizeOption = SimpleDialogItem(
                    icon: Icons.settings_outlined,
                    color: Colors.lightBlueAccent,
                    text: 'Resize'.i18n,
                    onPressed: () {
                      Navigator.pop(context);
                      showCupertinoModalPopup<void>(
                        context: context,
                        builder: (context) {
                          final _screenSize = MediaQuery.of(context).size;
                          return ImageResizer(
                            onImageResize: (width, height) {
                              final res = getImageNode(
                                controller,
                                controller.selection.start,
                              );
                              final attr = replaceStyleString(
                                getImageStyleString(controller),
                                width,
                                height,
                              );
                              controller.formatText(
                                res.offset,
                                1,
                                StyleAttributeM(attr),
                              );
                            },
                            imageWidth: _widthHeight?.width,
                            imageHeight: _widthHeight?.height,
                            maxWidth: _screenSize.width,
                            maxHeight: _screenSize.height,
                          );
                        },
                      );
                    },
                  );

                  final copyOption = SimpleDialogItem(
                    icon: Icons.copy_all_outlined,
                    color: Colors.cyanAccent,
                    text: 'Copy'.i18n,
                    onPressed: () {
                      final imageNode = getImageNode(
                        controller,
                        controller.selection.start,
                      ).imageNode;
                      final imageUrl = imageNode.value.data;
                      controller.copiedImageUrl = ImageM(
                        imageUrl,
                        getImageStyleString(controller),
                      );
                      Navigator.pop(context);
                    },
                  );

                  final removeOption = SimpleDialogItem(
                    icon: Icons.delete_forever_outlined,
                    color: Colors.red.shade200,
                    text: 'Remove'.i18n,
                    onPressed: () {
                      final offset = getImageNode(
                        controller,
                        controller.selection.start,
                      ).offset;
                      controller.replaceText(
                        offset,
                        1,
                        '',
                        TextSelection.collapsed(offset: offset),
                      );
                      Navigator.pop(context);
                    },
                  );

                  return Padding(
                    padding: const EdgeInsets.fromLTRB(50, 0, 50, 0),
                    child: SimpleDialog(
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                      ),
                      children: [resizeOption, copyOption, removeOption],
                    ),
                  );
                });
          },
          child: image,
        );
      }

      if (!readOnly || !isMobile() || isImageBase64(imageUrl)) {
        return image;
      }

      // We provide option menu for mobile platform excluding base64 image
      return _menuOptionsForReadonlyImage(context, imageUrl, image);

    case BlockEmbedM.videoType:
      final videoUrl = standardizeMediaUrl(node.value.data);

      if (videoUrl.contains('youtube.com') || videoUrl.contains('youtu.be')) {
        return YoutubeVideoApp(
          videoUrl: videoUrl,
          context: context,
          readOnly: readOnly,
        );
      }

      return VideoApp(
        videoUrl: videoUrl,
        context: context,
        readOnly: readOnly,
      );

    case BlockEmbedM.formulaType:
      final formula = node.value.data;
      final style = node.style.attributes['style'];
      print(node.style);
      return Math.tex(formula, textStyle: Theme.of(context).textTheme.subtitle1);


    default:
      // Throwing an error here does not help at all.
      // Even when there's only one Operation with a video attribute in the
      // whole doc it will be flushed away from the console by a large callstack.
      // The error that gets printed on repeat will flood the terminal filling up the entire
      // buffer with a message that is completely  misleading.
      // By rendering this text we can save countless hours of searching for the origin of the bug.
      // ignore: avoid_print
      print(
        'Embeddable type "${node.value.type}" is not supported by default web'
        'embed builder of VisualEditor. You must pass your own builder function '
        'to embedBuilder property of VisualEditor or EditorField widgets.',
      );

      return const SizedBox.shrink();
  }
}

Widget _menuOptionsForReadonlyImage(
  BuildContext context,
  String imageUrl,
  Widget image,
) {
  return GestureDetector(
    onTap: () {
      showDialog(
          context: context,
          builder: (context) {
            final saveOption = SimpleDialogItem(
              icon: Icons.save,
              color: Colors.greenAccent,
              text: 'Save'.i18n,
              onPressed: () {
                imageUrl = appendFileExtensionToImageUrl(imageUrl);
                GallerySaver.saveImage(imageUrl).then((_) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text('Saved'.i18n)));
                  Navigator.pop(context);
                });
              },
            );

            final zoomOption = SimpleDialogItem(
              icon: Icons.zoom_in,
              color: Colors.cyanAccent,
              text: 'Zoom'.i18n,
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ImageTapWrapper(
                      imageUrl: imageUrl,
                    ),
                  ),
                );
              },
            );

            return Padding(
              padding: const EdgeInsets.fromLTRB(50, 0, 50, 0),
              child: SimpleDialog(
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                ),
                children: [saveOption, zoomOption],
              ),
            );
          });
    },
    child: image,
  );
}
