import 'package:flutter/cupertino.dart';

import '../../editor/models/boundaries/character-boundary.model.dart';
import '../../editor/services/editor.service.dart';
import '../../shared/state/editor.state.dart';
import '../actions/apply-checklist-action.dart';
import '../actions/apply-header.action.dart';
import '../actions/copy-selection.action.dart';
import '../actions/delete-text.action.dart';
import '../actions/extend-selection-or-caret-position.action.dart';
import '../actions/indent-selection.action.dart';
import '../actions/select-all.action.dart';
import '../actions/toggle-text-style.action.dart';
import '../actions/update-text-selection-to-adjiacent-line.action.dart';
import '../actions/update-text-selection.action.dart';
import '../intents/apply-checklist.intent.dart';
import '../intents/apply-header.intent.dart';
import '../intents/indent-selection.intent.dart';
import '../intents/open-searchbar.intent.dart';
import '../intents/toggle-text-style.intent.dart';
import '../models/base/text-boundary.model.dart';
import '../models/collapse-selection.boundary.model.dart';
import '../models/document-boundary.model.dart';
import '../models/expanded-text-boundary.dart';
import '../models/line-break.model.dart';
import '../models/mixed.boundary.model.dart';
import '../models/whitespace-boundary.model.dart';
import '../models/word-boundary.model.dart' as models;
import 'clipboard.service.dart';

// Recognizes standard keyboard interactions and triggers document changes accordingly.
// (change selection, copy, paste etc)
class KeyboardActionsService {
  late final EditorService _editorService;
  late final ClipboardService _clipboardService;

  final EditorState state;

  KeyboardActionsService(this.state) {
    _editorService = EditorService(state);
    _clipboardService = ClipboardService(state);
  }

  // The method returns a map of intents and actions.
  // This system is built in Flutter to facilitate handling of text fields.
  // Custom behaviours can be defined when handling text.
  //
  // Needs refactoring:
  // Several types of actions are grouped together in one single factory class.
  // For example the DeleteTextAction can change it's behavior by
  // being initialised with different boundaries methods.
  // Also it contains a lot of if branches.
  // I'm thinking some of this code overlaps partly and can be isolated in
  // unique classes for a simpler code architecture.
  Map<Type, Action<Intent>> getActions(BuildContext context) {
    _initAndCacheAdjacentLineAction();
    final plainText = _editorService.plainText;

    return <Type, Action<Intent>>{
      // === VARIOUS ===

      DoNothingAndStopPropagationTextIntent: DoNothingAction(
        consumesKey: false,
      ),
      ReplaceTextIntent: CallbackAction<ReplaceTextIntent>(
        onInvoke: _clipboardService.removeSpecialCharsAndUpdateDocTextAndStyle,
      ),
      UpdateSelectionIntent: CallbackAction<UpdateSelectionIntent>(
        onInvoke: _updateSelection,
      ),
      DirectionalFocusIntent: DirectionalFocusAction.forTextField(),

      OpenSearchbarIntent: CallbackAction<OpenSearchbarIntent>(
        onInvoke: (_) => _displaySearchBar(context),
      ),

      // === DELETE ===

      DeleteCharacterIntent: _makeOverridable(
        DeleteTextAction<DeleteCharacterIntent>(
          _characterBoundary,
          state,
        ),
        context,
      ),
      DeleteToNextWordBoundaryIntent: _makeOverridable(
        DeleteTextAction<DeleteToNextWordBoundaryIntent>(
          _nextWordBoundary,
          state,
        ),
        context,
      ),
      DeleteToLineBreakIntent: _makeOverridable(
        DeleteTextAction<DeleteToLineBreakIntent>(_linebreak, state),
        context,
      ),

      // === EXTEND/MOVE SELECTION ===

      ExtendSelectionByCharacterIntent: _makeOverridable(
        UpdateTextSelectionAction<ExtendSelectionByCharacterIntent>(
          false,
          _characterBoundary,
          state,
        ),
        context,
      ),
      ExtendSelectionToNextWordBoundaryIntent: _makeOverridable(
        UpdateTextSelectionAction<ExtendSelectionToNextWordBoundaryIntent>(
          true,
          _nextWordBoundary,
          state,
        ),
        context,
      ),
      ExtendSelectionToLineBreakIntent: _makeOverridable(
        UpdateTextSelectionAction<ExtendSelectionToLineBreakIntent>(
          true,
          _linebreak,
          state,
        ),
        context,
      ),
      ExtendSelectionVerticallyToAdjacentLineIntent: _makeOverridable(
        state.refs.adjacentLineAction!,
        context,
      ),
      ExtendSelectionToDocumentBoundaryIntent: _makeOverridable(
        UpdateTextSelectionAction<ExtendSelectionToDocumentBoundaryIntent>(
          true,
          (intent) => DocumentBoundary(plainText),
          state,
        ),
        context,
      ),
      ExtendSelectionToNextWordBoundaryOrCaretLocationIntent: _makeOverridable(
        ExtendSelectionOrCaretPositionAction(
          _nextWordBoundary,
          state,
        ),
        context,
      ),

      // === COPY PASTE ===

      SelectAllTextIntent: _makeOverridable(
        SelectAllAction(state),
        context,
      ),
      CopySelectionTextIntent: _makeOverridable(
        CopySelectionAction(state),
        context,
      ),
      PasteTextIntent: _makeOverridable(
        CallbackAction<PasteTextIntent>(
          onInvoke: (intent) => _clipboardService.pasteText(intent.cause),
        ),
        context,
      ),

      // === INDENTATION ===

      IndentSelectionIntent: IndentSelectionAction(state),

      // === TEXT STYLE ===

      ToggleTextStyleIntent: ToggleTextStyleAction(state),

      // === CHECKLIST ===

      ApplyChecklistIntent: ApplyCheckListAction(state),

      // === HEADER ===

      ApplyHeaderIntent: ApplyHeaderAction(state),
    };
  }

