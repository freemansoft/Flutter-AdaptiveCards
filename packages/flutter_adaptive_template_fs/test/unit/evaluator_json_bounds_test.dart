import 'dart:convert';

import 'package:flutter_adaptive_template_fs/flutter_adaptive_template_fs.dart';
import 'package:flutter_test/flutter_test.dart';

dynamic evalExpression(
  String expression, {
  Map<String, dynamic> data = const {},
}) {
  final template = AdaptiveCardTemplate({'result': '\${$expression}'});
  final decoded = json.decode(template.expand(data)) as Map<String, dynamic>;
  return decoded['result'];
}

void main() {
  group('json() input bounds', () {
    test('returns null for an over-cap payload instead of decoding it', () {
      final huge = '[${List.filled(200000, '0').join(',')}]';
      expect(huge.length, greaterThan(256 * 1024));
      expect(evalExpression('json(payload)', data: {'payload': huge}), isNull);
    });

    test('still decodes a payload within the cap', () {
      expect(
        evalExpression('json(payload).foo', data: {'payload': '{"foo":"x"}'}),
        'x',
      );
    });
  });
}
