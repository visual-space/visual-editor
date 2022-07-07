# Editor (WIP)

## Overview
This is the main class of the Visual Editor. There are 2 constructors available, one for controlling all the settings of the editor in precise detail. The other one is the basic init that will spare you the pain of having to comb trough all the props. The default settings are carefully chosen to satisfy the basic needs of any app that needs rich text editing. The editor can be rendered either in scrollable mode or in expanded mode. Most apps will prefer the scrollable mode and a sticky EditorToolbar on top or at the bottom of the viewport. Use the expanded version when you want to stack multiple editors on top of each other. A placeholder text can be defined to be displayed when the editor has no contents. All the styles of the editor can be overridden using custom styles.

## Custom Embeds
Besides the existing styled text options the editor can also render custom embeds such as video players or whatever else the client apps desire to render in the documents. Any kind of widget can be provided to be displayed in the middle of the document text.

TODO Example how to use embeds or link to the md

## Callbacks
Several callbacks are available to be used when interacting with the editor:
- `onTapDown()`
- `onTapUp()`
- `onSingleLongTapStart()`
- `onSingleLongTapMoveUpdate()`
- `onSingleLongTapEnd()`

## Controller
Each instance of the editor will need an `EditorController`. EditorToolbar can be synced to `VisualEditor` via the `EditorController`.

## Rendering
The Editor uses Flutter `TextField` to render the paragraphs in a column of content. On top of the regular `TextField` we are rendering custom selection controls or highlights using the `RenderBox` API.

## Gestures
The VisualEditor class implements `TextSelectionGesturesBuilderDelegate`. This base class is used to separate the features related to gesture detection and to give the opportunity to override them.

## Custom Style Builder (WIP)
Custom styles can be defined for custom attributes.

Join on [discord](https://discord.gg/XpGygmXde4) to get advice and help or follow us on [YouTube Visual Coding](https://www.youtube.com/channel/UC2-5lfNbbErIds0Iuai8yfA) to learn more about the architecture of Visual Editor and other Flutter apps.