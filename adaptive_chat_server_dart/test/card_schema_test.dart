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
  return RegExp(
    r'Chart\.[A-Za-z]+(?:\.[A-Za-z]+)*',
  ).allMatches(text).map((m) => m.group(0)!).toSet();
}

/// The `type` enum the `--json-format schema` grammar constrains replies to.
Set<String> _schemaElementTypes() {
  final schema =
      jsonDecode(File('assets/card_schema.json').readAsStringSync())
          as Map<String, dynamic>;
  final element =
      (schema[r'$defs'] as Map<String, dynamic>)['Element']
          as Map<String, dynamic>;
  final type =
      (element['properties'] as Map<String, dynamic>)['type']
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

  group('card prompt, schema, and README palette agree', () {
    // Plain relative paths, matching the existing groups in this file — tests
    // run from the package root, and `package:path` is not imported here.
    final prompt = File('assets/card_system_prompt.txt').readAsStringSync();
    final schema =
        jsonDecode(File('assets/card_schema.json').readAsStringSync())
            as Map<String, dynamic>;
    final readme = File('README.md').readAsStringSync();

    // Types the prompt actually advertises: the bullet headings plus every
    // "type":"X" in its examples. Chart.* are covered by the chart group.
    Set<String> promptTypes() {
      // A bullet heading alone is not proof of an element type — the prompt
      // uses headings like "- Charts —" to introduce a family. Require a
      // matching "type":"X" example, which every real palette entry has and
      // no section heading does.
      final exampled = RegExp(
        '"type":"([A-Za-z.]+)"',
      ).allMatches(prompt).map((m) => m.group(1)!).toSet();
      final headings = RegExp(
        '^- ([A-Z][A-Za-z.]+) —',
        multiLine: true,
      ).allMatches(prompt).map((m) => m.group(1)!).toSet();
      // Structural children and the card wrapper appear in examples but are
      // not standalone palette entries a user would look up.
      return (headings.intersection(exampled)..addAll(exampled))..removeWhere(
        (t) =>
            t.startsWith('Chart.') ||
            const {
              'AdaptiveCard',
              'CarouselPage',
              'TableRow',
              'TableCell',
              'Column',
            }.contains(t),
      );
    }

    test('every type the prompt advertises is allowed by the schema enum', () {
      final defs = schema[r'$defs'] as Map<String, dynamic>;
      final element = defs['Element'] as Map<String, dynamic>;
      final properties = element['properties'] as Map<String, dynamic>;
      final typeSchema = properties['type'] as Map<String, dynamic>;
      final allowed = (typeSchema['enum'] as List).cast<String>().toSet();
      final missing = promptTypes().difference(allowed);
      expect(
        missing,
        isEmpty,
        reason:
            'These types are advertised in card_system_prompt.txt but absent '
            'from card_schema.json, so --json-format schema would reject '
            'exactly what the prompt asks the model to produce: $missing',
      );
    });

    test(
      'every type the prompt advertises is listed in the README palette',
      () {
        final missing = promptTypes()
            .where((t) => !readme.contains('`$t`'))
            .toSet();
        expect(
          missing,
          isEmpty,
          reason:
              'These types are advertised in card_system_prompt.txt but '
              'missing from the README palette list, so the documented '
              'palette is stale: $missing',
        );
      },
    );
  });
}
