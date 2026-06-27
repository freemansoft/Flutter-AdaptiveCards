import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/flutter_adaptive_cards_fs.dart';

/// Widgetbook page for the deprecated/legacy `Action.Http` with SnackBar
/// feedback on invoke.
///
/// `Action.Http` was the original Adaptive Cards HTTP action model (schema
/// v1.0), superseded by `Action.Execute` (Universal Action Model, schema v1.4);
/// it is still used by Outlook Actionable Messages. This page wires `onHttp` to
/// show the request the core resolved (method, url, body, headers) after
/// `{{nameInput.value}}` substitution. The core never performs the request — a
/// host (for example `flutter_adaptive_cards_host_fs`) supplies the transport.
class HttpActionDemoPage extends StatelessWidget {
  const HttpActionDemoPage({super.key});

  static const _assetPath = 'lib/samples/action_http/example1.json';

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
          onHttp: (invoke) {
            final headers = invoke.headers
                .map((h) => '${h.name}: ${h.value}')
                .join(', ');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'onHttp: ${invoke.method} ${invoke.url}'
                  '${invoke.body != null ? '\nbody=${invoke.body}' : ''}'
                  '${headers.isNotEmpty ? '\nheaders=$headers' : ''}',
                ),
              ),
            );
          },
          child: AdaptiveCardsCanvas.asset(
            assetPath: _assetPath,
            supportMarkdown: false,
            hostConfigs: HostConfigs(),
            showDebugJson: true,
          ),
        ),
      ),
    );
  }
}
