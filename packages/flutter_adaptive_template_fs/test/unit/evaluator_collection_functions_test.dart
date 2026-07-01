import 'dart:convert';

import 'package:flutter_adaptive_template_fs/flutter_adaptive_template_fs.dart';
import 'package:flutter_test/flutter_test.dart';

/// Evaluates a single expression via a one-field template (`result`).
dynamic evalExpression(
  String expression, {
  Map<String, dynamic> data = const {},
}) {
  final template = AdaptiveCardTemplate({'result': '\${$expression}'});
  final decoded = json.decode(template.expand(data)) as Map<String, dynamic>;
  return decoded['result'];
}

void main() {
  group('collection functions', () {
    test('join concatenates with a separator', () {
      expect(
        evalExpression(
          "join(items, ', ')",
          data: {
            'items': ['a', 'b', 'c'],
          },
        ),
        'a, b, c',
      );
    });

    test('first returns the first element', () {
      expect(
        evalExpression(
          'first(items)',
          data: {
            'items': [10, 20],
          },
        ),
        10,
      );
    });

    test('last returns the last element', () {
      expect(
        evalExpression(
          'last(items)',
          data: {
            'items': [10, 20],
          },
        ),
        20,
      );
    });

    test('sum adds numeric elements', () {
      expect(
        evalExpression(
          'sum(items)',
          data: {
            'items': [1, 2, 3],
          },
        ),
        6,
      );
    });

    test('average averages numeric elements', () {
      expect(
        evalExpression(
          'average(items)',
          data: {
            'items': [2, 4],
          },
        ),
        3.0,
      );
    });
  });

  group('date functions', () {
    test('formatEpoch formats seconds since epoch', () {
      // 1609459200 == 2021-01-01T00:00:00Z
      expect(
        evalExpression("formatEpoch(1609459200, 'yyyy')"),
        '2021',
      );
    });

    test('getFutureTime returns a parseable future timestamp', () {
      final result = evalExpression("getFutureTime(1, 'D')") as String;
      final parsed = DateTime.parse(result);
      expect(parsed.isAfter(DateTime.now()), isTrue);
    });
  });
}
