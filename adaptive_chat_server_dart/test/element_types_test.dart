import 'dart:convert';
import 'dart:io';

import 'package:adaptive_chat_server_dart/src/element_types.dart';
import 'package:test/test.dart';

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
    test('reads the ChildElement enum', () {
      expect(loadKnownElementTypes(schemaPath), {
        'TextBlock',
        'Badge',
        'ColumnSet',
        'Column',
        'Carousel',
      });
    });

    test('returns an empty set when the file is missing', () {
      expect(loadKnownElementTypes('${tempDir.path}/nope.json'), isEmpty);
    });

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
