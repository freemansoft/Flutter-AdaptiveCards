import 'package:flutter_adaptive_cards_fs/flutter_adaptive_cards_fs.dart';
import 'package:flutter_adaptive_cards_host_fs/flutter_adaptive_cards_host_fs.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('PlainJson round-trips a signin request', () {
    const invoke = SigninActionInvoke(
      value: 'https://login.example.com/oauth',
      connectionName: 'myConnection',
    );
    final request = AdaptiveCardInvokeRequest.fromSignin(
      invoke,
      state: 'magic-123',
    );

    final map = PlainJsonInvokeAdapter.toMap(request);
    expect(map['kind'], 'signin');
    expect(map['connectionName'], 'myConnection');
    expect(map['url'], 'https://login.example.com/oauth');
    expect(map['value'], 'magic-123');

    final restored = PlainJsonInvokeAdapter.requestFromMap(map);
    expect(restored.kind, AdaptiveCardInvokeKind.signin);
    expect(restored.connectionName, 'myConnection');
  });
}
