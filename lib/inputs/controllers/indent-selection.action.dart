import 'package:flutter/cupertino.dart';

import '../../shared/state/editor.state.dart';
import '../intents/indent-selection.intent.dart';

class IndentSelectionAction extends Action<IndentSelectionIntent> {
  final EditorState state;

  IndentSelectionAction(this.state);

  @override
  void invoke(IndentSelectionIntent intent, [BuildContext? context]) {
    state.refs.controller.indentSelection(
      intent.isIncrease,
    );
  }

  @override
  bool get isActionEnabled => true;
}
