import '../../controller/state/paste.state.dart';
import '../../cursor/state/cursor.state.dart';
import '../../documents/state/document.state.dart';
import '../../editor/state/editor-config.state.dart';
import '../../editor/state/platform-styles.state.dart';
import '../../editor/state/refresh-editor.state.dart';
import '../../editor/state/scroll-animation.state.dart';
import '../../editor/state/styles.state.dart';
import '../../headings/state/headings.state.dart';
import '../../highlights/state/highlights.state.dart';
import '../../inputs/state/keyboard-visible.state.dart';
import '../../inputs/state/pressed-keys.state.dart';
import '../../markers/state/markers-types.state.dart';
import '../../markers/state/markers-visibility.state.dart';
import '../../markers/state/markers.state.dart';
import '../../selection/state/last-tap-down.state.dart';
import '../../selection/state/selection-layers.state.dart';
import '../../selection/state/selection.state.dart';
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
//
// Keep the state store private
// I made special effort too keep the store private and not to allow access to the state.
// If you are exposing the store in public you are breaking encapsulation,
// thus allowing anyone to write code that depends on our private code.
// Therefore our private code becomes public API.
// Therefore we can't safely upgrade without ruining many client apps that
// used the private state for their own affairs.
class EditorState {
  // Controller
  late final PasteState paste;

  // Cursor
  late final CursorState cursor;

  // Documents
  // Usually if you change the document then you will have to call refreshState()
  // to trigger a new widget tree build()
  // Most of the code that changes the document directly is hosted in the controller.
  late final DocumentState document;

  // Editor
  late final EditorConfigState editorConfig;
  late final RefreshEditorState refreshEditor;
  late final StylesState styles;
  late final PlatformStylesState platformStyles;
  late final ScrollAnimationState scrollAnimation;

  // Highlights
  late final HighlightsState highlights;

  // Inputs
  late final KeyboardVisibleState keyboardVisible;
  late final PressedKeysState pressedKeys;

  // Markers
  late final MarkersTypesState markersTypes;

  // (!) Derived from the document at each build (not the source of truth)
  late final MarkersState markers;
  late final MarkersVisibilityState markersVisibility;

  // Headings
  late final HeadingsState headings;

  // Selections
  late final SelectionState selection;
  late final LastTapDownState lastTapDown;
  late final SelectionLayersState selectionLayers;

  // Caches references to different classes (widgets, renderers)
  // The library needs to support multiple instances.
  // Each instance has it's own custom state and it's own set of internal references.
  // We can't have the states as singletons, neither as constructor params for services, so we have to drill down via params.
  // Ideally we would keep the state store free of logic (pure data only, similar to redux, bloc, mobx, etc).
  // However, since we have to traverse so many files, it's more convenient to have fewer inputs to drill down.
  // Since already the state is passed all over the place we added the refs here for pure convenience.
  // Over 100 usages in 20+ files, so that would have required quite a lot of new inputs.
  // TODO Brainstorm if there's a way to avoid passing refs via the state store.
  // - So far we know we can't use imports because we need to be able to run to instances of the same editor in one page
  // - We need several references because we need to call code provided by the flutter API (maybe it can be separated in services).
  late final ReferencesState refs;

  EditorState({
     paste,
     cursor,
     document,
     editorConfig,
     refreshEditor,
     styles,
     platformStyles,
     scrollAnimation,
     highlights,
     keyboardVisible,
     pressedKeys,
     markersTypes,
     markers,
     markersVisibility,
     headings,
     selection,
     lastTapDown,
     selectionLayers,
     refs,
  }) {
    this.paste = paste ?? PasteState();
    this.cursor = cursor ?? CursorState();
    this.document = document ?? DocumentState();
    this.editorConfig = editorConfig ?? EditorConfigState();
    this.refreshEditor = refreshEditor ?? RefreshEditorState();
    this.styles = styles ?? StylesState();
    this.platformStyles = platformStyles ?? PlatformStylesState();
    this.scrollAnimation = scrollAnimation ?? ScrollAnimationState();
    this.highlights = highlights ?? HighlightsState();
    this.keyboardVisible = keyboardVisible ?? KeyboardVisibleState();
    this.pressedKeys = pressedKeys ?? PressedKeysState();
    this.markersTypes = markersTypes ?? MarkersTypesState();
    this.markers = markers ?? MarkersState();
    this.markersVisibility = markersVisibility ?? MarkersVisibilityState();
    this.headings = headings ?? HeadingsState();
    this.selection = selection ?? SelectionState();
    this.lastTapDown = lastTapDown ?? LastTapDownState();
    this.selectionLayers = selectionLayers ?? SelectionLayersState();
    this.refs = refs ?? ReferencesState();
  }

  // A complex set of circumstances led to the need of shallow cloning the state store.
  // We created the state store to separate the state in a standalone layer instead of having it mixed in the code.
  // We keep the state store in the controller because we can have multiple editors in the page (meaning we need multiple states).
  // The state is passed to the VisualEditor and Toolbar via a safety mechanism that prevents external access to the state.
  // One of the issues that happens in this setup is that novice users can generate the controller in the template.
  // It's possible that when the parent page triggers a build, the editor widget does not change, yet the controller is new.
  // Therefore we have a few steps needed to disconnect the old controller and connect the new one (triggered via Flutter widget life cycle methods).
  // Another possible situation is that we are creating the controller only once but we trigger a new widget build.
  // For example in the sandbox page we have a change of layout happening between mobile and desktop.
  // This change of layout prompts Flutter to rebuild the editor using the old controller.
  // During this widget rebuild process we are creating new instances of controllers such as the CursorController.
  // The trouble is triggered by the fact that the old widget and the new widget use the same state instance.
  // When the new controller is created it gets stored in the refs state of the old state store (same reference).
  // Later once the old widget is disposed, the widget will also dispose of the newly created controller.
  // Which creates a runtime error because we are trying to subscribe to ValueNotifier that no longer is active.
  // The solution was to shallow clone the state such that the previous state module remain intact, except the references.
  // The references module is created from scratch again.
  // Thanks to this new setup we no longer store the new cursor controller in the state of the old widget.
  // Which means we can safely dispose of the old cursor controller and keep using the new cursor controller.
  //
  // As you can see, the current state setup, although it was supposed to be an easier way of handling state it requires quite some complicated fixes.
  // We will be reworking the entire setup to avoid such complex scenarios. However this requires major retrofitting of the entire code base.
  // TODO In the near future we want to refactor the code such that we remove most of the logic from the Editor up in the Controller.
  // And from the controller we want to push it to services. The idea is that the editor should only know how to render, not how to react.
  // This would make finding the features of the editor a lot easier.
  EditorState copy() => EditorState(
        paste: paste,
        cursor: cursor,
        document: document,
        editorConfig: editorConfig,
        refreshEditor: refreshEditor,
        styles: styles,
        platformStyles: platformStyles,
        scrollAnimation: scrollAnimation,
        highlights: highlights,
        keyboardVisible: keyboardVisible,
        pressedKeys: pressedKeys,
        markersTypes: markersTypes,
        markers: markers,
        markersVisibility: markersVisibility,
        headings: headings,
        selection: selection,
        lastTapDown: lastTapDown,
        selectionLayers: selectionLayers,
        refs: ReferencesState(),
      );
}