  // === PRIVATE ===

  void _initAndCacheAdjacentLineAction() {
    state.refs.adjacentLineAction ??= UpdateTextSelectionToAdjacentLineAction<
        ExtendSelectionVerticallyToAdjacentLineIntent>(state);
  }

  TextBoundaryM _characterBoundary(DirectionalTextEditingIntent intent) {
    final TextBoundaryM atomicTextBoundary = CharacterBoundary(state);

    return CollapsedSelectionBoundary(atomicTextBoundary, intent.forward);
  }

  TextBoundaryM _nextWordBoundary(DirectionalTextEditingIntent intent) {
    final TextBoundaryM atomicTextBoundary;
    final TextBoundaryM boundary;
    final plainText = _editorService.plainText;

    atomicTextBoundary = CharacterBoundary(state);

    // This isn't enough. Newline characters.
    boundary = ExpandedTextBoundary(
      WhitespaceBoundary(plainText),
      models.WordBoundary(state.refs.renderer, plainText),
    );

    final mixedBoundary = intent.forward
        ? MixedBoundary(atomicTextBoundary, boundary)
        : MixedBoundary(boundary, atomicTextBoundary);

    // Use a _MixedBoundary to make sure we don't leave invalid codepoints in the field after deletion.
    return CollapsedSelectionBoundary(mixedBoundary, intent.forward);
  }

  TextBoundaryM _linebreak(DirectionalTextEditingIntent intent) {
    final TextBoundaryM atomicTextBoundary;
    final TextBoundaryM boundary;
    final plainText = _editorService.plainText;

    atomicTextBoundary = CharacterBoundary(state);
    boundary = LineBreak(state.refs.renderer, plainText);

    // The _MixedBoundary is to make sure we don't leave invalid code units in the field after deletion.
    // `boundary` doesn't need to be wrapped in a _CollapsedSelectionBoundary,
    // since the document boundary is unique and the linebreak boundary is already caret-location based.
    return intent.forward
        ? MixedBoundary(
            CollapsedSelectionBoundary(atomicTextBoundary, true),
            boundary,
          )
        : MixedBoundary(
            boundary,
            CollapsedSelectionBoundary(atomicTextBoundary, false),
          );
  }

  // Needs improved documentation.
  // Currently not sure why all actions need to be overridable.
  // Flutter explains that actions can be overriden, but it's unclear when and why to do so.
  Action<T> _makeOverridable<T extends Intent>(
    Action<T> defaultAction,
    BuildContext context,
  ) {
    return Action<T>.overridable(
      context: context,
      defaultAction: defaultAction,
    );
  }

  void _displaySearchBar(BuildContext context) {
    final overlayState = Overlay.of(context);

    overlayState.insert(
      state.refs.overlayEntry,
    );
  }

  void _updateSelection(UpdateSelectionIntent intent) {
    _editorService.removeSpecialCharsAndUpdateDocTextAndStyle(
      intent.currentTextEditingValue.copyWith(
        selection: intent.newSelection,
      ),
      intent.cause,
    );
  }

  UpdateTextSelectionToAdjacentLineAction<
          ExtendSelectionVerticallyToAdjacentLineIntent>
      getAdjacentLineAction() => UpdateTextSelectionToAdjacentLineAction<
              ExtendSelectionVerticallyToAdjacentLineIntent>(
            state,
          );
}
