import 'dart:convert';

import 'package:test/test.dart';

// Relative: these live outside lib/, so there is no package: URI.
import '../tool/model_probes/tool_channel.dart';

void main() {
  group('toolCallArguments', () {
    test('reads arguments returned as a decoded map', () {
      final message = {
        'tool_calls': [
          {
            'function': {
              'name': 'render_adaptive_card',
              'arguments': {
                'body': [
                  {'type': 'TextBlock', 'text': 'hi'},
                ],
              },
            },
          },
        ],
      };
      expect(
        toolCallArguments(message, 'render_adaptive_card'),
        containsPair('body', isA<List<dynamic>>()),
      );
    });

    test('reads arguments returned as a JSON string', () {
      // Some Ollama builds return arguments as an unparsed string.
      final message = {
        'tool_calls': [
          {
            'function': {
              'name': 'render_adaptive_card',
              'arguments': '{"body":[{"type":"TextBlock","text":"hi"}]}',
            },
          },
        ],
      };
      expect(
        toolCallArguments(message, 'render_adaptive_card'),
        containsPair('body', isA<List<dynamic>>()),
      );
    });

    test('returns null when a different tool was called', () {
      final message = {
        'tool_calls': [
          {
            'function': {
              'name': 'get_current_temperature',
              'arguments': <String, dynamic>{},
            },
          },
        ],
      };
      expect(toolCallArguments(message, 'render_adaptive_card'), isNull);
    });

    test('returns null when there are no tool calls', () {
      expect(
        toolCallArguments(const {'content': 'hello'}, 'render_adaptive_card'),
        isNull,
      );
    });
  });

  group('replyEquivalent', () {
    test('a tool call becomes the JSON body a prose reply would carry', () {
      final message = {
        'tool_calls': [
          {
            'function': {
              'name': 'render_adaptive_card',
              'arguments': {
                'body': [
                  {'type': 'Input.Date', 'id': 'when'},
                ],
              },
            },
          },
        ],
      };
      final reply = replyEquivalent(message, 'render_adaptive_card');
      // Must be exactly what the prose channel would have emitted, so the
      // existing shape scoring applies without a tool-aware branch.
      expect(jsonDecode(reply), [
        {'type': 'Input.Date', 'id': 'when'},
      ]);
    });

    test('no tool call falls through to the content verbatim', () {
      // This is what makes the negative control work: an uncalled tool must
      // look like prose to the judge, not like an empty card.
      const message = {'content': 'SDUI means server-driven UI.'};
      expect(
        replyEquivalent(message, 'render_adaptive_card'),
        'SDUI means server-driven UI.',
      );
    });

    test('a tool call with no body yields an empty string, not "null"', () {
      // Guards against jsonEncode(null) producing the literal text "null",
      // which tryParseCardBody would treat as a scalar rather than absence.
      final message = {
        'tool_calls': [
          {
            'function': {
              'name': 'render_adaptive_card',
              'arguments': <String, dynamic>{},
            },
          },
        ],
      };
      expect(replyEquivalent(message, 'render_adaptive_card'), isEmpty);
    });
  });

  group('renderCardTool', () {
    test('wraps the schema ElementArray as the body parameter', () {
      final schema = {
        r'$defs': {
          'ElementArray': {'type': 'array'},
        },
      };
      final tool = renderCardTool(schema);
      final function = tool['function']! as Map<String, dynamic>;
      final params = function['parameters']! as Map<String, dynamic>;
      final props = params['properties']! as Map<String, dynamic>;
      expect(function['name'], 'render_adaptive_card');
      expect(params['required'], ['body']);
      expect(props['body'], {'type': 'array'});
    });
  });
}
