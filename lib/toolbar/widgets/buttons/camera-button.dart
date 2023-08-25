import 'dart:async';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../controller/controllers/editor-controller.dart';
import '../../../editor/services/run-build.service.dart';
import '../../../shared/models/editor-icon-theme.model.dart';
import '../../../shared/state/editor-state-receiver.dart';
import '../../../shared/state/editor.state.dart';
import '../../models/media-picker.type.dart';
import '../toolbar.dart';

// Insert in the document images capture via the camera.
// ignore: must_be_immutable
class CameraButton extends StatefulWidget with EditorStateReceiver {
  final IconData icon;
  final double iconSize;
  final Color? fillColor;
  final EditorController controller;
  final OnImagePickCallback? onImagePickCallback;
  final OnVideoPickCallback? onVideoPickCallback;
  final WebImagePickImpl? webImagePickImpl;
  final WebVideoPickImpl? webVideoPickImpl;
  final FilePickImpl? filePickImpl;
  final EditorIconThemeM? iconTheme;
  final double buttonsSpacing;
  late EditorState _state;

  CameraButton({
    required this.icon,
    required this.controller,
    required this.buttonsSpacing,
    this.iconSize = defaultIconSize,
    this.fillColor,
    this.onImagePickCallback,
    this.onVideoPickCallback,
    this.filePickImpl,
    this.webImagePickImpl,
    this.webVideoPickImpl,
    this.iconTheme,
    Key? key,
  }) : super(key: key) {
    controller.setStateInEditorStateReceiver(this);
  }

  @override
  State<CameraButton> createState() => _CameraButtonState();

  @override
  void cacheStateStore(EditorState state) {
    _state = state;
  }
}

class _CameraButtonState extends State<CameraButton> {
  late final MediaLoaderService _mediaLoaderService;
  late final RunBuildService _runBuildService;

  StreamSubscription? _runBuild$L;

  @override
  void initState() {
    _mediaLoaderService = MediaLoaderService(widget._state);
    _runBuildService = RunBuildService(widget._state);

    _subscribeToRunBuild();
    super.initState();
  }

  @override
  void dispose() {
    _runBuild$L?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSelectionCameraEnabled =
        widget._state.disabledButtons.isSelectionCameraEnabled;

    final iconColor = isSelectionCameraEnabled
        ? widget.iconTheme?.iconUnselectedColor ?? theme.iconTheme.color
        : theme.disabledColor;
    final iconFillColor = widget.iconTheme?.iconUnselectedFillColor ??
        (widget.fillColor ?? theme.canvasColor);

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
      onPressed: isSelectionCameraEnabled
          ? () => _handleCameraButtonTap(
                context,
                widget.controller,
                onImagePickCallback: widget.onImagePickCallback,
                onVideoPickCallback: widget.onVideoPickCallback,
                filePickImpl: widget.filePickImpl,
                webImagePickImpl: widget.webImagePickImpl,
              )
          : null,
    );
  }

  // === PRIVATE ===
  
  Future<void> _handleCameraButtonTap(
    BuildContext context,
    EditorController controller, {
    OnImagePickCallback? onImagePickCallback,
    OnVideoPickCallback? onVideoPickCallback,
    FilePickImpl? filePickImpl,
    WebImagePickImpl? webImagePickImpl,
  }) async {
    if (onImagePickCallback != null && onVideoPickCallback != null) {
      // Show dialog to choose Photo or Video
      return await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            contentPadding: const EdgeInsets.symmetric(vertical: 60),
            content: Column(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              mainAxisSize: MainAxisSize.min,
              children: [
                _photoButton(
                  context,
                  onImagePickCallback,
                  filePickImpl,
                  webImagePickImpl,
                ),
                _videoButton(
                  context,
                  onVideoPickCallback,
                  filePickImpl,
                )
              ],
            ),
          );
        },
      );
    }

    if (onImagePickCallback != null) {
      return _mediaLoaderService.pickImage(
        context,
        ImageSource.camera,
        onImagePickCallback,
        filePickImpl: filePickImpl,
        webImagePickImpl: webImagePickImpl,
      );
    }

    assert(onVideoPickCallback != null, 'onVideoPickCallback must not be null');
    return _mediaLoaderService.insertVideo(
      context,
      ImageSource.camera,
      onVideoPickCallback!,
      filePickImpl: filePickImpl,
      webVideoPickImpl: widget.webVideoPickImpl,
    );
  }

  Widget _videoButton(BuildContext context,
      OnVideoPickCallback onVideoPickCallback, FilePickImpl? filePickImpl) {
    return Padding(
      padding: EdgeInsets.only(top: 15),
      child: TextButton.icon(
        icon: const Icon(
          Icons.movie_creation,
          color: Colors.orangeAccent,
          size: 40,
        ),
        label: const Text(
          'Video',
          style: TextStyle(color: Colors.black87),
        ),
        onPressed: () {
          _mediaLoaderService.insertVideo(
            context,
            ImageSource.camera,
            onVideoPickCallback,
            filePickImpl: filePickImpl,
            webVideoPickImpl: widget.webVideoPickImpl,
          );
        },
      ),
    );
  }

  TextButton _photoButton(
      BuildContext context,
      OnImagePickCallback onImagePickCallback,
      FilePickImpl? filePickImpl,
      WebImagePickImpl? webImagePickImpl) {
    return TextButton.icon(
      icon: const Icon(
        Icons.photo,
        color: Colors.cyanAccent,
        size: 40,
      ),
      label: const Text(
        'Photo',
        style: TextStyle(color: Colors.black87),
      ),
      onPressed: () {
        _mediaLoaderService.pickImage(
          context,
          ImageSource.camera,
          onImagePickCallback,
          filePickImpl: filePickImpl,
          webImagePickImpl: webImagePickImpl,
        );
      },
    );
  }

  // === UTILS ===

  // In order to update the button state after each selection change check if button is enabled.
  void _subscribeToRunBuild() {
    _runBuild$L = _runBuildService.runBuild$.listen(
      (_) => setState(() {}),
    );
  }
}
