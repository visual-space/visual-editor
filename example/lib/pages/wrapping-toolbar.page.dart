import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:visual_editor/visual-editor.dart';

import '../widgets/demo-page-scaffold.dart';
import '../widgets/loading.dart';

// Horizontal toolbars can either scroll or wrap.
// It is recommended on mobiles to use the horizontal scrolling toolbar.
// Or if you don't want scroll, avoid enabling all editing options, to have fewer tools.
// Otherwise they will wrap around.
class WrappingToolbarPage extends StatefulWidget {
  @override
  _WrappingToolbarPageState createState() => _WrappingToolbarPageState();
}

class _WrappingToolbarPageState extends State<WrappingToolbarPage> {
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
                _toolbars(
                  children: [
                    _withScroll(),
                    _fixed(),
                  ],
                ),
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
          padding: EdgeInsets.only(
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

  Widget _toolbars({required List<Widget> children}) => Container(
        padding: EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 8,
        ),
        child: Column(
          children: children,
        ),
      );

  Widget _toolbar({required String title, required bool multiRowsDisplay}) =>
      Padding(
        padding: EdgeInsets.only(top: 50),
        child: Column(
          children: [
            Text(title),
            EditorToolbar.basic(
              controller: _controller!,
              multiRowsDisplay: multiRowsDisplay,
              customIcons: [
                // Custom icon
                EditorCustomButtonM(icon: Icons.favorite, onTap: () {}),
              ],
            ),
          ],
        ),
      );

  Widget _withScroll() => _toolbar(
        title: 'Horizontal with scroll',
        multiRowsDisplay: false,
      );

  Widget _fixed() => _toolbar(
        title: 'Horizontal wrapping',
        multiRowsDisplay: true,
      );

  Future<void> _loadDocumentAndInitController() async {
    final result = await rootBundle.loadString(
      'assets/docs/wrapping-toolbar.json',
    );
    final document = DocumentM.fromJson(jsonDecode(result));

    setState(() {
      _controller = EditorController(
        document: document,
      );
    });
  }
}
