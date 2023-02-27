import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:visual_editor/visual-editor.dart';

import '../../shared/widgets/demo-page-scaffold.dart';
import '../../shared/widgets/loading.dart';
import '../const/profile-card-dimensions.dart';
import '../const/profiles-list.const.dart';
import '../models/profile-card.cfg.dart';
import '../models/profile-card.model.dart';
import '../widgets/profile-card.dart';

// Hovering a marker will display a profile card.
// The most efficient way to achieve this behavior is to link every marker with the profile.
// For this, we can store in the marker dynamic parameter 'data' the id of the profile and keep
// the profiles list separately. In this way, we keep the markers on the server as simple as possible.
class ProfileCardOnMarkerPage extends StatefulWidget {
  @override
  _ProfileCardOnMarkerPageState createState() =>
      _ProfileCardOnMarkerPageState();
}

class _ProfileCardOnMarkerPageState extends State<ProfileCardOnMarkerPage> {
  EditorController? _controller;
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();
  bool _isProfileCardVisible = false;

  // Cache used to temporary store the rectangle and line offset as
  // delivered by the editor while the scroll offset is changing.
  var _rectangle = TextBox.fromLTRBD(0, 0, 0, 0, TextDirection.ltr);
  Offset? _lineOffset = Offset.zero;
  ProfileCardM _profile = ProfileCardM();

  // (!) This stream is extremely important for maintaining the page performance when updating the profile card position.
  // The _positionProfileCardAtRectangle() method will be called many times per second when scrolling.
  // Therefore we want to avoid at all costs to setState() in the parent ProfileCardOnMarkerPage.
  // We will update only the ProfileCard via the stream.
  // By using this trick we can prevent Flutter from running expensive page updates.
  // We will target our updates only on the area that renders the profile card (far better performance).
  final _profileCardCfg$ = StreamController<ProfileCardCfg>.broadcast();
  late ProfileCardCfg _profileCardCfg;

  @override
  void initState() {
    _loadDocumentAndInitController();
    super.initState();
  }

  @override
  Widget build(BuildContext context) => _scaffold(
        child: _controller != null
            ? _stack(
                children: [
                  _col(
                    children: [
                      _editor(),
                      _toolbar(),
                    ],
                  ),
                  if (_isProfileCardVisible) _profileCard(),
                ],
              )
            : Loading(),
      );

  Widget _stack({required List<Widget> children}) => Stack(
        children: children,
      );

  Widget _scaffold({required Widget child}) => DemoPageScaffold(
        child: child,
      );

  Widget _col({required List<Widget> children}) => Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: children,
      );

  Widget _profileCard() => ProfileCard(
        cfg: _profileCardCfg,
        cfg$: _profileCardCfg$,
      );

  Widget _editor() => Flexible(
        child: Container(
          color: Colors.white,
          padding: EdgeInsets.fromLTRB(16, 0, 16, 0),
          child: VisualEditor(
            controller: _controller!,
            scrollController: _scrollController,
            focusNode: _focusNode,
            config: EditorConfigM(
                markerTypes: _getMarkerTypes(),
                onScroll: _updateProfileCardPositionAfterScroll
                // Uncomment this param if you want to initialise the editor with the markers turned off.
                // They can later be re-enabled at runtime via the controller.
                // markersVisibility: true,
                ),
          ),
        ),
      );

  Widget _toolbar() => Container(
        padding: EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 8,
        ),
        child: EditorToolbar.basic(
          controller: _controller!,
          showMarkers: true,
          multiRowsDisplay: false,
        ),
      );

  Future<void> _loadDocumentAndInitController() async {
    final deltaJson = await rootBundle.loadString(
      'lib/markers/assets/profile-card-on-marker.json',
    );
    final document = DocumentM.fromJson(jsonDecode(deltaJson));

    setState(() {
      _controller = EditorController(
        document: document,
      );
    });
  }

  List<MarkerTypeM> _getMarkerTypes() => [
        MarkerTypeM(
          id: 'expert',
          name: 'Expert',
          color: Colors.blue.withOpacity(0.2),
          onAddMarkerViaToolbar: (_) => 'fake-id-1',
          onEnter: _displayProfileCardOnMarker,
          onExit: (marker) {
            _hideProfileCard();
          },
        ),
      ];

  void _displayProfileCard() {
    setState(() {
      _isProfileCardVisible = true;
    });
  }

  void _hideProfileCard() {
    if (_isProfileCardVisible != false) {
      setState(() {
        _isProfileCardVisible = false;
      });
    }
  }

  void _displayProfileCardOnMarker(MarkerM marker) {
    final rectangle = marker.rectangles![0];
    final lineOffset = marker.docRelPosition;
    _rectangle = rectangle;
    _lineOffset = lineOffset;
    _getProfileByMarker(marker);
    _positionProfileCardAtRectangle();
    _displayProfileCard();
  }

  // Use the updated scroll offset and the existing cached rectangles
  void _updateProfileCardPositionAfterScroll() {
    if (_isProfileCardVisible) {
      _positionProfileCardAtRectangle();
    }
  }

  void _getProfileByMarker(MarkerM marker) {
    _profile = PROFILE_LIST.firstWhere(
      (profile) => profile.id == marker.data,
    );
  }

  void _positionProfileCardAtRectangle() {
    final midPoint = (_rectangle.left + _rectangle.right) / 2;
    final scrollOffset = _scrollController.offset;
    const menuHalfWidth = profileCardWidth / 2 - 20;

    // Profile card position
    final offset = Offset(
      midPoint - menuHalfWidth,
      (_lineOffset?.dy ?? 0) +
          _rectangle.top -
          scrollOffset -
          profileCardHeight,
    );

    _profileCardCfg = ProfileCardCfg(
      profile: _profile,
      offset: offset,
    );

    _profileCardCfg$.sink.add(
      ProfileCardCfg(
        profile: _profile,
        offset: offset,
      ),
    );
  }
}
