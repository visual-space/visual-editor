import 'package:flutter/cupertino.dart';

import '../../document/models/attributes/attributes.model.dart';
import '../../shared/state/editor.state.dart';
import '../../styles/services/styles.service.dart';
import '../intents/apply-header.intent.dart';

// Applies header to the selected line.
class ApplyHeaderAction extends Action<ApplyHeaderIntent> {
  late final StylesService _stylesService;

  final EditorState state;

  ApplyHeaderAction(this.state) {
    _stylesService = StylesService(state);
  }

  @override
  void invoke(ApplyHeaderIntent intent, [BuildContext? context]) {
    // Checks if selection has a header applied, if not adds an header attr with a null value
    final selectionHeader =
        _stylesService.getSelectionStyle().attributes[AttributesM.header.key] ??
            AttributesM.header;

    // If intent (applied header using keyboard hotkey (e.g. CTRL + 1) is the same as
    // the selection header, then set attr to an header with null value,
    // otherwise set it to intent header.
    final attribute =
        selectionHeader == intent.header ? AttributesM.header : intent.header;

    // Format selection with the corresponding attr.
    _stylesService.formatSelection(
      attribute,
    );
  }

  @override
  bool get isActionEnabled => true;
}
