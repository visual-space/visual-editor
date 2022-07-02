import 'package:flutter/material.dart';

class SelectionLayersState {
  // The object supplied to the CompositedTransformTarget that wraps the text field.
  final LayerLink toolbarLayerLink = LayerLink();

  // The objects supplied to the CompositedTransformTarget that wraps the location of start selection handle.
  final LayerLink startHandleLayerLink = LayerLink();

  // The objects supplied to the CompositedTransformTarget that wraps the location of end selection handle.
  final LayerLink endHandleLayerLink = LayerLink();
}
