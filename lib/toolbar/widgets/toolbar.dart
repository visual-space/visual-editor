import 'package:flutter/material.dart';
import 'package:i18n_extension/i18n_widget.dart';

import '../../controller/controllers/editor-controller.dart';
import '../../documents/models/attribute.model.dart';
import '../../shared/models/editor-dialog-theme.model.dart';
import '../../shared/models/editor-icon-theme.model.dart';
import '../../shared/widgets/arrow-scrollable-button-list.dart';
import '../../shared/widgets/icon-button.dart';
import '../models/editor-custom-icon.dart';
import '../models/media-picker.type.dart';
import 'buttons/camera-button.dart';
import 'buttons/clear-format-button.dart';
import 'buttons/color-button.dart';
import 'buttons/dropdown-button.dart';
import 'buttons/history-button.dart';
import 'buttons/image-button.dart';
import 'buttons/indent-button.dart';
import 'buttons/link-style-button.dart';
import 'buttons/select-alignment-button.dart';
import 'buttons/select-header-style-button.dart';
import 'buttons/toggle-check-list-button.dart';
import 'buttons/toggle-style-button.dart';
import 'buttons/video-button.dart';

export '../../embeds/services/image-video.utils.dart';
export '../../shared/widgets/icon-button.dart';
export 'buttons/clear-format-button.dart';
export 'buttons/color-button.dart';
export 'buttons/history-button.dart';
export 'buttons/image-button.dart';
export 'buttons/indent-button.dart';
export 'buttons/link-style-button.dart';
export 'buttons/select-alignment-button.dart';
export 'buttons/select-header-style-button.dart';
export 'buttons/toggle-check-list-button.dart';
export 'buttons/toggle-style-button.dart';
export 'buttons/video-button.dart';

// The default size of the icon of a button.
const defaultIconSize = 18.0;

// The factor of how much larger the button is in relation to the icon.
const iconButtonFactor = 1.77;

class EditorToolbar extends StatelessWidget implements PreferredSizeWidget {
  // If you want custom order for the buttons you can provide a list of
  // children straight to the the EditorToolbar constructor.
  // However in this case it's almost pointless to use this Widget
  // since it does not provide much functionality on top of the custom buttons set.
  // You can build your own widget, just remember to provide the the locale via the I18n Widget.
  final List<Widget> children;
  final double toolbarHeight;

  // The spacing between buttons
  final double buttonsSpacing;
  final WrapAlignment toolbarIconAlignment;

  // Renders the buttons on multiple rows.
  // If disabled renders the buttons on a single row with arrows.
  final bool multiRowsDisplay;

  // The color of the buttons.
  // Defaults to ThemeData.canvasColor of the current Theme if no color is given.
  final Color? color;

  final FilePickImpl? filePickImpl;

  // The locale to use for the editor buttons, defaults to system locale
  // More https://github.com/singerdmx/flutter-quill#translation
  final Locale? locale;

  // Custom buttons can be appended to the end of the Toolbar buttons row.
  final List<EditorCustomButton> customButtons;

  @override
  Size get preferredSize => Size.fromHeight(toolbarHeight);

  const EditorToolbar({
    required this.children,
    this.toolbarHeight = 36,
    this.toolbarIconAlignment = WrapAlignment.center,
    this.buttonsSpacing = 4,
    this.multiRowsDisplay = true,
    this.color,
    this.filePickImpl,
    this.customButtons = const [],
    this.locale,
    Key? key,
  }) : super(key: key);

