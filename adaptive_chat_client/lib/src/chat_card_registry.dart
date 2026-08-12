import 'package:flutter_adaptive_cards_fs/flutter_adaptive_cards_fs.dart';
import 'package:flutter_adaptive_charts_fs/flutter_adaptive_charts_fs.dart';

/// [CardTypeRegistry] used for every server-authored bubble in the chat log.
///
/// Adds the `Chart.*` element builders on top of the core element set, so a
/// model reply containing a chart renders as a chart instead of the
/// unknown-type error placeholder. Pass it to the log's
/// `AdaptiveCardsCanvas`; the compose card keeps the default registry because
/// it is a fixed local card that never contains a chart.
///
/// Chart *overlay* extensions are deliberately omitted: they exist for hosts
/// that patch chart data at runtime, and the chat client renders each server
/// card once and never mutates it.
final CardTypeRegistry chatCardTypeRegistry = CardTypeRegistry(
  addedElements: CardChartsRegistry.additionalChartElements,
);
