// Host-only demo: builds card JSON and a HostConfig from knobs to showcase
// the Teams `roundedCorners` property across Container, ColumnSet, Column,
// Table, and Image.

import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/flutter_adaptive_cards_fs.dart';
import 'package:widgetbook/widgetbook.dart';

import 'package:widgetbook_workspace/widgetbook_card_registry.dart';

/// Widgetbook page demonstrating the Teams `roundedCorners` property on
/// Container, ColumnSet, Column, Table, and Image, with the radius driven by
/// `HostConfig.cornerRadius`.
///
/// Two knobs drive the demo:
/// - `roundedCorners` (boolean) is patched into every element's JSON.
/// - `cornerRadius` (double slider) is used to *construct* the [HostConfig]
///   passed to [RawAdaptiveCard.fromMap], proving the radius comes from
///   HostConfig rather than being hardcoded per element.
class RoundedCornersKnobsPage extends StatefulWidget {
  /// Creates the rounded-corners knobs demo page.
  const RoundedCornersKnobsPage({super.key});

  @override
  State<RoundedCornersKnobsPage> createState() =>
      _RoundedCornersKnobsPageState();
}

class _RoundedCornersKnobsPageState extends State<RoundedCornersKnobsPage> {
  // Stable across rebuilds (same pattern as TableKnobsPage / ChartKnobsPage):
  // RawAdaptiveCard.fromMap has no async content load, so its
  // `didUpdateWidget` picks up a new `map` and re-reads `hostConfigs`
  // synchronously on every build. Keeping the same GlobalKey identity here
  // (rather than folding knob values into a ValueKey) avoids remounting the
  // card subtree, so both knobs update smoothly with no placeholder flash.
  final GlobalKey<RawAdaptiveCardState> _cardKey = GlobalKey();

  /// Builds a card body demonstrating `roundedCorners: rounded` on all five
  /// supported elements: Container, ColumnSet, Column (inside the
  /// ColumnSet), Table, and Image.
  Map<String, dynamic> _cardMap({required bool rounded}) {
    return <String, dynamic>{
      r'$schema': 'http://adaptivecards.io/schemas/adaptive-card.json',
      'type': 'AdaptiveCard',
      'version': '1.5',
      'body': <Object?>[
        {
          'type': 'TextBlock',
          'text': 'roundedCorners across Container, ColumnSet, Column, '
              'Table, and Image',
          'weight': 'Bolder',
          'size': 'Medium',
          'wrap': true,
        },
        {
          'type': 'Container',
          'style': 'accent',
          'roundedCorners': rounded,
          'items': <Object?>[
            {'type': 'TextBlock', 'text': 'Container', 'wrap': true},
          ],
        },
        {
          'type': 'ColumnSet',
          'style': 'emphasis',
          'roundedCorners': rounded,
          'columns': <Object?>[
            {
              'type': 'Column',
              'width': 'stretch',
              'style': 'good',
              'roundedCorners': rounded,
              'items': <Object?>[
                {
                  'type': 'TextBlock',
                  'text': 'Column (own roundedCorners)',
                  'wrap': true,
                },
              ],
            },
            {
              'type': 'Column',
              'width': 'stretch',
              'items': <Object?>[
                {'type': 'TextBlock', 'text': 'ColumnSet', 'wrap': true},
              ],
            },
          ],
        },
        {
          'type': 'Table',
          'roundedCorners': rounded,
          'showGridLines': true,
          'firstRowAsHeader': true,
          'gridStyle': 'accent',
          'columns': <Object?>[
            {'width': 'stretch'},
            {'width': 'stretch'},
          ],
          'rows': <Object?>[
            {
              'type': 'TableRow',
              'cells': <Object?>[
                {
                  'type': 'TableCell',
                  'style': 'accent',
                  'items': <Object?>[
                    {
                      'type': 'TextBlock',
                      'text': 'Header 1',
                      'weight': 'Bolder',
                      'wrap': true,
                    },
                  ],
                },
                {
                  'type': 'TableCell',
                  'style': 'accent',
                  'items': <Object?>[
                    {
                      'type': 'TextBlock',
                      'text': 'Header 2',
                      'weight': 'Bolder',
                      'wrap': true,
                    },
                  ],
                },
              ],
            },
            {
              'type': 'TableRow',
              'cells': <Object?>[
                {
                  'type': 'TableCell',
                  'items': <Object?>[
                    {'type': 'TextBlock', 'text': 'Cell 1', 'wrap': true},
                  ],
                },
                {
                  'type': 'TableCell',
                  'items': <Object?>[
                    {'type': 'TextBlock', 'text': 'Cell 2', 'wrap': true},
                  ],
                },
              ],
            },
          ],
        },
        {
          'type': 'Image',
          'url': 'https://adaptivecards.io/content/cats/2.png',
          'size': 'Medium',
          'roundedCorners': rounded,
          'backgroundColor': '#FFDDDDDD',
          'altText': 'Cat photo with roundedCorners applied',
        },
      ],
    };
  }

  @override
  Widget build(BuildContext context) {
    final rounded = context.knobs.boolean(
      label: 'roundedCorners',
      initialValue: true,
    );
    final radius = context.knobs.double.slider(
      label: 'cornerRadius',
      initialValue: 8,
      min: 0,
      max: 32,
    );

    return SelectionArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(8),
        child: RawAdaptiveCard.fromMap(
          key: _cardKey,
          map: _cardMap(rounded: rounded),
          cardTypeRegistry: widgetbookCardTypeRegistry,
          hostConfigs: HostConfigs(
            light: HostConfig(cornerRadius: radius),
            dark: HostConfig(cornerRadius: radius),
          ),
          showDebugJson: true,
        ),
      ),
    );
  }
}
