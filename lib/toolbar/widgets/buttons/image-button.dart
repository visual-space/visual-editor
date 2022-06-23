import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../controller/services/editor-controller.dart';
import '../../../documents/models/nodes/block-embed.model.dart';
import '../../../shared/models/editor-dialog-theme.model.dart';
import '../../../shared/models/editor-icon-theme.model.dart';
import '../../models/media-pick.enum.dart';
import '../../models/media-picker.type.dart';
import '../dialogs/link-dialog.dart';
import '../toolbar.dart';

class ImageButton extends StatelessWidget {
  final IconData icon;
  final double iconSize;
  final Color? fillColor;
  final EditorController controller;
  final OnImagePickCallback? onImagePickCallback;
  final WebImagePickImpl? webImagePickImpl;
  final FilePickImpl? filePickImpl;
  final MediaPickSettingSelector? mediaPickSettingSelector;
  final EditorIconThemeM? iconTheme;
  final EditorDialogThemeM? dialogTheme;

  const ImageButton({
    required this.icon,
    required this.controller,
    this.iconSize = defaultIconSize,
    this.onImagePickCallback,
    this.fillColor,
    this.filePickImpl,
    this.webImagePickImpl,
    this.mediaPickSettingSelector,
    this.iconTheme,
    this.dialogTheme,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final iconColor = iconTheme?.iconUnselectedColor ?? theme.iconTheme.color;
    final iconFillColor =
        iconTheme?.iconUnselectedFillColor ?? (fillColor ?? theme.canvasColor);

    return IconBtn(
      icon: Icon(icon, size: iconSize, color: iconColor),
      highlightElevation: 0,
      hoverElevation: 0,
      size: iconSize * 1.77,
      fillColor: iconFillColor,
      borderRadius: iconTheme?.borderRadius ?? 2,
      onPressed: () => _onPressedHandler(context),
    );
  }

  // === PRIVATE ===

  Future<void> _onPressedHandler(BuildContext context) async {
    if (onImagePickCallback != null) {
      final selector =
          mediaPickSettingSelector ?? ImageVideoUtils.selectMediaPickSetting;
      final source = await selector(context);
      if (source != null) {
        if (source == MediaPickSettingE.Gallery) {
          _pickImage(context);
        } else {
          _typeLink(context);
        }
      }
    } else {
      _typeLink(context);
    }
  }

  void _pickImage(BuildContext context) => ImageVideoUtils.handleImageButtonTap(
        context,
        controller,
        ImageSource.gallery,
        onImagePickCallback!,
        filePickImpl: filePickImpl,
        webImagePickImpl: webImagePickImpl,
      );

  void _typeLink(BuildContext context) {
    showDialog<String>(
      context: context,
      builder: (_) => LinkDialog(
        dialogTheme: dialogTheme,
      ),
    ).then(_linkSubmitted);
  }

  void _linkSubmitted(String? value) {
    if (value != null && value.isNotEmpty) {
      final index = controller.selection.baseOffset;
      final length = controller.selection.extentOffset - index;

      controller.replaceText(
        index,
        length,
        BlockEmbedM.image(value),
        null,
      );
    }
  }
}
