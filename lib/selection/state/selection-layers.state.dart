import 'package:flutter/material.dart';

class SelectionLayersState {
  static final _instance = SelectionLayersState._privateConstructor();

  // The object supplied to the CompositedTransformTarget that wraps the text field.
  final LayerLink toolbarLayerLink = LayerLink();

  // The objects supplied to the CompositedTransformTarget that wraps the location of start selection handle.
  final LayerLink startHandleLayerLink = LayerLink();

  // The objects supplied to the CompositedTransformTarget that wraps the location of end selection handle.
  final LayerLink endHandleLayerLink = LayerLink();

  factory SelectionLayersState() => _instance;

  SelectionLayersState._privateConstructor();
}
