import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:visual_editor/visual-editor.dart';

import '../widgets/demo-scaffold.dart';
import '../widgets/loading.dart';

// In case setState() is used by mistake the editor should be able to continue working.
//
class OverwriteControllerPage extends StatefulWidget {
  @override
  _OverwriteControllerPageState createState() => _OverwriteControllerPageState();
}

class _OverwriteControllerPageState extends State<OverwriteControllerPage> {
  EditorController? _controller;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    _loadDocument();

    // (!) This is a counter example of what not to do.
    // Visual Editor was built to endure such an event.
    // However you will see the impact of performance.
    // Check the EditorController API to see how to
    // update the doc without using setState().
    Timer(Duration(seconds: 3), _loadDocument);

    super.initState();
  }

  @override
  Widget build(BuildContext context) => _scaffold(
        children: _controller != null
            ? [
                _editor(),
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
            scrollController: ScrollController(),
            focusNode: _focusNode,
            config: EditorConfigM(
              placeholder: 'Enter text',
            ),
          ),
        ),
      );

  Future<void> _loadDocument() async {
    final result = await rootBundle.loadString(
      'assets/docs/overwrite-controller.json',
    );
    final document = DocumentM.fromJson(jsonDecode(result));

    setState(() {
      _controller = EditorController(
        document: document,
      );
    });
  }
}
