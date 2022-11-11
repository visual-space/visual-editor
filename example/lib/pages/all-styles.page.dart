import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:visual_editor/visual-editor.dart';

import '../const/sample-highlights.const.dart';
import '../services/editor.service.dart';
import '../widgets/demo-scaffold.dart';
import '../widgets/loading.dart';

// Demo of all the styles that can be applied to a document.
class AllStylesPage extends StatefulWidget {
  @override
  _AllStylesPageState createState() => _AllStylesPageState();
}

class _AllStylesPageState extends State<AllStylesPage> {
  final _editorService = EditorService();

  EditorController? _controller;
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    _loadDocumentAndInitController();
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
        // Uncomment to provide a custom "pick from" dialog.
        // mediaPickSettingSelector: _editorService.selectMediaPickSettingE,
        showAlignmentButtons: true,
        multiRowsDisplay: false,
      );

  Future<void> _loadDocumentAndInitController() async {
    final deltaJson = await rootBundle.loadString(
      'assets/docs/all-styles.json',
    );
    final document = DocumentM.fromJson(jsonDecode(deltaJson));

    setState(() {
      _controller = EditorController(
        document: document,
        highlights: SAMPLE_HIGHLIGHTS,
      );
    });
  }
}
