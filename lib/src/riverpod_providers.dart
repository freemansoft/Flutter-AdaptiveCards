import 'package:flutter_adaptive_cards/src/cards/adaptive_card_element.dart';
import 'package:flutter_adaptive_cards/src/flutter_raw_adaptive_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Providers used to expose existing widget State objects via Riverpod.
final rawAdaptiveCardStateProvider = Provider<RawAdaptiveCardState>((ref) {
  throw UnimplementedError('rawAdaptiveCardStateProvider must be overridden');
});

final adaptiveCardElementStateProvider = Provider<AdaptiveCardElementState>((
  ref,
) {
  throw UnimplementedError(
    'adaptiveCardElementStateProvider must be overridden',
  );
});
