import 'package:flutter_adaptive_cards_fs/flutter_adaptive_cards_fs.dart';
import 'package:flutter_adaptive_cards_host_fs/flutter_adaptive_cards_host_fs.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Teams adapter emits signin/verifyState with state', () {
    const invoke = SigninActionInvoke(
      value: 'https://login.example.com/oauth',
      connectionName: 'myConnection',
    );
    final request = AdaptiveCardInvokeRequest.fromSignin(
      invoke,
      state: 'magic-123',
    );

    final map = TeamsInvokeAdapter.toMap(request);
    expect(map['type'], 'invoke');
    expect(map['name'], 'signin/verifyState');
    expect((map['value'] as Map)['state'], 'magic-123');
  });
}
