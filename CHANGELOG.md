## [0.0.3]
* Cleaning up editor.dart
* Improved docs
* Break editor.dart in multiple files
* Split source code in modules
* Updated linting options (removed some restrictions to improve readability)
* Moved all legacy files in /core to prepare for new modules
* Renamed to Visual Editor
* Bumped to Flutter 3.0.0
* Removed the mixins from RawEditor
* Separated code into services.
* Refactored many methods to avoid reading/manipulating values straight from the RawEditor context.
  This reduces the coupling, enabling us to isolate code into services that can be unit tested.
* Merged Editor and RawEditor.
* Replaced ChangeNotifiers with state streams.
* Added migration guide

## [0.0.2]
* Custom highlights

## [0.0.1]
* Rich text editor based on Flutter Quill Delta.