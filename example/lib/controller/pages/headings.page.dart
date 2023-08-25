import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:visual_editor/headings/models/heading-type.enum.dart';
import 'package:visual_editor/headings/models/heading.model.dart';
import 'package:visual_editor/visual-editor.dart';

import '../../shared/const/dimensions.const.dart';
import '../../shared/widgets/demo-page-scaffold.dart';
import '../../shared/widgets/loading.dart';
import '../widgets/headings-panel.dart';

// All headings from the document are extracted and displayed on the panel.
// The type of heading which is displayed can be customized in the controller
// Tapping on a heading in the panel will scroll the document to it.
class HeadingsPage extends StatefulWidget {
  @override
  _HeadingsPageState createState() => _HeadingsPageState();
}

class _HeadingsPageState extends State<HeadingsPage> {
  EditorController? _controller;
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();
  final _headings$ = StreamController<List<HeadingM>>.broadcast();
  bool _isMobile = false;
  bool _isHeadingsPaneVisible = false;

  @override
  void initState() {
    _loadDocumentAndInitController();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    _isMobile = width < 800.0;

    return _scaffold(
      children: _controller != null
          ? [
              _flexibleRow(
                children: [
                  if (_isMobile) _displayPanelButton(),
                  if (_isHeadingsPaneVisible || !_isMobile) _headingsPanel(),
                  _editor(),
                  _fillerToBalanceRow(),
                ],
              ),
              _toolbar(),
            ]
          : [
              Loading(),
            ],
    );
  }

  Widget _scaffold({required List<Widget> children}) => DemoPageScaffold(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: children,
        ),
      );

  Widget _flexibleRow({required List<Widget> children}) => Flexible(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      );

  Widget _headingsPanel() => Container(
        padding: EdgeInsets.fromLTRB(30, 10, 0, 0),
        width: _isMobile ? 200 : 300,
        child: HeadingsPanel(
          headings$: _headings$,
          scrollController: _scrollController,
        ),
      );

  Widget _displayPanelButton() => InkWell(
        child: Icon(Icons.menu),
        onTap: () => setState(
          () => _isHeadingsPaneVisible = !_isHeadingsPaneVisible,
        ),
      );

  // Row is space in between, therefore we need on the right side an empty container to force the editor on the center.
  Widget _fillerToBalanceRow() => Container(width: 0);

  Widget _editor() => Flexible(
        child: Container(
          width: PAGE_WIDTH,
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(30, 0, 30, 0),
          child: VisualEditor(
            controller: _controller!,
            scrollController: _scrollController,
            focusNode: _focusNode,
            config: EditorConfigM(
              onBuildCompleted: _updateHeadings,
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
          showMarkers: true,
          multiRowsDisplay: _isMobile ? false : true,
        ),
      );

  Future<void> _loadDocumentAndInitController() async {
    final result = await rootBundle.loadString(
      'lib/controller/assets/headings.json',
    );
    final document = DeltaDocM.fromJson(jsonDecode(result));
    setState(() {
      _controller = EditorController(
        document: document,
      );
    });
  }

  void _updateHeadings() {
    final headings = _controller?.getHeadingsByType(
          [HeadingTypeE.h1, HeadingTypeE.h2],
        ) ??
        [];

    // (!) Notice that we don't setState() on the entire widget.
    // We only trigger a smaller widget down bellow in the widget tree.
    // The goal is to keep maximum rendering performance by avoiding to re-render the entire editor again.
    // Even with the change detection mechanism, there's still a performance penalty.
    // Pay attention to such issues when building your app.
    _headings$.sink.add(headings);
  }
}
