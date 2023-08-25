import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:visual_editor/visual-editor.dart';

import '../../shared/const/dimensions.const.dart';
import '../../shared/widgets/demo-page-scaffold.dart';

// Here you can test any change in the editor and see the delta document output that is generated.
// Very useful for debugging or when adding new features or just for learning purposes.
// (!) If you want to see some particular feature in isolation, delete the demo content and insert whatever content you need.
// On mobiles the page displays sliding panels for the editor and json preview to enable the client devs
// to preview either rich text or delta json within the maximum available screen area.
// TODO Highlight changed text fragments between edits
// TODO Use monospace font for the json preview
class DeltaSandboxPage extends StatefulWidget {
  const DeltaSandboxPage({Key? key}) : super(key: key);

  @override
  State<DeltaSandboxPage> createState() => _DeltaSandboxPageState();
}

class _DeltaSandboxPageState extends State<DeltaSandboxPage> {
  late EditorController _editorController;
  final _scrollController = ScrollController();
  late TextEditingController _jsonInputController;
  late final StreamSubscription _jsonInput$L;
  bool _hasExpandedView = true;
  bool _isMobile = false;
  final double _expandedEditorHeight = 350;
  final double _minimizedEditorHeight = 200;
  double _width = 0;

  // We use the focus to check if editor or json input has triggered the change.
  // This is essential for preventing a circular update loop between editor and input.
  final _focusNode = FocusNode();

  @override
  void initState() {
    _setupEditorController();
    _setupJsonInputController();
    _subscribeToJsonInputAndUpdateEditorDoc();
    _loadDocumentAndInitController();
    super.initState();
  }

  @override
  void dispose() {
    _jsonInputController.dispose();
    _jsonInput$L.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _width = MediaQuery.of(context).size.width;
    _isMobile = _width < PAGE_WIDTH;

    return _scaffoldCol(
      actions: [
        _toggleEditorJsonPreviewBtn(),
      ],
      children: [
        _adaptiveColRow(
          children: [
            _editor(),
            _jsonPreview(),
          ],
        ),
        _toolbar(),
      ],
    );
  }

  Widget _scaffoldCol({
    required List<Widget> actions,
    required List<Widget> children,
  }) =>
      DemoPageScaffold(
        pageWidth: PAGE_WIDTH,
        actions: actions,
        child: Column(
          children: children,
        ),
      );

  Widget _toggleEditorJsonPreviewBtn() => _isMobile
      ? Padding(
          padding: EdgeInsets.only(right: 10),
          child: IconButton(
            onPressed: _toggleExpandedEditorView,
            icon: _hasExpandedView
                ? Icon(Icons.arrow_downward)
                : Icon(Icons.arrow_upward),
          ),
        )
      : SizedBox.shrink();

  Widget _adaptiveColRow({required List<Widget> children}) => Expanded(
        child: _isMobile
            ? Column(
                children: children,
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: children,
              ),
      );

  Widget _jsonPreview() => Expanded(
        child: Container(
          color: Colors.grey.shade300,
          width: _isMobile ? _width : PAGE_WIDTH / 2,
          padding: EdgeInsets.symmetric(horizontal: 15),
          child: TextField(
            controller: _jsonInputController,
            maxLines: null,
            minLines: 1,
          ),
        ),
      );

  Widget _editor() => AnimatedContainer(
        width: _isMobile ? _width : PAGE_WIDTH / 2,
        duration: Duration(milliseconds: 200),
        height: _isMobile
            ? _hasExpandedView
                ? _minimizedEditorHeight
                : _expandedEditorHeight
            : 750,
        color: Colors.white,
        child: VisualEditor(
          controller: _editorController,
          scrollController: _scrollController,
          focusNode: _focusNode,
          config: EditorConfigM(
            placeholder: 'Enter text',
            padding: EdgeInsets.fromLTRB(15, 0, 15, 0),
            onBuildCompleted: _updateJsonPreview,
          ),
        ),
      );

  Widget _toolbar() => EditorToolbar.basic(
        color: Colors.white,
        controller: _editorController,
        showMarkers: true,
        multiRowsDisplay: false,
        iconTheme: EditorIconThemeM(
          iconUnselectedFillColor: Colors.white,
        ),
      );

  // === UTILS ===

  // Toggle the editor's visibility ratio for mobile, for better usability
  void _toggleExpandedEditorView() {
    setState(() {
      _hasExpandedView = !_hasExpandedView;
    });
  }

  void _setupEditorController() {
    _editorController = EditorController(
      document: DeltaDocM.fromJson(
        jsonDecode(LOREM_LIPSUM_DOC_JSON),
      ),
    );
  }

  void _setupJsonInputController() =>
      _jsonInputController = TextEditingController(
        text: _formatJson(LOREM_LIPSUM_DOC_JSON),
      );

  Future<void> _loadDocumentAndInitController() async {
    final doc = await rootBundle.loadString(
      'lib/developer/assets/delta-sandbox.json',
    );
    final delta = DeltaDocM.fromJson(jsonDecode(doc)).delta;

    _editorController.update(
      delta,

      // Prevents the insertion of the caret if the editor is not focused
      ignoreFocus: true,
    );
    _jsonInputController.text = doc;
  }

  // Each time the editor changes we update the contents of the json preview
  void _updateJsonPreview() {
    final jsonDoc = jsonEncode(
      _editorController.document.delta.toJson(),
    );

    // Update json preview only if the change was emitted by the editor
    if (_focusNode.hasFocus) {
      _jsonInputController.text = _formatJson(jsonDoc);
    }
  }

  void _subscribeToJsonInputAndUpdateEditorDoc() {
    _jsonInputController.addListener(() {
      // Update editor only if the change was emitted by the json input
      if (!_focusNode.hasFocus) {
        final delta = DeltaDocM.fromJson(
          jsonDecode(_jsonInputController.text),
        ).delta;

        _editorController.update(
          delta,

          // Prevents the insertion of the caret if the editor is not focused
          ignoreFocus: true,
        );
      }
    });
  }

  String _formatJson(String json) => JsonEncoder.withIndent('  ').convert(
        jsonDecode(json),
      );
}
