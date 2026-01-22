import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_adaptive_template/flutter_adaptive_template.dart';

void main() {
  group('AdaptiveCardTemplate', () {
    test('Basic Property Binding', () {
      final templateJson = {"type": "TextBlock", "text": "\${firstName}"};

      final data = {"firstName": "Matt"};

      final template = AdaptiveCardTemplate(templateJson);
      final result = template.expand(data);
      final resultJson = json.decode(result);

      expect(resultJson['text'], 'Matt');
    });

    test('Deep Property Binding', () {
      final templateJson = {
        "type": "TextBlock",
        "text": "\${address.city}, \${address.state}",
      };

      final data = {
        "address": {"city": "Redmond", "state": "WA"},
      };

      final template = AdaptiveCardTemplate(templateJson);
      final result = template.expand(data);
      final resultJson = json.decode(result);

      expect(resultJson['text'], 'Redmond, WA');
    });

    test('Indexer Binding', () {
      final templateJson = {"type": "TextBlock", "text": "\${items[0].name}"};

      final data = {
        "items": [
          {"name": "Item 1"},
          {"name": "Item 2"},
        ],
      };

      final template = AdaptiveCardTemplate(templateJson);
      final result = template.expand(data);
      final resultJson = json.decode(result);

      expect(resultJson['text'], 'Item 1');
    });

    test('Scope Switching with \$data', () {
      final templateJson = {
        "type": "Container",
        "\$data": "\${person}",
        "items": [
          {"type": "TextBlock", "text": "\${name}"},
        ],
      };

      final data = {
        "person": {"name": "Matt"},
      };

      final template = AdaptiveCardTemplate(templateJson);
      final result = template.expand(data);
      final resultJson = json.decode(result);

      // Expected: The Container should NOT have $data anymore, and its item should have resolved text
      expect(resultJson['type'], 'Container');
      expect(resultJson.containsKey('\$data'), false);
      expect(resultJson['items'][0]['text'], 'Matt');
    });

    test('Iteration with \$data', () {
      final templateJson = {
        "type": "Container",
        "items": [
          {"type": "TextBlock", "\$data": "\${items}", "text": "\${name}"},
        ],
      };

      final data = {
        "items": [
          {"name": "A"},
          {"name": "B"},
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

    test('Conditional \$when', () {
      final templateJson = {
        "type": "Container",
        "items": [
          {
            "type": "TextBlock",
            "\$when": "\${price > 30}",
            "text": "Expensive",
          },
          {"type": "TextBlock", "\$when": "\${price <= 30}", "text": "Cheap"},
        ],
      };

      final template = AdaptiveCardTemplate(templateJson);

      // Case 1: Expensive
      final result1 = template.expand({"price": 35});
      final json1 = json.decode(result1);
      final items1 = json1['items'] as List;
      expect(items1.length, 1);
      expect(items1[0]['text'], 'Expensive');

      // Case 2: Cheap
      final result2 = template.expand({"price": 25});
      final json2 = json.decode(result2);
      final items2 = json2['items'] as List;
      expect(items2.length, 1);
      expect(items2[0]['text'], 'Cheap');
    });

    test('Expressions: if()', () {
      final templateJson = {"text": "\${if(value, 'Yes', 'No')}"};

      final template = AdaptiveCardTemplate(templateJson);

      final r1 = json.decode(template.expand({"value": true}));
      expect(r1['text'], 'Yes');

      final r2 = json.decode(template.expand({"value": false}));
      expect(r2['text'], 'No');
    });

    test('Expressions: json()', () {
      final templateJson = {"text": "\${json(payload).foo}"};

      final data = {"payload": "{\"foo\": \"bar\"}"};

      final template = AdaptiveCardTemplate(templateJson);
      final result = json.decode(template.expand(data));
      expect(result['text'], 'bar');
    });

    test('Magic Variables: \$root and \$index', () {
      // Corrected test case to match the spec
      final templateJson = {
        "type": "Container",
        "items": [
          {
            "type": "TextBlock",
            "\$data": "\${items}",
            "text": "\${\$index}: \${name} from \${\$root.requestName}",
          },
        ],
      };

      final data = {
        "requestName": "Test",
        "items": [
          {"name": "Item A"},
          {"name": "Item B"},
        ],
      };

      final template = AdaptiveCardTemplate(templateJson);
      final result = json.decode(template.expand(data));
      final items = result['items'] as List;

      expect(items[0]['text'], '0: Item A from Test');
      expect(items[1]['text'], '1: Item B from Test');
    });
  });
}
