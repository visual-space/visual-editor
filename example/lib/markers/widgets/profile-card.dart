import 'dart:async';

import 'package:flutter/material.dart';

import '../const/profile-card-dimensions.dart';
import '../models/profile-card.cfg.dart';

class ProfileCard extends StatefulWidget {
  final ProfileCardCfg cfg;
  final StreamController<ProfileCardCfg> cfg$;

  ProfileCard({
    required this.cfg,
    required this.cfg$,
    Key? key,
  }) : super(key: key);

  @override
  State<ProfileCard> createState() => _ProfileCardState();
}

class _ProfileCardState extends State<ProfileCard> {
  late ProfileCardCfg _cfg;
  late StreamSubscription _cfg$L;

  @override
  void initState() {
    _subscribeToPositionOffset();
    super.initState();
  }

  @override
  void dispose() {
    _cfg$L.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _box(
      child: _col(
        children: [
          _name(),
          _description(),
        ],
      ),
    );
  }

  Widget _box({required Widget child}) => Positioned(
        left: _cfg.offset?.dx ?? 0,
        top: _cfg.offset?.dy ?? 0,
        child: Container(
          height: profileCardHeight,
          width: profileCardWidth,
          color: Colors.black87,
          padding: EdgeInsets.all(15),
          child: child,
        ),
      );

  Widget _col({required List<Widget> children}) => Column(
        mainAxisSize: MainAxisSize.min,
        children: children,
      );

  Widget _name() => Container(
        padding: EdgeInsets.only(bottom: 10),
        child: Text(
          _cfg.profile?.userName ?? '',
          style: TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      );

  Widget _description() => Text(
        _cfg.profile?.description ?? '',
        style: TextStyle(
          color: Colors.white,
          fontSize: 12,
        ),
      );

  // (!) If using rxdart we could avoid the init and additional param by using a BehaviourSubject.
  // However we wanted to keep this lib lightweight and avoid adding unnecessary libs.
  // Therefore the init and update are done via 2 params.
  void _subscribeToPositionOffset() {
    // Init
    _cfg = widget.cfg;

    // Update
    _cfg$L = widget.cfg$.stream.listen(
      (cfg) => setState(() {
        _cfg = cfg;
      }),
    );
  }
}
