import '../models/heading-type.enum.dart';
import '../models/heading.model.dart';

// Store all headings find in a document.
// At the first build, all existent headings are extracted from
// the document then they are synchronously added in the document and state store
class HeadingsState {
  // === HEADING TYPES ===

  List<HeadingTypeE> headingsTypes = [HeadingTypeE.h1];

  // === HEADINGS ===

  List<HeadingM> _headings = [];

  List<HeadingM> get headings => _headings;

  void addHeading(HeadingM heading) {
    _headings.add(heading);
  }

  void removeAllHeadings() {
    _headings = [];
  }
}
