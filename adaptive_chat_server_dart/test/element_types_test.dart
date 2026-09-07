import 'dart:convert';
import 'dart:io';

import 'package:adaptive_chat_server_dart/src/element_types.dart';
import 'package:test/test.dart';

// Unit tests for element_types.dart: the schema-driven vocabulary loader
// (loadKnownElementTypes) and the walker that flags a reply's `type` values
// straying outside it (unknownElementTypes). What this guards: an invented or
// misspelled element `type` is still valid JSON, so it passes card detection
// and then silently renders as an empty blank — the one failure mode no
// probe can score, because every probe judges a reply by whether it parses.
// Ordinary behavioral tests, but note the boundary: every schema here is a
// synthetic file written to a temp dir for the duration of one test, so
// these exercise the parsing/fallback logic in isolation — nothing here
// reads or validates the real bundled assets/card_schema.json.
void main() {
  late Directory tempDir;
  late String schemaPath;

  /// Writes a schema whose ChildElement enum is exactly [types].
  void writeSchema(List<String> types) {
    File(schemaPath).writeAsStringSync(
      jsonEncode({
        r'$defs': {
          'ChildElement': {
            'type': 'object',
            'properties': {
              'type': {'type': 'string', 'enum': types},
            },
          },
        },
      }),
    );
  }

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('element_types_test');
    schemaPath = '${tempDir.path}/card_schema.json';
    writeSchema(['TextBlock', 'Badge', 'ColumnSet', 'Column', 'Carousel']);
  });

  tearDown(() => tempDir.deleteSync(recursive: true));

  group('loadKnownElementTypes', () {
    // Happy path: the walker below trusts this result is the *complete*
    // vocabulary, so a loader that silently dropped or truncated entries
    // would turn every one of them into a false "unknown type" warning.
    test('reads the ChildElement enum', () {
      expect(loadKnownElementTypes(schemaPath), {
        'TextBlock',
        'Badge',
        'ColumnSet',
        'Column',
        'Carousel',
      });
    });

    // A schema path is process config that can simply be wrong (typo, moved
    // asset); this must degrade the check, not crash server startup.
    test('returns an empty set when the file is missing', () {
      expect(loadKnownElementTypes('${tempDir.path}/nope.json'), isEmpty);
    });

    // Same degrade-gracefully contract as a missing file, but reached
    // through the decode path instead — a hand-edited or truncated schema on
    // disk is still readable as bytes, just not as JSON.
    test('returns an empty set when the JSON is malformed', () {
      File(schemaPath).writeAsStringSync('{not json');
      expect(loadKnownElementTypes(schemaPath), isEmpty);
    });

    test('returns an empty set when ChildElement is absent', () {
      // Typed literal: a bare `{}` trips
      // inference_failure_on_collection_literal, which is a warning and
      // makes `dart analyze` exit non-zero.
      File(schemaPath).writeAsStringSync(
        jsonEncode({r'$defs': <String, dynamic>{}}),
      );
      expect(loadKnownElementTypes(schemaPath), isEmpty);
    });
  });

  // unknownElementTypes never touches a schema file itself — every case
  // below hand-builds its `known` set, so this group is really testing the
  // walk/tolerate logic on its own, independent of loadKnownElementTypes.
  group('unknownElementTypes', () {
    final known = {'TextBlock', 'Badge', 'ColumnSet', 'Column', 'Carousel'};

    test('a body of known types yields nothing', () {
      final body = [
        {'type': 'TextBlock', 'text': 'hi'},
        {'type': 'Badge', 'text': 'New'},
      ];
      expect(unknownElementTypes(body, known), isEmpty);
    });

    test('a misspelled top-level type is flagged', () {
      // The exact failure this exists for: valid JSON, renders as nothing.
      final body = [
        {'type': 'Textblock', 'text': 'hi'},
      ];
      expect(unknownElementTypes(body, known), {'Textblock'});
    });

    // Nesting is where this bites in practice: a bad type buried inside a
    // ColumnSet/Column renders as an invisible gap in the layout, not an
    // obviously broken card, so the walker has to recurse rather than only
    // scan the top-level body array.
    test('a misspelled type nested inside a container is flagged', () {
      final body = [
        {
          'type': 'ColumnSet',
          'columns': [
            {
              'type': 'Column',
              'items': [
                {'type': 'Input.RadioButtons', 'id': 'x'},
              ],
            },
          ],
        },
      ];
      expect(unknownElementTypes(body, known), {'Input.RadioButtons'});
    });

    // Guards against an early-return walker: the operator-facing warning
    // joins every hit into one message, so silently reporting only the
    // first would hide how much of a reply is actually broken.
    test('every unknown type is reported, not just the first', () {
      final body = [
        {'type': 'Textblock', 'text': 'hi'},
        {'type': 'BadgeX', 'text': 'New'},
      ];
      expect(unknownElementTypes(body, known), {'Textblock', 'BadgeX'});
    });

    test('an empty known set disables the check', () {
      // A failed schema load must not flag every element in every reply.
      final body = [
        {'type': 'Textblock', 'text': 'hi'},
      ];
      expect(unknownElementTypes(body, const <String>{}), isEmpty);
    });

    // False-positive guard: the walker keys off the `type` property
    // specifically, not any string value that happens to spell a type name
    // (e.g. inside author-written text).
    test('non-type string values are not mistaken for types', () {
      final body = [
        {'type': 'TextBlock', 'text': 'Textblock is misspelled', 'wrap': true},
      ];
      expect(unknownElementTypes(body, known), isEmpty);
    });

    test(
      'AdaptiveCard, TextRun, and Action.* are tolerated non-element '
      'positions, not unknown element types',
      () {
        // RichTextBlock and ActionSet are ordinary body elements, so they
        // belong in the known set. TextRun, Action.ShowCard, and AdaptiveCard
        // are legal `type` values in a fully renderable card, but in
        // positions ChildElement never lists: TextRun inside a
        // RichTextBlock's inlines, Action.ShowCard inside an actions array,
        // and AdaptiveCard nested inside that Action.ShowCard's `card`.
        final known2 = {...known, 'RichTextBlock', 'ActionSet'};
        final body = [
          {
            'type': 'RichTextBlock',
            'inlines': [
              {'type': 'TextRun', 'text': 'hi'},
            ],
          },
          {
            'type': 'ActionSet',
            'actions': [
              {
                'type': 'Action.ShowCard',
                'card': {
                  'type': 'AdaptiveCard',
                  'body': [
                    {'type': 'TextBlock', 'text': 'nested'},
                  ],
                },
              },
              {'type': 'Action.OpenUrl', 'url': 'https://example.com'},
              {'type': 'Action.ToggleVisibility', 'targetElements': <String>[]},
            ],
          },
        ];
        expect(unknownElementTypes(body, known2), isEmpty);
      },
    );

    test(
      'a genuine misspelling is still flagged alongside tolerated types',
      () {
        // The fix must not blanket-disable detection: a real typo sitting
        // next to legal non-element types must still be caught.
        final known2 = {...known, 'RichTextBlock', 'ActionSet'};
        final body = [
          {
            'type': 'RichTextBlock',
            'inlines': [
              {'type': 'TextRun', 'text': 'hi'},
            ],
          },
          {
            'type': 'ActionSet',
            'actions': [
              {'type': 'Action.OpenUrl', 'url': 'https://example.com'},
            ],
          },
          {'type': 'Textblock', 'text': 'oops'},
        ];
        expect(unknownElementTypes(body, known2), {'Textblock'});
      },
    );
  });
}
