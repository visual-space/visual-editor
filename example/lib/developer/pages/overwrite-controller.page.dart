import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:visual_editor/visual-editor.dart';
import '../../shared/widgets/demo-page-scaffold.dart';
import '../../shared/widgets/loading.dart';

// In case setState() is used by mistake the editor should be able to continue working.
class OverwriteControllerPage extends StatefulWidget {
  @override
  _OverwriteControllerPageState createState() =>
      _OverwriteControllerPageState();
}

class _OverwriteControllerPageState extends State<OverwriteControllerPage> {
  EditorController? _controller;
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    _loadDocumentAndInitController();

    // (!) This is a counter example of what not to do.
    // Visual Editor was built to endure such an event.
    // However you will see the impact of performance.
    // Check the EditorController API to see how to
    // update the doc without using setState().
    Timer(Duration(seconds: 3), _loadDocumentAndInitController);

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

  Widget _editor() => Expanded(
        child: Container(
          color: Colors.white,
          padding: EdgeInsets.fromLTRB(16, 0, 16, 0),
          child: VisualEditor(
            controller: _controller!,
            scrollController: _scrollController,
            focusNode: _focusNode,
            config: EditorConfigM(
              expands: true,
              placeholder: 'Enter text',
            ),
          ),
        ),
      );

  Widget _toolbar() => Container(
        padding: EdgeInsets.symmetric(
          vertical: 16,
        ),
        child: EditorToolbar.basic(
          controller: _controller!,
          multiRowsDisplay: false,
        ),
      );

  Future<void> _loadDocumentAndInitController() async {
    final deltaJson = await rootBundle.loadString(
      'lib/developer/assets/overwrite-controller.json',
    );
    final document = DeltaDocM.fromJson(jsonDecode(deltaJson));

    setState(() {
      _controller = EditorController(
        document: document,
      );
    });
  }
}
