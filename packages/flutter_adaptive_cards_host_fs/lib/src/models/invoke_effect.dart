import 'package:flutter_adaptive_cards_fs/flutter_adaptive_cards_fs.dart';

/// One server-driven effect applied to a rendered card.
sealed class AdaptiveCardInvokeEffect {
  /// Creates an invoke effect.
  const AdaptiveCardInvokeEffect();
}

/// Replaces the entire card JSON (host must reload the canvas/map).
class ReplaceCardEffect extends AdaptiveCardInvokeEffect {
  /// Creates an effect that supplies a full Adaptive Card map.
  const ReplaceCardEffect(this.card);

  /// Complete Adaptive Card JSON to render next.
  final Map<String, dynamic> card;
}

/// Applies sparse element overlay patches via `applyUpdates` on card state.
class ApplyPatchesEffect extends AdaptiveCardInvokeEffect {
  /// Creates an effect with one or more [AdaptiveElementUpdate] patches.
  const ApplyPatchesEffect(this.elements);

  /// Element overlay patches (choices, values, visibility, and so on).
  final List<AdaptiveElementUpdate> elements;
}

/// Sets validation errors on inputs by id.
class SetInputErrorsEffect extends AdaptiveCardInvokeEffect {
  /// Creates an effect mapping input ids to error messages.
  const SetInputErrorsEffect(this.errors);

  /// Input id → validation message.
  final Map<String, String> errors;
}

/// Explicit no-op (parsed for forward compatibility).
class NoOpEffect extends AdaptiveCardInvokeEffect {
  /// Creates a no-op effect.
  const NoOpEffect();
}
