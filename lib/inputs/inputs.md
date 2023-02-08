# Inputs

## Architecture Overview
The current editor is composed of two major parts, the remote input and the document model.  

- **Plain text remove input** - Receives inputs from the system. Communicates with the software keyboard and the autocomplete feature. It stores the plain text content and the selection. 
- **Rich text document model** - Stores the actual delta document as a set of delta operations. It processes the deltas to obtain a set of nodes that describe each visual element of the document. 
- **InputConnectService** - This service manages the connection to the input used by the platform (android, ios, or web html). It can establish a `TextInputConnection` between the system's `TextInput` and a `TextInputClient` (visual editor).

## Input Connection Service
When a user start typing, new characters are inserted by the remote input. The remote input is the input used by the system to synchronize the content of the input with the state of the software keyboard or other input devices. The remote input stores only plain text. The actual rich text is stored in the editor state store as a DocumentM.

The main `VisualEditor` class implements several mixins as required by Flutter. One of the expected overrides is `updateEditingValue()`. This in turn invokes `_inputConnectionService.diffPlainTextAndUpdateDocumentModel()`. This method will run a series of checks to figure out if the plain text or text selection have changed. Depending on the result we invoke further methods to either `updateSelection()` or `replaceText()`. Depending on these changes the next setp in the code flow will be to `runBuild()` and update the widgets tree. This process is explained in great details in [Documents](https://github.com/visual-space/visual-editor/blob/develop/lib/document/document.md) and [Controller](https://github.com/visual-space/visual-editor/blob/develop/lib/controller/controller.md).

## Keyboard Service
The Keyboard service handles requesting the software keyboard and connecting to the remote input. If the software keyboard is enable it triggers the build. This service is not used to stream the keystrokes to the document itself. The document gets updates from the remote input via the `InputConnectionService` (Read inputs.md). This service is used for other needs such as figuring out if meta keys are pressed (ex: when ctrl clicking links).

Join on [discord](https://discord.gg/XpGygmXde4) to get advice and help or follow us on [YouTube Visual Coding](https://www.youtube.com/channel/UC2-5lfNbbErIds0Iuai8yfA) to learn more about the architecture of Visual Editor and other Flutter apps.