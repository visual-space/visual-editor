import 'package:flutter/material.dart';
import 'profile-card.model.dart';

class ProfileCardCfg {
  final ProfileCardM? profile;
  final Offset? offset;

  const ProfileCardCfg({
    this.profile,
    this.offset,
  });

  @override
  String toString() {
    return 'ProfileCardCfg('
        'profile: $profile, '
        'offset: $offset,'
        ')';
  }

  ProfileCardCfg copyWith({
    ProfileCardM? profile,
    Offset? offset,
  }) =>
      ProfileCardCfg(
        profile: profile ?? this.profile,
        offset: offset ?? this.offset,
      );
}
