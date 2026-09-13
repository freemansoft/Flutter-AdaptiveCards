import 'package:flutter_adaptive_cards_fs/flutter_adaptive_cards_fs.dart';

/// One server-driven effect applied to a rendered card.
sealed class const AdaptiveCardInvokeEffect() {
  /// Base type for parsed backend effects; use concrete subclasses.
  this;
}

/// Replaces the entire card JSON (host must reload the canvas/map).
class const ReplaceCardEffect(
  /// Complete Adaptive Card JSON to render next.
  final Map<String, dynamic> card,
) extends AdaptiveCardInvokeEffect {
  /// Full card replacement from a parsed response; host reloads via
  /// `AdaptiveCardInvokeResponse.applyTo` `onCardReplaced`.
  this;
}

/// Applies sparse element overlay patches via `applyUpdates` on card state.
class const ApplyPatchesEffect(
  /// Element overlay patches (choices, values, visibility, and so on).
  final List<AdaptiveElementUpdate> elements,
) extends AdaptiveCardInvokeEffect {
  /// Overlay patches from a parsed response; applied by
  /// `AdaptiveCardInvokeResponse.applyTo` without replacing baseline JSON.
  this;
}

/// Sets validation errors on inputs by id.
class const SetInputErrorsEffect(
  /// Input id → validation message.
  final Map<String, String> errors,
) extends AdaptiveCardInvokeEffect {
  /// Server validation feedback keyed by input `id`; applied by
  /// `AdaptiveCardInvokeResponse.applyTo`.
  this;
}

/// Explicit no-op (parsed for forward compatibility).
class const NoOpEffect() extends AdaptiveCardInvokeEffect {
  /// Acknowledged response with no UI changes; safe to ignore.
  this;
}