  factory EditorToolbar.basic({
    required EditorController controller,
    double toolbarIconSize = defaultIconSize,
    double toolbarSectionSpacing = 4,
    WrapAlignment toolbarIconAlignment = WrapAlignment.center,
    bool showDividers = true,
    bool showFontSize = true,
    bool showBoldButton = true,
    bool showItalicButton = true,
    bool showSmallButton = false,
    bool showUnderLineButton = true,
    bool showStrikeThrough = true,
    bool showInlineCode = true,
    bool showColorButton = true,
    bool showBackgroundColorButton = true,
    bool showClearFormat = true,
    bool showAlignmentButtons = false,
    bool showLeftAlignment = true,
    bool showCenterAlignment = true,
    bool showRightAlignment = true,
    bool showJustifyAlignment = true,
    bool showHeaderStyle = true,
    bool showListNumbers = true,
    bool showListBullets = true,
    bool showListCheck = true,
    bool showCodeBlock = true,
    bool showQuote = true,
    bool showIndent = true,
    bool showLink = true,
    bool showUndo = true,
    bool showRedo = true,
    bool multiRowsDisplay = true,
    bool showImageButton = true,
    bool showVideoButton = true,
    bool showCameraButton = true,
    bool showDirection = false,
    OnImagePickCallback? onImagePickCallback,
    OnVideoPickCallback? onVideoPickCallback,
    MediaPickSettingSelector? mediaPickSettingSelector,
    FilePickImpl? filePickImpl,
    WebImagePickImpl? webImagePickImpl,
    WebVideoPickImpl? webVideoPickImpl,
    List<EditorCustomButton> customIcons = const [],

    // Map of font sizes in int
    Map<String, int>? fontSizeValues,
    int? initialFontSizeValue,

    // The theme to use for the icons in the buttons, uses type EditorIconThemeM
    EditorIconThemeM? iconTheme,

    // The theme to use for the theming of the LinkDialog(), shown when embedding an image, for example
    EditorDialogThemeM? dialogTheme,

    // The locale to use for the editor buttons, defaults to system locale
    // More at https://github.com/singerdmx/flutter-quill#translation
    Locale? locale,
    Key? key,
  }) {
    final isButtonGroupShown = [
      showFontSize ||
          showBoldButton ||
          showItalicButton ||
          showSmallButton ||
          showUnderLineButton ||
          showStrikeThrough ||
          showInlineCode ||
          showColorButton ||
          showBackgroundColorButton ||
          showClearFormat ||
          onImagePickCallback != null ||
          onVideoPickCallback != null,
      showAlignmentButtons || showDirection,
      showLeftAlignment,
      showCenterAlignment,
      showRightAlignment,
      showJustifyAlignment,
      showHeaderStyle,
      showListNumbers || showListBullets || showListCheck || showCodeBlock,
      showQuote || showIndent,
      showLink
    ];

    // Default font size values
    final fontSizes = fontSizeValues ??
        {
          'Default': 0,
          '10': 10,
          '12': 12,
          '14': 14,
          '16': 16,
          '18': 18,
          '20': 20,
          '24': 24,
          '28': 28,
          '32': 32,
          '48': 48
        };

    Widget _divider() => Container(
          margin: EdgeInsets.only(
            top: multiRowsDisplay ? 7 : 4,
          ),
          height: toolbarIconSize,
          width: 1,
          color: Colors.grey.shade400,
        );

    return EditorToolbar(
      key: key,
      toolbarHeight: toolbarIconSize * 2,
      buttonsSpacing: toolbarSectionSpacing,
      toolbarIconAlignment: toolbarIconAlignment,
      multiRowsDisplay: multiRowsDisplay,
      customButtons: customIcons,
      locale: locale,
      children: [
        if (showUndo)
          HistoryButton(
            icon: Icons.undo_outlined,
            iconSize: toolbarIconSize,
            controller: controller,
            undo: true,
            iconTheme: iconTheme,
          ),
        if (showRedo)
          HistoryButton(
            icon: Icons.redo_outlined,
            iconSize: toolbarIconSize,
            controller: controller,
            undo: false,
            iconTheme: iconTheme,
          ),
        if (showFontSize)
          DropdownBtn(
            iconTheme: iconTheme,
            iconSize: toolbarIconSize,
            attribute: AttributeM.size,
            controller: controller,
            items: [
              for (MapEntry<String, int> fontSize in fontSizes.entries)
                PopupMenuItem<int>(
                  key: ValueKey(fontSize.key),
                  value: fontSize.value,
                  child: Text(fontSize.key.toString()),
                ),
            ],
            onSelected: (newSize) {
              if ((newSize != null) && (newSize as int > 0)) {
                controller
                    .formatSelection(AttributeM.fromKeyValue('size', newSize));
              }
              if (newSize as int == 0) {
                controller
                    .formatSelection(AttributeM.fromKeyValue('size', null));
              }
            },
            rawitemsmap: fontSizes,
            initialValue: (initialFontSizeValue != null) &&
                    (initialFontSizeValue <= fontSizes.length - 1)
                ? initialFontSizeValue
                : 0,
          ),
        if (showBoldButton)
          ToggleStyleButton(
            attribute: AttributeM.bold,
            icon: Icons.format_bold,
            iconSize: toolbarIconSize,
            controller: controller,
            iconTheme: iconTheme,
          ),
        if (showItalicButton)
          ToggleStyleButton(
            attribute: AttributeM.italic,
            icon: Icons.format_italic,
            iconSize: toolbarIconSize,
            controller: controller,
            iconTheme: iconTheme,
          ),
        if (showSmallButton)
          ToggleStyleButton(
            attribute: AttributeM.small,
            icon: Icons.format_size,
            iconSize: toolbarIconSize,
            controller: controller,
            iconTheme: iconTheme,
          ),
        if (showUnderLineButton)
          ToggleStyleButton(
            attribute: AttributeM.underline,
            icon: Icons.format_underline,
            iconSize: toolbarIconSize,
            controller: controller,
            iconTheme: iconTheme,
          ),
        if (showStrikeThrough)
          ToggleStyleButton(
            attribute: AttributeM.strikeThrough,
            icon: Icons.format_strikethrough,
            iconSize: toolbarIconSize,
            controller: controller,
            iconTheme: iconTheme,
          ),
        if (showInlineCode)
          ToggleStyleButton(
            attribute: AttributeM.inlineCode,
            icon: Icons.code,
            iconSize: toolbarIconSize,
            controller: controller,
            iconTheme: iconTheme,
          ),
        if (showColorButton)
          ColorButton(
            icon: Icons.color_lens,
            iconSize: toolbarIconSize,
            controller: controller,
            background: false,
            iconTheme: iconTheme,
          ),
        if (showBackgroundColorButton)
          ColorButton(
            icon: Icons.format_color_fill,
            iconSize: toolbarIconSize,
            controller: controller,
            background: true,
            iconTheme: iconTheme,
          ),
        if (showClearFormat)
          ClearFormatButton(
            icon: Icons.format_clear,
            iconSize: toolbarIconSize,
            controller: controller,
            iconTheme: iconTheme,
          ),
        if (showImageButton)
          ImageButton(
            icon: Icons.image,
            iconSize: toolbarIconSize,
            controller: controller,
            onImagePickCallback: onImagePickCallback,
            filePickImpl: filePickImpl,
            webImagePickImpl: webImagePickImpl,
            mediaPickSettingSelector: mediaPickSettingSelector,
            iconTheme: iconTheme,
            dialogTheme: dialogTheme,
          ),
        if (showVideoButton)
          VideoButton(
            icon: Icons.movie_creation,
            iconSize: toolbarIconSize,
            controller: controller,
            onVideoPickCallback: onVideoPickCallback,
            filePickImpl: filePickImpl,
            webVideoPickImpl: webImagePickImpl,
            mediaPickSettingSelector: mediaPickSettingSelector,
            iconTheme: iconTheme,
            dialogTheme: dialogTheme,
          ),
        if ((onImagePickCallback != null || onVideoPickCallback != null) &&
            showCameraButton)
          CameraButton(
            icon: Icons.photo_camera,
            iconSize: toolbarIconSize,
            controller: controller,
            onImagePickCallback: onImagePickCallback,
            onVideoPickCallback: onVideoPickCallback,
            filePickImpl: filePickImpl,
            webImagePickImpl: webImagePickImpl,
            webVideoPickImpl: webVideoPickImpl,
            iconTheme: iconTheme,
          ),
        if (showDividers &&
            isButtonGroupShown[0] &&
            (isButtonGroupShown[1] ||
                isButtonGroupShown[2] ||
                isButtonGroupShown[3] ||
                isButtonGroupShown[4] ||
                isButtonGroupShown[5]))
          _divider(),
        if (showAlignmentButtons)
          SelectAlignmentButton(
            controller: controller,
            iconSize: toolbarIconSize,
            iconTheme: iconTheme,
            showLeftAlignment: showLeftAlignment,
            showCenterAlignment: showCenterAlignment,
            showRightAlignment: showRightAlignment,
            showJustifyAlignment: showJustifyAlignment,
          ),
        if (showDirection)
          ToggleStyleButton(
            attribute: AttributeM.rtl,
            controller: controller,
            icon: Icons.format_textdirection_r_to_l,
            iconSize: toolbarIconSize,
            iconTheme: iconTheme,
          ),
        if (showDividers &&
            isButtonGroupShown[1] &&
            (isButtonGroupShown[2] ||
                isButtonGroupShown[3] ||
                isButtonGroupShown[4] ||
                isButtonGroupShown[5]))
          _divider(),
        if (showHeaderStyle)
          SelectHeaderStyleButton(
            controller: controller,
            iconSize: toolbarIconSize,
            iconTheme: iconTheme,
          ),
        if (showDividers &&
            showHeaderStyle &&
            isButtonGroupShown[2] &&
            (isButtonGroupShown[3] ||
                isButtonGroupShown[4] ||
                isButtonGroupShown[5]))
          _divider(),
        if (showListNumbers)
          ToggleStyleButton(
            attribute: AttributeM.ol,
            controller: controller,
            icon: Icons.format_list_numbered,
            iconSize: toolbarIconSize,
            iconTheme: iconTheme,
          ),
        if (showListBullets)
          ToggleStyleButton(
            attribute: AttributeM.ul,
            controller: controller,
            icon: Icons.format_list_bulleted,
            iconSize: toolbarIconSize,
            iconTheme: iconTheme,
          ),
        if (showListCheck)
          ToggleCheckListButton(
            attribute: AttributeM.unchecked,
            controller: controller,
            icon: Icons.check_box,
            iconSize: toolbarIconSize,
            iconTheme: iconTheme,
          ),
        if (showCodeBlock)
          ToggleStyleButton(
            attribute: AttributeM.codeBlock,
            controller: controller,
            icon: Icons.code,
            iconSize: toolbarIconSize,
            iconTheme: iconTheme,
          ),
        if (showDividers &&
            isButtonGroupShown[3] &&
            (isButtonGroupShown[4] || isButtonGroupShown[5]))
          _divider(),
        if (showQuote)
          ToggleStyleButton(
            attribute: AttributeM.blockQuote,
            controller: controller,
            icon: Icons.format_quote,
            iconSize: toolbarIconSize,
            iconTheme: iconTheme,
          ),
        if (showIndent)
          IndentButton(
            icon: Icons.format_indent_increase,
            iconSize: toolbarIconSize,
            controller: controller,
            isIncrease: true,
            iconTheme: iconTheme,
          ),
        if (showIndent)
          IndentButton(
            icon: Icons.format_indent_decrease,
            iconSize: toolbarIconSize,
            controller: controller,
            isIncrease: false,
            iconTheme: iconTheme,
          ),
        if (showDividers && isButtonGroupShown[4] && isButtonGroupShown[5])
          _divider(),
        if (showLink)
          LinkStyleButton(
            controller: controller,
            iconSize: toolbarIconSize,
            iconTheme: iconTheme,
            dialogTheme: dialogTheme,
          ),
        if (customIcons.isNotEmpty)
          if (showDividers) _divider(),
        for (var customIcon in customIcons)
          IconBtn(
            highlightElevation: 0,
            hoverElevation: 0,
            size: toolbarIconSize * iconButtonFactor,
            icon: Icon(
              customIcon.icon,
              size: toolbarIconSize,
            ),
            borderRadius: iconTheme?.borderRadius ?? 2,
            onPressed: customIcon.onTap,
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return I18n(
      initialLocale: locale,
      child: multiRowsDisplay
          ? Wrap(
              alignment: toolbarIconAlignment,
              runSpacing: 4,
              spacing: buttonsSpacing,
              children: children,
            )
          : Container(
              constraints: BoxConstraints.tightFor(
                height: preferredSize.height,
              ),
              color: color ?? Theme.of(context).canvasColor,
              child: ArrowScrollableButtonList(
                buttons: children,
              ),
            ),
    );
  }
}
