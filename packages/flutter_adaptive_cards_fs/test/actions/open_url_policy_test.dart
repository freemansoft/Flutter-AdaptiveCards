import 'package:flutter_adaptive_cards_fs/src/security/adaptive_fetch_policy.dart';
import 'package:flutter_adaptive_cards_fs/src/security/adaptive_uri_policy.dart';
import 'package:flutter_adaptive_cards_fs/src/security/inherited_security_policy.dart';
import 'package:flutter_test/flutter_test.dart';
import '../utils/test_utils.dart';

void main() {
  testWidgets('DefaultOpenUrl blocks javascript: even with a host handler', (
    tester,
  ) async {
    const card = {
      'type': 'AdaptiveCard',
      'version': '1.0',
      'body': <Map<String, dynamic>>[],
      'actions': [
        {
          'type': 'Action.OpenUrl',
          'title': 'Evil',
          'url': 'javascript:alert(1)',
        },
      ],
    };

    await tester.pumpWidget(
      InheritedAdaptiveCardSecurityPolicy(
        uriPolicy: AdaptiveUriPolicy.standard,
        fetchPolicy: AdaptiveFetchPolicy.standard,
        child: getTestWidgetFromMap(
          map: card,
          title: 'open url policy test',
          onOpenUrl: (_) => fail('host handler should not run'),
          onSubmit: (_) {},
          onExecute: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Evil'));
    await tester.pumpAndSettle();

    expect(find.textContaining('not allowed'), findsOneWidget);
  });

  testWidgets('DefaultOpenUrl allows mailto: when scheme is allowed', (
    tester,
  ) async {
    const card = {
      'type': 'AdaptiveCard',
      'version': '1.0',
      'body': <Map<String, dynamic>>[],
      'actions': [
        {
          'type': 'Action.OpenUrl',
          'title': 'Mail',
          'url': 'mailto:someone@example.com',
        },
      ],
    };

    var called = false;
    await tester.pumpWidget(
      InheritedAdaptiveCardSecurityPolicy(
        uriPolicy: const AdaptiveUriPolicy(
          allowedSchemes: {'https', 'http', 'mailto'},
        ),
        fetchPolicy: AdaptiveFetchPolicy.standard,
        child: getTestWidgetFromMap(
          map: card,
          title: 'open url policy test',
          onOpenUrl: (invoke) {
            called = true;
            expect(invoke.url, 'mailto:someone@example.com');
          },
          onSubmit: (_) {},
          onExecute: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Mail'));
    await tester.pumpAndSettle();

    expect(called, isTrue);
  });
}
