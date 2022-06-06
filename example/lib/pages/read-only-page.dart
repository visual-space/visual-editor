import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:visual_editor/visual-editor.dart' hide Text;

import '../universal_ui/universal-ui.dart';
import '../widgets/demo-scaffold.dart';

class ReadOnlyPage extends StatefulWidget {
  @override
  _ReadOnlyPageState createState() => _ReadOnlyPageState();
}

class _ReadOnlyPageState extends State<ReadOnlyPage> {
  final FocusNode _focusNode = FocusNode();
  bool _edit = false;

  @override
  Widget build(BuildContext context) {
    return DemoScaffold(
      documentFilename: 'sample_data.json',
      builder: _buildContent,
      showToolbar: _edit == true,
      floatingActionButton: FloatingActionButton.extended(
        label: Text(_edit == true ? 'Done' : 'Edit'),
        onPressed: _toggleEdit,
        icon: Icon(_edit == true ? Icons.check : Icons.edit),
      ),
    );
  }

  Widget _buildContent(BuildContext context, EditorController? controller) {
    var visualEditor = VisualEditor(
      controller: controller!,
      scrollController: ScrollController(),
      focusNode: _focusNode,
      config: EditorCfgM(
        autoFocus: true,
        readOnly: !_edit,
      ),
    );
    if (kIsWeb) {
      visualEditor = VisualEditor(
        controller: controller,
        scrollController: ScrollController(),
        focusNode: _focusNode,
        config: EditorCfgM(
          autoFocus: true,
          readOnly: !_edit,
          embedBuilder: defaultEmbedBuilderWeb,
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: visualEditor,
      ),
    );
  }

  void _toggleEdit() {
    setState(() {
      _edit = !_edit;
    });
  }
}
