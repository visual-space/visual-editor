import '../models/search-match.model.dart';

// Handle all matches found when a user search a certain syntax.
// We need to keep them in a separate state because the matches will be used for more features
// such as, matches positions sidebar or navigate trough matches.
class SearchState {
  List<SearchMatchM> matches = [];

  void addMatches(List<SearchMatchM> _matches) {
    matches = _matches;
  }
}
