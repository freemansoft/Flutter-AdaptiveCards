import 'package:flutter_adaptive_cards/src/flutter_adaptive_cards.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AdaptiveCardContentProvider tests', () {
    const jsonString =
        '{"type": "AdaptiveCard", "version": "1.0", "body": [{"type": "TextBlock", "text": "Hello"}]}';
    final contentMap = {
      'type': 'AdaptiveCard',
      'version': '1.0',
      'body': [
        {'type': 'TextBlock', 'text': 'Hello'},
      ],
    };

    test('JsonAdaptiveCardContentProvider loads correct content', () async {
      final provider = JsonAdaptiveCardContentProvider(jsonString: jsonString);
      final content = await provider.loadAdaptiveCardContent();
      expect(content, equals(contentMap));
    });

    test('MemoryAdaptiveCardContentProvider loads correct content', () async {
      final provider = MemoryAdaptiveCardContentProvider(content: contentMap);
      final content = await provider.loadAdaptiveCardContent();
      expect(content, equals(contentMap));
    });
  });

  group('AdaptiveCard constructors', () {
    const jsonString =
        '{"type": "AdaptiveCard", "version": "1.0", "body": [{"type": "TextBlock", "text": "Hello"}]}';
    final contentMap = {
      'type': 'AdaptiveCard',
      'version': '1.0',
      'body': [
        {'type': 'TextBlock', 'text': 'Hello'},
      ],
    };

    test(
      'AdaptiveCard.json and AdaptiveCard.memory have correct providers',
      () {
        final cardJson = AdaptiveCard.json(jsonString: jsonString);
        final cardMemory = AdaptiveCard.memory(content: contentMap);

        expect(
          cardJson.adaptiveCardContentProvider,
          isA<JsonAdaptiveCardContentProvider>(),
        );
        expect(
          cardMemory.adaptiveCardContentProvider,
          isA<MemoryAdaptiveCardContentProvider>(),
        );
      },
    );

    test(
      'AdaptiveCard.json and AdaptiveCard.memory providers return same content',
      () async {
        final cardJson = AdaptiveCard.json(jsonString: jsonString);
        final cardMemory = AdaptiveCard.memory(content: contentMap);

        final contentJson = await cardJson.adaptiveCardContentProvider
            .loadAdaptiveCardContent();
        final contentMemory = await cardMemory.adaptiveCardContentProvider
            .loadAdaptiveCardContent();

        expect(contentJson, equals(contentMemory));
      },
    );
  });
}
