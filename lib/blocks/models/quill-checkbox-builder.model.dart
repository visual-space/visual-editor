import 'package:flutter/material.dart';

abstract class QuillCheckboxBuilder {
  Widget build({
    required BuildContext context,
    required bool isChecked,
    required ValueChanged<bool> onChanged,
  });
}
