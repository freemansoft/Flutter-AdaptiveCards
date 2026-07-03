import 'package:flutter_adaptive_cards_fs/flutter_adaptive_cards_fs.dart';
import 'package:flutter_adaptive_cards_host_fs/flutter_adaptive_cards_host_fs.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('fromSignin carries connectionName, url, and state', () {
    const invoke = SigninActionInvoke(
      value: 'https://login.example.com/oauth',
      connectionName: 'myConnection',
    );

    final request = AdaptiveCardInvokeRequest.fromSignin(
      invoke,
      state: 'magic-123',
    );

    expect(request.kind, AdaptiveCardInvokeKind.signin);
    expect(request.connectionName, 'myConnection');
    expect(request.url, 'https://login.example.com/oauth');
    expect(request.value, 'magic-123');
  });
}
