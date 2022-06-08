import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../widgets/raw-editor.dart';

// +++ DELETE
// Base interface for the editor state which defines contract used by various mixins.
abstract class EditorStateM extends State<RawEditor>
    implements TextSelectionDelegate {
}
