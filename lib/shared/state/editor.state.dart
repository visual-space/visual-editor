import '../../controller/state/paste.state.dart';
import '../../cursor/state/cursor.state.dart';
import '../../document/state/document.state.dart';
import '../../editor/models/editor-cfg.model.dart';
import '../../editor/state/run-build.state.dart';
import '../../editor/state/scroll-animation.state.dart';
import '../../headings/state/headings.state.dart';
import '../../highlights/state/highlights.state.dart';
import '../../inputs/state/input.state.dart';
import '../../inputs/state/keyboard.state.dart';
import '../../inputs/state/pressed-keys.state.dart';
import '../../markers/state/markers-types.state.dart';
import '../../markers/state/markers-visibility.state.dart';
import '../../markers/state/markers.state.dart';
import '../../selection/state/last-tap-down.state.dart';
import '../../selection/state/selection-layers.state.dart';
import '../../selection/state/selection.state.dart';
import '../../styles/state/platform-styles.state.dart';
import '../../styles/state/styles.state.dart';
import '../../toolbar/state/toolbar.state.dart';
import 'references.state.dart';

// Stores the entire state of an editor instance.
// The goal is to isolate the state layer in a distinct pure data layer.
// The editor can be initialised several times in a page, therefore
// the store is passed via prop drilling instead of imports.
// Each state is related to one feature.
// We don't have a group for modules since we don't have that many features to track.
// Beware: We made special effort too keep the store private and
// to prevent direct access form the client code.
// Keeping the store private avoids internal implementation lock-in.
// Note that we skipped one level for the config state to avoid useless double
// nesting all over the codebase "state.config.config".
// Read more: state-store.md
class EditorState {
  // Controller
  final paste = PasteState();

  // Cursor
  final cursor = CursorState();

  // Documents
  final document = DocumentState();
  final headings = HeadingsState();

  // Editor
  late EditorConfigM config;
  final runBuild = RunBuildState();
  final styles = StylesState();
  final platformStyles = PlatformStylesState();
  final scrollAnimation = ScrollAnimationState();

  // Highlights
  final highlights = HighlightsState();

  // Inputs
  final input = InputState();
  final keyboard = KeyboardState();
  final pressedKeys = PressedKeysState();

  // Markers
  final markersTypes = MarkersTypesState();
  final markers = MarkersState();
  final markersVisibility = MarkersVisibilityState();

  // Selection
  final selection = SelectionState();
  final lastTapDown = LastTapDownState();
  final selectionLayers = SelectionLayersState();

  // Toolbar
  final toolbar = ToolbarState();

  // Internal References
  final refs = ReferencesState();
}
