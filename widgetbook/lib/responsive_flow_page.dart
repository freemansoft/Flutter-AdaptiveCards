import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/flutter_adaptive_cards_fs.dart';
import 'package:widgetbook/widgetbook.dart';

import 'package:widgetbook_workspace/widgetbook_card_registry.dart';

/// Widgetbook demo for responsive layout (`targetWidth` / `Layout.Flow`).
///
/// Renders the same responsive sample cards the golden and widget tests use,
/// inside a width-constrained box whose width is driven by a knob. Dragging the
/// width across the breakpoints flips the card's width bucket, so containers
/// reflow between a vertical stack (narrow) and a wrapping flow (wide). A second
/// knob picks which responsive sample to render.
class ResponsiveFlowPage extends StatelessWidget {
  const ResponsiveFlowPage({super.key});

  /// Selectable responsive samples (label → asset path). Each file is a copy of
  /// the matching `test/samples/responsive/*.json` fixture used by the package
  /// golden and widget tests.
  static const _samples = <String, String>{
    'Container flow': 'lib/samples/responsive/flow_container.json',
    'Column flow (itemWidth)': 'lib/samples/responsive/flow_column.json',
  };

  @override
  Widget build(BuildContext context) {
    final width = context.knobs.double.slider(
      label: 'Card width (px)',
      initialValue: 900,
      min: 100,
      max: 1000,
      divisions: 90,
    );
    final sampleLabel = context.knobs.object.dropdown<String>(
      label: 'Sample',
      options: _samples.keys.toList(),
      initialOption: _samples.keys.first,
      labelBuilder: (value) => value,
    );
    final assetPath = _samples[sampleLabel]!;

    return Align(
      alignment: Alignment.topCenter,
      child: SizedBox(
        width: width,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Width: ${width.round()} px — bucket: ${_bucketLabel(width)}',
                style: Theme.of(context).textTheme.labelMedium,
              ),
              const SizedBox(height: 8),
              AdaptiveCardsCanvas.asset(
                assetPath: assetPath,
                cardTypeRegistry: widgetbookCardTypeRegistry,
                hostConfigs: HostConfigs(),
                showDebugJson: false,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Mirrors the Adaptive Cards spec-default breakpoints used by the library.
  String _bucketLabel(double width) {
    if (width < 165) return 'veryNarrow';
    if (width < 350) return 'narrow';
    if (width < 768) return 'standard';
    return 'wide';
  }
}
