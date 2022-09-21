# Changelog
If you want to learn more about the specs, all tickets are available by following the hashtag links.

## [0.5.0] Markers [#69](https://github.com/visual-space/visual-editor/issues/69)
* Added custom markers. Multiple marker types can be defined. The client app can define callbacks for hovering the markers.
    * Split the AttributeM static properties in methods in multiple files
    * Refactored the `DropdownButton` in Toolbar to make it more generic
    * Added demo page for the markers and highlights features
    * Various small code cleanups
* Added new method in the editor controller `toggleMarkers()`. It toggles all markers at once. [#111](https://github.com/visual-space/visual-editor/issues/111)
* Markers - Initial visibility config parameter [#116](https://github.com/visual-space/visual-editor/issues/116)

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

## [0.3.0] Architecture refactoring [#1](https://github.com/visual-space/visual-editor/issues/1)
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