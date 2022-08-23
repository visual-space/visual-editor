import '../../controller/state/paste.state.dart';
import '../../cursor/state/cursor.state.dart';
import '../../documents/state/document.state.dart';
import '../../editor/state/editor-config.state.dart';
import '../../editor/state/platform-styles.state.dart';
import '../../editor/state/refresh-editor.state.dart';
import '../../editor/state/scroll-animation.state.dart';
import '../../editor/state/styles.state.dart';
import '../../highlights/state/highlights.state.dart';
import '../../inputs/state/keyboard-visible.state.dart';
import '../../inputs/state/pressed-keys.state.dart';
import '../../markers/state/markers-types.state.dart';
import '../../markers/state/markers-visibility.state.dart';
import '../../selection/state/extend-selection.state.dart';
import '../../selection/state/last-tap-down.state.dart';
import '../../selection/state/selection-layers.state.dart';
import 'references.state.dart';

// Global state store.
// Stores the entire state of an editor instance.
// Attempts to use the same principles of operation as any redux/ngrx state store.
// (pure data, unidirectional, reactive)
// We use one class to hold all the state needed by one editor instance.
// Prior to this design we had all the states as singletons.
// The advantage of the previous solution was the reduction of properties drill down.
// However the issue with the prev design was that multiple instances were sharing the same state.
// With the current pattern we still have to drill down props, but it's far easier to follow the line.
// Read more here: https://github.com/visual-space/visual-editor/blob/develop/lib/shared/state-store.md

class EditorState {
  // Controller
  final paste = PasteState();

  // Cursor
  final cursor = CursorState();

  // Documents
  final document = DocumentState();

  // Editor
  final editorConfig = EditorConfigState();
  final refreshEditor = RefreshEditorState();
  final styles = StylesState();
  final platformStyles = PlatformStylesState();
  final scrollAnimation = ScrollAnimationState();

  // Highlights
  final highlights = HighlightsState();

  // Inputs
  final keyboardVisible = KeyboardVisibleState();
  final pressedKeys = PressedKeysState();

  // Markers
  final markersTypes = MarkersTypesState();
  final markersVisibility = MarkersVisibilityState();

  // Selections
  final extendSelection = ExtendSelectionState();
  final lastTapDown = LastTapDownState();
  final selectionLayers = SelectionLayersState();

  // Caches references to different classes (widgets, renderers)
  // The library needs to support multiple instances.
  // Each instance has it's own custom state and it's own set of internal references.
  // We can't have the states as singletons, neither as constructor params for services, so we have to drill down via params.
  // Ideally we would keep the state store free of logic (pure data only, similar to redux, bloc, mobx, etc).
  // However, since we have to traverse so many files, it's more convenient to have fewer inputs to drill down.
  // Since already the state is passed all over the place we added the refs here for pure convenience.
  // Over 100 usages in 20+ files, so that would have required quite a lot of new inputs.
  final refs = ReferencesState();
}
