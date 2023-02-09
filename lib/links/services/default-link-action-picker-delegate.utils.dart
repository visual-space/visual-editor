import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../document/models/nodes/node.model.dart';
import '../../shared/translations/toolbar.i18n.dart';
import '../models/link-action-menu.enum.dart';
import '../widgets/cupertino-link-action.dart.dart';
import '../widgets/material-link-action.dart.dart';

Future<LinkMenuAction> defaultLinkActionPickerDelegate(
  BuildContext context,
  String link,
  NodeM node,
) async {
  switch (defaultTargetPlatform) {
    case TargetPlatform.iOS:
      return _showCupertinoLinkMenu(context, link);

    case TargetPlatform.android:
      return _showMaterialMenu(context, link);

    default:
      assert(
        false,
        'defaultShowLinkActionsMenu not supposed to '
        'be invoked for $defaultTargetPlatform',
      );

      return LinkMenuAction.none;
  }
}

// === PRIVATE ===

Future<LinkMenuAction> _showCupertinoLinkMenu(
  BuildContext context,
  String link,
) async {
  final result = await showCupertinoModalPopup<LinkMenuAction>(
    context: context,
    builder: (ctx) {
      return CupertinoActionSheet(
        title: Text(link),
        actions: [
          CupertinoLinkAction(
            title: 'Open',
            icon: Icons.language_sharp,
            onPressed: () => Navigator.of(context).pop(LinkMenuAction.launch),
          ),
          CupertinoLinkAction(
            title: 'Copy',
            icon: Icons.copy_sharp,
            onPressed: () => Navigator.of(context).pop(LinkMenuAction.copy),
          ),
          CupertinoLinkAction(
            title: 'Remove',
            icon: Icons.link_off_sharp,
            onPressed: () => Navigator.of(context).pop(LinkMenuAction.remove),
          ),
        ],
      );
    },
  );
  return result ?? LinkMenuAction.none;
}

Future<LinkMenuAction> _showMaterialMenu(
  BuildContext context,
  String link,
) async {
  final result = await showModalBottomSheet<LinkMenuAction>(
    context: context,
    builder: (ctx) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          MaterialLinkAction(
            title: 'Open'.i18n,
            icon: Icons.language_sharp,
            onPressed: () => Navigator.of(context).pop(LinkMenuAction.launch),
          ),
          MaterialLinkAction(
            title: 'Copy'.i18n,
            icon: Icons.copy_sharp,
            onPressed: () => Navigator.of(context).pop(LinkMenuAction.copy),
          ),
          MaterialLinkAction(
            title: 'Remove'.i18n,
            icon: Icons.link_off_sharp,
            onPressed: () => Navigator.of(context).pop(LinkMenuAction.remove),
          ),
        ],
      );
    },
  );

  return result ?? LinkMenuAction.none;
}
