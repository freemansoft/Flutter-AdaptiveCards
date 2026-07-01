import 'package:flutter_adaptive_cards_fs/flutter_adaptive_cards_fs.dart';
import 'package:flutter_adaptive_cards_host_fs/flutter_adaptive_cards_host_fs.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PlainJsonInvokeResponseParser', () {
    test('parses applyPatches and setInputErrors', () {
      final response = PlainJsonInvokeResponseParser.parse({
        'type': 'adaptiveCard.invokeResponse',
        'effects': [
          {
            'type': 'applyPatches',
            'elements': [
              {
                'id': 'city',
                'choices': [
                  {'title': 'Paris', 'value': 'paris'},
                ],
              },
            ],
          },
          {
            'type': 'setInputErrors',
            'errors': {'email': 'Bad'},
          },
        ],
      });
      expect(response.effects, hasLength(2));
      expect(response.effects[0], isA<ApplyPatchesEffect>());
      expect(response.effects[1], isA<SetInputErrorsEffect>());
    });

    test('parses top-level card shorthand', () {
      final card = <String, dynamic>{
        'type': 'AdaptiveCard',
        'version': '1.5',
        'body': <Map<String, dynamic>>[],
      };
      final response = PlainJsonInvokeResponseParser.parse({
        'type': 'adaptiveCard.invokeResponse',
        'card': card,
      });
      expect(response.effects.single, isA<ReplaceCardEffect>());
    });
  });

  test('applyTo applies setInputErrors via cardState', () {
    final state = _RecordingCardState();
    const AdaptiveCardInvokeResponse([
      SetInputErrorsEffect({'email': 'Required'}),
    ]).applyTo(state);
    expect(state.appliedErrors, isTrue);
  });

  test('ReplaceCardEffect requires onCardReplaced', () {
    final state = _RecordingCardState();
    expect(
      () => const AdaptiveCardInvokeResponse([
        ReplaceCardEffect(<String, dynamic>{
          'type': 'AdaptiveCard',
          'version': '1.5',
          'body': <Map<String, dynamic>>[],
        }),
      ]).applyTo(state),
      throwsA(isA<StateError>()),
    );
  });

  test('cardValidator rejecting a card throws and skips replacement', () {
    final state = _RecordingCardState();
    var replaced = false;
    expect(
      () =>
          const AdaptiveCardInvokeResponse([
            ReplaceCardEffect(<String, dynamic>{'type': 'AdaptiveCard'}),
          ]).applyTo(
            state,
            onCardReplaced: (_) => replaced = true,
            cardValidator: (_) => false,
          ),
      throwsA(isA<AdaptiveCardInvokeResponseParseException>()),
    );
    expect(replaced, isFalse);
  });

  test('cardValidator accepting a card allows replacement', () {
    final state = _RecordingCardState();
    Map<String, dynamic>? got;
    const AdaptiveCardInvokeResponse([
      ReplaceCardEffect(<String, dynamic>{'type': 'AdaptiveCard'}),
    ]).applyTo(
      state,
      onCardReplaced: (card) => got = card,
      cardValidator: (_) => true,
    );
    expect(got, isNotNull);
  });
}

class _RecordingCardState extends RawAdaptiveCardState {
  bool appliedErrors = false;

  @override
  void applyUpdates({
    Iterable<AdaptiveElementUpdate> elements = const [],
    Iterable<AdaptiveActionUpdate> actions = const [],
  }) {
    appliedErrors = elements.isNotEmpty;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
