// Compare arrays to detect if the elements are the same in both.
bool areListsEqual(var list1, var list2) {
  final bothAreLists = list1 is List && list2 is List;
  final sameLength = list1?.length == list2?.length;

  if (!bothAreLists || !sameLength) {
    return false;
  }

  // Check if elements are equal
  for (var i = 0; i < list1.length; i++) {
    if (list1[i] != list2[i]) {
      return false;
    }
  }

  return true;
}
