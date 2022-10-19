import 'package:flutter/material.dart';
import 'package:i18n_extension/i18n_widget.dart';

import '../../controller/controllers/editor-controller.dart';
import '../../documents/models/attributes/attributes-aliases.model.dart';
import '../../documents/models/attributes/attributes.model.dart';
import '../../shared/models/editor-dialog-theme.model.dart';
import '../../shared/models/editor-icon-theme.model.dart';
import '../../shared/widgets/arrow-scrollable-button-list.dart';
import '../../shared/widgets/icon-button.dart';
import '../models/editor-custom-icon.model.dart';
import '../models/font-sizes.const.dart';
import '../models/media-picker.type.dart';
import 'buttons/camera-button.dart';
import 'buttons/clear-format-button.dart';
import 'buttons/color-button.dart';
import 'buttons/history-button.dart';
import 'buttons/image-button.dart';
import 'buttons/indent-button.dart';
import 'buttons/link-style-button.dart';
import 'buttons/select-alignment-button.dart';
import 'buttons/select-header-style-button.dart';
import 'buttons/toggle-check-list-button.dart';
import 'buttons/toggle-style-button.dart';
import 'buttons/video-button.dart';
import 'dropdowns/markers-dropdown.dart';
import 'dropdowns/sizes-dropdown.dart';

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
const defaultIconSize = 21.0;

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
  final List<EditorCustomButtonM> customButtons;

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
    double toolbarSectionSpacing = 2.5,
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

    // Disabled by default because most apps wont need such functionality.
    // Enable it only if your app requires the authors to define the markers themselves.
    // Markers can be added also programmatically via the controller.
    bool showMarkers = false,
    OnImagePickCallback? onImagePickCallback,
    OnVideoPickCallback? onVideoPickCallback,
    MediaPickSettingSelector? mediaPickSettingSelector,
    FilePickImpl? filePickImpl,
    WebImagePickImpl? webImagePickImpl,
    WebVideoPickImpl? webVideoPickImpl,
    List<EditorCustomButtonM> customIcons = const [],

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
    final fontSizes = fontSizeValues ?? FONT_SIZES;

    Widget _divider() => Container(
          margin: EdgeInsets.only(
            top: multiRowsDisplay ? 6.5 : 0,
            left: 7,
            right: 7,
          ),
          height: toolbarIconSize + 5,
          width: 1.3,
          color: Colors.grey.shade400,
        );

    return EditorToolbar(
      key: key,
      toolbarHeight: toolbarIconSize * 3,
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
            buttonsSpacing: toolbarSectionSpacing,
            undo: true,
            iconTheme: iconTheme,
          ),
        if (showRedo)
          HistoryButton(
            icon: Icons.redo_outlined,
            iconSize: toolbarIconSize,
            controller: controller,
            buttonsSpacing: toolbarSectionSpacing,
            undo: false,
            iconTheme: iconTheme,
          ),
        if (showFontSize)
          SizesDropdown(
            fontSizes: fontSizes,
            controller: controller,
            toolbarIconSize: toolbarIconSize,
            iconTheme: iconTheme,
            initialFontSizeValue: initialFontSizeValue ?? 11,
          ),
        if (showBoldButton)
          ToggleStyleButton(
            attribute: AttributesM.bold,
            icon: Icons.format_bold,
            buttonsSpacing: toolbarSectionSpacing,
            iconSize: toolbarIconSize,
            controller: controller,
            iconTheme: iconTheme,
          ),
        if (showItalicButton)
          ToggleStyleButton(
            attribute: AttributesM.italic,
            icon: Icons.format_italic,
            buttonsSpacing: toolbarSectionSpacing,
            iconSize: toolbarIconSize,
            controller: controller,
            iconTheme: iconTheme,
          ),
        if (showSmallButton)
          ToggleStyleButton(
            attribute: AttributesM.small,
            icon: Icons.format_size,
            buttonsSpacing: toolbarSectionSpacing,
            iconSize: toolbarIconSize,
            controller: controller,
            iconTheme: iconTheme,
          ),
        if (showUnderLineButton)
          ToggleStyleButton(
            attribute: AttributesM.underline,
            icon: Icons.format_underline,
            iconSize: toolbarIconSize,
            controller: controller,
            buttonsSpacing: toolbarSectionSpacing,
            iconTheme: iconTheme,
          ),
        if (showStrikeThrough)
          ToggleStyleButton(
            attribute: AttributesM.strikeThrough,
            icon: Icons.format_strikethrough,
            iconSize: toolbarIconSize,
            controller: controller,
            buttonsSpacing: toolbarSectionSpacing,
            iconTheme: iconTheme,
          ),
        if (showInlineCode)
          ToggleStyleButton(
            attribute: AttributesM.inlineCode,
            icon: Icons.code,
            iconSize: toolbarIconSize,
            controller: controller,
            buttonsSpacing: toolbarSectionSpacing,
            iconTheme: iconTheme,
          ),
        if (showColorButton)
          ColorButton(
            icon: Icons.color_lens,
            iconSize: toolbarIconSize,
            controller: controller,
            buttonsSpacing: toolbarSectionSpacing,
            background: false,
            iconTheme: iconTheme,
          ),
        if (showBackgroundColorButton)
          ColorButton(
            icon: Icons.format_color_fill,
            iconSize: toolbarIconSize,
            buttonsSpacing: toolbarSectionSpacing,
            controller: controller,
            background: true,
            iconTheme: iconTheme,
          ),
        if (showClearFormat)
          ClearFormatButton(
            icon: Icons.format_clear,
            buttonsSpacing: toolbarSectionSpacing,
            iconSize: toolbarIconSize,
            controller: controller,
            iconTheme: iconTheme,
          ),
        if (showImageButton)
          ImageButton(
            icon: Icons.image,
            iconSize: toolbarIconSize,
            buttonsSpacing: toolbarSectionSpacing,
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
            buttonsSpacing: toolbarSectionSpacing,
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
            buttonsSpacing: toolbarSectionSpacing,
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
            buttonsSpacing: toolbarSectionSpacing,
            showLeftAlignment: showLeftAlignment,
            showCenterAlignment: showCenterAlignment,
            showRightAlignment: showRightAlignment,
            showJustifyAlignment: showJustifyAlignment,
          ),
        if (showDirection)
          ToggleStyleButton(
            attribute: AttributesAliasesM.rtl,
            buttonsSpacing: toolbarSectionSpacing,
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
            buttonsSpacing: toolbarSectionSpacing,
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
            buttonsSpacing: toolbarSectionSpacing,
            attribute: AttributesAliasesM.ol,
            controller: controller,
            icon: Icons.format_list_numbered,
            iconSize: toolbarIconSize,
            iconTheme: iconTheme,
          ),
        if (showListBullets)
          ToggleStyleButton(
            attribute: AttributesAliasesM.ul,
            controller: controller,
            icon: Icons.format_list_bulleted,
            buttonsSpacing: toolbarSectionSpacing,
            iconSize: toolbarIconSize,
            iconTheme: iconTheme,
          ),
        if (showListCheck)
          ToggleCheckListButton(
            attribute: AttributesAliasesM.unchecked,
            controller: controller,
            icon: Icons.check_box,
            buttonsSpacing: toolbarSectionSpacing,
            iconSize: toolbarIconSize,
            iconTheme: iconTheme,
          ),
        if (showCodeBlock)
          ToggleStyleButton(
            attribute: AttributesM.codeBlock,
            controller: controller,
            icon: Icons.code,
            buttonsSpacing: toolbarSectionSpacing,
            iconSize: toolbarIconSize,
            iconTheme: iconTheme,
          ),
        if (showDividers &&
            isButtonGroupShown[3] &&
            (isButtonGroupShown[4] || isButtonGroupShown[5]))
          _divider(),
        if (showQuote)
          ToggleStyleButton(
            attribute: AttributesM.blockQuote,
            controller: controller,
            buttonsSpacing: toolbarSectionSpacing,
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
            buttonsSpacing: toolbarSectionSpacing,
            iconTheme: iconTheme,
          ),
        if (showIndent)
          IndentButton(
            icon: Icons.format_indent_decrease,
            buttonsSpacing: toolbarSectionSpacing,
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
            buttonsSpacing: toolbarSectionSpacing,
            iconTheme: iconTheme,
            dialogTheme: dialogTheme,
          ),
        if (showMarkers)
          MarkersDropdown(
            controller: controller,
            iconSize: toolbarIconSize,
            buttonsSpacing: toolbarSectionSpacing,
            toolbarIconSize: toolbarIconSize,
            iconTheme: iconTheme,
          ),
        if (customIcons.isNotEmpty)
          if (showDividers) _divider(),
        for (var customIcon in customIcons)
          IconBtn(
            highlightElevation: 0,
            buttonsSpacing: toolbarSectionSpacing,
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
          ? Container(
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: Wrap(
                alignment: toolbarIconAlignment,
                runSpacing: 4,
                children: children,
              ),
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
