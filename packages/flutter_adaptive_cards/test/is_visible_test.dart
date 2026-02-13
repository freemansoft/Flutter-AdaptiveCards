import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'utils/test_utils.dart';

void main() {
  group('isVisible Property Tests', () {
    testWidgets('Element with isVisible: true should be visible', (
      tester,
    ) async {
      const testJson = '''
      {
        "type": "AdaptiveCard",
        "version": "1.0",
        "body": [
          {
            "type": "TextBlock",
            "id": "visibleText",
            "text": "I am visible",
            "isVisible": true
          }
        ]
      }
      ''';

      final widget = getTestWidgetFromString(jsonString: testJson);
      await tester.pumpWidget(widget);

      // Should find the Visibility widget
      final visibilityFinder = find.byType(Visibility);
      expect(visibilityFinder, findsWidgets);

      // Should find the text
      expect(find.text('I am visible'), findsOneWidget);
    });

    testWidgets('Element with isVisible: false should be hidden', (
      tester,
    ) async {
      const testJson = '''
      {
        "type": "AdaptiveCard",
        "version": "1.0",
        "body": [
          {
            "type": "TextBlock",
            "id": "hiddenText",
            "text": "I am hidden",
            "isVisible": false
          }
        ]
      }
      ''';

      final widget = getTestWidgetFromString(jsonString: testJson);
      await tester.pumpWidget(widget);

      // Should find Visibility widget
      final visibilityFinder = find.byType(Visibility);
      expect(visibilityFinder, findsWidgets);

      // Text should NOT be found (hidden)
      expect(find.text('I am hidden'), findsNothing);
    });

    testWidgets(
      'Element without isVisible property should default to visible',
      (tester) async {
        const testJson = '''
      {
        "type": "AdaptiveCard",
        "version": "1.0",
        "body": [
          {
            "type": "TextBlock",
            "id": "defaultText",
            "text": "I have no isVisible property"
          }
        ]
      }
      ''';

        final widget = getTestWidgetFromString(jsonString: testJson);
        await tester.pumpWidget(widget);

        // Text should be visible by default
        expect(find.text('I have no isVisible property'), findsOneWidget);
      },
    );

    testWidgets('Multiple elements with mixed isVisible states', (
      tester,
    ) async {
      const testJson = '''
      {
        "type": "AdaptiveCard",
        "version": "1.0",
        "body": [
          {
            "type": "TextBlock",
            "id": "visible1",
            "text": "Visible 1",
            "isVisible": true
          },
          {
            "type": "TextBlock",
            "id": "hidden1",
            "text": "Hidden 1",
            "isVisible": false
          },
          {
            "type": "TextBlock",
            "id": "default1",
            "text": "Default Visible"
          },
          {
            "type": "TextBlock",
            "id": "visible2",
            "text": "Visible 2",
            "isVisible": true
          }
        ]
      }
      ''';

      final widget = getTestWidgetFromString(jsonString: testJson);
      await tester.pumpWidget(widget);

      // Should find visible elements
      expect(find.text('Visible 1'), findsOneWidget);
      expect(find.text('Visible 2'), findsOneWidget);
      expect(find.text('Default Visible'), findsOneWidget);

      // Should NOT find hidden element
      expect(find.text('Hidden 1'), findsNothing);
    });

    testWidgets('isVisible with string values "true" and "false"', (
      tester,
    ) async {
      const testJson = '''
      {
        "type": "AdaptiveCard",
        "version": "1.0",
        "body": [
          {
            "type": "TextBlock",
            "id": "stringTrue",
            "text": "String True",
            "isVisible": "true"
          },
          {
            "type": "TextBlock",
            "id": "stringFalse",
            "text": "String False",
            "isVisible": "false"
          }
        ]
      }
      ''';

      final widget = getTestWidgetFromString(jsonString: testJson);
      await tester.pumpWidget(widget);

      // String "true" should be visible
      expect(find.text('String True'), findsOneWidget);

      // String "false" should be hidden
      expect(find.text('String False'), findsNothing);
    });

    testWidgets('Container with isVisible affects all children', (
      tester,
    ) async {
      const testJson = '''
      {
        "type": "AdaptiveCard",
        "version": "1.0",
        "body": [
          {
            "type": "Container",
            "id": "hiddenContainer",
            "isVisible": false,
            "items": [
              {
                "type": "TextBlock",
                "text": "Inside hidden container"
              },
              {
                "type": "TextBlock",
                "text": "Also hidden"
              }
            ]
          }
        ]
      }
      ''';

      final widget = getTestWidgetFromString(jsonString: testJson);
      await tester.pumpWidget(widget);

      // Children of hidden container should not be visible
      expect(find.text('Inside hidden container'), findsNothing);
      expect(find.text('Also hidden'), findsNothing);
    });
  });
}
