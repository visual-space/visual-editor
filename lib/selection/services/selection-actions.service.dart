import 'package:flutter/foundation.dart';

import 'selection-actions.logic.dart';

// Shows the selection buttons at the location of the current cursor.
// Returns `false` if a buttons couldn't be shown.
// When the buttons is already shown, or when no text selection currently exists.
// Web is using native dom elements to enable clipboard functionality of the buttons: copy, paste, select, cut.
// It might also provide additional functionality depending on the browser (such as translate).
// Due to this we should not show Flutter buttons for the editable text elements.
class SelectionActionsService {
  // +++ REVIEW Controller? State? Merge?
  SelectionActionsLogic? selectionActions;

  static final _instance = SelectionActionsService._privateConstructor();

  factory SelectionActionsService() => _instance;

  SelectionActionsService._privateConstructor();

  // +++ DELETE, TEMP until widget.controller is migrated
  dynamic rawEditorState;

  bool showToolbar() {
    if (kIsWeb) {
      return false;
    }

    final hasSelection = selectionActions == null;
    final hasToolbarAlready = selectionActions!.toolbar != null;

    if (hasSelection || hasToolbarAlready) {
      return false;
    }

    selectionActions!.update(rawEditorState.textEditingValue);
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
