// Diff between two texts - old text and new text
class DiffM {
  // Start index in old text at which changes begin.
  final int start;

  // The deleted text
  final String deleted;

  // The inserted text
  final String inserted;

  DiffM(
    this.start,
    this.deleted,
    this.inserted,
  );

  @override
  String toString() {
    return 'Diff[$start, "$deleted", "$inserted"]';
  }
}
