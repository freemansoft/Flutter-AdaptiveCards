import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/src/action/action_type_registry.dart';
import 'package:flutter_adaptive_cards_fs/src/action/default_actions.dart';
import 'package:flutter_adaptive_cards_fs/src/cards/actions/http.dart';
import 'package:flutter_adaptive_cards_fs/src/cards/elements/media.dart';
import 'package:flutter_adaptive_cards_fs/src/cards/elements/text_block.dart';
import 'package:flutter_adaptive_cards_fs/src/cards/elements/unknown.dart';
import 'package:flutter_adaptive_cards_fs/src/registry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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
                'https://github.com/youtube/api-samples/raw/refs/heads/master/java/src/main/resources/sample-video.mp4',
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

  testWidgets('Action.Http resolves to AdaptiveActionHttp widget', (
    tester,
  ) async {
    final Widget action = const CardTypeRegistry().getAction(
      map: {
        'type': 'Action.Http',
        'title': 'Go',
        'method': 'GET',
        'url': 'https://example.com',
      },
    );

    expect(action.runtimeType, equals(AdaptiveActionHttp));
  });

  test('Action.Http resolves to DefaultHttpAction handler', () {
    final action = const DefaultActionTypeRegistry().getActionForType(
      map: {'type': 'Action.Http'},
    );

    expect(action, isA<DefaultHttpAction>());
  });
}

class _TestAddition extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: Text('Test'));
  }
}
