// Every time a header exceeds the characters limit a counter
// that shows how many characters are above the limit.
// Every counter has its own position in the document based on the header's position.
class CharacterCounterM {
  final int count;
  final double? yPosition;

  const CharacterCounterM({
    required this.count,
    required this.yPosition,
  });

  CharacterCounterM copyWith({
    int? count,
    double? yPosition,
  }) =>
      CharacterCounterM(
        count: count ?? this.count,
        yPosition: yPosition ?? this.yPosition,
      );
}
