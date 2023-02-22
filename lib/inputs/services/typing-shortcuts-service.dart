import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../document/models/attributes/attribute.model.dart';
import '../../document/models/attributes/attributes-aliases.model.dart';
import '../../document/models/history/change-source.enum.dart';
import '../../document/models/nodes/block.model.dart';
import '../../document/models/nodes/line.model.dart';
import '../../document/services/nodes/line.utils.dart';
import '../../selection/services/selection.service.dart';
import '../../shared/state/editor.state.dart';

// When user types specific combinations of keys (e.g. 1. + space, TAB, etc.) apply specific styling/indenting/inserting actions.
class TypingShortcutsService {
  late final SelectionService _selectionService;

  final EditorState state;

  TypingShortcutsService(this.state) {
    _selectionService = SelectionService(state);
  }

  // Returns the pressed or released key.
  KeyEventResult getKeyEventResult(FocusNode node, RawKeyEvent event) {
    // Don't handle key if there is a meta key pressed.
    if (event.isAltPressed || event.isControlPressed || event.isMetaPressed) {
      return KeyEventResult.ignored;
    }

    // When the key is released, do nothing.
    if (event is! RawKeyDownEvent) {
      return KeyEventResult.ignored;
    }

    // Don't handle key if there is an active selection.
    if (state.refs.controller.selection.baseOffset !=
        state.refs.controller.selection.extentOffset) {
      return KeyEventResult.ignored;
    }

    // Handle indenting blocks when pressing the tab key.
    if (event.logicalKey == LogicalKeyboardKey.tab) {
      return _handleTabKey(event);
    }

    // Handle inserting lists when space is pressed following a list initiating phrase.
    if (event.logicalKey == LogicalKeyboardKey.space) {
      _handleSpaceKey(event);
    }

    // Default
    return KeyEventResult.ignored;
  }

  // === PRIVATE ==

  KeyEventResult _handleSpaceKey(RawKeyEvent event) {
    final child = state.refs.documentController.queryChild(
      state.refs.controller.selection.baseOffset,
    );

    if (child.node == null) {
      return KeyEventResult.ignored;
    }

    final line = child.node as LineM?;
    if (line == null) {
      return KeyEventResult.ignored;
    }

    // Get the first 2 chars of a line.
    final lineUtils = LineUtils();
    final text = lineUtils.getPlainText(line, 0, 2);

    const olKeyPhrase = '1.';
    const ulKeyPhrase = '-';

    if (text == olKeyPhrase) {
      _updateSelectionForKeyPhrase(
        olKeyPhrase,
        AttributesAliasesM.orderedList,
      );
    } else if (text[0] == ulKeyPhrase) {
      _updateSelectionForKeyPhrase(
        ulKeyPhrase,
        AttributesAliasesM.bulletList,
      );
    } else {
      return KeyEventResult.ignored;
    }

    return KeyEventResult.handled;
  }

  KeyEventResult _handleTabKey(RawKeyEvent event) {
    final child = state.refs.documentController.queryChild(
      state.refs.controller.selection.baseOffset,
    );
    final node = child.node!;
    final nodeParent = node.parent;

    if (child.node == null) {
      return _insertTabCharacter();
    }

    if (nodeParent == null || nodeParent is! BlockM) {
      return event.isShiftPressed
          ? _removeTabCharacter()
          : _insertTabCharacter();
    }

    // Ordered lists, unordered lists, checked type line.
    if (nodeParent.style.containsKey(AttributesAliasesM.orderedList.key) ||
        nodeParent.style.containsKey(AttributesAliasesM.bulletList.key) ||
        nodeParent.style.containsKey(AttributesAliasesM.checked.key)) {
      state.refs.controller.indentSelection(!event.isShiftPressed);
      return KeyEventResult.handled;
    }

    if (node is! LineM || (node.isNotEmpty && node.first is! String)) {
      return _insertTabCharacter();
    }

    if (node.isNotEmpty && (node.first as String).isNotEmpty) {
      return _insertTabCharacter();
    }

    return _insertTabCharacter();
  }

  void _updateSelectionForKeyPhrase(
    String phrase,
    AttributeM attribute,
  ) {
    state.refs.controller
      ..formatSelection(attribute)
      ..replaceText(
        state.refs.controller.selection.baseOffset - phrase.length,
        phrase.length,
        '',
        null,
      );

    // It is unclear why the selection moves forward the edit distance.
    // For indenting a bullet list we need to move the cursor with -1 and for ol with -2.
    attribute == AttributesAliasesM.orderedList
        ? _moveCursor(-2)
        : _moveCursor(-1);
  }

  // TODO When pressing shift + tab even though there aren't any tab char added
  // The logic is going to remove 4 chars before the charet. That's not what we intend.
  // One possible solution to this is to verify if there are 4 whitespaces before the charet.
  // If there are, apply this logic, else do not.
  KeyEventResult _removeTabCharacter() {
    state.refs.controller.replaceText(
      state.refs.controller.selection.baseOffset - 4,
      4,
      '',
      null,
    );

    _moveCursor(-4);

    return KeyEventResult.handled;
  }

  // Flutter doesn't add the \t character properly, so in order to add 4 whitespaces
  // we used a string.
  KeyEventResult _insertTabCharacter() {
    const tab = '    ';

    state.refs.controller.replaceText(
      state.refs.controller.selection.baseOffset,
      0,
      tab,
      null,
    );

    _moveCursor(4);

    return KeyEventResult.handled;
  }

  void _moveCursor(int chars) {
    final selection = state.refs.controller.selection;

    _selectionService.cacheSelectionAndRunBuild(
      state.refs.controller.selection.copyWith(
        baseOffset: selection.baseOffset + chars,
        extentOffset: selection.baseOffset + chars,
      ),
      ChangeSource.LOCAL,
    );
  }
}
