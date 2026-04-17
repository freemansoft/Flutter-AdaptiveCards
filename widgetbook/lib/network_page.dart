import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/flutter_adaptive_cards_fs.dart';
import 'package:flutter_adaptive_charts_fs/flutter_adaptive_charts_fs.dart';
import 'package:format/format.dart';

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
        child: AdaptiveCardsRoot.network(
          url: url,
          // add the chart registrations
          cardTypeRegistry: CardTypeRegistry(
            addedElements: CardChartsRegistry.additionalChartElements,
          ),
          onChange: (id, value, dataQuery, state) {
            assert(() {
              developer.log(
                format(
                  'onChange: id: {}, value: {}, dataQuery: {}, state: {}',
                  id,
                  value,
                  dataQuery,
                  state,
                ),
                name: runtimeType.toString(),
              );
              return true;
            }());

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  format(
                    'onChange: id: {}, value: {}, dataQuery: {}, state: {}',
                    id,
                    value,
                    dataQuery,
                    state,
                  ),
                ),
              ),
            );
          },

          hostConfigs: HostConfigs(),
          showDebugJson: true,
        ),
      ),
    );
  }
}
