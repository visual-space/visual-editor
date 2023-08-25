import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:visual_editor/visual-editor.dart';

import '../../markers/const/demo-highlights.const.dart';
import '../../shared/services/files.service.dart';
import '../../shared/widgets/demo-page-scaffold.dart';
import '../../shared/widgets/loading.dart';

// Demo of all the styles that can be applied to a document.
class AllStylesPage extends StatefulWidget {
  @override
  _AllStylesPageState createState() => _AllStylesPageState();
}

class _AllStylesPageState extends State<AllStylesPage> {
  final _filesService = FilesService();

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

  Widget _scaffold({required List<Widget> children}) => DemoPageScaffold(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: children,
        ),
      );

  Widget _editor() => Flexible(
        child: Container(
          color: Colors.white,
          padding: EdgeInsets.fromLTRB(16, 0, 16, 0),
          child: VisualEditor(
            controller: _controller!,
            scrollController: _scrollController,
            focusNode: _focusNode,
            config: EditorConfigM(
              highlights: DEMO_HIGHLIGHTS,
              placeholder: 'Enter text',
            ),
          ),
        ),
      );

  Widget _toolbar() => EditorToolbar.basic(
        controller: _controller!,
        onImagePickCallback: _filesService.onImagePickCallback,
        onVideoPickCallback: kIsWeb ? _filesService.onVideoPickCallback : null,
        filePickImpl: _filesService.isDesktop()
            ? _filesService.openFileSystemPickerForDesktop
            : null,
        webImagePickImpl: _filesService.webImagePickImpl,
        // Uncomment to provide a custom "pick from" dialog.
        // mediaPickSettingSelector: _runBuildService.selectMediaPickSettingE,
        showAlignmentButtons: true,
        multiRowsDisplay: false,
        showSearch: true,
      );

  Future<void> _loadDocumentAndInitController() async {
    final deltaJson = await rootBundle.loadString(
      'lib/styles/assets/all-styles.json',
    );
    final document = DeltaDocM.fromJson(jsonDecode(deltaJson));

    setState(() {
      _controller = EditorController(
        document: document,
      );
    });
  }
}
