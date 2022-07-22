import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:visual_editor/visual-editor.dart';

import '../widgets/demo-scaffold.dart';

class DeltaSandbox extends StatefulWidget {
  const DeltaSandbox({Key? key}) : super(key: key);

  @override
  State<DeltaSandbox> createState() => _DeltaSandboxState();
}

class _DeltaSandboxState extends State<DeltaSandbox> {
  late EditorController _editorController;
  late TextEditingController _jsonInputController;
  late final StreamSubscription _editorListener;
  late final StreamSubscription _jsonInputListener;

  // Essential for preventing a circular invocation.
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    _setupEditorController();
    _setupJsonInputController();
    _subscribeToEditor();
    _subscribeToJsonInput();
    _loadDocument();
    super.initState();
  }

  @override
  void dispose() {
    _jsonInputController.dispose();
    _editorListener.cancel();
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
              scrollController: ScrollController(),
              focusNode: _focusNode,
              config: EditorConfigM(
                placeholder: 'Enter text',
              ),
            ),
          ),
        ),
      );

  Widget _toolbar() => Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 8,
        ),
        child: EditorToolbar.basic(
          controller: _editorController,
        ),
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
    );
  }

  void _setupJsonInputController() =>
      _jsonInputController = TextEditingController(
        text: _formatJson(
          LOREM_LIPSUM_DOC_JSON,
        ),
      );

  Future<void> _loadDocument() async {
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

  void _subscribeToEditor() {
    _editorListener = _editorController.document.changes.listen((_) {
      final jsonDoc = jsonEncode(
        _editorController.document.toDelta().toJson(),
      );

      // Update json preview only if the change was emitted by the editor
      if (_focusNode.hasFocus) {
        _jsonInputController.text = _formatJson(jsonDoc);
      }
    });
  }

  void _subscribeToJsonInput() {
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
