import '../../editor/services/run-build.service.dart';
import '../../highlights/models/highlight.model.dart';
import '../../shared/state/editor.state.dart';

// Adds removes temporary highlights from the document.
class HighlightsService {
  late final RunBuildService _runBuildService;

  final EditorState state;

  HighlightsService(this.state) {
    _runBuildService = RunBuildService(state);
  }

  void addHighlight(HighlightM highlight) {
    state.highlights.addHighlight(highlight);
    _runBuildService.runBuild();
  }

  void removeHighlight(HighlightM highlight) {
    state.highlights.removeHighlight(highlight);
    _runBuildService.runBuild();
  }

  void removeAllHighlights() {
    state.highlights.removeAllHighlights();
    _runBuildService.runBuild();
  }
}
