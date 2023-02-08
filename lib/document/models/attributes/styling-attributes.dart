import '../../../markers/models/marker.model.dart';
import 'attribute-scope.enum.dart';
import 'attribute.model.dart';

// Using the AttributeM model class we are predefining the rich text attributes to be used in the editor.
// Additional attributes need to be defined here when implementing new text features.

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
  FontAttributeM(String? value) : super('font', AttributeScope.INLINE, value);
}

class SizeAttributeM extends AttributeM<String?> {
  SizeAttributeM(String? value) : super('size', AttributeScope.INLINE, value);
}

class LinkAttributeM extends AttributeM<String?> {
  LinkAttributeM(String? value) : super('link', AttributeScope.INLINE, value);
}

class ColorAttributeM extends AttributeM<String?> {
  ColorAttributeM(String? value) : super('color', AttributeScope.INLINE, value);
}

class BackgroundAttributeM extends AttributeM<String?> {
  BackgroundAttributeM(String? value)
      : super('background', AttributeScope.INLINE, value);
}

// Displays the placeholder text when no content is available.
class PlaceholderAttributeM extends AttributeM<bool> {
  PlaceholderAttributeM() : super('placeholder', AttributeScope.INLINE, true);
}

// On one attribute we can have multiple markers each one with a different id.
// Multiple markers of the same type can be used per attribute.
class MarkersAttributeM extends AttributeM<List<MarkerM>?> {
  MarkersAttributeM(List<MarkerM>? markers)
      : super('markers', AttributeScope.INLINE, markers);
}

class HeaderAttributeM extends AttributeM<int?> {
  HeaderAttributeM({int? level}) : super('header', AttributeScope.BLOCK, level);
}

class IndentAttributeM extends AttributeM<int?> {
  IndentAttributeM({int? level}) : super('indent', AttributeScope.BLOCK, level);
}

class AlignAttributeM extends AttributeM<String?> {
  AlignAttributeM(String? value) : super('align', AttributeScope.BLOCK, value);
}

class ListAttributeM extends AttributeM<String?> {
  ListAttributeM(String? value) : super('list', AttributeScope.BLOCK, value);
}

class CodeBlockAttributeM extends AttributeM<bool> {
  CodeBlockAttributeM() : super('code-block', AttributeScope.BLOCK, true);
}

class BlockQuoteAttributeM extends AttributeM<bool> {
  BlockQuoteAttributeM() : super('blockquote', AttributeScope.BLOCK, true);
}

class DirectionAttributeM extends AttributeM<String?> {
  DirectionAttributeM(String? value)
      : super('direction', AttributeScope.BLOCK, value);
}

class WidthAttributeM extends AttributeM<String?> {
  WidthAttributeM(String? value) : super('width', AttributeScope.IGNORE, value);
}

class HeightAttributeM extends AttributeM<String?> {
  HeightAttributeM(String? value)
      : super('height', AttributeScope.IGNORE, value);
}

class StyleAttributeM extends AttributeM<String?> {
  StyleAttributeM(String? value) : super('style', AttributeScope.IGNORE, value);
}

class TokenAttributeM extends AttributeM<String> {
  TokenAttributeM(String value) : super('token', AttributeScope.IGNORE, value);
}

// `script` is supposed to be inline attribute but it is not supported yet (subscript, superscript)
class ScriptAttributeM extends AttributeM<String> {
  ScriptAttributeM(String value)
      : super('script', AttributeScope.IGNORE, value);
}
