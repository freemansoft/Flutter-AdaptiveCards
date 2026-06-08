import 'package:flutter_adaptive_cards_host_fs/flutter_adaptive_cards_host_fs.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('toMap and requestFromMap round-trip execute request', () {
    const req = AdaptiveCardInvokeRequest(
      kind: AdaptiveCardInvokeKind.execute,
      verb: 'save',
      actionId: 'a1',
      data: {'k': 'v'},
    );
    final map = PlainJsonInvokeAdapter.toMap(req);
    expect(map['kind'], 'execute');
    expect(map['verb'], 'save');
    final parsed = PlainJsonInvokeAdapter.requestFromMap(map);
    expect(parsed.verb, 'save');
    expect(parsed.data, {'k': 'v'});
  });

  test('responseFromMap parses setInputErrors', () {
    final response = PlainJsonInvokeAdapter.responseFromMap({
      'type': 'adaptiveCard.invokeResponse',
      'effects': [
        {
          'type': 'setInputErrors',
          'errors': {'email': 'Required'},
        },
      ],
    });
    expect(response.effects.single, isA<SetInputErrorsEffect>());
    final effect = response.effects.single as SetInputErrorsEffect;
    expect(effect.errors['email'], 'Required');
  });
}
