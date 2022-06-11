import 'package:flutter/material.dart';

import '../../blocks/models/default-styles.model.dart';

class DocumentStyles extends InheritedWidget {
  const DocumentStyles({
    required this.styles,
    required Widget child,
    Key? key,
  }) : super(key: key, child: child);

  final DefaultStyles styles;

  @override
  bool updateShouldNotify(DocumentStyles oldWidget) {
    return styles != oldWidget.styles;
  }

  static DefaultStyles? getStyles(BuildContext context, bool nullOk) {
    final widget = context.dependOnInheritedWidgetOfExactType<DocumentStyles>();

    if (widget == null && nullOk) {
      return null;
    }

    assert(widget != null);
    return widget!.styles;
  }
}
