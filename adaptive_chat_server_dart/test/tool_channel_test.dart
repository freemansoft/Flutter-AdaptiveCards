import 'dart:convert';

import 'package:test/test.dart';

// Relative: these live outside lib/, so there is no package: URI.
import '../tool/model_probes/tool_channel.dart';

// Ordinary behavioral unit test of tool_channel.dart, the shared plumbing
// that lets tool_call_probe.dart and shape_ab.dart's `--channel tool` offer
// Ollama the same `render_adaptive_card` function and score its tool-call
// reply exactly as a prose reply. Without these tests, a broken
// toolCallArguments (wrong tool name matched, or a string-vs-map arguments
// shape missed) would make every probe using the tool channel silently
// score "model never called the tool" instead of failing loudly, and a
// broken replyEquivalent could make a null/no-op tool call collapse to the
// literal text "null" — which tryParseCardBody reads as a scalar, not as an
// absent reply — corrupting the pass/fail verdict rather than raising one.
void main() {
  group('toolCallArguments', () {
    // The common case Ollama actually returns; the decoded-string variant
    // right below is the one that needs its own code path.
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

    // A model can be offered more than one tool; the caller cares about
    // exactly one of them, and must not mistake a call to some other tool
    // for a rendered card.
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

    // A model that declines the tool and answers in prose is the expected
    // negative control, not an error case.
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
    // The two probes offering this tool must hand the model the same body
    // schema the prose channel enforces — a hand-written shape that
    // diverges here would let the tool channel accept payloads the prose
    // path's schema would reject, comparing the two channels unfairly.
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
