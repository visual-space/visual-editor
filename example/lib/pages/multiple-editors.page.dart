import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:visual_editor/visual-editor.dart';

import '../widgets/demo-scaffold.dart';
import '../widgets/loading.dart';

// Multiple editors can be listed in a singles page, each one of them with their own controller.
// The architecture of the editor maintains for each instance a dedicated state object.
class MultipleEditorsPage extends StatefulWidget {
  @override
  _MultipleEditorsPageState createState() => _MultipleEditorsPageState();
}

class _MultipleEditorsPageState extends State<MultipleEditorsPage> {
  EditorController? _controller1;
  EditorController? _controller2;
  final _focusNode = FocusNode();

  @override
  void initState() {
    _loadDocument();
    super.initState();
  }

  @override
  Widget build(BuildContext context) => _scaffold(
        children: _controller1 != null
            ? [
                _toolbar(_controller1),
                _editor(_controller1),
                _toolbar(_controller2),
                _editor(_controller2),
              ]
            : [
                Loading(),
              ],
      );

  Widget _scaffold({required List<Widget> children}) => DemoScaffold(
        child: SingleChildScrollView(
          controller: ScrollController(),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: children,
          ),
        ),
      );

  Widget _toolbar(EditorController? controller) => Container(
        padding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 8,
        ),
        child: EditorToolbar.basic(controller: controller!),
      );

  Widget _editor(EditorController? controller) => Container(
        color: Colors.white,
        padding: const EdgeInsets.only(
          left: 16,
          right: 16,
        ),
        child: VisualEditor(
          controller: controller!,
          scrollController: ScrollController(),
          focusNode: _focusNode,
          config: EditorConfigM(
            placeholder: 'Enter text',
          ),
        ),
      );

  Future<void> _loadDocument() async {
    final result = await rootBundle.loadString(
      'assets/docs/multiple-editors.json',
    );
    final document1 = DocumentM.fromJson(jsonDecode(result)[0]);
    final document2 = DocumentM.fromJson(jsonDecode(result)[1]);

    setState(() {
      _controller1 = EditorController(
        document: document1,
      );
      _controller2 = EditorController(
        document: document2,
      );
    });
  }
}
