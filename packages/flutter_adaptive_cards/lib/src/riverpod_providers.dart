import 'package:flutter_adaptive_cards/src/cards/adaptive_card_element.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Providers used to expose existing widget State objects via Riverpod.

/// This will get overriden by a call from AdaptiveCardElement build method
/// in adaptive_card_element.dart
final adaptiveCardElementStateProvider = Provider<AdaptiveCardElementState>((
  ref,
) {
  throw UnimplementedError(
    'adaptiveCardElementStateProvider must be overridden',
  );
});
