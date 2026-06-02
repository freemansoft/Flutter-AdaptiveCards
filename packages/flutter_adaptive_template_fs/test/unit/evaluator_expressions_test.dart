import 'dart:convert';

import 'package:flutter_adaptive_template_fs/flutter_adaptive_template_fs.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

/// Evaluates a single expression via a one-field template (`result`).
dynamic evalExpression(
  String expression, {
  Map<String, dynamic> data = const {},
}) {
  final template = AdaptiveCardTemplate({'result': '\${$expression}'});
  final decoded = json.decode(template.expand(data)) as Map<String, dynamic>;
  return decoded['result'];
}

/// Expands a string field that may mix literals and `${...}` segments.
String evalStringField(
  String fieldValue, {
  Map<String, dynamic> data = const {},
}) {
  final template = AdaptiveCardTemplate({'text': fieldValue});
  final decoded = json.decode(template.expand(data)) as Map<String, dynamic>;
  return decoded['text'] as String;
}

void main() {
  const isoDate = '2025-10-15T12:00:00Z';

  group('Evaluator expression matrix', () {
    group('operators', () {
      test('arithmetic and precedence', () {
        expect(evalExpression('2 + 3 * 4'), 14);
        expect(evalExpression('10 % 3'), 1);
        expect(evalExpression('2 ^ 3'), 8);
        expect(evalExpression('10 - 3'), 7);
        expect(evalExpression('6 / 2'), 3);
      });

      test('string concatenation with plus', () {
        expect(evalExpression("'a' + 'b'"), 'ab');
        expect(evalExpression("'x' + 1"), 'x1');
      });

      test('numeric comparisons', () {
        expect(evalExpression('3 > 2'), isTrue);
        expect(evalExpression('3 >= 3'), isTrue);
        expect(evalExpression('2 < 3'), isTrue);
        expect(evalExpression('2 <= 2'), isTrue);
        expect(evalExpression('1 == 1'), isTrue);
        expect(evalExpression('1 != 2'), isTrue);
      });

      test('logical AND short-circuits on false left operand', () {
        expect(evalExpression('false && (10 / 0 == 1)'), isFalse);
      });

      test('logical OR short-circuits on true left operand', () {
        expect(evalExpression('true || (10 / 0 == 1)'), isTrue);
      });

      test('unary operators', () {
        expect(evalExpression('!true'), isFalse);
        expect(evalExpression('-5'), -5);
        expect(evalExpression('+5'), 5);
      });

      test('literals', () {
        expect(evalExpression('true'), isTrue);
        expect(evalExpression('false'), isFalse);
        expect(evalExpression('null'), isNull);
      });
    });

    group('collection and string builtins', () {
      const data = <String, dynamic>{
        'name': 'freeman',
        'spacedName': '  freeman  ',
        'items': ['a', 'b'],
        'payload': '{"foo": "bar"}',
      };

      test('length', () {
        expect(evalExpression("length('abc')"), 3);
        expect(evalExpression('length(items)', data: data), 2);
        expect(evalExpression('length(name)', data: data), 7);
      });

      test('concat', () {
        expect(evalExpression("concat('a', 'b', 'c')"), 'abc');
        expect(evalExpression("concat('a', null, 'c')"), 'ac');
      });

      test('empty', () {
        expect(evalExpression("empty('')"), isTrue);
        expect(evalExpression('empty(null)'), isTrue);
        expect(evalExpression("empty('x')"), isFalse);
        expect(evalExpression('empty(items)', data: data), isFalse);
      });

      test('core string functions', () {
        expect(evalExpression('toUpper(name)', data: data), 'FREEMAN');
        expect(evalExpression('trim(spacedName)', data: data), 'freeman');
        expect(
          evalExpression("replace(name, 'e', 'x')", data: data),
          'frxxman',
        );
        expect(evalExpression('substring(name, 1, 4)', data: data), 'reem');
      });

      test('core math functions', () {
        expect(evalExpression('min(10, 5, 20)'), 5);
        expect(evalExpression('max(10, 5, 20)'), 20);
        expect(evalExpression('round(3.6)'), 4);
        expect(evalExpression('floor(3.6)'), 3);
        expect(evalExpression('ceil(3.2)'), 4);
      });
    });

    group('conditional and json builtins', () {
      test('if()', () {
        expect(evalExpression("if(true, 'Yes', 'No')"), 'Yes');
        expect(evalExpression("if(false, 'Yes', 'No')"), 'No');
      });

      test('if() with wrong arity returns null', () {
        expect(evalExpression("if(true, 'only')"), isNull);
      });

      test('json() parses payload', () {
        expect(
          evalExpression(
            'json(payload).foo',
            data: {'payload': '{"foo": "x"}'},
          ),
          'x',
        );
      });

      test('json() returns null for invalid JSON', () {
        expect(evalExpression("json('not json')"), isNull);
      });

      test('unknown function returns null', () {
        expect(evalExpression('doesNotExist(1)'), isNull);
      });
    });

    group('date and time builtins', () {
      const data = <String, dynamic>{'myDate': isoDate};

      test('date parts and date()', () {
        expect(evalExpression('year(myDate)', data: data), 2025);
        expect(evalExpression('month(myDate)', data: data), 10);
        expect(evalExpression('dayOfMonth(myDate)', data: data), 15);
        expect(
          evalExpression('date(myDate)', data: data),
          DateFormat('M/d/yyyy').format(DateTime.parse(isoDate)),
        );
      });

      test('addDays addHours addMinutes addSeconds', () {
        expect(
          (evalExpression('addDays(myDate, 5)', data: data) as String).contains(
            '2025-10-20',
          ),
          isTrue,
        );
        expect(
          (evalExpression('addHours(myDate, 2)', data: data) as String)
              .contains('2025-10-15T14:00:00'),
          isTrue,
        );
        expect(
          (evalExpression('addMinutes(myDate, 30)', data: data) as String)
              .contains('2025-10-15T12:30:00'),
          isTrue,
        );
        expect(
          (evalExpression('addSeconds(myDate, 45)', data: data) as String)
              .contains('2025-10-15T12:00:45'),
          isTrue,
        );
      });

      test('formatDateTime uses local timezone', () {
        final local = DateTime.parse(isoDate).toLocal();
        expect(
          evalExpression("formatDateTime(myDate, 'MM/dd/yyyy')", data: data),
          DateFormat('MM/dd/yyyy').format(local),
        );
      });

      test('utcNow returns non-empty ISO string', () {
        final value = evalExpression('utcNow()') as String;
        expect(value, isNotEmpty);
        expect(DateTime.parse(value).isUtc, isTrue);
      });
    });

    group('member access and binding', () {
      const data = <String, dynamic>{
        'user': {'name': 'Matt'},
        'items': [
          {'name': 'A'},
          {'name': 'B'},
        ],
      };

      test('dot path from data scope', () {
        expect(evalExpression('user.name', data: data), 'Matt');
      });

      test('bracket index in expression', () {
        expect(evalExpression('items[1].name', data: data), 'B');
      });

      test('missing property evaluates to null in pure expression', () {
        expect(evalExpression('user.missing', data: data), isNull);
      });

      test('missing property interpolates to empty string', () {
        expect(
          evalStringField(r'Hello ${user.missing}!', data: data),
          'Hello !',
        );
      });
    });

    group('interpolation and parse failures', () {
      test('legacy brace syntax without dollar sign', () {
        expect(
          evalStringField('Hello {name}!', data: {'name': 'Ada'}),
          'Hello Ada!',
        );
      });

      test('malformed pure expression returns original literal', () {
        expect(evalExpression('(a + b'), r'${(a + b}');
      });

      test('malformed segment in interpolation is left unchanged', () {
        expect(
          evalStringField(r'ok ${(bad} end'),
          r'ok ${(bad} end',
        );
      });

      test('pure expression returns non-string types without stringifying', () {
        expect(evalExpression('2 + 3'), 5);
        expect(evalExpression('true'), isTrue);
      });
    });
  });
}
