import 'package:flutter/material.dart';

import '../../../document/models/attributes/attribute.model.dart';
import '../../../document/models/attributes/attributes.model.dart';
import '../../const/arabian-roman-numbers.const.dart';
import '../../const/roman-numbers.const.dart';

// Displays the index of a line inside a block of ordered list or code block.
// It holds the logic for converting the index from integer to alpha or roman and vice-versa.
class NumberPoint extends StatelessWidget {
  final Map<int?, int> indentLevelCounts;
  final TextStyle textStyle;
  final double containerWidth;
  final Map<String, AttributeM> attrs;
  final bool hasDotAfterNumber;
  final double endPadding;
  final int blockLength;

  const NumberPoint({
    required this.indentLevelCounts,
    required this.textStyle,
    required this.containerWidth,
    required this.attrs,
    required this.blockLength,
    this.hasDotAfterNumber = true,
    this.endPadding = 0.0,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final olString = _getOlString();

    return Container(
      alignment: AlignmentDirectional.topEnd,
      width: containerWidth,
      padding: EdgeInsetsDirectional.only(end: endPadding),
      child: Text('$olString${hasDotAfterNumber ? '.' : ''}', style: textStyle),
    );
  }

  String _getOlString() {
    // Stores the indentation level of the current line.
    final int indentLevel = attrs[AttributesM.indent.key]?.value ?? 0;

    // First the indentLevelCounts is going to be empty.
    // This is for other levels of indentation, so they don't connect with the other indented.
    if (indentLevelCounts.containsKey(indentLevel + 1)) {
      // last visited level is done, going up
      indentLevelCounts.remove(indentLevel + 1);
    }

    final count = (indentLevelCounts[indentLevel] ?? 0) + 1;
    indentLevelCounts[indentLevel] = count;

    final numberingMode = indentLevel % 3;
    if (numberingMode == 1) {
      // a. b. c.
      return _intToAlpha(count);
    } else if (numberingMode == 2) {
      // i. ii. iii.
      return _intToRoman(count);
    }

    return count.toString();
  }

  String _intToAlpha(int n) {
    final result = StringBuffer();
    while (n > 0) {
      n--;
      result.write(String.fromCharCode((n % 26).floor() + 97));
      n = (n / 26).floor();
    }

    return result.toString().split('').reversed.join();
  }

  String _intToRoman(int input) {
    var num = input;

    if (num < 0) {
      return '';
    } else if (num == 0) {
      return 'null';
    }

    final builder = StringBuffer();
    for (var a = 0; a < arabianRomanNumbers.length; a++) {
      // Equals 1 only when arabianRomanNumbers[a] = num
      final times = (num / arabianRomanNumbers[a]).truncate();
      // executes n times where n is the number of times you have to add
      // the current roman number value to reach current num.
      builder.write(romanNumbers[a] * times);
      // Subtract previous roman number value from num
      num -= times * arabianRomanNumbers[a];
    }

    return builder.toString().toLowerCase();
  }
}