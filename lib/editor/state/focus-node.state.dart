import 'package:flutter/cupertino.dart';

class FocusNodeState {
  factory FocusNodeState() => _instance;
  static final _instance = FocusNodeState._privateConstructor();

  FocusNodeState._privateConstructor();

  late FocusNode _node;

  FocusNode get node => _node;

  void setFocusNode(FocusNode node) => _node = node;
}
