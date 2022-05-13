import 'package:flutter/material.dart';

// Internal use, used to get drag direction information
class DragTextSelection extends TextSelection {
  const DragTextSelection({
    TextAffinity affinity = TextAffinity.downstream,
    int baseOffset = 0,
    int extentOffset = 0,
    bool isDirectional = false,
    this.first = true,
  }) : super(
          baseOffset: baseOffset,
          extentOffset: extentOffset,
          affinity: affinity,
          isDirectional: isDirectional,
        );

  final bool first;

  @override
  DragTextSelection copyWith({
    int? baseOffset,
    int? extentOffset,
    TextAffinity? affinity,
    bool? isDirectional,
    bool? first,
  }) {
    return DragTextSelection(
      baseOffset: baseOffset ?? this.baseOffset,
      extentOffset: extentOffset ?? this.extentOffset,
      affinity: affinity ?? this.affinity,
      isDirectional: isDirectional ?? this.isDirectional,
      first: first ?? this.first,
    );
  }
}
