import 'dart:async';
import 'dart:convert';

import 'package:editorapp/services/editor.service.dart';
import 'package:editorapp/widgets/demo-scaffold.dart';
import 'package:editorapp/widgets/loading.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:visual_editor/visual-editor.dart';


// Demo of RTL support that can be used with the editor.
class RTLPage extends StatefulWidget {
  @override
  _RTLPageState createState() => _RTLPageState();
}

class _RTLPageState extends State<RTLPage> {
  final _editorService = EditorService();

  EditorController? _controller;
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    _loadDocument();
    super.initState();
  }

  @override
  Widget build(BuildContext context) => _scaffold(
        children: _controller != null
            ? [
                _editor(),
                _toolbar(),
              ]
            : [
                Loading(),
              ],
      );

  Widget _scaffold({required List<Widget> children}) => DemoScaffold(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: children,
        ),
      );

  Widget _editor() => Flexible(
        child: Container(
          color: Colors.white,
          padding: const EdgeInsets.only(
            left: 16,
            right: 16,
          ),
          child: VisualEditor(
            controller: _controller!,
            scrollController: _scrollController,
            focusNode: _focusNode,
            config: EditorConfigM(
              placeholder: 'Enter text',
            ),
          ),
        ),
      );

  Widget _toolbar() => EditorToolbar.basic(
        controller: _controller!,
        onImagePickCallback: _editorService.onImagePickCallback,
        onVideoPickCallback: kIsWeb ? _editorService.onVideoPickCallback : null,
        filePickImpl: _editorService.isDesktop()
            ? _editorService.openFileSystemPickerForDesktop
            : null,
        webImagePickImpl: _editorService.webImagePickImpl,

        /// Disable all buttons except rtl-ltr and TextAlignment buttons
        multiRowsDisplay: false,
        showDividers: false,
        showFontSize: false,
        showBoldButton: false,
        showItalicButton: false,
        showSmallButton: false,
        showUnderLineButton: false,
        showStrikeThrough: false,
        showInlineCode: false,
        showColorButton: false,
        showBackgroundColorButton: false,
        showClearFormat: false,
        showAlignmentButtons: true,
        showHeaderStyle: false,
        showListNumbers: false,
        showListBullets: false,
        showListCheck: false,
        showCodeBlock: false,
        showQuote: false,
        showIndent: false,
        showLink: false,
        showUndo: false,
        showRedo: false,
        showImageButton: false,
        showVideoButton: false,
        showCameraButton: false,
        showMarkers: false,

        /// rtl-ltr and TextAlignment buttons
        showLeftAlignment: true,
        showCenterAlignment: true,
        showRightAlignment: true,
        showJustifyAlignment: true,
        showDirection: true,
      );

  Future<void> _loadDocument() async {
    final result = await rootBundle.loadString(
      'assets/docs/rtl.json',
    );
    final document = DocumentM.fromJson(jsonDecode(result));
    // final document = DocumentM.fromJson(js);

    setState(() {
      _controller = EditorController(
        document: document,
      );
    });
  }
}
