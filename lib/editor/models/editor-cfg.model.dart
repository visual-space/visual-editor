import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../controller/models/controller-callbacks.model.dart';
import '../../embeds/models/default-embed-builders.model.dart';
import '../../embeds/models/embed-builder.model.dart';
import '../../highlights/models/highlight.model.dart';
import '../../links/models/link-action.picker.type.dart';
import '../../links/services/default-link-action-picker-delegate.utils.dart';
import '../../markers/models/marker-type.model.dart';
import '../../styles/models/cfg/custom-style-builder.typedef.dart';
import '../../styles/models/cfg/editor-styles.model.dart';

// When instantiating a new Visual Editor, developers can control several styling and behaviour options.
// They are all defined here in this model for the sake of clear separation of code.
// By eliminating individual properties from the main VisualEditor instance and grouping them in a model
// we create a far easier to read and maintain architecture.
// Grouping these properties in a class makes passing these properties around a lot easier.
// Note that the editor and scroll controllers are passed at the top level not here in the config.
@immutable
class EditorConfigM {
  // Whether the editor should create a scrollable container for its doc-tree.
  // When set to `true` the editor's height can be controlled by minHeight, maxHeight and expands properties.
  // When set to `false` the editor always expands to fit the entire doc-tree of the document and
  // should be placed as a child of another scrollable widget, otherwise the doc-tree may be clipped.
  final bool scrollable;

  // TODO DOC (currently not sure why this is defined)
  final double scrollBottomInset;

  // Additional space around the doc-tree of this editor.
  final EdgeInsetsGeometry padding;

  // Whether this editor should focus itself if nothing else is already focused.
  // If true, the keyboard will open as soon as this editor obtains focus.
  // Otherwise, the keyboard is only shown after the user taps the editor.
  final bool autoFocus;

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

  final EditorStylesM? customStyles;

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

  // Whether the styles of the text will be applied to the next line of text after splitting in two lines.
  final bool keepStyleOnNewLine;

  // Overrides all internal default builders with custom implementations.
  final DefaultEmbedBuilders? overrideEmbedBuilders;

  // Renders custom content to be displayed as provided by the client apps.
  // Custom embeds don't work as editable text, they are standalone doc-tree of content that have their own internal behaviour.
  final List<EmbedBuilderM> customEmbedBuilders;

  // Styles can be provided to customize the look and feel of the Visual Editor using custom attributes.
  final CustomStyleBuilder? customStyleBuilder;

  // The locale to use for the editor buttons, defaults to system locale.
  final Locale? locale;

  // Delegate function responsible for showing menu with link actions on mobile platforms (iOS, Android).
  // The menu is triggered in editing mode when the user long-presses a link-styled text segment.
  // VisualEditor provides default implementation which can be overridden by this field to customize the user experience.
  // By default on iOS the menu is displayed with showCupertinoModalPopup which constructs an instance of CupertinoActionSheet.
  // For Android, the menu is displayed with showModalBottomSheet and a list of Material ListTiles.
  final LinkActionPickerDelegate? linkActionPickerDelegate;

  // Whether to show the link menu when tapping on a link, or not.
  // Keep in mind that link menu and create/edit link menu from the toolbar are 2 different things.
  final bool linkMenuDisabled;

  // A floating cursor will help you to see what is currently under your thumb when moving the caret.
  final bool floatingCursorDisabled;

  // If force press is enable, long tap on words selects the word.
  final bool forcePressEnabled;

  // The initial text selection when the editor is rendered.
  // Defaults to none
  final TextSelection? selection;

  // Custom GUI for text selection controls
  final TextSelectionControls? textSelectionControls;

  // Highlights are ranges of text that are temporarily labeled in a distinct color.
  final List<HighlightM> highlights;

  // Markers are permanent highlights that are stored in the document.
  final List<MarkerTypeM> markerTypes;

  // Controls the initial markers visibility.
  // For certain scenarios it might be desired to init the editor with the markers turned off.
  // Later the markers can be enabled using: _controller.toggleMarkers()
  final bool? markersVisibility;

  /// Configuration of handler for media content inserted via the system input method.
  ///
  /// See [https://api.flutter.dev/flutter/widgets/EditableText/contentInsertionConfiguration.html]
  final ContentInsertionConfiguration? contentInsertionConfiguration;

