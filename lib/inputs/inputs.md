# Inputs
This module handles the keystrokes, the insertion of new text in the document, the clipboard and not least the remote input connection. The remote input connection is basically the bridge between flutter and the OS input methods.


## Architecture
The current editor is composed of two major parts, the remote input and the document model.  

- **Plain text remote input** - Receives inputs from the system. Communicates with the software keyboard and the autocomplete feature. It stores the plain text content and the selection. 
- **Rich text document model** - Stores the actual delta document as a set of delta operations. It processes the deltas to obtain a set of nodes that describe each visual element of the document. 
- **InputConnectService** - This service manages the connection to the input used by the platform (android, ios, or web html). It can establish a `TextInputConnection` between the system's `TextInput` and a `TextInputClient` (visual editor).


## Gesture Detector
Multiple callbacks can be called for one sequence of input gestures. An ordinary `GestureDetector` configured to handle events like tap and double tap will only recognize one or the other. This widget detects: the first tap and then, if another tap down occurs within a time limit, the double tap. Most gestures end up calling runBuild() to refresh the document widget tree.


## Input Connection Service
When a user start typing, new characters are inserted by the remote input. The remote input is the input used by the system to synchronize the content of the input with the state of the software keyboard or other input devices. The remote input stores only plain text. The actual rich text is stored in the editor state store as a DocumentM. The editor observes the states of the remote input and diffs them. The diffs are then applied to the internal document. The remote input does not contain any styling. All the styling is stored in the editor document and is managed by the `DocumentController`.

The main `VisualEditor` class implements several mixins as required by Flutter. One of the expected overrides is `updateEditingValue()`. This in turn invokes `_inputConnectionService.diffPlainTextAndUpdateDocumentModel()`. This method will run a series of checks to figure out if the plain text or text selection have changed. Depending on the result we invoke further methods to either `updateSelection()` or `replace()`. Depending on these changes the next setp in the code flow will be to `runBuild()` and update the widgets tree. This process is explained in great details in [Documents](https://github.com/visual-space/visual-editor/blob/develop/lib/document/document.md) and [Controller](https://github.com/visual-space/visual-editor/blob/develop/lib/controller/controller.md).


## Keyboard Service
The Keyboard service handles requesting the software keyboard and connecting to the remote input. If the software keyboard is enable it triggers the build. This service is not used to stream the keystrokes to the document itself. The document gets updates from the remote input via the `InputConnectionService`. This service is used for other needs such as figuring out if meta keys are pressed (ex: when ctrl clicking links).

