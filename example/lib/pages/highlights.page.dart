import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:visual_editor/shared/utils/string.utils.dart';
import 'package:visual_editor/visual-editor.dart';

import '../const/sample-highlights.const.dart';
import '../widgets/demo-scaffold.dart';
import '../widgets/loading.dart';
import '../widgets/selection-stats.dart';

// Highlights are text selections that are temporarily marked in color.
// They can be enabled on demand for features such as highlighted a searched string.
class HighlightsPage extends StatefulWidget {
  @override
  _HighlightsPageState createState() => _HighlightsPageState();
}

class _HighlightsPageState extends State<HighlightsPage> {
  EditorController? _controller;
  final _focusNode = FocusNode();
  final _scrollController = ScrollController();
  late TextSelection _selection;
  final _selection$ = StreamController<TextSelection>.broadcast();

  // TextSelection _selection = TextSelection.collapsed(offset: 0);

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
                _actionsCol(
                  children: [
                    _newHighlightButton(),
                    _selectionStats(),
                  ],
                ),
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

  Widget _actionsCol({required List<Widget> children}) => Column(
        children: children,
      );

  Widget _newHighlightButton() => Container(
        padding: EdgeInsets.all(20),
        child: Row(
          children: [
            Padding(
              padding: EdgeInsets.only(
                right: 10,
              ),
              child: ElevatedButton(
                child: Text('Add highlight'),
                onPressed: () {
                  _controller?.addHighlight(
                    HighlightM(
                      id: getTimeBasedId(),
                      textSelection: _selection.copyWith(),
                      onEnter: (highlight) {},
                      onExit: (highlight) {},
                      onSingleTapUp: (highlight) {
                        print('Highlight tapped ${highlight.id}');
                      },
                    ),
                  );
                },
              ),
            ),
            ElevatedButton(
              child: Text('Clear highlights'),
              onPressed: () {},
            ),
          ],
        ),
      );

  Widget _selectionStats() => SelectionStats(
        selection$: _selection$,
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
            config: EditorConfigM(),
          ),
        ),
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

  Future<void> _loadDocumentAndInitController() async {
    final deltaJson = await rootBundle.loadString('assets/docs/highlights.json');
    final document = DocumentM.fromJson(jsonDecode(deltaJson));

    setState(() {
      _initEditorController(document);
    });
  }

  void _initEditorController(DocumentM document) {
    _controller = EditorController(
      document: document,
      highlights: SAMPLE_HIGHLIGHTS,
      onSelectionChanged: (selection, markers) {
        _selection = selection;

        // (!) Notice that we don't setState() on the entire widget.
        // We only trigger a smaller widget down bellow in the widget tree.
        // The goal is to keep maximum rendering performance by avoiding to re-render the entire editor again.
        // Even with the change detection mechanism, there's still a performance penalty.
        // Pay attention to such issues when building your app.
        // _selection = selection;
        _selection$.sink.add(selection);
      },
    );
  }
}
