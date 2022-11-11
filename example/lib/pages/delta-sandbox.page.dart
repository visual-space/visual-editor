import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:visual_editor/visual-editor.dart';

import '../widgets/demo-scaffold.dart';

// Here you can test any change in the editor and see the delta document output that is generated.
// Very useful for debugging or when adding new features or just for learning purposes.
// (!) If you want to see some particular feature in isolation,
// delete the demo content and insert whatever content you need.
// TODO Highlight changed text fragments between edits
// TODO Use monospace font for the json preview
class DeltaSandbox extends StatefulWidget {
  const DeltaSandbox({Key? key}) : super(key: key);

  @override
  State<DeltaSandbox> createState() => _DeltaSandboxState();
}

class _DeltaSandboxState extends State<DeltaSandbox> {
  late EditorController _editorController;
  final _scrollController = ScrollController();
  late TextEditingController _jsonInputController;
  late final StreamSubscription _jsonInputListener;

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
    _jsonInputListener.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _scaffoldRow(
        children: [
          _col(
            children: [
              _editor(),
              _toolbar(),
            ],
          ),
          _jsonPreview(),
        ],
      );

  Widget _scaffoldRow({required List<Widget> children}) => DemoScaffold(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      );

  Widget _col({required List<Widget> children}) => Expanded(
        child: Column(
          children: children,
        ),
      );

  Widget _editor() => Expanded(
        child: SingleChildScrollView(
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.only(
              left: 16,
              right: 16,
            ),
            child: VisualEditor(
              controller: _editorController,
              scrollController: _scrollController,
              focusNode: _focusNode,
              config: EditorConfigM(
                placeholder: 'Enter text',
              ),
            ),
          ),
        ),
      );

  Widget _toolbar() => EditorToolbar.basic(
        controller: _editorController,
        showMarkers: true,
        multiRowsDisplay: false,
      );

  Widget _jsonPreview() => Expanded(
        child: SingleChildScrollView(
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 15),
            child: TextField(
              controller: _jsonInputController,
              maxLines: null,
              minLines: 1,
            ),
          ),
        ),
      );

  // === UTILS ===

  void _setupEditorController() {
    _editorController = EditorController(
        document: DocumentM.fromJson(
          jsonDecode(LOREM_LIPSUM_DOC_JSON),
        ),
        onBuildComplete: _updateJsonPreview);
  }

  void _setupJsonInputController() =>
      _jsonInputController = TextEditingController(
        text: _formatJson(
          LOREM_LIPSUM_DOC_JSON,
        ),
      );

  Future<void> _loadDocumentAndInitController() async {
    final doc = await rootBundle.loadString(
      'assets/docs/delta-sandbox.json',
    );
    final delta = DocumentM.fromJson(jsonDecode(doc)).toDelta();

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
      _editorController.document.toDelta().toJson(),
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
        final delta = DocumentM.fromJson(
          jsonDecode(_jsonInputController.text),
        ).toDelta();

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
