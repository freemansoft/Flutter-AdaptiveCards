import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

// Relative: shape_cases lives outside lib/, so there is no package: URI.
import '../tool/model_probes/shape_cases.dart';

// shape_cases.dart's `shapeCases` list is the coverage table shape_ab.dart
// measures against, and its correctness cannot be checked by running it —
// a wrong `accepted` set or a stale case just quietly measures the wrong
// thing and reports a plausible-looking pass rate. Most of this file is
// therefore not a unit test of application behavior but a consistency
// checker cross-referencing the case table against two other committed
// artifacts it must never drift from: `assets/card_schema.json` (what the
// server will actually render) and `assets/card_system_prompt.txt` (what the
// model is told it may produce). The last group checks the case table
// against another probe's hardcoded prompts instead, for the same reason.

/// The element types `--json-format schema` will actually accept, read from
/// the shipped schema so this test tracks the schema rather than a copy.
Set<String> schemaElementTypes() {
  final schema =
      jsonDecode(File('assets/card_schema.json').readAsStringSync())
          as Map<String, dynamic>;
  final defs = schema[r'$defs'] as Map<String, dynamic>;
  final element = defs['Element'] as Map<String, dynamic>;
  final properties = element['properties'] as Map<String, dynamic>;
  final typeSchema = properties['type'] as Map<String, dynamic>;
  return (typeSchema['enum'] as List).cast<String>().toSet();
}

/// Element types the card system prompt actually advertises to the model.
///
/// Shape coverage is about what the model is *asked* to produce, which is a
/// different question from what the client can render — `schemaElementTypes()`
/// answers the second. The two were one set until the schema was widened to
/// mirror the element registry; a type the prompt never advertises can never
/// appear in a reply, so a shape case targeting one would fail on every model
/// forever.
///
/// Reading only `"type":"X"` examples is not enough: several palette entries
/// are advertised in prose alone. `Input.Text`, `Input.Number`, and
/// `Input.Time` share one bullet with no example between them, and
/// `Chart.Donut` and `Chart.HorizontalBar` are named beside a sibling's
/// example. A type the model is told about counts whether or not it got its
/// own example, so bullet headings are read too.
Set<String> promptElementTypes() {
  final prompt = File('assets/card_system_prompt.txt').readAsStringSync();
  final types = <String>{
    ...RegExp(
      '"type":"([A-Za-z.]+)"',
    ).allMatches(prompt).map((m) => m.group(1)!),
  };
  // Palette bullets name their types before an em dash, and one bullet may
  // list several separated by commas or "and".
  for (final bullet in RegExp(
    r'^\s*- ([^\n—]+)—',
    multiLine: true,
  ).allMatches(prompt)) {
    for (final token in bullet.group(1)!.split(RegExp(',| and '))) {
      final candidate = token.trim();
      if (RegExp(r'^[A-Z][A-Za-z]*(\.[A-Za-z]+)*$').hasMatch(candidate)) {
        types.add(candidate);
      }
    }
  }
  return types..removeAll({
    // Structural children and the card wrapper appear in examples but are
    // not standalone palette entries a shape case could target.
    'AdaptiveCard',
    'CarouselPage',
    'TableRow',
    'TableCell',
    'Column',
    // `- Charts —` introduces the chart family; it is a heading, not a
    // type, and no element may be spelled `Charts`.
    'Charts',
  });
}

void main() {
  group('the shape case table', () {
    test('has 25 cases', () {
      // Pins the count check_results_test.dart and ModelBehavior.md's shape
      // table both hardcode as the denominator ('n/25'). Adding or removing
      // a case without updating this changes what every published score
      // means without changing how it is read.
      expect(shapeCases, hasLength(25));
    });

    test('every accepted type is one the schema allows', () {
      final allowed = schemaElementTypes();
      final bad = <String>{};
      for (final c in shapeCases) {
        bad.addAll(c.accepted.difference(allowed));
      }
      expect(
        bad,
        isEmpty,
        reason:
            "These accepted types are not in card_schema.json's enum, so the "
            'probe would be asserting a shape the server itself rejects — a '
            'typo here silently fails every model: $bad',
      );
    });

    test('case ids are unique', () {
      // caseId is how a result row is tied back to a case and how `--only`
      // selects one — a duplicate would make two different prompts share one
      // slot in the per-case score, silently dropping coverage rather than
      // failing loudly.
      final ids = shapeCases.map((c) => c.id).toList();
      expect(ids.toSet(), hasLength(ids.length));
    });

    test('no case has an empty id or prompt', () {
      for (final c in shapeCases) {
        expect(c.id, isNotEmpty);
        expect(c.prompt.trim(), isNotEmpty, reason: 'case ${c.id}');
      }
    });

    test('requiresInput is only set where every accepted type is an input', () {
      for (final c in shapeCases.where((c) => c.requiresInput)) {
        expect(
          c.accepted.every((t) => t.startsWith('Input.')),
          isTrue,
          reason:
              'case ${c.id} demands an input but accepts a non-input type '
              '(${c.accepted}) — it cannot sensibly require both',
        );
        expect(c.accepted, isNotEmpty, reason: 'case ${c.id}');
      }
    });

    test('exactly one case is the prose negative control', () {
      // An empty `accepted` set means "a card here is the failure" — the one
      // case checking the model doesn't reach for a card when plain text
      // would do. A second one would silently double-weight that check
      // against the 24 cases proving the opposite; zero would mean nothing
      // in the table catches card-happy over-generation at all.
      final controls = shapeCases.where((c) => c.accepted.isEmpty).toList();
      expect(controls, hasLength(1));
      expect(controls.single.id, 'prose');
      expect(controls.single.requiresInput, isFalse);
    });

    test(
      'accepted types cover exactly the prompt palette minus TextBlock, '
      'Icon, and Image',
      () {
        // Pinned against the prompt palette, not the schema enum. Those were
        // the same set until the schema was widened to mirror the element
        // registry, which split them: the enum now records what the client
        // can render, a superset the model is never told about and could not
        // emit if it tried. If the prompt gains a type, this fails rather
        // than letting the coverage claim (here, in the README, and in the
        // spec) go stale by leaving it unprobed.
        final allowed = promptElementTypes();
        final documentedExclusions = {'TextBlock', 'Icon', 'Image'};
        final expectedCoverage = allowed.difference(documentedExclusions);
        final actualCoverage = shapeCases.expand((c) => c.accepted).toSet();
        expect(
          actualCoverage,
          equals(expectedCoverage),
          reason:
              'shapeCases should cover every element type the card system '
              'prompt advertises except the documented exclusions '
              '(TextBlock, Icon, Image). If this fails because the prompt '
              'gained a type, either add a case that exercises it or add it '
              'to the documented exclusions here, in the doc comment above '
              'shapeCases, and in README.md / the spec.',
        );
      },
    );

    test('the six choice cases match choiceset_ab.dart verbatim', () {
      // Copied from choiceset_ab.dart's _prompts. If that list changes, the
      // two probes stop being comparable and this test should fail loudly.
      const expected = [
        'what are my options for deployment targets',
        'which log level should I use?',
        'what environments can I deploy to?',
        'what are my options for notification frequency',
        'help me pick a database engine',
        'what build modes can I choose from?',
      ];
      final choicePrompts = shapeCases
          .where((c) => c.id.startsWith('choice'))
          .map((c) => c.prompt)
          .toList();
      expect(choicePrompts, equals(expected));
    });
  });
}
