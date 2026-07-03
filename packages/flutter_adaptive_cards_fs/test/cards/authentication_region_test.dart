import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/flutter_adaptive_cards_fs.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final cardJson = <String, dynamic>{
    'type': 'AdaptiveCard',
    'version': '1.4',
    'body': <dynamic>[
      {'type': 'TextBlock', 'text': 'Body'},
    ],
    'authentication': {
      'text': 'Please sign in',
      'connectionName': 'myConnection',
      'buttons': [
        {
          'type': 'signin',
          'title': 'Sign in',
          'value': 'https://login.example.com/oauth',
        },
      ],
    },
  };

  Widget wrap({
    void Function(SigninActionInvoke)? onSignin,
    void Function(OpenUrlActionInvoke)? onOpenUrl,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: InheritedAdaptiveCardHandlers(
          onSubmit: (_) {},
          onExecute: (_) {},
          onOpenUrl: onOpenUrl ?? (_) {},
          onOpenUrlDialog: (_) {},
          onChange: (_) {},
          onSignin: onSignin,
          child: AdaptiveCardsCanvas.map(
            content: cardJson,
            hostConfigs: HostConfigs(),
          ),
        ),
      ),
    );
  }

  testWidgets('renders sign-in text and button', (tester) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    expect(find.text('Please sign in'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
  });

  testWidgets('tapping sign-in fires onSignin with value + connectionName',
      (tester) async {
    SigninActionInvoke? captured;
    await tester.pumpWidget(wrap(onSignin: (i) => captured = i));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();

    expect(captured, isNotNull);
    expect(captured!.value, 'https://login.example.com/oauth');
    expect(captured!.connectionName, 'myConnection');
  });

  testWidgets('falls back to onOpenUrl when onSignin is null', (tester) async {
    OpenUrlActionInvoke? opened;
    await tester.pumpWidget(wrap(onOpenUrl: (i) => opened = i));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();

    expect(opened, isNotNull);
    expect(opened!.url, 'https://login.example.com/oauth');
  });

  testWidgets('sign-in region renders between body and the action strip',
      (tester) async {
    final cardWithAction = <String, dynamic>{
      'type': 'AdaptiveCard',
      'version': '1.4',
      'body': <dynamic>[
        {'type': 'TextBlock', 'text': 'Body'},
      ],
      'actions': <dynamic>[
        {'type': 'Action.Submit', 'title': 'Submit'},
      ],
      'authentication': {
        'text': 'Please sign in',
        'connectionName': 'myConnection',
        'buttons': [
          {'type': 'signin', 'title': 'Sign in', 'value': 'https://x'},
        ],
      },
    };

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: InheritedAdaptiveCardHandlers(
            onSubmit: (_) {},
            onExecute: (_) {},
            onOpenUrl: (_) {},
            onOpenUrlDialog: (_) {},
            onChange: (_) {},
            child: AdaptiveCardsCanvas.map(
              content: cardWithAction,
              hostConfigs: HostConfigs(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final bodyY = tester.getTopLeft(find.text('Body')).dy;
    final signinY = tester.getTopLeft(find.text('Sign in')).dy;
    final submitY = tester.getTopLeft(find.text('Submit')).dy;

    // Order top-to-bottom: body, then sign-in region, then actions.
    expect(bodyY, lessThan(signinY));
    expect(signinY, lessThan(submitY));
  });
}
