import 'package:flutter/material.dart';

// Options to be listed in the dropdown list of a dropdown
@immutable
class DropDownOptionM<T> {
  final String name;
  final T value;

  const DropDownOptionM({
    required this.name,
    required this.value,
  });

  @override
  String toString() {
    return 'DropDownOptionM(name: $name, value: $value)';
  }
}
