import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/flutter_adaptive_cards_fs.dart';
import 'package:format/format.dart';

import 'package:widgetbook_workspace/widgetbook_card_registry.dart';

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
    assert(() {
      developer.log(format('URL: {}', url), name: runtimeType.toString());
      return true;
    }());

    return SelectionArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(8),
        child: AdaptiveCardsCanvas.asset(
          assetPath: url,
          supportMarkdown: supportMarkdown,
          initData: initData,
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

            //   ScaffoldMessenger.of(context).showSnackBar(
            //     SnackBar(
            //       content: Text(
            //         format(
            //           'onChange: id: {}, value: {}, dataQuery: {}, state: {}',
            //           id,
            //           value,
            //           dataQuery,
            //           state,
            //         ),
            //       ),
            //     ),snackBarAnimationStyle:
            //   );
          },

          hostConfigs: HostConfigs(),
          showDebugJson: true,
        ),
      ),
    );
  }
}
