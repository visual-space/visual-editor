import 'package:flutter/services.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';

import '../../cursor/services/caret.service.dart';
import '../../editor/services/gui.service.dart';
import '../../shared/state/editor.state.dart';
import '../../shared/utils/platform.utils.dart';
import 'input-connection.service.dart';

// Handles requesting the software keyboard and connecting to the remote input.
// If the software keyboard is enable it triggers the build.
// (!) WARNING This service is not used to stream the keystrokes to the document itself.
// The document gets updates from the remote input via the InputConnectionService (Read inputs.md).
// This service is used for other needs such as figuring out if meta keys are pressed (ex: when ctrl clicking links).
class KeyboardService {
  late final InputConnectionService _inputConnectionService;
  late final CaretService _caretService;

  final EditorState state;

  KeyboardService(this.state) {
    _inputConnectionService = InputConnectionService(state);
    _caretService = CaretService(state);
  }

  // === SUBSCRIBE TO SOFTWARE KEYBOARD ===

  // Detects if the system has software keyboard that can change the screen size.
  // If the software keyboard is toggled then we run build again.
  // For systems that have a hardware keyboard we don't do anything special.
  void subscribeToKeyboardVisibilityAndRunBuild(
    GuiService guiService,
    void Function() runBuild,
  ) {
    // Physical keyboard present - GUI never changes size
    if (isKeyboardOS()) {
      state.keyboard.isVisible = true;
    } else {
      final editor = state.refs.widget;

      isIOSSimulator().then((isIosSimulator) {
        // Treat iOS Simulator like a keyboard OS
        if (isIosSimulator) {
          state.keyboard.isVisible = true;
        } else {
          // Most likely we are on mobile or table now.
          // Check if the software kb is visible.
          editor.kbVisibCtrl = KeyboardVisibilityController();
          state.keyboard.isVisible = editor.kbVisibCtrl!.isVisible;

          // If the editor controller is swapped at runtime cancel prev subscription.
          editor.kbVisib$L?.cancel();

          // Subscribe to kb visibility changes and runBuild
          editor.kbVisib$L = editor.kbVisibCtrl?.onChange.listen((visible) {
            state.keyboard.isVisible = visible;

            if (visible) {
              // Run build
              guiService.updateGuiElementsAndBuild(
                !state.refs.focusNode.hasFocus,
                runBuild,
              );
            }
          });

          // Run build on key press from hardware kb
          HardwareKeyboard.instance.addHandler(
            state.refs.widget.updGuiAndBuildViaHardwareKbEvent,
          );
        }
      });
    }
  }

  // Run Build once on init if the system has hardware keyboard (not software).
  // KeyboardVisibilityController only checks for keyboards that adjust the screen size.
  // Also watch for hardware keyboards that don't alter the screen (i.e. Chromebook, Android tablet
  // and any hardware keyboards from an OS not listed in isKeyboardOS()).
  bool updGuiAndBuildViaHardwareKeyboardEvent(
    GuiService guiService,
    void Function() runBuild,
  ) {
    if (!state.keyboard.isVisible) {
      // Hardware keyboard key pressed. Set visibility to true
      state.keyboard.isVisible = true;

      // Run build on key press
      guiService.updateGuiElementsAndBuild(
        !state.refs.focusNode.hasFocus,
        runBuild,
      );
    }

    // Remove the key handler. It's no longer needed.
    // If KeyboardVisibilityController clears visibility, it wil also enable it when appropriate.
    HardwareKeyboard.instance.removeHandler(
      state.refs.widget.updGuiAndBuildViaHardwareKbEvent,
    );

    // We didn't handle the event, just needed to know a key was pressed
    return false;
  }

  // Express interest in interacting with the keyboard.
  // If this control is already attached to the keyboard, this function will request that the keyboard become visible.
  // Otherwise, this function will ask the focus system that it become focused.
  // If successful in acquiring focus, the control will then attach to the keyboard and
  // request that the keyboard become visible.
  // Requested on selection change or when the document model was changed.
  void requestKeyboard() {
    if (state.refs.focusNode.hasFocus) {
      _inputConnectionService.openConnectionIfNeeded(_plainText);
      _caretService.showCaretOnScreen();
    } else {
      state.refs.focusNode.requestFocus();
    }
  }

  // === PRESSED KEYS ===

  void setPressedKeys(Set<LogicalKeyboardKey> pressedKeys) {
    state.pressedKeys.setPressedKeys(pressedKeys);
  }

  Stream<Set<LogicalKeyboardKey>> get pressedKeys$ {
    return state.pressedKeys.pressedKeys$;
  }

  bool get metaPressed {
    return state.pressedKeys.metaPressed;
  }

  bool get controlPressed {
    return state.pressedKeys.controlPressed;
  }

  // === PRIVATE ===

  // State store accessor duplicated from DocumentsService to avoid circular references.
  // Helps us avoid needles drill-down of the plainText.
  // Also keeps the public API of the SelectionService simpler.
  TextEditingValue get _plainText {
    return TextEditingValue(
      text: state.refs.documentController.toPlainText(),
      selection: state.selection.selection,
    );
  }
}
