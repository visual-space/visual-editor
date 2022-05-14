import 'package:flutter/material.dart';

abstract class EditorCheckboxBuilder {
  Widget build({
    required BuildContext context,
    required bool isChecked,
    required ValueChanged<bool> onChanged,
  });
}
