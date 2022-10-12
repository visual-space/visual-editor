import '../models/heading-type.enum.dart';
import '../models/heading.model.dart';

// Store all headings find in a document.
// At the first build, all existent headings are extracted from
// the document then they are synchronously added in the document and state store
class HeadingsState {
  List<HeadingTypeE> _headingsTypes = [HeadingTypeE.h1];
  List<HeadingM> _headings = [];

  List<HeadingM> get headings => _headings;

  List<HeadingTypeE> get headingsTypes => _headingsTypes;

  void setHeadingTypes(List<HeadingTypeE> headingTypes) {
    _headingsTypes = headingTypes;
  }

  void addHeading(HeadingM heading) {
    _headings.add(heading);
  }

  void removeAllHeadings() {
    _headings = [];
  }
}
