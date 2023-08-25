import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:visual_editor/visual-editor.dart';

import '../../shared/widgets/demo-page-scaffold.dart';
import '../../shared/widgets/loading.dart';

// Multiple editors can be listed in a singles page, each one of them with their own controller.
// The architecture of the editor maintains for each instance a dedicated state object.
// The first state store architecture made use of singleton state classes
// that were imported by the services and widgets that needed them.
// However once complete the issue of sharing states between running instances showed up.
// The solution was to bundle all the state classes in a single `EditorState` class.
// This class gets instantiated once per `EditorController`.
// Therefore each editor instance has it's own internal state independent of the other editors from the same page.
class MultipleEditorsPage extends StatefulWidget {
  @override
  _MultipleEditorsPageState createState() => _MultipleEditorsPageState();
}

class _MultipleEditorsPageState extends State<MultipleEditorsPage> {
  EditorController? _controller1;
  EditorController? _controller2;

  final _focusNode1 = FocusNode();
  final _focusNode2 = FocusNode();

  final _scrollCtrl1 = ScrollController();
  final _scrollCtrl2 = ScrollController();

  @override
  void initState() {
    _loadDocumentAndInitController();
    super.initState();
  }

  @override
  Widget build(BuildContext context) => _scaffold(
        children: _controller1 != null
            ? [
                _toolbar(
                  controller: _controller1,
                ),
                _editor(
                  controller: _controller1,
                  focusNode: _focusNode1,
                  scrollController: _scrollCtrl1,
                ),
                _toolbar(
                  controller: _controller2,
                ),
                _editor(
                    controller: _controller2,
                    focusNode: _focusNode2,
                    scrollController: _scrollCtrl2),
              ]
            : [
                Loading(),
              ],
      );

  Widget _scaffold({required List<Widget> children}) => DemoPageScaffold(
        child: SingleChildScrollView(
          controller: ScrollController(),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: children,
          ),
        ),
      );

  Widget _toolbar({required EditorController? controller}) => Container(
        padding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 8,
        ),
        child: EditorToolbar.basic(
          controller: controller!,
          multiRowsDisplay: false,
        ),
      );

  Widget _editor({
    required FocusNode focusNode,
    required ScrollController scrollController,
    EditorController? controller,
  }) =>
      Container(
        color: Colors.white,
        padding: const EdgeInsets.only(
          left: 16,
          right: 16,
        ),
        child: VisualEditor(
          controller: controller!,
          scrollController: scrollController,
          focusNode: focusNode,
          config: EditorConfigM(
            placeholder: 'Enter text',
          ),
        ),
      );

  Future<void> _loadDocumentAndInitController() async {
    final deltaJson = await rootBundle.loadString(
      'lib/developer/assets/multiple-editors.json',
    );
    final document1 = DeltaDocM.fromJson(jsonDecode(deltaJson)[0]);
    final document2 = DeltaDocM.fromJson(jsonDecode(deltaJson)[1]);

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
