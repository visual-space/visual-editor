import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:visual_editor/visual-editor.dart';

import '../widgets/demo-scaffold.dart';
import '../widgets/loading.dart';

// Custom toolbar made from a mix of buttons (library and custom made buttons).
class CustomToolbarPage extends StatefulWidget {
  @override
  _CustomToolbarPageState createState() => _CustomToolbarPageState();
}

class _CustomToolbarPageState extends State<CustomToolbarPage> {
  EditorController? _controller;
  final FocusNode _focusNode = FocusNode();

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
            scrollController: ScrollController(),
            focusNode: _focusNode,
            config: EditorConfigM(
              placeholder: 'Enter text',
            ),
          ),
        ),
      );

  Widget _toolbar() => Container(
        padding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 8,
        ),
        child: EditorToolbar.basic(
          controller: _controller!,
        ),
      );

  Future<void> _loadDocument() async {
    final result =
        await rootBundle.loadString('assets/docs/custom-toolbar.json');
    final document = DocumentM.fromJson(jsonDecode(result));

    setState(() {
      _controller = EditorController(
        document: document,
        selection: const TextSelection.collapsed(offset: 0),
      );
    });
  }
}
