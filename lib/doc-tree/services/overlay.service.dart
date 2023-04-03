import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../links/services/links.service.dart';
import '../../links/widgets/link-menu.dart';
import '../../shared/state/editor.state.dart';
import '../../styles/services/styles.service.dart';

// We avoid using Stack widget for displaying widgets on the screen by using the
// flutter Overlay API. Every overlay in our editor should be accessed from here.
class OverlayService {
  late final LinksService _linksService;
  late final StylesService _stylesService;

  final EditorState state;

  OverlayEntry? _linkMenuOverlayEntry;

  OverlayService(this.state) {
    _linksService = LinksService(state);
    _stylesService = StylesService(state);
  }

  // === LINK MENU OVERLAY ===

  // Handles the logic for displaying the link menu.
  void refreshLinkMenuOverlay(BuildContext context) {
    // (!) getLinkMenuOverlay() is executed at each new build.
    // In order to prevent multiple entries to be added because multiples builds
    // are done (hovering over highlights, changing selection, extending selection, apply styling etc).
    // We must first remove the previous entry and then apply the new one.
    // Idk exactly why flutter keeps the old overlay entry even though a new build was made.
    // Even in docs of they are approaching it the same (by removing the overlay)
    // https://api.flutter.dev/flutter/widgets/Overlay-class.html
    _removeLinkMenuOverlay();

    // Gets the offset for the link menu after the layout is fully built, and then creates a
    // overlay entry which places the link menu correctly.
    _setlinkMenuOverlayEntry();

    // In order to prevent overlapping with the framework building it's widget tree, we must
    // insert the overlay entries after the build has finished.
    SchedulerBinding.instance.addPostFrameCallback((_) {
      final overlayState = Overlay.of(context);

      // Link Menu
      _insertLinkMenu(overlayState);
    });
  }

  // === PRIVATE ===

  void _insertLinkMenu(OverlayState overlayState) {
    final isLinkSelected =
        _stylesService.getSelectionStyle().attributes.containsKey('link');
    final isLinkMenuEnabled = state.config.linkMenuDisabled != true;

    // Link Menu
    isLinkSelected && isLinkMenuEnabled
        ? overlayState.insert(
            _linkMenuOverlayEntry!,
          )
        : null;
  }

  void _removeLinkMenuOverlay() {
    final linkMenuOverlay = _linkMenuOverlayEntry;

    if (linkMenuOverlay != null && linkMenuOverlay.mounted) {
      linkMenuOverlay.remove();
    }
  }

  void _setlinkMenuOverlayEntry() {
    // Default value
    var offset = Offset.infinite;

    // (!) Must be set after the layout was fully built, because selected link rectangles
    // are stored after the build, and they are needed inside the getOffsetForLinkMenu()
    // in order to calculate the offset.
    SchedulerBinding.instance.addPostFrameCallback((_) {
      offset = _linksService.getOffsetForLinkMenu();
    });

    final linkMenuOverlayEntry = OverlayEntry(
      builder: (context) {
        return Positioned(
          top: offset.dy,
          left: offset.dx,
          child: Material(
            color: Colors.transparent,
            child: LinkMenu(
              controller: state.refs.controller,
            ),
          ),
        );
      },
    );

    _linkMenuOverlayEntry = linkMenuOverlayEntry;
  }
}
