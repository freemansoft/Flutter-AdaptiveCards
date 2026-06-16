import 'package:flutter_adaptive_cards_fs/flutter_adaptive_cards_fs.dart';
import 'package:flutter_adaptive_charts_fs/flutter_adaptive_charts_fs.dart';

/// Default [CardTypeRegistry] for the widgetbook sample app (chart elements only).
///
/// Use for generic, network, knob, and non-chart-overlay demo pages.
final CardTypeRegistry widgetbookCardTypeRegistry = CardTypeRegistry(
  addedElements: CardChartsRegistry.additionalChartElements,
);

/// [CardTypeRegistry] for the widgetbook chart overlay demo page.
///
/// Includes chart [ElementOverlayExtension]s in addition to chart element builders.
final CardTypeRegistry widgetbookChartOverlayCardTypeRegistry =
    CardTypeRegistry(
      addedElements: CardChartsRegistry.additionalChartElements,
      overlayExtensions: CardChartsRegistry.overlayExtensions,
    );
