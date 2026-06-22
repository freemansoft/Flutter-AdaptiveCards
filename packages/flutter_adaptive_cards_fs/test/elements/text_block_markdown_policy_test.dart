import 'package:flutter_adaptive_cards_fs/src/security/adaptive_fetch_policy.dart';
import 'package:flutter_adaptive_cards_fs/src/security/adaptive_uri_policy.dart';
import 'package:flutter_adaptive_cards_fs/src/security/inherited_security_policy.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import '../utils/test_utils.dart';

void main() {
  testWidgets(
    'markdown link with javascript: scheme is blocked, host handler not called',
    (tester) async {
      const card = {
        'type': 'AdaptiveCard',
        'version': '1.0',
        'body': [
          {
            'type': 'TextBlock',
            'text': '[click](javascript:alert(1))',
          },
        ],
      };

      await tester.pumpWidget(
        InheritedAdaptiveCardSecurityPolicy(
          uriPolicy: AdaptiveUriPolicy.standard,
          fetchPolicy: AdaptiveFetchPolicy.standard,
          child: getTestWidgetFromMap(
            map: card,
            title: 'markdown policy test',
            onOpenUrl: (_) => fail('host handler should not run'),
            onSubmit: (_) {},
            onExecute: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap the rendered markdown link.
      await tester.tap(find.byType(MarkdownBody));
      await tester.pumpAndSettle();

      expect(find.textContaining('not allowed'), findsOneWidget);
    },
  );
}
