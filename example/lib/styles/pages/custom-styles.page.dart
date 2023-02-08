import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:visual_editor/visual-editor.dart';

import '../../shared/widgets/demo-page-scaffold.dart';
import '../../shared/widgets/loading.dart';
import '../const/demo-custom-styles.const.dart';

// Multiple editors with custom styles.
// Each editor showcases in the toolbar only the styles customised in each particular example.
class CustomStylesPage extends StatefulWidget {
  @override
  _CustomStylesPageState createState() => _CustomStylesPageState();
}

class _CustomStylesPageState extends State<CustomStylesPage> {
  late EditorController _controllerHeadings;
  late EditorController _controllerParagraphs;
  late EditorController _controllerListQuotesAndSnippets;
  final _focusNodeHeadings = FocusNode();
  final _focusNodeParagraphs = FocusNode();
  final _focusNodeListQuotesAndSnippets = FocusNode();
  bool _pageLoaded = false;

  @override
  void initState() {
    _loadDocument();
    super.initState();
  }

  @override
  Widget build(BuildContext context) => _scaffold(
        children: _pageLoaded
            ? [
                _headings(),
                _paragraphs(),
                _listQuotesAndSnippets(),
              ]
            : [
                Loading(),
              ],
      );

  Widget _scaffold({required List<Widget> children}) => DemoPageScaffold(
        child: SingleChildScrollView(
          controller: ScrollController(),
          child: Column(
            children: children,
          ),
        ),
      );

  Widget _headings() => _editorWithToolbar(
        controller: _controllerHeadings,
        focusNode: _focusNodeHeadings,
        styles: headings,
      );

  Widget _paragraphs() => _editorWithToolbar(
        controller: _controllerParagraphs,
        focusNode: _focusNodeParagraphs,
        styles: paragraphsAndTypography,
        showUnderLineButton: true,
        showStrikeThrough: true,
      );

  Widget _listQuotesAndSnippets() => _editorWithToolbar(
        controller: _controllerListQuotesAndSnippets,
        focusNode: _focusNodeListQuotesAndSnippets,
        styles: listQuotesAndSnippets,
        showInlineCode: true,
        showListBullets: true,
        showListCheck: true,
        showListNumbers: true,
        showQuote: true,
      );

  // Each one of the editor toolbar pairs will receive a different styles setup.
  // Check the constants that are provided as styles to see how to customize the editor styles.
  Widget _editorWithToolbar({
    required EditorController? controller,
    required FocusNode focusNode,
    required EditorStylesM styles,
    bool showUnderLineButton = false,
    bool showStrikeThrough = false,
    bool showListBullets = false,
    bool showListCheck = false,
    bool showListNumbers = false,
    bool showQuote = false,
    bool showInlineCode = false,
  }) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 75),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _editor(
              controller: controller,
              styles: styles,
              focusNode: focusNode,
            ),
            _toolbar(
              controller: controller,
              showUnderLineButton: showUnderLineButton,
              showStrikeThrough: showStrikeThrough,
              showListBullets: showListBullets,
              showListCheck: showListCheck,
              showListNumbers: showListNumbers,
              showQuote: showQuote,
              showInlineCode: showInlineCode,
            ),
          ],
        ),
      );

  Widget _toolbar({
    required EditorController? controller,
    required bool showUnderLineButton,
    required bool showStrikeThrough,
    required bool showListBullets,
    required bool showListCheck,
    required bool showListNumbers,
    required bool showQuote,
    required bool showInlineCode,
  }) =>
      Padding(
        padding: const EdgeInsets.only(top: 8),
        child: EditorToolbar.basic(
          controller: controller!,
          showUnderLineButton: showUnderLineButton,
          showStrikeThrough: showStrikeThrough,
          showBackgroundColorButton: false,
          showImageButton: false,
          showVideoButton: false,
          showListBullets: showListBullets,
          showListCheck: showListCheck,
          showCodeBlock: false,
          showIndent: false,
          showListNumbers: showListNumbers,
          showQuote: showQuote,
          showDividers: false,
          showLink: false,
          showInlineCode: showInlineCode,
          showClearFormat: false,
        ),
      );

  Widget _editor({
    required EditorController? controller,
    required FocusNode focusNode,
    required EditorStylesM styles,
  }) =>
      Container(
        color: Colors.white,
        padding: const EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: 30,
        ),
        child: VisualEditor(
          controller: controller!,
          focusNode: focusNode,
          config: EditorConfigM(
            customStyles: styles,
            placeholder: 'Enter text',
          ),
        ),
      );

  Future<void> _loadDocument() async {
    final headingsDeltaJson = await rootBundle.loadString(
      'lib/styles/assets/custom-styles/custom-headings.json',
    );
    final paragraphsDeltaJson = await rootBundle.loadString(
      'lib/styles/assets/custom-styles/custom-paragraphs.json',
    );
    final listsDeltaJson = await rootBundle.loadString(
      'lib/styles/assets/custom-styles/custom-lists.json',
    );

    _pageLoaded = true;

    setState(() {
      _controllerHeadings = EditorController(
        document: DocumentM.fromJson(
          jsonDecode(headingsDeltaJson),
        ),
      );
      _controllerParagraphs = EditorController(
        document: DocumentM.fromJson(
          jsonDecode(paragraphsDeltaJson),
        ),
      );
      _controllerListQuotesAndSnippets = EditorController(
        document: DocumentM.fromJson(
          jsonDecode(listsDeltaJson),
        ),
      );
    });
  }
}
