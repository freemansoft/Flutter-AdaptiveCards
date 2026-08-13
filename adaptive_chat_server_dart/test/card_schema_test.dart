import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

/// Every `Chart.*` type named anywhere in the card system prompt, read from
/// the prompt itself so this test tracks the prompt rather than a hardcoded
/// copy.
///
/// Matches prose mentions as well as JSON examples: the prompt introduces
/// `Chart.Donut` and `Chart.HorizontalBar` in prose beside a sibling type's
/// example, and a type the model is told about is advertised whether or not
/// it got its own example. The trailing-segment group stops at a sentence
/// period, so `use Chart.Pie.` yields `Chart.Pie`.
Set<String> _chartTypesInPrompt() {
  final text = File('assets/card_system_prompt.txt').readAsStringSync();
  return RegExp(r'Chart\.[A-Za-z]+(?:\.[A-Za-z]+)*')
      .allMatches(text)
      .map((m) => m.group(0)!)
      .toSet();
}

/// The `type` enum the `--json-format schema` grammar constrains replies to.
Set<String> _schemaElementTypes() {
  final schema =
      jsonDecode(File('assets/card_schema.json').readAsStringSync())
          as Map<String, dynamic>;
  final element = (schema[r'$defs'] as Map<String, dynamic>)['Element']
      as Map<String, dynamic>;
  final type = (element['properties'] as Map<String, dynamic>)['type']
      as Map<String, dynamic>;
  return (type['enum'] as List).cast<String>().toSet();
}

void main() {
  group('card prompt and card schema agree on chart types', () {
    test('the prompt advertises the six flat-data chart types', () {
      expect(_chartTypesInPrompt(), {
        'Chart.Pie',
        'Chart.Donut',
        'Chart.VerticalBar',
        'Chart.HorizontalBar',
        'Chart.Line',
        'Chart.Gauge',
      });
    });

    test('every chart type in the prompt is allowed by the schema enum', () {
      // Without this, `--json-format schema` grammar-forbids exactly the
      // types the prompt just told the model to use.
      expect(_schemaElementTypes(), containsAll(_chartTypesInPrompt()));
    });

    test('the schema does not allow multi-series chart types', () {
      // Grouped/stacked need a nested {legend, values:[{x,y}]} shape and are
      // deliberately out of the advertised palette.
      expect(
        _schemaElementTypes(),
        isNot(contains('Chart.VerticalBar.Grouped')),
      );
      expect(
        _schemaElementTypes(),
        isNot(contains('Chart.HorizontalBar.Stacked')),
      );
    });
  });
}
