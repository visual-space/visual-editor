import 'package:flutter/cupertino.dart';

import '../../controller/services/editor-text.service.dart';
import '../../controller/state/editor-controller.state.dart';
import '../models/boundaries/base/text-boundary.model.dart';
import '../models/boundaries/character-boundary.model.dart';
import '../models/boundaries/collapse-selection.boundary.model.dart';
import '../models/boundaries/document-boundary.model.dart';
import '../models/boundaries/expanded-text-boundary.dart';
import '../models/boundaries/line-break.model.dart';
import '../models/boundaries/mixed.boundary.model.dart';
import '../models/boundaries/whitespace-boundary.model.dart';
import '../models/boundaries/word-boundary.model.dart';
import '../state/editor-renderer.state.dart';
import 'actions/copy-selection.action.dart';
import 'actions/delete-text.action.dart';
import 'actions/extend-selection-or-caret-position.action.dart';
import 'actions/select-all.action.dart';
import 'actions/update-text-selection-to-adjiacent-line.action.dart';
import 'actions/update-text-selection.action.dart';
import 'clipboard.service.dart';

class KeyboardActionsService {
  final _editorTextService = EditorTextService();
  final _editorRendererState = EditorRendererState();
  final _editorControllerState = EditorControllerState();
  final _clipboardService = ClipboardService();

  static final _instance = KeyboardActionsService._privateConstructor();

  factory KeyboardActionsService() => _instance;

  KeyboardActionsService._privateConstructor();

  Map<Type, Action<Intent>> getActions(BuildContext context) =>
      <Type, Action<Intent>>{
        DoNothingAndStopPropagationTextIntent: DoNothingAction(
          consumesKey: false,
        ),
        ReplaceTextIntent: _replaceTextAction,
        UpdateSelectionIntent: _updateSelectionAction,
        DirectionalFocusIntent: DirectionalFocusAction.forTextField(),

        // Delete
        DeleteCharacterIntent: _makeOverridable(
          DeleteTextAction<DeleteCharacterIntent>(_characterBoundary),
          context,
        ),
        DeleteToNextWordBoundaryIntent: _makeOverridable(
          DeleteTextAction<DeleteToNextWordBoundaryIntent>(_nextWordBoundary),
          context,
        ),
        DeleteToLineBreakIntent: _makeOverridable(
          DeleteTextAction<DeleteToLineBreakIntent>(_linebreak),
          context,
        ),

        // Extend/Move Selection
        ExtendSelectionByCharacterIntent: _makeOverridable(
          UpdateTextSelectionAction<ExtendSelectionByCharacterIntent>(
            false,
            _characterBoundary,
          ),
          context,
        ),
        ExtendSelectionToNextWordBoundaryIntent: _makeOverridable(
          UpdateTextSelectionAction<ExtendSelectionToNextWordBoundaryIntent>(
            true,
            _nextWordBoundary,
          ),
          context,
        ),
        ExtendSelectionToLineBreakIntent: _makeOverridable(
          UpdateTextSelectionAction<ExtendSelectionToLineBreakIntent>(
            true,
            _linebreak,
          ),
          context,
        ),
        ExtendSelectionVerticallyToAdjacentLineIntent: _makeOverridable(
          getAdjacentLineAction(),
          context,
        ),
        ExtendSelectionToDocumentBoundaryIntent: _makeOverridable(
          UpdateTextSelectionAction<ExtendSelectionToDocumentBoundaryIntent>(
            true,
            _documentBoundary,
          ),
          context,
        ),
        ExtendSelectionToNextWordBoundaryOrCaretLocationIntent:
            _makeOverridable(
          ExtendSelectionOrCaretPositionAction(_nextWordBoundary),
          context,
        ),

        // Copy Paste
        SelectAllTextIntent: _makeOverridable(
          SelectAllAction(),
          context,
        ),
        CopySelectionTextIntent: _makeOverridable(
          CopySelectionAction(),
          context,
        ),
        PasteTextIntent: _makeOverridable(
          CallbackAction<PasteTextIntent>(
            onInvoke: (intent) => _clipboardService.pasteText(
              intent.cause,
              _editorControllerState.controller,
            ),
          ),
          context,
        ),
      };

  // === PRIVATE ===

  TextBoundaryM _characterBoundary(DirectionalTextEditingIntent intent) {
    final TextBoundaryM atomicTextBoundary = CharacterBoundary(
      _editorTextService.textEditingValue,
    );

    return CollapsedSelectionBoundary(atomicTextBoundary, intent.forward);
  }

  TextBoundaryM _nextWordBoundary(
    DirectionalTextEditingIntent intent,
  ) {
    final TextBoundaryM atomicTextBoundary;
    final TextBoundaryM boundary;

    // final TextEditingValue textEditingValue =
    //     _textEditingValueforTextLayoutMetrics;
    atomicTextBoundary = CharacterBoundary(_editorTextService.textEditingValue);

    // This isn't enough. Newline characters.
    boundary = ExpandedTextBoundary(
      WhitespaceBoundary(_editorTextService.textEditingValue),
      WordBoundary(
        _editorRendererState.renderer,
        _editorTextService.textEditingValue,
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
  ) {
    final TextBoundaryM atomicTextBoundary;
    final TextBoundaryM boundary;

    // final TextEditingValue textEditingValue =
    //     _textEditingValueforTextLayoutMetrics;
    atomicTextBoundary = CharacterBoundary(_editorTextService.textEditingValue);
    boundary = LineBreak(
      _editorRendererState.renderer,
      _editorTextService.textEditingValue,
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

  TextBoundaryM _documentBoundary(DirectionalTextEditingIntent intent) =>
      DocumentBoundary(_editorTextService.textEditingValue);

  Action<T> _makeOverridable<T extends Intent>(
    Action<T> defaultAction,
    BuildContext context,
  ) {
    return Action<T>.overridable(
      context: context,
      defaultAction: defaultAction,
    );
  }

  late final _replaceTextAction = CallbackAction<ReplaceTextIntent>(
    onInvoke: _clipboardService.replaceText,
  );

  void _updateSelection(UpdateSelectionIntent intent) {
    _editorTextService.userUpdateTextEditingValue(
      intent.currentTextEditingValue.copyWith(
        selection: intent.newSelection,
      ),
      intent.cause,
    );
  }

  late final _updateSelectionAction = CallbackAction<UpdateSelectionIntent>(
    onInvoke: _updateSelection,
  );

  UpdateTextSelectionToAdjacentLineAction<
          ExtendSelectionVerticallyToAdjacentLineIntent>
      getAdjacentLineAction() => UpdateTextSelectionToAdjacentLineAction<
          ExtendSelectionVerticallyToAdjacentLineIntent>();
}
