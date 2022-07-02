import 'package:flutter/cupertino.dart';

import '../../controller/services/editor-text.service.dart';
import '../../editor/models/boundaries/character-boundary.model.dart';
import '../../shared/state/editor.state.dart';
import '../controllers/copy-selection.action.dart';
import '../controllers/delete-text.action.dart';
import '../controllers/extend-selection-or-caret-position.action.dart';
import '../controllers/select-all.action.dart';
import '../controllers/update-text-selection-to-adjiacent-line.action.dart';
import '../controllers/update-text-selection.action.dart';
import '../models/base/text-boundary.model.dart';
import '../models/collapse-selection.boundary.model.dart';
import '../models/document-boundary.model.dart';
import '../models/expanded-text-boundary.dart';
import '../models/line-break.model.dart';
import '../models/mixed.boundary.model.dart';
import '../models/whitespace-boundary.model.dart';
import '../models/word-boundary.model.dart';
import 'clipboard.service.dart';

class KeyboardActionsService {
  final _editorTextService = EditorTextService();
  final _clipboardService = ClipboardService();

  static final _instance = KeyboardActionsService._privateConstructor();

  factory KeyboardActionsService() => _instance;

  KeyboardActionsService._privateConstructor();

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
  Map<Type, Action<Intent>> getActions(
    BuildContext context,
    EditorState state,
  ) =>
      <Type, Action<Intent>>{
        // === VARIOUS ===

        DoNothingAndStopPropagationTextIntent: DoNothingAction(
          consumesKey: false,
        ),
        ReplaceTextIntent: CallbackAction<ReplaceTextIntent>(
          onInvoke: (intent) => _clipboardService.replaceText(intent, state),
        ),
        UpdateSelectionIntent: CallbackAction<UpdateSelectionIntent>(
          onInvoke: (intent) => _updateSelection(intent, state),
        ),
        DirectionalFocusIntent: DirectionalFocusAction.forTextField(),

        // === DELETE ===

        DeleteCharacterIntent: _makeOverridable(
          DeleteTextAction<DeleteCharacterIntent>(_characterBoundary, state),
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
          UpdateTextSelectionToAdjacentLineAction<
              ExtendSelectionVerticallyToAdjacentLineIntent>(state),
          context,
        ),
        ExtendSelectionToDocumentBoundaryIntent: _makeOverridable(
          UpdateTextSelectionAction<ExtendSelectionToDocumentBoundaryIntent>(
            true,
            (intent, state) => DocumentBoundary(
              state.refs.editorController.plainTextEditingValue,
            ),
            state,
          ),
          context,
        ),
        ExtendSelectionToNextWordBoundaryOrCaretLocationIntent:
            _makeOverridable(
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
            onInvoke: (intent) => _clipboardService.pasteText(
              intent.cause,
              state,
            ),
          ),
          context,
        ),
      };

  // === PRIVATE ===

  TextBoundaryM _characterBoundary(
    DirectionalTextEditingIntent intent,
    EditorState state,
  ) {
    final TextBoundaryM atomicTextBoundary = CharacterBoundary(state);

    return CollapsedSelectionBoundary(atomicTextBoundary, intent.forward);
  }

  TextBoundaryM _nextWordBoundary(
    DirectionalTextEditingIntent intent,
    EditorState state,
  ) {
    final TextBoundaryM atomicTextBoundary;
    final TextBoundaryM boundary;

    atomicTextBoundary = CharacterBoundary(state);

    // This isn't enough. Newline characters.
    boundary = ExpandedTextBoundary(
      WhitespaceBoundary(state.refs.editorController.plainTextEditingValue),
      WordBoundary(
        state.refs.renderer,
        state.refs.editorController.plainTextEditingValue,
      ),
    );

    final mixedBoundary = intent.forward
        ? MixedBoundary(atomicTextBoundary, boundary)
        : MixedBoundary(boundary, atomicTextBoundary);

    // Use a _MixedBoundary to make sure we don't leave invalid codepoints in the field after deletion.
    return CollapsedSelectionBoundary(mixedBoundary, intent.forward);
  }

  TextBoundaryM _linebreak(
    DirectionalTextEditingIntent intent,
    EditorState state,
  ) {
    final TextBoundaryM atomicTextBoundary;
    final TextBoundaryM boundary;

    atomicTextBoundary = CharacterBoundary(state);
    boundary = LineBreak(
      state.refs.renderer,
      state.refs.editorController.plainTextEditingValue,
    );

    // The _MixedBoundary is to make sure we don't leave invalid code units in the field after deletion.
    // `boundary` doesn't need to be wrapped in a _CollapsedSelectionBoundary,
    // since the document boundary is unique and the linebreak boundary is already caret-location based.
    return intent.forward
        ? MixedBoundary(
            CollapsedSelectionBoundary(
              atomicTextBoundary,
              true,
            ),
            boundary,
          )
        : MixedBoundary(
            boundary,
            CollapsedSelectionBoundary(
              atomicTextBoundary,
              false,
            ),
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

  void _updateSelection(
    UpdateSelectionIntent intent,
    EditorState state,
  ) {
    _editorTextService.userUpdateTextEditingValue(
      intent.currentTextEditingValue.copyWith(
        selection: intent.newSelection,
      ),
      intent.cause,
      state,
    );
  }

  UpdateTextSelectionToAdjacentLineAction<
      ExtendSelectionVerticallyToAdjacentLineIntent> getAdjacentLineAction(
    EditorState state,
  ) =>
      UpdateTextSelectionToAdjacentLineAction<
          ExtendSelectionVerticallyToAdjacentLineIntent>(state);
}
