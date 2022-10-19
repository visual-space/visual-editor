import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:visual_editor/visual-editor.dart';

import '../widgets/demo-scaffold.dart';

// Demonstrates the placeholder functionality of the editor.
// When a document is completely empty, the placeholder text is displayed.
// Notice that we don't load any document, we init straight away with empty document.
class PlaceholderPage extends StatefulWidget {
  @override
  _PlaceholderPageState createState() => _PlaceholderPageState();
}

class _PlaceholderPageState extends State<PlaceholderPage> {
  late EditorController _controller;
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    _initDocument();
    super.initState();
  }

  @override
  Widget build(BuildContext context) => _scaffold(
        children: [
          _editor(),
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
            controller: _controller,
            scrollController: _scrollController,
            focusNode: _focusNode,
            config: EditorConfigM(
              placeholder: 'Enter text',
            ),
          ),
        ),
      );

  Future<void> _initDocument() async {
    _controller = EditorController(
      document: DocumentM.fromJson(
        jsonDecode(EMPTY_DELTA_DOC_JSON),
      ),
    );
  }
}
