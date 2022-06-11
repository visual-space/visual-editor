import 'attribute-scope.enum.dart';
import 'attribute.model.dart';

class BoldAttributeM extends AttributeM<bool> {
  BoldAttributeM() : super('bold', AttributeScope.INLINE, true);
}

class ItalicAttributeM extends AttributeM<bool> {
  ItalicAttributeM() : super('italic', AttributeScope.INLINE, true);
}

class SmallAttributeM extends AttributeM<bool> {
  SmallAttributeM() : super('small', AttributeScope.INLINE, true);
}

class UnderlineAttributeM extends AttributeM<bool> {
  UnderlineAttributeM() : super('underline', AttributeScope.INLINE, true);
}

class StrikeThroughAttributeM extends AttributeM<bool> {
  StrikeThroughAttributeM() : super('strike', AttributeScope.INLINE, true);
}

class InlineCodeAttributeM extends AttributeM<bool> {
  InlineCodeAttributeM() : super('code', AttributeScope.INLINE, true);
}

class FontAttributeM extends AttributeM<String?> {
  FontAttributeM(String? val) : super('font', AttributeScope.INLINE, val);
}

class SizeAttributeM extends AttributeM<String?> {
  SizeAttributeM(String? val) : super('size', AttributeScope.INLINE, val);
}

class LinkAttributeM extends AttributeM<String?> {
  LinkAttributeM(String? val) : super('link', AttributeScope.INLINE, val);
}

class ColorAttributeM extends AttributeM<String?> {
  ColorAttributeM(String? val) : super('color', AttributeScope.INLINE, val);
}

class BackgroundAttributeM extends AttributeM<String?> {
  BackgroundAttributeM(String? val)
      : super('background', AttributeScope.INLINE, val);
}

// This is custom attribute for hint
class PlaceholderAttributeM extends AttributeM<bool> {
  PlaceholderAttributeM() : super('placeholder', AttributeScope.INLINE, true);
}

class HeaderAttributeM extends AttributeM<int?> {
  HeaderAttributeM({int? level}) : super('header', AttributeScope.BLOCK, level);
}

class IndentAttributeM extends AttributeM<int?> {
  IndentAttributeM({int? level}) : super('indent', AttributeScope.BLOCK, level);
}

class AlignAttributeM extends AttributeM<String?> {
  AlignAttributeM(String? val) : super('align', AttributeScope.BLOCK, val);
}

class ListAttributeM extends AttributeM<String?> {
  ListAttributeM(String? val) : super('list', AttributeScope.BLOCK, val);
}

class CodeBlockAttributeM extends AttributeM<bool> {
  CodeBlockAttributeM() : super('code-block', AttributeScope.BLOCK, true);
}

class BlockQuoteAttributeM extends AttributeM<bool> {
  BlockQuoteAttributeM() : super('blockquote', AttributeScope.BLOCK, true);
}

class DirectionAttributeM extends AttributeM<String?> {
  DirectionAttributeM(String? val)
      : super('direction', AttributeScope.BLOCK, val);
}

class WidthAttributeM extends AttributeM<String?> {
  WidthAttributeM(String? val) : super('width', AttributeScope.IGNORE, val);
}

class HeightAttributeM extends AttributeM<String?> {
  HeightAttributeM(String? val) : super('height', AttributeScope.IGNORE, val);
}

class StyleAttributeM extends AttributeM<String?> {
  StyleAttributeM(String? val) : super('style', AttributeScope.IGNORE, val);
}

class TokenAttributeM extends AttributeM<String> {
  TokenAttributeM(String val) : super('token', AttributeScope.IGNORE, val);
}

// `script` is supposed to be inline attribute but it is not supported yet
class ScriptAttributeM extends AttributeM<String> {
  ScriptAttributeM(String val) : super('script', AttributeScope.IGNORE, val);
}
