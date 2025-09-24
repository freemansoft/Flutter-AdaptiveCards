import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'cards/adaptive_card_element.dart';
import 'flutter_raw_adaptive_card.dart';

// Providers used to expose existing widget State objects via Riverpod.
final rawAdaptiveCardStateProvider = Provider<RawAdaptiveCardState>((ref) {
  throw UnimplementedError('rawAdaptiveCardStateProvider must be overridden');
});

final adaptiveCardElementStateProvider =
    Provider<AdaptiveCardElementState>((ref) {
  throw UnimplementedError(
      'adaptiveCardElementStateProvider must be overridden');
});
