import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards/src/elements/media.dart';
import 'package:flutter_adaptive_cards/src/elements/text_block.dart';
import 'package:flutter_adaptive_cards/src/elements/unknown.dart';
import 'package:flutter_adaptive_cards/src/flutter_raw_adaptive_card.dart';
import 'package:flutter_adaptive_cards/src/registry.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

class MockAdaptiveCardState extends Mock implements RawAdaptiveCardState {
  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.debug}) {
    return '';
  }
}

void main() {
  setUp(() {});

  testWidgets('Basic types return', (tester) async {
    const CardTypeRegistry cardRegistry = CardTypeRegistry();
    final Widget adaptiveElement = cardRegistry.getElement(
      map: {
        'type': 'TextBlock',
        'text': 'Adaptive Card design session',
        'size': 'large',
        'weight': 'bolder',
      },
    );

    expect(adaptiveElement.runtimeType, equals(AdaptiveTextBlock));

    final Widget second = cardRegistry.getElement(
      map: {
        'type': 'Media',
        'poster':
            'https://docs.microsoft.com/en-us/adaptive-cards/content/videoposter.png',
        'sources': [
          {
            'mimeType': 'video/mp4',
            'url':
                'https://cdn.adaptivecards.io/assets/AdaptiveCardsOverviewVideo.mp4',
          },
        ],
      },
    );

    expect(second.runtimeType, equals(AdaptiveMedia));
  });

  testWidgets('Unknown element', (tester) async {
    const CardTypeRegistry cardRegistry = CardTypeRegistry();

    final Widget adaptiveElement = cardRegistry.getElement(
      map: {'type': 'NoType'},
    );

    expect(adaptiveElement.runtimeType, equals(AdaptiveUnknown));

    final AdaptiveUnknown unknown = adaptiveElement as AdaptiveUnknown;

    expect(unknown.type, equals('NoType'));
  });

  testWidgets('Removed element', (tester) async {
    const CardTypeRegistry cardRegistry = CardTypeRegistry(
      removedElements: ['TextBlock'],
    );

    final Widget adaptiveElement = cardRegistry.getElement(
      map: {
        'type': 'TextBlock',
        'text': 'Adaptive Card design session',
        'size': 'large',
        'weight': 'bolder',
      },
    );

    expect(adaptiveElement.runtimeType, equals(AdaptiveUnknown));

    final AdaptiveUnknown unknown = adaptiveElement as AdaptiveUnknown;

    expect(unknown.type, equals('TextBlock'));
  });

  testWidgets('Add element', (tester) async {
    final CardTypeRegistry cardRegistry = CardTypeRegistry(
      addedElements: {'Test': (map) => _TestAddition()},
    );

    final element = cardRegistry.getElement(
      map: {'type': 'Test'},
    );

    expect(element.runtimeType, equals(_TestAddition));

    await tester.pumpWidget(element);

    expect(find.text('Test'), findsOneWidget);
  });
}

class _TestAddition extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: Text('Test'));
  }
}
