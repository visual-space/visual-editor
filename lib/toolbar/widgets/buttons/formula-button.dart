import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../controller/controllers/editor-controller.dart';
import '../../../documents/models/nodes/block-embed.model.dart';
import '../../../shared/models/editor-dialog-theme.model.dart';
import '../../../shared/models/editor-icon-theme.model.dart';
import '../../models/media-pick.enum.dart';
import '../../models/media-picker.type.dart';
import '../dialogs/link-dialog.dart';
import '../toolbar.dart';

class FormulaButton extends StatelessWidget {
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
  final double buttonsSpacing;

  const FormulaButton({
    required this.icon,
    required this.controller,
    required this.buttonsSpacing,
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
      icon: Icon(
        icon,
        size: iconSize,
        color: iconColor,
      ),
      buttonsSpacing: buttonsSpacing,
      highlightElevation: 0,
      hoverElevation: 0,
      size: iconSize * 1.77,
      fillColor: iconFillColor,
      borderRadius: iconTheme?.borderRadius ?? 2,
      onPressed: () => _onPressedHandler(context),
    );
  }

  Future<void> _onPressedHandler(BuildContext context) async {
    final index = controller.selection.baseOffset;
    final length = controller.selection.extentOffset - index;

    controller.replaceText(index, length, BlockEmbedM.formula(''), null);
  }
}
