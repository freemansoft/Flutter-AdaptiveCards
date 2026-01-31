import 'package:flutter_adaptive_cards/src/actions/action_type_registry.dart';
import 'package:flutter_adaptive_cards/src/cards/adaptive_card_element.dart';
import 'package:flutter_adaptive_cards/src/flutter_raw_adaptive_card.dart';
import 'package:flutter_adaptive_cards/src/reference_resolver.dart';
import 'package:flutter_adaptive_cards/src/registry.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Providers used to expose existing widget State objects via Riverpod.

/// This will get overriden by a call from [RawAdaptiveCardState] build method
final adaptiveCardElementStateProvider = Provider<AdaptiveCardElementState>((
  ref,
) {
  throw UnimplementedError(
    'adaptiveCardElementStateProvider must be overridden',
  );
});

/// This will get overriden by a call from [RawAdaptiveCardState] build method
/// Lets each AdaptiveCardElement have its own sub-scope
final rawAdaptiveCardStateProvider = Provider<RawAdaptiveCardState>((
  ref,
) {
  throw UnimplementedError(
    'rawAdaptiveCardElementStateProvider must be overridden',
  );
});

/// This will get overriden by a call from [RawAdaptiveCardState] build method
final cardTypeRegistryProvider = Provider<CardTypeRegistry>((
  ref,
) {
  throw UnimplementedError(
    'cardTypeRegistry must be overridden',
  );
});

/// This will get overriden by a call from [RawAdaptiveCardState] build method
final actionTypeRegistryProvider = Provider<ActionTypeRegistry>((
  ref,
) {
  throw UnimplementedError(
    'cardTypeRegistry must be overridden',
  );
});

/// This will get overriden by a call from [RawAdaptiveCardState] build method
final styleReferenceResolverProvider = Provider<ReferenceResolver>((
  ref,
) {
  throw UnimplementedError(
    'cardTypeRegistry must be overridden',
  );
});
