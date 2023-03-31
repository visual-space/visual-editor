import 'package:flutter/cupertino.dart';

import '../../shared/state/editor.state.dart';
import '../../styles/services/styles.service.dart';
import '../intents/indent-selection.intent.dart';

// It either indents or un-indents the selection lines of text based on the value of
// the IndentSelectionIntent.
class IndentSelectionAction extends Action<IndentSelectionIntent> {
  late final StylesService _stylesService;

  final EditorState state;

  IndentSelectionAction(this.state) {
    _stylesService = StylesService(state);
  }

  @override
  void invoke(IndentSelectionIntent intent, [BuildContext? context]) {
    _stylesService.indentSelection(
      intent.isIncrease,
    );
  }

  @override
  bool get isActionEnabled => true;
}
