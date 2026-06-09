import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/flutter_adaptive_cards_fs.dart';

/// Widgetbook page for root-card `refresh` with SnackBar feedback on invoke.
class RefreshDemoPage extends StatelessWidget {
  const RefreshDemoPage({super.key});

  static const _assetPath = 'lib/samples/v1.4/refresh_demo.json';

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
          onRefresh: (invoke) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'onRefresh: verb=${invoke.verb ?? '(none)'} '
                  'data=${invoke.data}',
                ),
              ),
            );
          },
          child: AdaptiveCardsCanvas.asset(
            assetPath: _assetPath,
            currentUserId: 'demo-user',
            hostConfigs: HostConfigs(),
            showDebugJson: true,
          ),
        ),
      ),
    );
  }
}
