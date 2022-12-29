import 'dart:async';

import 'package:flutter/material.dart';

import '../controllers/headings-counter.controller.dart';
import '../models/character-counter.model.dart';

// Displayed near every heading that exceeded the length limit.
// It shows how many characters are above the limit.
// The information about the counters is got directly from the controller.
class CharacterCountersSmart extends StatefulWidget {
  final HeadingsCounterController headingsController;

  const CharacterCountersSmart({
    required this.headingsController,
    Key? key,
  }) : super(key: key);

  @override
  State<CharacterCountersSmart> createState() => _CharacterCountersSmartState();
}

class _CharacterCountersSmartState extends State<CharacterCountersSmart> {
  late final StreamSubscription _countersListener;
  List<CharacterCounterM> _counters = [];

  @override
  void initState() {
    _subscribeToCounters();
    super.initState();
  }

  @override
  void dispose() {
    _countersListener.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _stack(
      children: [
        for (final counter in _counters)
          _counter(
            counter,
          ),
      ],
    );
  }

  Widget _stack({required List<Widget> children}) => Stack(
        children: children,
      );

  Widget _counter(CharacterCounterM counter) => Positioned(
        top: counter.yPosition,
        right: 0,
        child: Text(
          '-${counter.count}',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.red,
          ),
        ),
      );

  void _subscribeToCounters() {
    _countersListener = widget.headingsController.counters$().listen((counters) {
      setState(() {
        _counters = counters;
      });
    });
  }
}
