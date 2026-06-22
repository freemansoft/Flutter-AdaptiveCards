import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/flutter_adaptive_cards_fs.dart';
import 'package:format/format.dart';

import 'package:widgetbook_workspace/widgetbook_card_registry.dart';

/// A simplified page widget for Widgetbook that displays a single AdaptiveCard
/// from a network URL.
///
/// Based on example/lib/network_page.dart but adapted for Widgetbook:
/// - No Scaffold/AppBar (Widgetbook provides its own chrome)
class NetworkPage extends StatelessWidget {
  const NetworkPage({super.key, required this.url});
  final String url;

  @override
  Widget build(BuildContext context) {
    return SelectionArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(8),
        child: AdaptiveCardsCanvas.network(
          url: url,
          cardTypeRegistry: widgetbookCardTypeRegistry,
          onChange: (invoke) {
            assert(() {
              developer.log(
                format(
                  'onChange: id: {}, value: {}, dataQuery: {}, state: {}',
                  invoke.inputId,
                  invoke.value,
                  invoke.dataQuery,
                  invoke.cardState,
                ),
                name: runtimeType.toString(),
              );
              return true;
            }());

            // ScaffoldMessenger.of(context).showSnackBar(
            //   SnackBar(
            //     content: Text(
            //       format(
            //         'onChange: id: {}, value: {}, dataQuery: {}, state: {}',
            //         id,
            //         value,
            //         dataQuery,
            //         state,
            //       ),
            //     ),
            //   ),
            // );
          },

          hostConfigs: HostConfigs(),
          showDebugJson: true,
        ),
      ),
    );
  }
}
