import 'package:flutter/material.dart';

import 'default-styles.utils.dart';

class EditorStylesUtils extends InheritedWidget {
  const EditorStylesUtils({
    required this.data,
    required Widget child,
    Key? key,
  }) : super(key: key, child: child);

  final DefaultStyles data;

  @override
  bool updateShouldNotify(EditorStylesUtils oldWidget) {
    return data != oldWidget.data;
  }

  static DefaultStyles? getStyles(BuildContext context, bool nullOk) {
    final widget = context.dependOnInheritedWidgetOfExactType<EditorStylesUtils>();

    if (widget == null && nullOk) {
      return null;
    }

    assert(widget != null);
    return widget!.data;
  }
}
