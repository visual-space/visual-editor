import 'package:flutter/scheduler.dart';

import '../../shared/state/editor.state.dart';

// Provides easy access to the build trigger.
// After the document changes have been applied and the gui elements have
// been updated, it's now time to update the document widget tree.
class RunBuildService {
  final EditorState state;

  RunBuildService(this.state);

  Stream get runBuild$ {
    return state.runBuild.runBuild$;
  }

  void runBuild() {
    state.runBuild.runBuild();
  }

  void callBuildCompleteCallback() {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      final onBuildComplete = state.config.onBuildComplete;

      if (onBuildComplete != null) {
        onBuildComplete();
      }
    });
  }
}
