import 'styling-attributes.dart';

class AttributesM {
  static final bold = BoldAttributeM();
  static final italic = ItalicAttributeM();
  static final small = SmallAttributeM();
  static final underline = UnderlineAttributeM();
  static final strikeThrough = StrikeThroughAttributeM();
  static final inlineCode = InlineCodeAttributeM();
  static final font = FontAttributeM(null);
  static final size = SizeAttributeM(null);
  static final link = LinkAttributeM(null);
  static final color = ColorAttributeM(null);
  static final background = BackgroundAttributeM(null);
  static final placeholder = PlaceholderAttributeM();
  static final markers = MarkersAttributeM(null);
  static final header = HeaderAttributeM();
  static final indent = IndentAttributeM();
  static final align = AlignAttributeM(null);
  static final list = ListAttributeM(null);
  static final codeBlock = CodeBlockAttributeM();
  static final blockQuote = BlockQuoteAttributeM();
  static final direction = DirectionAttributeM(null);
  static final width = WidthAttributeM(null);
  static final height = HeightAttributeM(null);
  static final style = StyleAttributeM(null);
  static final token = TokenAttributeM('');
  static final script = ScriptAttributeM('');
  static const mobileWidth = 'mobileWidth';
  static const mobileHeight = 'mobileHeight';
  static const mobileMargin = 'mobileMargin';
  static const mobileAlignment = 'mobileAlignment';
}
