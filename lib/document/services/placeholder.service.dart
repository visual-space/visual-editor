import 'dart:convert';

import '../../document/models/delta-doc.model.dart';
import '../../shared/state/editor.state.dart';
import '../controllers/document.controller.dart';

// If the user provided doc is empty then we provide back a placeholder document.
// The placeholder doc is used until the user document is filled up with some characters.
class PlaceholderService {
  final EditorState state;

  PlaceholderService(this.state);

  // If the user document is empty, we replace it with placeholder document.
  // Note that we are not inserting content in the editor document.
  // Once the user starts typing characters the input will be preserved in an empty document.
  // The placeholder doc+controller are used only temporarily until the editor doc is no longer empty.
  DocumentController getDocOrPlaceholderCtrl() {
    final docIsEmpty = state.refs.documentController.isEmpty();
    final showPlaceholder = docIsEmpty && state.config.placeholder != null;
    var docController = state.refs.documentController;

    if (showPlaceholder) {
      docController = DocumentController(_placeholderDoc(), null, null);
    }

    return docController;
  }

  DeltaDocM _placeholderDoc() => DeltaDocM.fromJson(
        jsonDecode(
          '[{'
            '"attributes":{"placeholder":true},'
            '"insert":"${state.config.placeholder}\\n"'
          '}]',
        ),
      );

}
