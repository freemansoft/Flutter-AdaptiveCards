import 'package:flutter_adaptive_cards_host_fs/flutter_adaptive_cards_host_fs.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('execute toMap matches Teams action envelope', () {
    const req = AdaptiveCardInvokeRequest(
      kind: AdaptiveCardInvokeKind.execute,
      verb: 'saveProfile',
      data: {'name': 'Ada'},
    );
    final map = TeamsInvokeAdapter.toMap(req);
    expect(map['type'], 'invoke');
    expect(map['name'], 'adaptiveCard/action');
    final action =
        (map['value'] as Map<String, dynamic>)['action']
            as Map<String, dynamic>;
    expect(action['verb'], 'saveProfile');
    expect(action['data'], {'name': 'Ada'});
  });

  test('inputChange toMap uses application/search', () {
    const req = AdaptiveCardInvokeRequest(
      kind: AdaptiveCardInvokeKind.inputChange,
      inputId: 'city',
      data: {'country': 'usa'},
    );
    final map = TeamsInvokeAdapter.toMap(req);
    expect(map['name'], 'application/search');
    final value = map['value'] as Map<String, dynamic>;
    expect(value['data'], {'country': 'usa'});
  });

  test('responseFromMap parses adaptive card attachment', () {
    final card = {
      'type': 'AdaptiveCard',
      'version': '1.5',
      'body': <Map<String, dynamic>>[],
    };
    final response = TeamsInvokeAdapter.responseFromMap({
      'attachments': [
        {
          'contentType': 'application/vnd.microsoft.card.adaptive',
          'content': card,
        },
      ],
    });
    expect(response.effects.single, isA<ReplaceCardEffect>());
    final effect = response.effects.single as ReplaceCardEffect;
    expect(effect.card, card);
  });
}
