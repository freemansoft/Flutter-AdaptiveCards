// casting dynamic all over the place isn't worth it in thest
// ignore_for_file: avoid_dynamic_calls

import 'dart:convert';

import 'package:flutter_adaptive_template_fs/flutter_adaptive_template_fs.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AdaptiveCardTemplate', () {
    test('Basic Property Binding', () {
      final templateJson = {'type': 'TextBlock', 'text': r'${firstName}'};

      final data = {'firstName': 'Matt'};

      final template = AdaptiveCardTemplate(templateJson);
      final result = template.expand(data);
      final resultJson = json.decode(result);

      expect(resultJson['text'], 'Matt');
    });

    test('Deep Property Binding', () {
      final templateJson = {
        'type': 'TextBlock',
        'text': r'${address.city}, ${address.state}',
      };

      final data = {
        'address': {'city': 'Redmond', 'state': 'WA'},
      };

      final template = AdaptiveCardTemplate(templateJson);
      final result = template.expand(data);
      final resultJson = json.decode(result);

      expect(resultJson['text'], 'Redmond, WA');
    });

    test('Indexer Binding', () {
      final templateJson = {'type': 'TextBlock', 'text': r'${items[0].name}'};

      final data = {
        'items': [
          {'name': 'Item 1'},
          {'name': 'Item 2'},
        ],
      };

      final template = AdaptiveCardTemplate(templateJson);
      final result = template.expand(data);
      final resultJson = json.decode(result);

      expect(resultJson['text'], 'Item 1');
    });

    test(r'Scope Switching with $data', () {
      final templateJson = {
        'type': 'Container',
        'items': [
          {
            'type': 'Container',
            r'$data': r'${person}',
            'items': [
              {'type': 'TextBlock', 'text': r'${name}'},
            ],
          },
          {
            'type': 'Container',
            r'$data': r'${pet}',
            'items': [
              {'type': 'TextBlock', 'text': r'${name}'},
            ],
          },
        ],
      };

      final data = {
        'person': {'name': 'Matt'},
        'pet': {'name': 'Fido'},
      };

      final template = AdaptiveCardTemplate(templateJson);
      final result = template.expand(data);
      final resultJson = json.decode(result);

      // Expected: The Container should NOT have $data anymore,
      // and its item should have resolved text
      expect(resultJson['type'], 'Container');
      expect(resultJson.containsKey(r'$data'), false);
      expect(resultJson['items'][0]['items'][0]['text'], 'Matt');
      expect(resultJson['items'][1]['items'][0]['text'], 'Fido');
    });

    test(r'Iteration with $data', () {
      final templateJson = {
        'type': 'Container',
        'items': [
          {'type': 'TextBlock', r'$data': r'${items}', 'text': r'${name}'},
        ],
      };

      final data = {
        'items': [
          {'name': 'A'},
          {'name': 'B'},
        ],
      };

      final template = AdaptiveCardTemplate(templateJson);
      final result = template.expand(data);
      final resultJson = json.decode(result);

      final items = resultJson['items'] as List;
      expect(items.length, 2);
      expect(items[0]['text'], 'A');
      expect(items[1]['text'], 'B');
    });

    test(r'Conditional $when', () {
      final templateJson = {
        'type': 'Container',
        'items': [
          {
            'type': 'TextBlock',
            r'$when': r'${price > 30}',
            'text': 'Expensive',
          },
          {'type': 'TextBlock', r'$when': r'${price <= 30}', 'text': 'Cheap'},
        ],
      };

      final template = AdaptiveCardTemplate(templateJson);

      // Case 1: Expensive
      final result1 = template.expand({'price': 35});
      final json1 = json.decode(result1);
      final items1 = json1['items'] as List;
      expect(items1.length, 1);
      expect(items1[0]['text'], 'Expensive');

      // Case 2: Cheap
      final result2 = template.expand({'price': 25});
      final json2 = json.decode(result2);
      final items2 = json2['items'] as List;
      expect(items2.length, 1);
      expect(items2[0]['text'], 'Cheap');
    });

    test('Expressions: if()', () {
      final templateJson = {'text': r"${if(value, 'Yes', 'No')}"};

      final template = AdaptiveCardTemplate(templateJson);

      final r1 = json.decode(template.expand({'value': true}));
      expect(r1['text'], 'Yes');

      final r2 = json.decode(template.expand({'value': false}));
      expect(r2['text'], 'No');
    });

    test('Expressions: json()', () {
      final templateJson = {'text': r'${json(payload).foo}'};

      final data = {'payload': '{"foo": "bar"}'};

      final template = AdaptiveCardTemplate(templateJson);
      final result = json.decode(template.expand(data));
      expect(result['text'], 'bar');
    });

    test(r'Magic Variables: $root and $index', () {
      // Corrected test case to match the spec
      final templateJson = {
        'type': 'Container',
        'items': [
          {
            'type': 'TextBlock',
            r'$data': r'${items}',
            'text': r'${$index}: ${name} from ${$root.requestName}',
          },
        ],
      };

      final data = {
        'requestName': 'Test',
        'items': [
          {'name': 'Item A'},
          {'name': 'Item B'},
        ],
      };

      final template = AdaptiveCardTemplate(templateJson);
      final result = json.decode(template.expand(data));
      final items = result['items'] as List;

      expect(items[0]['text'], '0: Item A from Test');
      expect(items[1]['text'], '1: Item B from Test');
    });

    test('Expressions: Math operations % and ^', () {
      final templateJson = {
        'modulo': r'${10 % 3}',
        'power': r'${2 ^ 3}',
      };

      final template = AdaptiveCardTemplate(templateJson);
      final result = json.decode(template.expand({}));
      
      expect(result['modulo'], 1);
      expect(result['power'], 8);
    });

    test('Expressions: Math functions', () {
      final templateJson = {
        'min': r'${min(10, 5, 20)}',
        'max': r'${max(10, 5, 20)}',
        'round': r'${round(3.6)}',
        'floor': r'${floor(3.6)}',
        'ceil': r'${ceil(3.2)}',
      };

      final template = AdaptiveCardTemplate(templateJson);
      final result = json.decode(template.expand({}));
      
      expect(result['min'], 5);
      expect(result['max'], 20);
      expect(result['round'], 4);
      expect(result['floor'], 3);
      expect(result['ceil'], 4);
    });

    test('Expressions: String functions', () {
      final templateJson = {
        'toUpper': r'${toUpper(name)}',
        'toLower': r'${toLower(name)}',
        'trim': r'${trim(spacedName)}',
        'substr': r'${substring(name, 1, 4)}',
        'replace': r"${replace(name, 'e', 'x')}",
      };

      final template = AdaptiveCardTemplate(templateJson);
      final result = json.decode(template.expand({
        'name': 'freeman',
        'spacedName': '  freeman  '
      }));
      
      expect(result['toUpper'], 'FREEMAN');
      expect(result['toLower'], 'freeman');
      expect(result['trim'], 'freeman');
      expect(result['substr'], 'reem');
      expect(result['replace'], 'frxxman');
    });
  });
}
