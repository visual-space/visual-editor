import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:visual_editor/document/models/attributes/attributes-aliases.model.dart';
import 'package:visual_editor/document/models/attributes/attributes.model.dart';
import 'package:visual_editor/shared/widgets/default-button.dart';
import 'package:visual_editor/visual-editor.dart';

import '../../shared/const/dimensions.const.dart';
import '../../shared/widgets/demo-page-scaffold.dart';
import '../../shared/widgets/loading.dart';

// Demonstrates insertion of new elements at the end of the document.
// This process consists of 2 operations:
// - Create a new empty line (replace the last element of the document with an empty line)
// - Apply to the new empty line desired attribute.
class AddElementsPage extends StatefulWidget {
  @override
  _AddElementsPageState createState() => _AddElementsPageState();
}

class _AddElementsPageState extends State<AddElementsPage> {
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
                _row(
                  children: [
                    _insertH1LineBtn(),
                    _insertBulletListBtn(),
                    _insertCodeBlockBtn(),
                  ],
                ),
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
          width: PAGE_WIDTH,
          color: Colors.white,
          padding: EdgeInsets.fromLTRB(30, 0, 30, 30),
          child: VisualEditor(
            controller: _controller!,
            scrollController: _scrollController,
            focusNode: _focusNode,
            config: EditorConfigM(),
          ),
        ),
      );

  Widget _row({required List<Widget> children}) => Container(
        margin: EdgeInsets.only(top: 15),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: children,
        ),
      );

  Widget _insertH1LineBtn() => DefaultButton(
        name: 'Insert H1 Line',
        onPressed: _insertH1Line,
      );

  Widget _insertBulletListBtn() => DefaultButton(
        name: 'Insert Bullet List',
        padding: EdgeInsets.symmetric(horizontal: 25),
        onPressed: _insertBulletList,
      );

  Widget _insertCodeBlockBtn() => DefaultButton(
        name: 'Insert Code Block',
        onPressed: _insertCodeBlock,
      );

  Widget _toolbar() => Container(
        padding: EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 8,
        ),
        child: EditorToolbar.basic(
          controller: _controller!,
          multiRowsDisplay: false,
        ),
      );

  // === UTILS ===

  void _insertH1Line() {
    final docLen = _controller!.docLength;
    _controller!.replace(docLen - 1, 0, '\nHeading\n', null);
    _controller!.formatTextRange(docLen, 0, AttributesAliasesM.h1);
  }

  void _insertBulletList() {
    final docLen = _controller!.docLength;
    _controller!.replace(docLen - 1, 0, '\nBullet list\n', null);
    _controller!.formatTextRange(docLen, 0, AttributesAliasesM.bulletList);
  }

  void _insertCodeBlock() {
    final docLen = _controller!.docLength;
    _controller!.replace(docLen - 1, 0, '\nfinal count = 0;\n', null);
    _controller!.formatTextRange(docLen, 0, AttributesM.codeBlock);
  }

  Future<void> _loadDocumentAndInitController() async {
    final deltaJson = await rootBundle.loadString(
      'lib/controller/assets/add-elements.json',
    );
    final document = DeltaDocM.fromJson(jsonDecode(deltaJson));

    setState(() {
      _controller = EditorController(
        document: document,
      );
    });
  }
}
