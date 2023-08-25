import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:visual_editor/visual-editor.dart';

import '../../shared/widgets/demo-page-scaffold.dart';
import '../const/demo-custom-styles.const.dart';

// Demonstrates the placeholder functionality of the editor.
// When a document is completely empty, the placeholder text is displayed.
// Notice that we don't load any document, we init straight away with empty document.
// The placeholder styling can be controlled independently (it does not inherit from text custom styles).
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
            controller: _controller,
            scrollController: _scrollController,
            focusNode: _focusNode,
            config: EditorConfigM(
              placeholder: 'Enter text',
              customStyles: EditorStylesM(
                paragraph: getTextBlockStyle(),
                placeHolder: getTextBlockStyle(color: Colors.black12),
              ),
            ),
          ),
        ),
      );

  TextBlockStyleM getTextBlockStyle({Color? color}) => TextBlockStyleM(
        TextStyle(
          fontSize: 50,
          fontWeight: FontWeight.w700,
          height: 1.4,
          color: color,
        ),
        VerticalSpacing(top: 0, bottom: 20),
        VerticalSpacing(top: 0, bottom: 0),
        VERTICAL_SPACING_EMPTY,
        null,
      );

  Future<void> _initDocument() async {
    _controller = EditorController(
      document: DeltaDocM.fromJson(
        jsonDecode(EMPTY_DELTA_DOC_JSON),
      ),
    );
  }
}
