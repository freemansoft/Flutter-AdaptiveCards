import 'package:flutter_adaptive_cards_fs/flutter_adaptive_cards_fs.dart';

/// One server-driven effect applied to a rendered card.
sealed class AdaptiveCardInvokeEffect {
  /// Base type for parsed backend effects; use concrete subclasses.
  const AdaptiveCardInvokeEffect();
}

/// Replaces the entire card JSON (host must reload the canvas/map).
class ReplaceCardEffect extends AdaptiveCardInvokeEffect {
  /// Full card replacement from a parsed response; host reloads via
  /// `AdaptiveCardInvokeResponse.applyTo` `onCardReplaced`.
  const ReplaceCardEffect(this.card);

  /// Complete Adaptive Card JSON to render next.
  final Map<String, dynamic> card;
}

/// Applies sparse element overlay patches via `applyUpdates` on card state.
class ApplyPatchesEffect extends AdaptiveCardInvokeEffect {
  /// Overlay patches from a parsed response; applied by
  /// `AdaptiveCardInvokeResponse.applyTo` without replacing baseline JSON.
  const ApplyPatchesEffect(this.elements);

  /// Element overlay patches (choices, values, visibility, and so on).
  final List<AdaptiveElementUpdate> elements;
}

/// Sets validation errors on inputs by id.
class SetInputErrorsEffect extends AdaptiveCardInvokeEffect {
  /// Server validation feedback keyed by input `id`; applied by
  /// `AdaptiveCardInvokeResponse.applyTo`.
  const SetInputErrorsEffect(this.errors);

  /// Input id → validation message.
  final Map<String, String> errors;
}

/// Explicit no-op (parsed for forward compatibility).
class NoOpEffect extends AdaptiveCardInvokeEffect {
  /// Acknowledged response with no UI changes; safe to ignore.
  const NoOpEffect();
}
