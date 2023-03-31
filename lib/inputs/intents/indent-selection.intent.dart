import 'package:flutter/material.dart';

class IndentSelectionIntent extends Intent {
  final bool isIncrease;

  const IndentSelectionIntent(
    this.isIncrease,
  );
}
