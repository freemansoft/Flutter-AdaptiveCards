import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

// Relative: shape_cases lives outside lib/, so there is no package: URI.
import '../tool/model_probes/shape_cases.dart';

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

void main() {
  group('the shape case table', () {
    test('has 25 cases', () {
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
      final controls = shapeCases.where((c) => c.accepted.isEmpty).toList();
      expect(controls, hasLength(1));
      expect(controls.single.id, 'prose');
      expect(controls.single.requiresInput, isFalse);
    });

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