  // === CALLBACKS ===

  // Returns whether gesture is handled
  final TapDownCallback? onTapDown;

  // Returns whether gesture is handled
  final TapUpCallback? onTapUp;

  // Returns whether gesture is handled
  final SingleLongTapStartCallback? onSingleLongTapStart;

  // Returns whether gesture is handled
  final SingleLongTapMoveCallback? onSingleLongTapMoveUpdate;

  // Returns whether gesture is handled
  final SingleLongTapCallback? onSingleLongTapEnd;

  // Fires when characters are added or removed from the document.
  // (!) Does not fire on style changes.
  // Return false to ignore the event.
  // Be aware that it emits way before any build() was completed.
  // Therefore you wont have access to the latest rectangles for highlights and markers.
  final ReplaceTextCallback? onReplaceText;

  // Invoked when the document plain text has changed but timed to be triggered after the build,
  // such that we can extract the latest rectangles as well.
  final void Function()? onReplaceTextCompleted;

  final DeleteCallback? onDelete;

  final OnSelectionChangedCallback? onSelectionChanged;

  // When this callback is invoked we still don't have the latest rendered rectangles.
  // Use onBuildComplete to access the latest selection rectangles.
  final SelectionCompleteCallback? onSelectionCompleted;

  // Called each time when the editor is updated via the runBuild$ stream.
  // This signal can be used to update the placement of text attachments using the latest rectangles data (after any text editing operation).
  // It happens after the build has completed to ensure that we have access to the latest rectangles.
  // (!) Beware that this callback is invoked on every change, including style changes,
  // hovering highlights/markers and changing the selection and possibly other reasons.
  // Therefore, if you want to be notified only on character changes you are better off using onReplaceText.
  final void Function()? onBuildCompleted;
  final void Function()? onScroll;

  // Callback to invoke when user wants to launch a URL.
  final ValueChanged<String>? onLaunchUrl;

  // Customize any of the settings available  in VisualEditor
  EditorConfigM({
    this.scrollable = true,
    this.padding = EdgeInsets.zero,
    this.autoFocus = false,
    this.readOnly = false,
    this.expands = false,
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
    this.keepStyleOnNewLine = false,
    this.overrideEmbedBuilders,
    this.customEmbedBuilders = const [],
    this.linkActionPickerDelegate = defaultLinkActionPickerDelegate,
    this.linkMenuDisabled = false,
    this.customStyleBuilder,
    this.locale,
    this.floatingCursorDisabled = false,
    this.forcePressEnabled = false,
    this.selection,
    this.textSelectionControls,
    this.highlights = const [],
    this.markerTypes = const [],
    this.markersVisibility = true,
    this.contentInsertionConfiguration,

    // Callbacks
    this.onTapDown,
    this.onTapUp,
    this.onSingleLongTapStart,
    this.onSingleLongTapMoveUpdate,
    this.onSingleLongTapEnd,
    this.onReplaceText,
    this.onReplaceTextCompleted,
    this.onDelete,
    this.onSelectionChanged,
    this.onSelectionCompleted,
    this.onBuildCompleted,
    this.onScroll,
    this.onLaunchUrl,
  })  : assert(maxHeight == null || maxHeight > 0, 'maxHeight cannot be null'),
        assert(minHeight == null || minHeight >= 0, 'minHeight cannot be null'),
        assert(
          maxHeight == null || minHeight == null || maxHeight >= minHeight,
          'maxHeight cannot be null',
        );

