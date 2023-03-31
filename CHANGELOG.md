# Changelog
If you want to learn more about the specs, all tickets are available by following the hashtag links.

## [0.12.0] Overlay - Custom overlay [#209](https://github.com/visual-space/visual-editor/issues/209)
- Removed the _onBuildComplete() method which was causing a lot of refreshes on the editor, and affecting the performance.
- Added docs for links.md
- Added overlay service in order to insert the link menu and for future menus to be added.
- Removed stack from the main method inside the editor, in order to place widgets on the screen inside the editor, we are now using overlay service.
- Moved some methods from manipulating links in controller.

## [0.11.0] Actions - Extract document manipulation logic from actions [#208](https://github.com/visual-space/visual-editor/issues/208)
  - Made the copy to clipboard button from the link menu to work properly.
  - Extracted code that manipulates the document from some of the actions and placed it into services.
- Disable adding styling in code blocks [185](https://github.com/visual-space/visual-editor/issues/185)
  - Added `DisabledButtonsState` in order to toggle the buttons color and disable applying different attrs to selection based on different selection attrs.
  - Disabled styling and most of the buttons in the toolbar when selection is code block or inline code.
  - Added `enableSelectionCodeButtons()` and `disableSelectionCodeButtons()` in `SelectionService` and `EditorController` in order to toggle enable/disable buttons when selection is code.

## [0.10.0] Blocks - Editable links [#10](https://github.com/visual-space/visual-editor/issues/10)
- Added link menu, now when tapping on a link, a menu opens, displaying the url of the link, and 3 buttons (edit link, remove link from text/url, and copy link to clipboard)
- Improved Readme.md, added screen captures of the new features
- Added custom fonts (RobotoMono) for code blocks and inline code
- Replaced code block icon from toolbar with a proper one, before it was using the same icon as inline code, which was not a proper UX.
- Selection - Can't select the first whitespace after any text [#176](https://github.com/visual-space/visual-editor/issues/176)
- Highlights - Controller method to remove highlights by id [#178](https://github.com/visual-space/visual-editor/issues/178)
- Demos - Demo page for multiple editors in scrollable parent [#161](https://github.com/visual-space/visual-editor/issues/161)

## [0.9.0] Inputs - Keyboard Shortcuts [#163](https://github.com/visual-space/visual-editor/issues/163)
- Added hotkeys for toolbar actions (e.g.: CTRL + B makes the selected text bold).
- Added ordered list on key combination (1. + space) at the beginning of a line and (- + space) creates bullet list.
- Fixed the wrong ordering number bug in ordered lists and code block. [#158](https://github.com/visual-space/visual-editor/issues/158)
- Added nested bullets with TAB key. [#11](https://github.com/visual-space/visual-editor/issues/11)

## [0.8.0] Improved file/folders structure [#174](https://github.com/visual-space/visual-editor/issues/174)
- Sys - Improve file/folders structure
- Add demo images in readme.
- Grouped demo pages navigation menu in categories.
- Grouped demo pages into modules.
- Removed `defaultToggleStyleButtonBuilder` from `ToggleStyleButton` and from `ToggleCheckListButton`.
- Created `DocumentEditingService`, Moved `formatText` `formatTextStyle` to `TextStylesService`.
- Renamed `SelectionActionsService` to `SelectionHandlesService`.
- Moved controller callbacks type definitions to standalone file.
- Removed local cached reference of the document from the controller. We are now reading the document only from the state store.
- Moved `keepStyleOnNewLine` to the state store in `EditorConfigM`. There was no need to separate this property from the main config.
- Moved toggledStyle to state store
- The controller was getting too big with too many methods. Maintenance was becoming difficult due to unclear code boundaries. We moved most of the methods to dedicated services.
- Moved selection to the state store
- Remove rectangles param from the `onSelectionChanged`.
- When it was first introduced we though we are going to use the param to get the rectangles and display the selection menu position. However in the meantime we developed the `onBuildComplete` callback. Since the rectangles data is stale we decided to remove it rather than refactor the whole code flow.
- (CANCELLED) Slice out refs from state. It simplifies the mental model needed to understand the state store. Abandoned, creates too much boilerplate in the buttons.
- Move controller callbacks into the config model.
- Remove useless setter getters from the state store. There's no point in having them if all they do is read and write.
- Move the remaining params as well: `selection`, `highlights`, `markerTypes`,
- We are no longer constrained to call methods defined only in the controller.
- Separate marker types and highlights as methods in the demo pages
- Update documentation to reflect the editor config params change. Updated the state store documentation.
- Remove EditorController.basic. It is no longer needed.
- Removed `editorWidget` from state no longer required
- Sliced `CoordinatesService` from `LinesAndBlocsService`.
- One is concerned with retrieving coordinates of elements in the document. The other is concerned with rendering the document lines and blocs.
- Created `StylesService` & `DocumentService`
- Rename `editorController` to controller
- Rename `editorWidgetState` to `widget`
- Move markers and highlights methods from controller to services
- Merge `CursorService` and `CaretService`
- Move `toolbarButtonToggler` and `copiedImageUrl` to the state store
- Review if all state branches are relevant
- Removed the additional layer from `config.config` even if it brakes the state store pattern. It's simply too much nesting repetition in the code base for no benefit.
- Replace all `refs.controller.selection` with the state/service version `selection.selection`
- Rename `TextValueService` to `PreBuildService` to better reflect what it really does.
- Rename `value` in `TextEditingValue` value to `plainText`.
- Rename `refreshEditor` to `runBuild`.
- Rename /documents module to /document.
- Rename /blocks to /doc-tree.
- Merge `DocumentRenderService` into `DocTreeService`.
- Rename `setState` to void `cacheStateStore` to avoid confusion with the widget `setState`.
- Rename `userUpdateTextEditingValue` to `removeSpecialCharsAndUpdateDocTextAndStyle`.
- Merge `EditorTextService` into `DocumentService` (defragmentation).
- Rename all listeners to short notation: `runBuild$L`.
- Replace all internal controller calls `refs.controller` with service calls.
- Rename `TextSelectionService` to `SelectionService`
- Improved management for embed builders list
- Wrapped state store access in the services. Improves code readability (more awareness)
- Replaced singleton services with services that have the state initialised. This means each instance of the editor gets a new set of services with the correct state store initialised. More details in the state-store.md document. This technique is useful because now we no longer need prop drilling to pass the state.
- Simplified the controller code further. It is currently a nice index of methods form services. No more wrapping.
- Moved document logic from the toolbar buttons to services. Now more methods are available in the controller for manipulating the document programmatically.
- Added `EmbedsService`, has methods for inserting embeds programatically.
- Wrapped DeltaUtils in a class
- In `InputConnectionService` Rename `updateEditingValue` to `diffPlainTextAndUpdateDocumentModel`
- Added `InputState` to cache temporarily the `plainText` value during
- Added clarifications what is the difference between `InputConnectionService` and the `KeyboardConnectionService`.
- Renamed `PreBuildService` to `GuiService` to better indicate it's role.
- Merged `runBuild` and `runBuildIfMounted`
- Merged `EditorKeyboardListener` into `VisualEditor`. It had nothing useful to add in the widget tree.
- Moved focus related update handler from `EditorService` into `GuiService`.
- Renamed `EditorService` to `RunBuildService`
- Rename `_emitPressedKeyHandler`, `state.pressedKeys.emitPressedKeys()`.
- Remove `_pressedKeysChanged`. It is useless since we use the state store. `metaOrControlPressed` can be read directly sync from the state store.
- Cleanup in `TextGesturesService`
- Expose selection service methods in controller.
- Remove rectangles param from `OnSelectionChangedCallback`. They are outdated because the callback is invoked before the build cycle can compute the new rectangles.
- Move all cached vars from services to the state store (we no longer use singletons for services).
- Move `TextGestures` service and widget to /inputs
- Convert stateful utils to services
- There are 2 `StylesService `. One of them was renamed to `StylesCfgService`.
- Renamed params in delta: `other` in `new`, `this` in `curr`
- Improved doc comments in `HistoryM`. It appears we have support for coop but it is not exposed/enabled publicly.
- Refactored `DocumentM`. Extracted most methods in a dedicated service `DocumentNodesService `. Improved doc comments.
- One of the challenges of understanding how `DocumentM` works was recognising if methods are pure or impure. I've updated the comments to reflect if methods are pure or impure (purity indicators). Having increased awareness of the purity of code improves the developers ability to predict what will happen. Thus makes the debugging process far easier.
- Rename `DocumentService` to `EditorService`. Rename `DocumentNodesService` to `DocumentService`. This reflects the reality of what happens in codebase. `EditorService` mutates doc, updates all systems and triggers build. `DocumentService` only performs the mutations on the doc.
- Refactored `DeltaM` and `OperationM`. Extracted most methods in a dedicated service `DeltaService`. Improved doc comments.
- Remove basic constructor
- Moved all the code from `HistoryM` into `HistoryService`, since this is an internal model never exposed in the public.
- We need to keep changes for multiple docs, we can't have a central one. _history stays in document model.
- Move changes$ from `DocumentM` in the `EditorController`. Changes are not operated and broadcasted from an idle document without the user being aware via the GUI. Therefore it does not make sense to keep the changes stream in the document model. We want to have the document model pure data.
- Move `HistoryService` and `DocumentService` in the controller. This means we can start migrating the document models to pure data. Also it means all services are now state store aware. The `HistoryService` and `DocumentService` were document aware only. We did not want to pass the state store to the document to avoid complicated architecture. Now that we are migrating all data from the models means we no longer risk exposing the state store in the public. More explanations about our architecture choices in editor.md .
- Convert `DocumentService` to `DocumentController`, `DeltaService` to `DeltaUtils`. This enables us to keep the models as pure data. It also enables advanced client developers to edit documents that are not cached in the `EditorController`.
- Moved _rules form `DocumentM` to `DocumentController`. Moved `customRules` to `stateStore` (one list per editor).
- Created `DocumentUtils` to segregate some simple utils that are used also when initialising the Document.
- Restored the old state one instance state store. No more shallow cloning. Shallow cloning the `EditorState` when passing it to the`Toolbar ` buttons meant that we lost the reference to the `DocumentController`. Fixed the `CusrsorController.dispose()` issue the correct way by caching the prev instance in the state store. Detailed explanation in state-store.md. Now the state store is back again a simple object, easy to understand.
- Convert `HistoryService` to `HistoryController`. We need a controller independent of the state store to be able to process changes also when the document model manipulated from outside.
- Move `HistoryController` in `DocumentController`. Edits running outside of the editor will update history as well.
- Merge all caching code of the editor in one method. No need to have so many small methods. Improved sorting of methods in `main.dart`.
- Rename `SelectionActionsController ` to `SelectionHandlesController`.
- Convert `DeltaService` to `DeltaUtils`.
- Renamed node `length` into `charsNum`.
- Renamed node `adjust` into `mergeSimilarNodes`.
- Created `EditableTextPaintService`. `EditableTextLineBoxRenderer` has many overrides concerned with computing the layout dimensions. Therefore the painting logic for selection/highlight boxes is better separated here. Separating the layout dimensions logic and painting logic helps improves readability and maintainability.
- Move code that is closely related to other modules to the respective modules
- Renamed `EditorRendererInner` to `EditorTextAreaRenderer` following the conventions for editable text line.

## [0.7.0] Custom Embeds [#157](https://github.com/visual-space/visual-editor/issues/157)
* Demos - Demo page for adding new items in document.
* Headings - Added text selection for headers [#195](https://github.com/visual-space/visual-editor/issues/195)
* Embeds - Separated embed builders based on the type of embed.
* Embeds - created `defaultEmbedBuilders` to supply standard embeds builders for images and videos, makes it easier to override standard embeds.
* Embeds - Added custom embeds. [#157](https://github.com/visual-space/visual-editor/issues/157)
  * Created `EmbedBuilderController` to handle selection of the embed builder.
  * Removed `BlockEmbedM` and all block embed implementations.
  * All embeddable objects now extend `EmbedM` unifying embed insertion into the document.
  * Created standard embeddable objects for images (`ImageEmbedM`) and videos (`VideoEmbedM`).
* Demos - Created `Custom Embeds Page`.
  * Created `custom-embeds.json`. [#157](https://github.com/visual-space/visual-editor/issues/157)
* Markers - Added new method in the editor controller `toggleMarkersByTypes()`. It toggles just certain types of markers.
  * Added new method in the editor controller `getMarkersVisibilityByTypes()`. It queries if certain types of markers are disabled [#120](https://github.com/visual-space/visual-editor/issues/120)
* Demos - Delta Sandbox, Adaptive layout for maximum screen area on mobiles. [#128](https://github.com/visual-space/visual-editor/issues/128)
* Demos - Aligned the navigation to the left, increased padding for better UI. [#162](https://github.com/visual-space/visual-editor/issues/162)
* Demos - Demo page for adding new items in document.[#195](https://github.com/visual-space/visual-editor/issues/195)
* Headings - Added text selection for headers [#197](https://github.com/visual-space/visual-editor/issues/197)
* Demos - Demo page for limited length headings. [#199](https://github.com/visual-space/visual-editor/issues/199)

## [0.6.0] Headings List [#140](https://github.com/visual-space/visual-editor/issues/140)
* Created a new demo page for showcasing the custom styles. Demo custom styles can pe altered by modifying the parameters found in 'demo-custom-styles.const.dart'. [#95](https://github.com/visual-space/visual-editor/issues/95)
* Exposed public method to access the headings after rendering headings from the document. The client code can read the text and the position (rectangles) of every heading. Similar to markers and highlights, we are storing this information in the internal state store after rendering. [#135](https://github.com/visual-space/visual-editor/issues/135)
  * Improved the null safety for the operation attributes. The getter was guaranteeing that the array will contain at least one AttributeM. Which is not true.
  * Added demo page to demonstrate how to render an index panel using the headings.
  * Implemented a scroll to feature. Tapping the headings will scroll ot the corresponding text.
* Blocks - Indenting does not work properly. Fixed issue with indenting not updating the line padding. This was a small mistake from the refactoring process because we misunderstood the `updateRenderObject()` method on the `EditableTextLineWidgetRenderer` [#88](https://github.com/visual-space/visual-editor/issues/88)
* Added `onReplaceTextComplete()` a callback for detecting when the document plain text has changed but timed to be triggered after the build. Such that we can extract the latest rectangles as well. [#155](https://github.com/visual-space/visual-editor/issues/155)
* Markers - Fixed: Extracting markers on non-scrollable editor yields global position instead of document position for the text line. [#160](https://github.com/visual-space/visual-editor/issues/160)

## [0.5.0] Markers [#69](https://github.com/visual-space/visual-editor/issues/69)
* Added custom markers. Multiple marker types can be defined. The client app can define callbacks for hovering the markers.
  * Split the AttributeM static properties in methods in multiple files
  * Refactored the `DropdownButton` in Toolbar to make it more generic
  * Added demo page for the markers and highlights features
  * Various small code cleanups
* Added new method in the editor controller `toggleMarkers()`. It toggles all markers at once. [#111](https://github.com/visual-space/visual-editor/issues/111)
* Markers - Initial visibility config parameter [#116](https://github.com/visual-space/visual-editor/issues/116)
* Markers - Marker attachments, Position widgets in sync with the markers found in the text [#117](https://github.com/visual-space/visual-editor/issues/117)
  * Retrieved the pixel coordinates of the markers rectangles that are drawn in `EditableTextLine`. Also retrieved the global position of each line of text. This information is essential for rendering attached widgets.
  * Added unique ids to markers to facilitate precise targeting when deleting or attaching widgets.
  * Added a dedicated `MarkersState` where the rendered markers and their pixel coordinates are stored. 
  * Fixed an issue with the conversion from json data to `NodeM` of markers attributes. When the markers were first implemented, by mistake, we stored the json data instead of the converted `NodeM` models when initialising the document and `StyleM`. Because of this error all markers were passed as json data, therefore some of the code is harder to read. This was fixed and now we are receiving `MarkerM` instead of json data.
  * Exposed 2 callbacks: `onBuildComplete()`, `onScrooll()`. These callbacks are essential for synchronising the attached widgets positions to the markers themselves.
  * Added new demo page to demonstrate how to attach arbitrary widgets to the markers.
* Markers - Paragraphs with markers don't get rendered if the editor is not scrollable (bugfix) [#118](https://github.com/visual-space/visual-editor/issues/118)
  * `scrollController` is no longer mandatory. It is possible for the editor to have the scroll disabled, so no scroll controller needed.
* Highlights - Add highlights from the controller. Improve the highlights page [#145](https://github.com/visual-space/visual-editor/issues/145)
* Highlights - Restore highlights hovering [#134](https://github.com/visual-space/visual-editor/issues/134)
  * Added ids to highlights. If we are using a pure functional approach in our code we can no longer rely on references to search for highlights in the state store. We need ids to be able to track which highlights are hovered.
* Markers - Render attachments for the selection (for quick menu) [#135](https://github.com/visual-space/visual-editor/issues/135)
  * Upgraded the highlights hovering service to use pixel coordinates instead of text position to detect the hovering.
  * Added a markers hovering service.
  * Added demo page to demonstrate how to attach menus or random widgets when tapping on highlights and markers or when changing the selection.
  * Exported the rectangles data for the selection. Now we have two ways of attaching widgets to the text selection. Read [Selection](https://github.com/visual-space/visual-editor/blob/develop/lib/selection/selection.md) documentation for more details.
* Documents - Delta Sandbox does not trigger update of the json input when changing styles. Fixed by using the newly added `onBuildComplete()` callback. The sandbox json preview now updates on any change including style changes and adding markers/highlights. [#93](https://github.com/visual-space/visual-editor/issues/93)
* Added delete markers buttons. They are triggered by the tapping on a marker. All markers with the
  same id will be deleted. Markers can be hidden or deleted.
* Added scroll behavior to the majority of toolbars and created a new page to differentiate between a toolbar with a horizontal scroll and a wrapping one. [#129](https://github.com/visual-space/visual-editor/issues/129)

## [0.4.0] Bug Fixing
* Fixed issue with `EditorController` being reinitialised on setState(). Usually setState() should not be used. However there are scenarios when the host code might request the entire editor to update (for example when changing styles). Prior to this fix the editor was crashing completely. When a client app triggers `setState()` it also rebuilds the `EditorController` if the first controller instance is not cached by the developer. When a new controller is created a new internal state store object is created as well. In this state store we also keep references towards several important classes: ScrollController, FocusNode, EditorRenderer. The issue came from the fact that these references were not properly renewed. In many places of the code base we have code snippets that depend on the latest refs being available. The fix was to patch the newly created state store with the proper refs. In the old Quill Repo this was present but due to the lack of documentation this code got discarded. Now this fix restores this functionality but with the necessary changes to make it work within the refactored codebase of Visual editor. [#77](https://github.com/visual-space/visual-editor/issues/77)
* Added delta json preview page. In this page you can see the json output as you type in the editor. Very helpful for learning quickly how the delta format works. [#66](https://github.com/visual-space/visual-editor/issues/66)
* Fixes related to the architecture cleanup refactoring. During the refactoring, despite our best efforts, some bugs showed up:
  * Tapping the toolbar buttons does not update their state (Post Refactoring) [#84](https://github.com/visual-space/visual-editor/issues/84)
  * Dual editors - Text is inserted in the wrong editor instance (Post Refactoring) - Added unique focusNodes. [#85](https://github.com/visual-space/visual-editor/issues/85)
  * After setState() in parent the selection no longer works + selecting text before setState() yields missing doc after setState() (Post Refactoring) [#86](https://github.com/visual-space/visual-editor/issues/86)
  * After controller reset, indenting, the bullet and number lists don't work (fails) (Post Refactor) [#87](https://github.com/visual-space/visual-editor/issues/87)
* Improved the toolbar documentation. [#86](https://github.com/visual-space/visual-editor/issues/86)
  * Added horizontal mouse scroll for toolbar.
  * Fixed the scroll controller which overlays over the toolbar buttons.
  * Fixed the toolbar stretching and irregular distance between buttons.
  * 
## [0.3.0] Architecture Refactoring [#1](https://github.com/visual-space/visual-editor/issues/1)
* Cleaning up editor.dart
* Improved docs [#2](https://github.com/visual-space/visual-editor/issues/2)
* Break editor.dart in multiple files
* Split source code in modules
* Updated linting options (removed some restrictions to improve readability)
* Moved all legacy files in /core to prepare for new modules
* Renamed to Visual Editor
* Bumped to Flutter 3.0.0 [#25](https://github.com/visual-space/visual-editor/issues/25)
* Removed the mixins from RawEditor
* Separated code into services.
* Refactored many methods to avoid reading/manipulating values straight from the RawEditor context.
  This reduces the coupling, enabling us to isolate code into services that can be unit tested.
* Merged Editor and RawEditor.
* Replaced ChangeNotifiers with state streams.
* Added migration guide [#60](https://github.com/visual-space/visual-editor/issues/60)
* Updated demo pages [#63](https://github.com/visual-space/visual-editor/issues/63)
* Migrated state architecture from singleton to one state per editor controller instance. [#61](https://github.com/visual-space/visual-editor/issues/61)
* Exported the Toolbar buttons so that custom toolbars can be build from scratch [#65](https://github.com/visual-space/visual-editor/issues/65)
* Delta documents sandbox page, preview the json (development aid)
* Remove tuple dependency [#45](https://github.com/visual-space/visual-editor/issues/45)
* Fix the placeholder is not displayed bug [#70](https://github.com/visual-space/visual-editor/issues/70)
* The caret is no longer displayed in readonly mode. The `showCursor` configuration option for `VisualEditor` was removed. It makes no sense to have the cared showing up in readonly mode. Or the caret missing in editable mode. [#73](https://github.com/visual-space/visual-editor/issues/73)
* Added first automatic test [#3](https://github.com/visual-space/visual-editor/issues/3)
* Renamed class that was colliding with the `Text class from Flutter [#33](https://github.com/visual-space/visual-editor/issues/33)

## [0.2.0] Highlights
* Custom highlights. This feature was initially developed for Quill. However we had major issues with the existing architecture. Therefore we decided to fork and run a major refactoring.

## [0.1.0] Quill Fork
* Rich text editor forked from [Flutter Quill](https://github.com/singerdmx/flutter-quill) and based on the Delta format.

Join on [discord](https://discord.gg/XpGygmXde4) to get advice and help or follow us on [YouTube Visual Coding](https://www.youtube.com/channel/UC2-5lfNbbErIds0Iuai8yfA) to learn more about the architecture of Visual Editor and other Flutter apps.