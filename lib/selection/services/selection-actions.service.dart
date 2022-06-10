import 'package:flutter/foundation.dart';

import '../../editor/state/raw-editor-swidget.state.dart';
import 'selection-actions.logic.dart';

// Shows the selection buttons at the location of the current cursor.
// Returns `false` if a buttons couldn't be shown.
// When the buttons is already shown, or when no text selection currently exists.
// Web is using native dom elements to enable clipboard functionality of the buttons: copy, paste, select, cut.
// It might also provide additional functionality depending on the browser (such as translate).
// Due to this we should not show Flutter buttons for the editable text elements.
class SelectionActionsService {
  final _rawEditorSWidgetState = RawEditorSWidgetState();

  // +++ REVIEW Controller? State? Merge?
  // +++ It seems to be always un undefined
  SelectionActionsLogic? selectionActions;

  static final _instance = SelectionActionsService._privateConstructor();

  factory SelectionActionsService() => _instance;

  SelectionActionsService._privateConstructor();

  bool showToolbar() {
    if (kIsWeb) {
      return false;
    }

    final hasSelection = selectionActions == null;
    final hasToolbarAlready = selectionActions!.toolbar != null;

    if (hasSelection || hasToolbarAlready) {
      return false;
    }

    selectionActions!.update(_rawEditorSWidgetState.editor.textEditingValue);
    selectionActions!.showToolbar();

    return true;
  }

  void hideToolbar([bool hideHandles = true]) {
    // If the buttons is currently visible.
    if (selectionActions?.toolbar != null) {
      hideHandles ? selectionActions?.hide() : selectionActions?.hideToolbar();
    }
  }
}
