import 'package:flutter_adaptive_cards_fs/flutter_adaptive_cards_fs.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('SigninActionInvoke.fromButton copies value and connectionName', () {
    const button = AuthCardButton(
      type: 'signin',
      title: 'Sign in',
      value: 'https://login.example.com/oauth',
    );

    final invoke = SigninActionInvoke.fromButton(
      button,
      connectionName: 'myConnection',
    );

    expect(invoke.value, 'https://login.example.com/oauth');
    expect(invoke.connectionName, 'myConnection');
  });
}
