import 'dart:collection';

import 'package:quiver/core.dart';

import 'attribute-scope.enum.dart';
import 'styling-attributes.dart';

class AttributeM<T> {
  AttributeM(
    this.key,
    this.scope,
    this.value,
  );

  /// Unique key of this attribute.
  final String key;
  final AttributeScope scope;
  final T value;

  static final Map<String, AttributeM> _registry = LinkedHashMap.of({
    AttributeM.bold.key: AttributeM.bold,
    AttributeM.italic.key: AttributeM.italic,
    AttributeM.small.key: AttributeM.small,
    AttributeM.underline.key: AttributeM.underline,
    AttributeM.strikeThrough.key: AttributeM.strikeThrough,
    AttributeM.inlineCode.key: AttributeM.inlineCode,
    AttributeM.font.key: AttributeM.font,
    AttributeM.size.key: AttributeM.size,
    AttributeM.link.key: AttributeM.link,
    AttributeM.color.key: AttributeM.color,
    AttributeM.background.key: AttributeM.background,
    AttributeM.placeholder.key: AttributeM.placeholder,
    AttributeM.header.key: AttributeM.header,
    AttributeM.align.key: AttributeM.align,
    AttributeM.direction.key: AttributeM.direction,
    AttributeM.list.key: AttributeM.list,
    AttributeM.codeBlock.key: AttributeM.codeBlock,
    AttributeM.blockQuote.key: AttributeM.blockQuote,
    AttributeM.indent.key: AttributeM.indent,
    AttributeM.width.key: AttributeM.width,
    AttributeM.height.key: AttributeM.height,
    AttributeM.style.key: AttributeM.style,
    AttributeM.token.key: AttributeM.token,
    AttributeM.script.key: AttributeM.script,
  });

  static final BoldAttributeM bold = BoldAttributeM();

  static final ItalicAttributeM italic = ItalicAttributeM();

  static final SmallAttributeM small = SmallAttributeM();

  static final UnderlineAttributeM underline = UnderlineAttributeM();

  static final StrikeThroughAttributeM strikeThrough = StrikeThroughAttributeM();

  static final InlineCodeAttributeM inlineCode = InlineCodeAttributeM();

  static final FontAttributeM font = FontAttributeM(null);

  static final SizeAttributeM size = SizeAttributeM(null);

  static final LinkAttributeM link = LinkAttributeM(null);

  static final ColorAttributeM color = ColorAttributeM(null);

  static final BackgroundAttributeM background = BackgroundAttributeM(null);

  static final PlaceholderAttributeM placeholder = PlaceholderAttributeM();

  static final HeaderAttributeM header = HeaderAttributeM();

  static final IndentAttributeM indent = IndentAttributeM();

  static final AlignAttributeM align = AlignAttributeM(null);

  static final ListAttributeM list = ListAttributeM(null);

  static final CodeBlockAttributeM codeBlock = CodeBlockAttributeM();

  static final BlockQuoteAttributeM blockQuote = BlockQuoteAttributeM();

  static final DirectionAttributeM direction = DirectionAttributeM(null);

  static final WidthAttributeM width = WidthAttributeM(null);

  static final HeightAttributeM height = HeightAttributeM(null);

  static final StyleAttributeM style = StyleAttributeM(null);

  static final TokenAttributeM token = TokenAttributeM('');

  static final ScriptAttributeM script = ScriptAttributeM('');

  static const String mobileWidth = 'mobileWidth';

  static const String mobileHeight = 'mobileHeight';

  static const String mobileMargin = 'mobileMargin';

  static const String mobileAlignment = 'mobileAlignment';

  static final Set<String> inlineKeys = {
    AttributeM.bold.key,
    AttributeM.italic.key,
    AttributeM.small.key,
    AttributeM.underline.key,
    AttributeM.strikeThrough.key,
    AttributeM.link.key,
    AttributeM.color.key,
    AttributeM.background.key,
    AttributeM.placeholder.key,
  };

