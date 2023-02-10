import 'package:flutter/material.dart';

import '../../document/models/nodes/line.model.dart';
import '../../shared/models/content-proxy-box-renderer.model.dart';
import '../../styles/models/doc-tree/inline-code-style.model.dart';

// An internal config object, used to decouple the paint code
// from the layout code in the EditableTextLineBoxRenderer.
@immutable
class TextPaintCfgM {
  final PaintingContext context;
  final Offset offset;
  final RenderBox? leading;
  final RenderContentProxyBox? underlyingText;
  final InlineCodeStyle inlineCodeStyle;
  final LineM line;
  final bool Function() containsCursor;
  final TextSelection selection;
  final bool Function(TextSelection selection) lineContainsSelection;
  final List<TextBox>? selectedRects;
  final Rect caretPrototype;
  final double devicePixelRatio;

  const TextPaintCfgM(
    this.context,
    this.offset,
    this.leading,
    this.underlyingText,
    this.inlineCodeStyle,
    this.line,
    this.containsCursor,
    this.selection,
    this.lineContainsSelection,
    this.selectedRects,
    this.caretPrototype,
    this.devicePixelRatio,
  );
}
