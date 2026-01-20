import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards/flutter_adaptive_cards.dart';
import 'package:format/format.dart';
import 'package:url_launcher/url_launcher.dart';

/// A simplified page widget for Widgetbook that displays a single AdaptiveCard
/// from a local asset URL.
///
/// Based on example/lib/generic_page.dart but adapted for Widgetbook:
/// - Displays a single card (not a list)
/// - No Scaffold/AppBar (Widgetbook provides its own chrome)
class GenericPage extends StatelessWidget {
  const GenericPage({
    super.key,
    required this.url,
    this.supportMarkdown = true,
    this.initData = const {},
  });
  final String url;
  final bool supportMarkdown;
  final Map<String, String> initData;

  @override
  Widget build(BuildContext context) {
    developer.log(format('URL: {}', url), name: runtimeType.toString());
    return SelectionArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(8),
        child: AdaptiveCard.asset(
          assetPath: url,
          supportMarkdown: supportMarkdown,
          initData: initData,
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
