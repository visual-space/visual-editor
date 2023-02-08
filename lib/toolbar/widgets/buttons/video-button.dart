import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../controller/controllers/editor-controller.dart';
import '../../../embeds/services/embeds.service.dart';
import '../../../shared/models/editor-dialog-theme.model.dart';
import '../../../shared/models/editor-icon-theme.model.dart';
import '../../../shared/state/editor-state-receiver.dart';
import '../../../shared/state/editor.state.dart';
import '../../models/media-pick.enum.dart';
import '../../models/media-picker.type.dart';
import '../dialogs/link-dialog.dart';
import '../toolbar.dart';

// Adds video in the document.
// ignore: must_be_immutable
class VideoButton extends StatelessWidget with EditorStateReceiver {
  late final EmbedsService _embedsService;
  late final MediaLoaderService _imageVideoUtils;

  final IconData icon;
  final double iconSize;
  final Color? fillColor;
  final EditorController controller;
  final OnVideoPickCallback? onVideoPickCallback;
  final WebVideoPickImpl? webVideoPickImpl;
  final FilePickImpl? filePickImpl;
  final MediaPickSettingSelector? mediaPickSettingSelector;
  final EditorIconThemeM? iconTheme;
  final EditorDialogThemeM? dialogTheme;
  final double buttonsSpacing;
  late EditorState _state;

  VideoButton({
    required this.icon,
    required this.controller,
    required this.buttonsSpacing,
    this.iconSize = defaultIconSize,
    this.onVideoPickCallback,
    this.fillColor,
    this.filePickImpl,
    this.webVideoPickImpl,
    this.mediaPickSettingSelector,
    this.iconTheme,
    this.dialogTheme,
    Key? key,
  }) : super(key: key) {
    controller.setStateInEditorStateReceiver(this);
    _embedsService = EmbedsService(_state);
    _imageVideoUtils = MediaLoaderService(_state);
  }

  @override
  void cacheStateStore(EditorState state) {
    _state = state;
  }

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
      highlightElevation: 0,
      buttonsSpacing: buttonsSpacing,
      hoverElevation: 0,
      size: iconSize * 1.77,
      fillColor: iconFillColor,
      borderRadius: iconTheme?.borderRadius ?? 2,
      onPressed: () => _insertVideo(context),
    );
  }

  // === PRIVATE ===

  Future<void> _insertVideo(BuildContext context) async {
    if (onVideoPickCallback != null) {
      final selector =
          mediaPickSettingSelector ?? _imageVideoUtils.selectMediaPickSetting;
      final source = await selector(context);

      if (source != null) {
        if (source == MediaPickSettingE.Gallery) {
          _pickVideo(context);
        } else {
          _typeLink(context);
        }
      }
    } else {
      _typeLink(context);
    }
  }

  void _pickVideo(BuildContext context) =>
      _imageVideoUtils.insertVideo(
        context,
        ImageSource.gallery,
        onVideoPickCallback!,
        filePickImpl: filePickImpl,
        webVideoPickImpl: webVideoPickImpl,
      );

  void _typeLink(BuildContext context) {
    showDialog<String>(
      context: context,
      builder: (_) => LinkDialog(
        dialogTheme: dialogTheme,
      ),
    ).then(_embedsService.insertInSelectionVideoViaUrl);
  }
}
