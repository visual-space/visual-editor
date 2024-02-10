import 'dart:async';

import 'package:flutter/material.dart';

import '../controller/controllers/editor-controller.dart';
import '../highlights/models/highlight.model.dart';
import '../shared/state/editor.state.dart';
import 'models/search-match.model.dart';
import 'search-bar-action-btn.dart';

// Replace the default browser search bar.
// Everytime a char is typed we search the final string in the entire document and highlight matches
// A counter of the total matches will be displayed on the toolbar.
// In the feature, more features will be add such as navigate trough matches and matches positions slimbar will be added
// TODO Review if there's a better solution:
// Added VE suffix to avoid collision with SearchBar from flutter.
class SearchBarVE extends StatefulWidget {
  final EditorController editorController;
  final EditorState state;

  SearchBarVE({
    required this.editorController,
    required this.state,
    Key? key,
  }) : super(key: key);

  @override
  State<SearchBarVE> createState() => _SearchBarVEState();
}

class _SearchBarVEState extends State<SearchBarVE> {
  final _controller = TextEditingController();
  final _fieldFocus = FocusNode();
  late StreamSubscription _changes$L;
  int _numOfMatches = 0;
  String _lastSearch = '';

  @override
  void initState() {
    _subscribeToDocumentChanges();
    super.initState();
  }

  @override
  void dispose() {
    _changes$L.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _box(
        child: _row(
          children: [
            _input(),
            if (_numOfMatches != 0) _totalMatches(),
            _divider(),
            _closeBtn(),
          ],
        ),
      );

  Widget _box({required Widget child}) => Material(
        child: Container(
          color: Colors.grey.shade900,
          padding: EdgeInsets.all(10),
          child: child,
        ),
      );

  Widget _row({required List<Widget> children}) => Row(
        mainAxisSize: MainAxisSize.min,
        children: children,
      );

  Widget _input() => Container(
        width: 180,
        child: TextField(
          cursorColor: Colors.white,
          focusNode: _fieldFocus,
          controller: _controller,
          style: TextStyle(
            fontSize: 14,
            height: 1.4,
            color: Colors.white,
          ),
          decoration: InputDecoration(
            fillColor: Colors.transparent,
            focusColor: Colors.transparent,
            hoverColor: Colors.transparent,
            contentPadding: EdgeInsets.fromLTRB(10, 12, 10, 8),
            isDense: true,
            filled: true,
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: Colors.transparent,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: Colors.transparent,
              ),
            ),
          ),
          textInputAction: TextInputAction.go,
          onChanged: (text) {
            if (text.isEmpty) {
              _numOfMatches = 0;
              _clearHighlights();
            }
            _cacheMatches(text);
            _highlightMatches();
            _lastSearch = text;
          },
        ),
      );

  Widget _totalMatches() => Container(
        child: Text(
          '$_numOfMatches',
          style: TextStyle(
            fontSize: 14,
            height: 1.4,
            color: Colors.white,
          ),
        ),
      );

  Widget _divider() => Container(
        margin: EdgeInsets.symmetric(horizontal: 15),
        width: 1,
        height: 30,
        color: Colors.grey,
      );

  Widget _closeBtn() => SearchBarActionBtn(
        icon: Icons.close,
        onTap: () {
          _clearHighlights();
          widget.state.refs.overlayEntry.remove();
        },
      );

  void _cacheMatches(String text) {
    final matchesSelection = widget.state.refs.documentController.searchText(text);
    final matches = <SearchMatchM>[];

    // Note that we are converting from TextSelectionM to TextSelection (material)
    // This step helps us maintain the document controller 100% functional in a dart backend.
    matchesSelection.forEach((selection) {
      matches.add(
        SearchMatchM(
          textSelection: TextSelection(
            baseOffset: selection.baseOffset,
            extentOffset: selection.extentOffset,
          ),
        ),
      );
    });

    setState(() {
      _numOfMatches = matches.length;
    });

    widget.state.search.addMatches(matches);
  }

  void _highlightMatches() {
    final matches = widget.state.search.matches;
    _clearHighlights();

    for (final match in matches) {
      widget.editorController.addHighlight(
        HighlightM(
          id: 'search-match',
          textSelection: match.textSelection,
          hoverColor: Color.fromRGBO(0xFF, 0xC1, 0x17, .3),
        ),
      );
    }
  }

  void _clearHighlights() {
    widget.editorController.removeHighlightsById('search-match');
  }

  // If the searchbar is active and the document changes we have to update our previous matches
  void _subscribeToDocumentChanges() {
    _changes$L = widget.editorController.changes$.listen((_) {
      _cacheMatches(_lastSearch);
      _highlightMatches();
    });
  }
}