  static final Set<String> blockKeys = LinkedHashSet.of({
    AttributeM.header.key,
    AttributeM.align.key,
    AttributeM.list.key,
    AttributeM.codeBlock.key,
    AttributeM.blockQuote.key,
    AttributeM.indent.key,
    AttributeM.direction.key,
  });

  static final Set<String> blockKeysExceptHeader = LinkedHashSet.of({
    AttributeM.list.key,
    AttributeM.align.key,
    AttributeM.codeBlock.key,
    AttributeM.blockQuote.key,
    AttributeM.indent.key,
    AttributeM.direction.key,
  });

  static final Set<String> exclusiveBlockKeys = LinkedHashSet.of({
    AttributeM.header.key,
    AttributeM.list.key,
    AttributeM.codeBlock.key,
    AttributeM.blockQuote.key,
  });

  static AttributeM<int?> get h1 => HeaderAttributeM(level: 1);

  static AttributeM<int?> get h2 => HeaderAttributeM(level: 2);

  static AttributeM<int?> get h3 => HeaderAttributeM(level: 3);

  // "attributes":{"align":"left"}
  static AttributeM<String?> get leftAlignment => AlignAttributeM('left');

  // "attributes":{"align":"center"}
  static AttributeM<String?> get centerAlignment => AlignAttributeM('center');

  // "attributes":{"align":"right"}
  static AttributeM<String?> get rightAlignment => AlignAttributeM('right');

  // "attributes":{"align":"justify"}
  static AttributeM<String?> get justifyAlignment => AlignAttributeM('justify');

  // "attributes":{"list":"bullet"}
  static AttributeM<String?> get ul => ListAttributeM('bullet');

  // "attributes":{"list":"ordered"}
  static AttributeM<String?> get ol => ListAttributeM('ordered');

  // "attributes":{"list":"checked"}
  static AttributeM<String?> get checked => ListAttributeM('checked');

  // "attributes":{"list":"unchecked"}
  static AttributeM<String?> get unchecked => ListAttributeM('unchecked');

  // "attributes":{"direction":"rtl"}
  static AttributeM<String?> get rtl => DirectionAttributeM('rtl');

  // "attributes":{"indent":1"}
  static AttributeM<int?> get indentL1 => IndentAttributeM(level: 1);

  // "attributes":{"indent":2"}
  static AttributeM<int?> get indentL2 => IndentAttributeM(level: 2);

  // "attributes":{"indent":3"}
  static AttributeM<int?> get indentL3 => IndentAttributeM(level: 3);

  static AttributeM<int?> getIndentLevel(int? level) {
    if (level == 1) {
      return indentL1;
    }

    if (level == 2) {
      return indentL2;
    }

    if (level == 3) {
      return indentL3;
    }

    return IndentAttributeM(level: level);
  }

  bool get isInline => scope == AttributeScope.INLINE;

  bool get isBlockExceptHeader => blockKeysExceptHeader.contains(key);

  Map<String, dynamic> toJson() => <String, dynamic>{key: value};

  static AttributeM? fromKeyValue(String key, dynamic value) {
    final origin = _registry[key];

    if (origin == null) {
      return null;
    }

    final attribute = clone(origin, value);

    return attribute;
  }

  static int getRegistryOrder(AttributeM attribute) {
    var order = 0;

    for (final attr in _registry.values) {
      if (attr.key == attribute.key) {
        break;
      }

      order++;
    }

    return order;
  }

  static AttributeM clone(AttributeM origin, dynamic value) {
    return AttributeM(origin.key, origin.scope, value);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! AttributeM) return false;
    final typedOther = other;
    return key == typedOther.key &&
        scope == typedOther.scope &&
        value == typedOther.value;
  }

  @override
  int get hashCode => hash3(key, scope, value);

  @override
  String toString() {
    return 'Attribute{key: $key, scope: $scope, value: $value}';
  }
}