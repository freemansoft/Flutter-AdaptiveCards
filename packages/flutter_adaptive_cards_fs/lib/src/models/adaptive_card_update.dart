import 'package:flutter/foundation.dart';
import 'package:flutter_adaptive_cards_fs/src/models/choice.dart';

/// One element's runtime overlay patch (baseline JSON unchanged).
@immutable
class AdaptiveElementUpdate {
  /// Creates a patch for element [id].
  const AdaptiveElementUpdate({
    required this.id,
    this.isVisible,
    this.value,
    this.errorMessage,
    this.isInvalid,
    this.isRequired,
    this.url,
    this.text,
    this.choices,
    this.queryCount,
    this.querySkip,
    this.querySearchText,
    this.clearValue = false,
    this.clearError = false,
    this.clearChoices = false,
    this.clearText = false,
    this.clearIsRequired = false,
    this.clearUrl = false,
  });

  /// Target element or input id from card JSON.
  final String id;

  /// Overrides baseline `"isVisible"`.
  final bool? isVisible;

  /// Overrides baseline `"value"` on inputs.
  final Object? value;

  /// Overrides baseline `"errorMessage"`.
  final String? errorMessage;

  /// Host validation flag merged into `"isInvalid"`.
  final bool? isInvalid;

  /// Overrides baseline `"isRequired"` on inputs.
  final bool? isRequired;

  /// Overrides baseline `"url"` on `Image` / `Media`.
  final String? url;

  /// Overrides baseline `"text"` (e.g. `TextBlock`).
  final String? text;

  /// Replaces `Input.ChoiceSet` `"choices"`.
  final List<Choice>? choices;

  /// Session override for `choices.data.count`.
  final int? queryCount;

  /// Session override for `choices.data.skip`.
  final int? querySkip;

  /// Typeahead search text (overlay only).
  final String? querySearchText;

  /// Clears the `inputValue` overlay.
  final bool clearValue;

  /// Clears validation overlays.
  final bool clearError;

  /// Clears the `choices` overlay.
  final bool clearChoices;

  /// Clears the `text` overlay.
  final bool clearText;

  /// Clears the `isRequired` overlay.
  final bool clearIsRequired;

  /// Clears the `url` overlay.
  final bool clearUrl;
}

/// Action overlay patch for `Action.*` nodes.
@immutable
class AdaptiveActionUpdate {
  /// Creates a patch for action [id].
  const AdaptiveActionUpdate({
    required this.id,
    this.isEnabled,
  });

  /// Target action id from card JSON.
  final String id;

  /// Overrides baseline `"isEnabled"`.
  final bool? isEnabled;
}
