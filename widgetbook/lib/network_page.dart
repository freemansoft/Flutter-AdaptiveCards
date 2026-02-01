import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards/flutter_adaptive_cards.dart';
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
        child: AdaptiveCard.network(
          url: url,
          onChange: (id, value, state) {
            developer.log(
              format(
                'onChange: id: {}, value: {}, state: {}',
                id,
                value,
                state,
              ),
              name: runtimeType.toString(),
            );
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  format(
                    'onChange: id: {}, value: {}, state: {}',
                    id,
                    value,
                    state,
                  ),
                ),
              ),
            );
          },

          hostConfigs: HostConfigs(
            light: HostConfig(),
            dark: HostConfig(),
          ),
          showDebugJson: true,
        ),
      ),
    );
  }
}
