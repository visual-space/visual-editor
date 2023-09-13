import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:path/path.dart';

import '../../shared/state/editor.state.dart';
import '../../shared/translations/toolbar.i18n.dart';
import '../services/media-loader.service.dart';
import 'image-tap-wrapper.dart';
import 'simple-dialog-item.dart';

// TODO: TEST ON MOBILE
// Dialog for image read only that can save the image or zoom on the image.
class OptionMenuForReadOnlyImage extends StatelessWidget {
  late final MediaLoaderService _mediaLoaderService;

  final String imageUrl;
  final Widget child;

  OptionMenuForReadOnlyImage({
    required EditorState state,
    required this.imageUrl,
    required this.child,
    Key? key,
  }) : super(key: key) {
    _mediaLoaderService = MediaLoaderService(state);
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () => showDialog(
          context: context,
          builder: (context) => _dialog(
            children: [
              _saveDialogItem(context),
              _zoomDialogItem(context),
            ],
          ),
        ),
        child: child,
      );

  Widget _dialog({required List<Widget> children}) => Padding(
        padding: const EdgeInsets.fromLTRB(50, 0, 50, 0),
        child: SimpleDialog(
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(
              Radius.circular(10),
            ),
          ),
          children: children,
        ),
      );

  Widget _saveDialogItem(BuildContext context) => SimpleDialogItem(
        icon: Icons.save,
        color: Colors.greenAccent,
        text: 'Save'.i18n,
        onPressed: () async {
          // Function for checking if the given image url is a local file or a link from the web.
          // Logic is the same as from `gallery_saver` in https://github.com/CarnegieTechnologies/gallery_saver/blob/45017dbf88bebe785f498f0ddfb30d75409c436e/lib/files.dart#L23-L27.
          bool isLocalFilePath(String path) {
            final uri = Uri.parse(path);
            return !uri.scheme.contains('http');
          }

          // Get image path or URL input
          final _imageUrl = _mediaLoaderService.appendFileExtensionToImageUrl(
            imageUrl,
          );

          // Define image path directory where the image will be saved into
          final imagePath = '${Directory.systemTemp.path}/${basename(_imageUrl)}';

          try {
            // We check if the path is a local file path. If so, we only save it to the gallery.
            if (isLocalFilePath(_imageUrl)) {
              await Gal.putImage(imagePath);
            }
            // If it's an URL, we need to download it locally and save it afterwards
            else {
              await Dio().download(_imageUrl, imagePath);
              await Gal.putImage(imagePath);
            }

            // Show a snackbar stating the image was successfully saved
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Saved'.i18n),
              ),
            );
            Navigator.pop(context);
          } catch (e) {
            // TODO: handle error properly
            print(e);
          }
        },
      );

  Widget _zoomDialogItem(BuildContext context) => SimpleDialogItem(
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
}
