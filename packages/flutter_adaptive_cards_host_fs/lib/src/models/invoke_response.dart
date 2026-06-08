import 'package:flutter_adaptive_cards_fs/flutter_adaptive_cards_fs.dart';
import 'package:flutter_adaptive_cards_host_fs/src/models/invoke_effect.dart';

/// Parsed backend invoke response with ordered effects.
///
/// Effects apply in order: patches, then errors, then full card replacement.
class AdaptiveCardInvokeResponse {
  /// Creates a response containing [effects] to run on the card.
  const AdaptiveCardInvokeResponse(this.effects);

  /// Ordered list of effects from the backend.
  final List<AdaptiveCardInvokeEffect> effects;

  /// Applies [effects] to [cardState] in order.
  ///
  /// [onCardReplaced] is required when the response includes
  /// [ReplaceCardEffect].
  void applyTo(
    RawAdaptiveCardState cardState, {
    void Function(Map<String, dynamic> card)? onCardReplaced,
  }) {
    for (final effect in effects) {
      switch (effect) {
        case ApplyPatchesEffect(:final elements):
          cardState.applyUpdates(elements: elements);
        case SetInputErrorsEffect(:final errors):
          cardState.applyUpdates(
            elements: errors.entries.map(
              (entry) => AdaptiveElementUpdate(
                id: entry.key,
                errorMessage: entry.value,
                isInvalid: true,
              ),
            ),
          );
        case ReplaceCardEffect(:final card):
          if (onCardReplaced == null) {
            throw StateError(
              'onCardReplaced is required for ReplaceCardEffect',
            );
          }
          onCardReplaced(card);
        case NoOpEffect():
          break;
      }
    }
  }
}

/// Thrown when invoke response JSON cannot be parsed.
class AdaptiveCardInvokeResponseParseException implements Exception {
  /// Creates a parse exception with a human-readable [message].
  AdaptiveCardInvokeResponseParseException(this.message);

  /// Describes what failed during parsing.
  final String message;

  @override
  String toString() => 'AdaptiveCardInvokeResponseParseException: $message';
}
