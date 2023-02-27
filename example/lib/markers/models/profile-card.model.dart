class ProfileCardM {
  final String? id;
  final String? userName;
  final String? description;

  const ProfileCardM({
    this.id,
    this.userName,
    this.description,
  });

  @override
  String toString() {
    return 'ProfileCardM('
        'id: $id, '
        'userName: $userName,'
        'description: $description,'
        ')';
  }
}
