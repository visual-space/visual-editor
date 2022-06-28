import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../blocks/models/custom-builders.type.dart';
import '../../blocks/models/default-styles.model.dart';
import '../../blocks/models/link-action.picker.type.dart';
import '../../blocks/services/default-link-action-picker-delegate.utils.dart';
import '../../embeds/widgets/default-embed-builder.dart';

// When instantiating a new Visual Editor, developers can control several styling and behaviour options.
// They are all defined here in this model for the sake of clear separation of code.
// By eliminating individual properties from the main VisualEditor instance and grouping them in a model
// we create a far easier to read and maintain architecture.
// Grouping these properties in a class makes passing these properties around a lot easier.
// Note that the editor and scroll controllers are passed at the top level not here in the config.
@immutable
class EditorConfigM {
  // Whether the editor should create a scrollable container for its blocks.
  // When set to `true` the editor's height can be controlled by minHeight, maxHeight and expands properties.
  // When set to `false` the editor always expands to fit the entire blocks of the document and
  // should be placed as a child of another scrollable widget, otherwise the blocks may be clipped.
  final bool scrollable;

  // TODO DOC (currently not sure why this is defined)
  final double scrollBottomInset;

  // Additional space around the blocks of this editor.
  final EdgeInsetsGeometry padding;

  // Whether this editor should focus itself if nothing else is already focused.
  // If true, the keyboard will open as soon as this editor obtains focus.
  // Otherwise, the keyboard is only shown after the user taps the editor.
  final bool autoFocus;

  // The cursor refers to the blinking caret when the editor is focused.
  final bool showCursor;

  // TODO DOC (currently not sure why this is defined)
  final bool? paintCursorAboveText;

  // When this is set to `true`, the text cannot be modified by any shortcut or keyboard operation.
  // The text remains selectable.
  final bool readOnly;

  // Content to be displayed when there is no content in the Delta document
  final String? placeholder;

  // Whether to enable user interface for changing the text selection.
  // For example, setting this to true will enable features such as long-pressing the editor to select text
  // and show the cut/copy/paste menu, and tapping to move the text cursor.
  // When this is false, the text selection cannot be adjusted by the user,
  // text cannot be copied, and the user cannot paste into the text field from the clipboard.
  final bool enableInteractiveSelection;

  // The minimum height to be occupied by this editor.
  // This only has effect if scrollable is set to `true` and expands is set to `false`.
  final double? minHeight;

  // The maximum height to be occupied by this editor.
  // This only has effect if scrollable is set to `true` and expands is set to `false`.
  final double? maxHeight;

  // The contents will be constrained by the maximum width and horizontally centered.
  // The scrollbar remains on the right side of the screen.
  // This is mostly useful on devices with wide screens.
  final double? maxContentWidth;

  final DefaultStyles? customStyles;

  // Whether this editor's height will be sized to fill its parent.
  // This only has effect if scrollable is set to `true`.
  // If expands is set to true and wrapped in a parent widget like Expanded or SizedBox, the editor will expand to fill the parent.
  // maxHeight and minHeight must both be `null` when this is set to `true`.
  final bool expands;

  // Configures how the platform keyboard will select an uppercase or lowercase keyboard.
  // Only supports text keyboards, other keyboard types will ignore this configuration.
  // Capitalization is locale-aware.
  // Defaults to TextCapitalization.sentences. Must not be `null`.
  final TextCapitalization textCapitalization;

  // The appearance of the keyboard.
  // This setting is only honored on iOS devices.
  final Brightness keyboardAppearance;

  // The ScrollPhysics to use when vertically scrolling the input.
  // This only has effect if scrollable is set to `true`.
  // If not specified, it will behave according to the current platform.
  final ScrollPhysics? scrollPhysics;

  // Callback to invoke when user wants to launch a URL.
  final ValueChanged<String>? onLaunchUrl;

  // Returns whether gesture is handled
  final bool Function(
    TapDownDetails details,
    TextPosition Function(Offset offset),
  )? onTapDown;

  // Returns whether gesture is handled
  final bool Function(
    TapUpDetails details,
    TextPosition Function(Offset offset),
  )? onTapUp;

  // Returns whether gesture is handled
  final bool Function(
    LongPressStartDetails details,
    TextPosition Function(Offset offset),
  )? onSingleLongTapStart;

  // Returns whether gesture is handled
  final bool Function(
    LongPressMoveUpdateDetails details,
    TextPosition Function(Offset offset),
  )? onSingleLongTapMoveUpdate;

  // Returns whether gesture is handled
  final bool Function(
    LongPressEndDetails details,
    TextPosition Function(Offset offset),
  )? onSingleLongTapEnd;

  // Renders custom content to be displayed as provided by the client apps.
  // Custom embeds don't work as editable text, they are standalone blocks of content that have their own internal behaviour.
  final EmbedBuilder? embedBuilder;

  // Styles can be provided to customize the look and feel of the Visual Editor.
  final CustomStyleBuilder? customStyleBuilder;

  // The locale to use for the editor buttons, defaults to system locale.
  final Locale? locale;

  // Delegate function responsible for showing menu with link actions on mobile platforms (iOS, Android).
  // The menu is triggered in editing mode when the user long-presses a link-styled text segment.
  // VisualEditor provides default implementation which can be overridden by this field to customize the user experience.
  // By default on iOS the menu is displayed with showCupertinoModalPopup which constructs an instance of CupertinoActionSheet.
  // For Android, the menu is displayed with showModalBottomSheet and a list of Material ListTiles.
  final LinkActionPickerDelegate? linkActionPickerDelegate;

  // A floating cursor will help you to see what is currently under your thumb when moving the caret.
  final bool floatingCursorDisabled;

  // If force press is enable, long tap on words selects the word.
  final bool forcePressEnabled;

  // Custom GUI for text selection controls
  final TextSelectionControls? textSelectionControls;

  // Customize any of the settings available in VisualEditor
  const EditorConfigM({
    this.scrollable = true,
    this.padding = EdgeInsets.zero,
    this.autoFocus = false,
    this.readOnly = false,
    this.expands = false,
    this.showCursor = true,
    this.paintCursorAboveText,
    this.placeholder,
    this.enableInteractiveSelection = true,
    this.scrollBottomInset = 0,
    this.minHeight,
    this.maxHeight,
    this.maxContentWidth,
    this.customStyles,
    this.textCapitalization = TextCapitalization.sentences,
    this.keyboardAppearance = Brightness.light,
    this.scrollPhysics,
    this.onLaunchUrl,
    this.onTapDown,
    this.onTapUp,
    this.onSingleLongTapStart,
    this.onSingleLongTapMoveUpdate,
    this.onSingleLongTapEnd,
    this.embedBuilder = defaultEmbedBuilder,
    this.linkActionPickerDelegate = defaultLinkActionPickerDelegate,
    this.customStyleBuilder,
    this.locale,
    this.floatingCursorDisabled = false,
    this.forcePressEnabled = false,
    this.textSelectionControls,
  })  : assert(maxHeight == null || maxHeight > 0, 'maxHeight cannot be null'),
        assert(minHeight == null || minHeight >= 0, 'minHeight cannot be null'),
        assert(maxHeight == null || minHeight == null || maxHeight >= minHeight,
            'maxHeight cannot be null');
}
