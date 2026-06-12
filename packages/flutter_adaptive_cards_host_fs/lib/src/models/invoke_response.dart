import 'package:flutter_adaptive_cards_fs/flutter_adaptive_cards_fs.dart';
import 'package:flutter_adaptive_cards_host_fs/src/models/invoke_effect.dart';

/// Parsed backend invoke response with ordered effects.
///
/// Effects apply in order: patches, then errors, then full card replacement.
class AdaptiveCardInvokeResponse {
  /// Parsed invoke result from a response adapter; hosts usually do not
  /// construct this directly.
  const AdaptiveCardInvokeResponse(this.effects);

  /// Effects to run in order via [applyTo]: patches, input errors, then full
  /// card replacement.
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
  /// Malformed or unsupported invoke response JSON from the backend.
  AdaptiveCardInvokeResponseParseException(this.message);

  /// Safe to log or surface in `AdaptiveCardBackendHandlers.onError`.
  final String message;

  @override
  String toString() => 'AdaptiveCardInvokeResponseParseException: $message';
}
