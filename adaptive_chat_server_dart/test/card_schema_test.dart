import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

// Not an ordinary behavioral unit test: nothing here calls library code. It
// cross-checks four independent sources of truth against each other by
// scraping them as text/JSON —
//   - assets/card_schema.json: the `type` enum `--json-format schema` uses to
//     grammar-constrain a model's reply,
//   - assets/card_system_prompt.txt: the palette the prompt tells the model
//     it may use (in prose and in its worked examples),
//   - packages/flutter_adaptive_cards_fs/lib/src/registry.dart and
//     .../flutter_adaptive_charts_fs/lib/src/card_chart_registry.dart: the
//     switch statements that decide what the renderer can actually draw, and
//   - README.md: the documented palette list.
// These four are edited independently and by hand, so they drift silently:
// a type added to a registry switch but never added to the schema enum makes
// `--json-format schema` grammar-forbid exactly what the renderer supports;
// a type removed from a registry switch but left in the schema enum lets the
// grammar advertise a type the renderer can no longer draw; a type added to
// the prompt's examples but missing from the schema enum makes the grammar
// reject the very shape the prompt just told the model to produce. None of
// that is a runtime bug this suite would catch by exercising code — it is a
// four-way consistency check between committed files, run here because nothing
// else in the build enforces it.
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

/// Element types the core library can render, read from the registry source
/// rather than from a copy kept here, so this test fails when the registry
/// gains or loses a case.
Set<String> _coreRegistryElementTypes() {
  final source = File(
    '../packages/flutter_adaptive_cards_fs/lib/src/registry.dart',
  ).readAsStringSync();
  // Not a raw string: the pattern has no backslashes, and `r"…"` here trips
  // very_good_analysis's unnecessary_raw_strings. Double quotes are correct
  // under prefer_single_quotes because the pattern contains single quotes.
  return RegExp("case '([A-Za-z][A-Za-z.]*)':")
      .allMatches(source)
      .map((m) => m.group(1)!)
      // The same switch carries action types; only elements belong here.
      .where((t) => !t.startsWith('Action.'))
      .toSet();
}

/// `Chart.*` types, which live in the optional charts package and are
/// renderable only when a host registered it.
///
/// The trailing-segment group is load-bearing: a bare `Chart\.[A-Za-z]+`
/// truncates `Chart.HorizontalBar.Stacked` to `Chart.HorizontalBar` and
/// dedupes it away, silently reporting 6 types where the registry declares 8.
Set<String> _chartRegistryElementTypes() {
  final source = File(
    '../packages/flutter_adaptive_charts_fs/lib/src/card_chart_registry.dart',
  ).readAsStringSync();
  return RegExp(
    r'Chart\.[A-Za-z]+(?:\.[A-Za-z]+)*',
  ).allMatches(source).map((m) => m.group(0)!).toSet();
}

/// The `type` enum covering every position, including nesting-only children.
Set<String> _schemaChildElementTypes() {
  final schema =
      jsonDecode(File('assets/card_schema.json').readAsStringSync())
          as Map<String, dynamic>;
  final child =
      (schema[r'$defs'] as Map<String, dynamic>)['ChildElement']
          as Map<String, dynamic>;
  final type =
      (child['properties'] as Map<String, dynamic>)['type']
          as Map<String, dynamic>;
  return (type['enum'] as List).cast<String>().toSet();
}

/// Types the prompt's examples nest inside a parent but which no registry
/// switch declares, because their parent widget builds them directly.
const _structuralChildTypes = {'Column', 'TableRow', 'TableCell'};

/// Registered types that are never a top-level body item.
///
/// `CarouselPage` and `TabPage` are legal only inside their parent's array.
/// `AdaptiveCard` is the wrapper and has its own `$defs/CardObject`; putting
/// it in `Element` would additionally make a bare card a legal body item and
/// let it match the wrong `oneOf` branch.
const _notTopLevel = {'AdaptiveCard', 'CarouselPage', 'TabPage'};

/// Renderable types the schema declines on purpose.
///
/// Grouped and stacked charts need a nested `{legend, values:[{x,y}]}` shape.
/// The card system prompt says outright that there is no grouped or stacked
/// chart, and the `does not allow multi-series chart types` test below asserts
/// the schema rejects them. Listed here so a registry-vs-schema diff shows a
/// decision rather than a gap.
const _deliberatelyExcluded = {
  'Chart.VerticalBar.Grouped',
  'Chart.HorizontalBar.Stacked',
};

Set<String> _renderableTopLevelTypes() => _coreRegistryElementTypes()
  ..addAll(_chartRegistryElementTypes())
  ..removeAll(_notTopLevel)
  ..removeAll(_deliberatelyExcluded);

void main() {
  group('the schema mirrors the renderable registry', () {
    test('the core registry contributes 30 element types', () {
      // Guards the regex itself: a change to registry.dart's switch style
      // would otherwise silently yield an empty set and pass everything.
      expect(_coreRegistryElementTypes(), hasLength(30));
    });

    test('the charts package declares 8 chart types', () {
      // 8, not 6: the two multi-series types are renderable and are excluded
      // from the schema by decision, not by absence.
      expect(_chartRegistryElementTypes(), hasLength(8));
      expect(_chartRegistryElementTypes(), containsAll(_deliberatelyExcluded));
    });

    // Equality, not just containment: a schema that allows a type the
    // registry cannot render is exactly as broken as one that forbids a
    // type the registry can draw — either way the two sources have drifted.
    test('the Element enum is exactly the renderable top-level set', () {
      expect(_schemaElementTypes(), _renderableTopLevelTypes());
    });
  });

  group('card prompt and card schema agree on chart types', () {
    // Freezes the palette the prompt currently teaches models about, so a
    // Chart.* mention added to the prompt is caught here directly rather
    // than only surfacing indirectly through the containsAll check below.
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

    // The failure this guards: the prompt tells the model to use a type the
    // JSON-schema grammar then forbids, so `--json-format schema` rejects
    // exactly the shape the prompt just told the model to produce.
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

    // The README palette is prose, not something the compiler enforces —
    // without this check it goes stale the moment a type is added to the
    // prompt without a matching edit to the doc.
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

  group('ChildElement covers every legal nested position', () {
    // ChildElement's enum must be derived from the top-level set, not
    // maintained as its own independent list — this pins the derivation, so
    // an edit that pastes a fresh list into the schema instead of extending
    // Element's is caught even when the two happen to agree on size.
    test('it is the top-level set plus child-only and structural types', () {
      expect(
        _schemaChildElementTypes(),
        _renderableTopLevelTypes()
          ..addAll({'CarouselPage', 'TabPage'})
          ..addAll(_structuralChildTypes),
      );
    });

    // A superset that happened to be equal in size would mean every
    // child-only type quietly vanished; the length check catches that in a
    // way containsAll alone would not.
    test('it is a strict superset of Element', () {
      expect(_schemaChildElementTypes(), containsAll(_schemaElementTypes()));
      expect(
        _schemaChildElementTypes().length,
        greaterThan(_schemaElementTypes().length),
      );
    });

    test('it excludes the AdaptiveCard wrapper', () {
      // A nested card belongs to Action.ShowCard, which this palette does not
      // offer; CardObject remains the only place the wrapper is legal.
      expect(_schemaChildElementTypes(), isNot(contains('AdaptiveCard')));
    });
  });
}
