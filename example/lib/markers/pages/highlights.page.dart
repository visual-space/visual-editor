import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:visual_editor/shared/utils/string.utils.dart';
import 'package:visual_editor/visual-editor.dart';

import '../../shared/widgets/demo-page-scaffold.dart';
import '../../shared/widgets/loading.dart';
import '../const/demo-highlights.const.dart';
import '../widgets/selection-stats.dart';

// Highlights are text selections that are temporarily marked in color.
// They can be enabled on demand for features such as highlighted a searched string.
// Highlights can be removed all at once, one by one (based on the object) or by id (one or more)
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
                    _row(
                      children: [
                        _addHighlightBtn(),
                        _removeGreenHighlightsBtn(),
                        _removeAllHighlightsBtn(),
                      ],
                    ),
                    _selectionStats(),
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

  Widget _actionsCol({required List<Widget> children}) => Column(
        children: children,
      );

  Widget _row({required List<Widget> children}) => Container(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Row(
          children: children,
        ),
      );

  Widget _addHighlightBtn() => ElevatedButton(
        onPressed: _addHighlight,
        child: Text('Add highlight'),
      );

  Widget _removeGreenHighlightsBtn() => Container(
        padding: EdgeInsets.symmetric(horizontal: 15),
        child: ElevatedButton(
          onPressed: _removeGreenHighlights,
          child: Text('Remove green highlights'),
        ),
      );

  Widget _removeAllHighlightsBtn() => ElevatedButton(
        onPressed: _removeAllHighlights,
        child: Text('Remove all highlights'),
      );

  Widget _selectionStats() => SelectionStats(
        selection$: _selection$,
      );

  Widget _editor() => Flexible(
        child: Container(
          color: Colors.white,
          padding: EdgeInsets.fromLTRB(16, 0, 16, 0),
          child: VisualEditor(
            controller: _controller!,
            scrollController: _scrollController,
            focusNode: _focusNode,
            config: EditorConfigM(
              highlights: DEMO_HIGHLIGHTS,
              onSelectionChanged: (selection) {
                _selection = selection;

                // (!) Notice that we don't setState() on the entire widget.
                // We only trigger a smaller widget down bellow in the widget tree.
                // The goal is to keep maximum rendering performance by avoiding to re-render the entire editor again.
                // Even with the change detection mechanism, there's still a performance penalty.
                // Pay attention to such issues when building your app.
                // _selection = selection;
                _selection$.sink.add(selection);
              },
            ),
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

  void _addHighlight() {
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
  }

// Remove all highlights with the same id
  void _removeGreenHighlights() {
    _controller?.removeHighlightsById('1255915683987000');
  }

  void _removeAllHighlights() {
    _controller?.removeAllHighlights();
  }

  Future<void> _loadDocumentAndInitController() async {
    final deltaJson = await rootBundle.loadString(
      'lib/markers/assets/highlights.json',
    );
    final document = DeltaDocM.fromJson(jsonDecode(deltaJson));

    setState(() {
      _controller = EditorController(
        document: document,
      );
    });
  }
}
