import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards/flutter_adaptive_cards.dart';
import 'package:format/format.dart';
import 'package:url_launcher/url_launcher.dart';

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
          onSubmit: (map) {
            developer.log(
              format('onSubmit map: {}', map.toString()),
              name: runtimeType.toString(),
            );
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  format(
                    'onSubmit: No handler found for map: \n {}',
                    map.toString(),
                  ),
                ),
              ),
            );
          },
          onExecute: (map) {
            developer.log(
              format('onExecute map: {}', map.toString()),
              name: runtimeType.toString(),
            );
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  format(
                    'onExecute: No handler found for map: \n {}',
                    map.toString(),
                  ),
                ),
              ),
            );
          },
          onOpenUrl: (url) {
            developer.log(
              format('onOpenUrl url: {}', url),
              name: runtimeType.toString(),
            );
            unawaited(launchUrl(Uri.parse(url)));
          },
          hostConfig: HostConfig(),
          showDebugJson: true,
        ),
      ),
    );
  }
}
