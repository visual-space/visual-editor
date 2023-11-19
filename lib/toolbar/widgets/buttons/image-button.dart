import 'dart:async';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../controller/controllers/editor-controller.dart';
import '../../../editor/services/run-build.service.dart';
import '../../../embeds/services/embeds.service.dart';
import '../../../shared/models/editor-dialog-theme.model.dart';
import '../../../shared/models/editor-icon-theme.model.dart';
import '../../../shared/state/editor-state-receiver.dart';
import '../../../shared/state/editor.state.dart';
import '../../models/media-pick.enum.dart';
import '../../models/media-picker.type.dart';
import '../../services/toolbar.service.dart';
import '../dialogs/link-dialog.dart';
import '../toolbar.dart';

// Adds an image.
// ignore: must_be_immutable
class ImageButton extends StatefulWidget implements EditorStateReceiver {
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
  late EditorState _state;

  ImageButton({
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
  }) : super(key: key) {
    controller.setStateInEditorStateReceiver(this);
  }

  @override
  State<ImageButton> createState() => _ImageButtonState();

  @override
  void cacheStateStore(EditorState state) {
    _state = state;
  }
}

class _ImageButtonState extends State<ImageButton> {
  late final RunBuildService _runBuildService;
  late final EmbedsService _embedsService;
  late final MediaLoaderService _mediaLoaderService;
  late final ToolbarService _toolbarService;

  StreamSubscription? _runBuild$L;

  @override
  void initState() {
    _runBuildService = RunBuildService(widget._state);
    _embedsService = EmbedsService(widget._state);
    _mediaLoaderService = MediaLoaderService(widget._state);
    _toolbarService = ToolbarService(widget._state);

    _subscribeToRunBuild();
    super.initState();
  }

  @override
  void dispose() {
    _runBuild$L?.cancel();
    super.dispose();
  }

  // TODO Needs cleanup
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final iconColor = isEnabled ? widget.iconTheme?.iconUnselectedColor ?? theme.iconTheme.color : widget.iconTheme?.disabledIconColor ?? theme.disabledColor;
    final iconFillColor =
        isEnabled ? (widget.iconTheme?.iconUnselectedFillColor ?? theme.canvasColor) : widget.iconTheme?.disabledIconFillColor ?? theme.disabledColor;

    return IconBtn(
      icon: Icon(
        widget.icon,
        size: widget.iconSize,
        color: iconColor,
      ),
      buttonsSpacing: widget.buttonsSpacing,
      highlightElevation: 0,
      hoverElevation: 0,
      size: widget.iconSize * 1.77,
      fillColor: iconFillColor,
      borderRadius: widget.iconTheme?.borderRadius ?? 2,
      onPressed: isEnabled ? () => _insertImage(context) : null,
    );
  }

  // === UTILS ===

  bool get isEnabled => _toolbarService.isStylingEnabled;

  Future<void> _insertImage(BuildContext context) async {
    if (widget.onImagePickCallback != null) {
      final selector = widget.mediaPickSettingSelector ?? _mediaLoaderService.selectMediaPickSetting;
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

  void _pickImage(BuildContext context) => _mediaLoaderService.pickImage(
        context,
        ImageSource.gallery,
        widget.onImagePickCallback!,
        filePickImpl: widget.filePickImpl,
        webImagePickImpl: widget.webImagePickImpl,
      );

  void _typeLink(BuildContext context) {
    showDialog<String>(
      context: context,
      builder: (_) => LinkDialog(
        dialogTheme: widget.dialogTheme,
      ),
    ).then(_embedsService.insertInSelectionImageViaUrl);
  }

  // In order to update the button state after each selection change check if button is enabled.
  void _subscribeToRunBuild() {
    _runBuild$L = _runBuildService.runBuild$.listen(
      (_) => setState(() {}),
    );
  }
}
