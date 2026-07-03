import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/flutter_adaptive_cards_fs.dart';

/// Widgetbook page for root-card `authentication` with SnackBar feedback on the
/// sign-in handoff.
///
/// Demonstrates the sign-in button path: tapping a button fires `onSignin` with
/// the button `value` (sign-in URL) and the `connectionName`. A real host opens
/// the URL, captures the OAuth redirect, and swaps in the returned card.
class AuthenticationDemoPage extends StatelessWidget {
  const AuthenticationDemoPage({super.key});

  static const _assetPath = 'lib/samples/v1.4/authentication_signin_demo.json';

  @override
  Widget build(BuildContext context) {
    return SelectionArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(8),
        child: InheritedAdaptiveCardHandlers(
          onSubmit: (_) {},
          onExecute: (_) {},
          onOpenUrl: (_) {},
          onOpenUrlDialog: (_) {},
          onChange: (_) {},
          onSignin: (invoke) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'onSignin: connection='
                  '${invoke.connectionName ?? '(none)'} '
                  'value=${invoke.value}',
                ),
              ),
            );
          },
          child: AdaptiveCardsCanvas.asset(
            assetPath: _assetPath,
            hostConfigs: HostConfigs(),
            showDebugJson: true,
          ),
        ),
      ),
    );
  }
}
