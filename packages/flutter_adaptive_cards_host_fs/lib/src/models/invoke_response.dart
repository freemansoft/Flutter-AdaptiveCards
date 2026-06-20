import 'package:flutter_adaptive_cards_fs/flutter_adaptive_cards_fs.dart';
import 'package:flutter_adaptive_cards_host_fs/src/models/invoke_effect.dart';

/// Validates a backend-supplied replacement card before it is rendered.
///
/// Return `false` to reject the card; `AdaptiveCardInvokeResponse.applyTo` then
/// throws [AdaptiveCardInvokeResponseParseException] instead of replacing the
/// rendered card. Use this to enforce a schema/size/allowlist on untrusted
/// `replaceCard` responses.
typedef AdaptiveCardValidator = bool Function(Map<String, dynamic> card);

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
  /// [ReplaceCardEffect]. When [cardValidator] is provided, a replacement card
  /// that fails validation is rejected with
  /// [AdaptiveCardInvokeResponseParseException] and is **not** applied — the
  /// guardrail for untrusted `replaceCard` responses.
  void applyTo(
    RawAdaptiveCardState cardState, {
    void Function(Map<String, dynamic> card)? onCardReplaced,
    AdaptiveCardValidator? cardValidator,
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
          if (cardValidator != null && !cardValidator(card)) {
            throw AdaptiveCardInvokeResponseParseException(
              'Backend replacement card rejected by cardValidator',
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