  EditorConfigM copyWith({
    bool? scrollable,
    double? scrollBottomInset,
    EdgeInsetsGeometry? padding,
    bool? autoFocus,
    bool? paintCursorAboveText,
    bool? readOnly,
    String? placeholder,
    bool? enableInteractiveSelection,
    double? minHeight,
    double? maxHeight,
    double? maxContentWidth,
    EditorStylesM? customStyles,
    bool? expands,
    TextCapitalization? textCapitalization,
    Brightness? keyboardAppearance,
    ScrollPhysics? scrollPhysics,
    bool? keepStyleOnNewLine,
    DefaultEmbedBuilders? overrideEmbedBuilders,
    List<EmbedBuilderM>? customEmbedBuilders,
    CustomStyleBuilder? customStyleBuilder,
    Locale? locale,
    LinkActionPickerDelegate? linkActionPickerDelegate,
    bool? linkMenuDisabled,
    bool? floatingCursorDisabled,
    bool? forcePressEnabled,
    TextSelection? selection,
    TextSelectionControls? textSelectionControls,
    List<HighlightM>? highlights,
    List<MarkerTypeM>? markerTypes,
    bool? markersVisibility,
    TapDownCallback? onTapDown,
    TapUpCallback? onTapUp,
    SingleLongTapStartCallback? onSingleLongTapStart,
    SingleLongTapMoveCallback? onSingleLongTapMoveUpdate,
    SingleLongTapCallback? onSingleLongTapEnd,
    ReplaceTextCallback? onReplaceText,
    void Function()? onReplaceTextCompleted,
    DeleteCallback? onDelete,
    OnSelectionChangedCallback? onSelectionChanged,
    SelectionCompleteCallback? onSelectionCompleted,
    void Function()? onBuildCompleted,
    void Function()? onScroll,
    ValueChanged<String>? onLaunchUrl,
  }) {
    return EditorConfigM(
      scrollable: scrollable ?? this.scrollable,
      scrollBottomInset: scrollBottomInset ?? this.scrollBottomInset,
      padding: padding ?? this.padding,
      autoFocus: autoFocus ?? this.autoFocus,
      paintCursorAboveText: paintCursorAboveText ?? this.paintCursorAboveText,
      readOnly: readOnly ?? this.readOnly,
      placeholder: placeholder ?? this.placeholder,
      enableInteractiveSelection: enableInteractiveSelection ?? this.enableInteractiveSelection,
      minHeight: minHeight ?? this.minHeight,
      maxHeight: maxHeight ?? this.maxHeight,
      maxContentWidth: maxContentWidth ?? this.maxContentWidth,
      customStyles: customStyles ?? this.customStyles,
      expands: expands ?? this.expands,
      textCapitalization: textCapitalization ?? this.textCapitalization,
      keyboardAppearance: keyboardAppearance ?? this.keyboardAppearance,
      scrollPhysics: scrollPhysics ?? this.scrollPhysics,
      keepStyleOnNewLine: keepStyleOnNewLine ?? this.keepStyleOnNewLine,
      overrideEmbedBuilders: overrideEmbedBuilders ?? this.overrideEmbedBuilders,
      customEmbedBuilders: customEmbedBuilders ?? this.customEmbedBuilders,
      customStyleBuilder: customStyleBuilder ?? this.customStyleBuilder,
      locale: locale ?? this.locale,
      linkActionPickerDelegate: linkActionPickerDelegate ?? this.linkActionPickerDelegate,
      linkMenuDisabled: linkMenuDisabled ?? this.linkMenuDisabled,
      floatingCursorDisabled: floatingCursorDisabled ?? this.floatingCursorDisabled,
      forcePressEnabled: forcePressEnabled ?? this.forcePressEnabled,
      selection: selection ?? this.selection,
      textSelectionControls: textSelectionControls ?? this.textSelectionControls,
      highlights: highlights ?? this.highlights,
      markerTypes: markerTypes ?? this.markerTypes,
      markersVisibility: markersVisibility ?? this.markersVisibility,
      onTapDown: onTapDown ?? this.onTapDown,
      onTapUp: onTapUp ?? this.onTapUp,
      onSingleLongTapStart: onSingleLongTapStart ?? this.onSingleLongTapStart,
      onSingleLongTapMoveUpdate: onSingleLongTapMoveUpdate ?? this.onSingleLongTapMoveUpdate,
      onSingleLongTapEnd: onSingleLongTapEnd ?? this.onSingleLongTapEnd,
      onReplaceText: onReplaceText ?? this.onReplaceText,
      onReplaceTextCompleted: onReplaceTextCompleted ?? this.onReplaceTextCompleted,
      onDelete: onDelete ?? this.onDelete,
      onSelectionChanged: onSelectionChanged ?? this.onSelectionChanged,
      onSelectionCompleted: onSelectionCompleted ?? this.onSelectionCompleted,
      onBuildCompleted: onBuildCompleted ?? this.onBuildCompleted,
      onScroll: onScroll ?? this.onScroll,
      onLaunchUrl: onLaunchUrl ?? this.onLaunchUrl,
    );
  }
}

