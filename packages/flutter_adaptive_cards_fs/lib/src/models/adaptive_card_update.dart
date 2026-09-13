import 'package:flutter/foundation.dart';
import 'package:flutter_adaptive_cards_fs/src/models/choice.dart';
import 'package:flutter_adaptive_cards_fs/src/models/fact.dart';

/// One element's runtime overlay patch (baseline JSON unchanged).
@immutable
class const AdaptiveElementUpdate({
  /// Target element or input id from card JSON.
  required final String id,

  /// Overrides baseline `"isVisible"`.
  final bool? isVisible,

  /// Overrides baseline `"value"` on inputs.
  final Object? value,

  /// Overrides baseline `"errorMessage"`.
  final String? errorMessage,

  /// Host validation flag merged into `"isInvalid"`.
  final bool? isInvalid,

  /// Overrides baseline `"isRequired"` on inputs.
  final bool? isRequired,

  /// Overrides baseline `"url"` on `Image` / `Media`.
  final String? url,

  /// Overrides baseline `"text"` (e.g. `TextBlock`).
  final String? text,

  /// Replaces `Input.ChoiceSet` `"choices"`.
  final List<Choice>? choices,

  /// Session override for `choices.data.count`.
  final int? queryCount,

  /// Session override for `choices.data.skip`.
  final int? querySkip,

  /// Typeahead search text (overlay only).
  final String? querySearchText,

  /// Overrides baseline `"label"` on inputs.
  final String? label,

  /// Overrides baseline `"placeholder"` on inputs.
  final String? placeholder,

  /// Replaces `FactSet` `"facts"`.
  final List<Fact>? facts,

  /// Replaces `RichTextBlock` `"inlines"`.
  final List<Map<String, dynamic>>? inlines,

  /// Patches optional-package overlay payloads keyed by extension id.
  final Map<String, Map<String, dynamic>>? extensionPatches,

  /// Clears the `inputValue` overlay.
  final bool clearValue = false,

  /// Clears validation overlays.
  final bool clearError = false,

  /// Clears the `choices` overlay.
  final bool clearChoices = false,

  /// Clears the `text` overlay.
  final bool clearText = false,

  /// Clears the `isRequired` overlay.
  final bool clearIsRequired = false,

  /// Clears the `url` overlay.
  final bool clearUrl = false,

  /// Clears the `label` overlay.
  final bool clearLabel = false,

  /// Clears the `placeholder` overlay.
  final bool clearPlaceholder = false,

  /// Clears the `facts` overlay.
  final bool clearFacts = false,

  /// Clears the `inlines` overlay.
  final bool clearInlines = false,

  /// Clears optional-package overlay payloads for these extension ids.
  final Set<String> clearExtensions = const {},
}) {
  /// Creates a patch for element [id].
  this;
}

/// Action overlay patch for `Action.*` nodes.
@immutable
class const AdaptiveActionUpdate({
  /// Target action id from card JSON.
  required final String id,

  /// Overrides baseline `"isEnabled"`.
  final bool? isEnabled,

  /// Overrides baseline `"title"`.
  final String? title,

  /// Overrides baseline `"tooltip"`.
  final String? tooltip,

  /// Overrides baseline `"iconUrl"`.
  final String? iconUrl,

  /// Clears the `title` overlay.
  final bool clearTitle = false,

  /// Clears the `tooltip` overlay.
  final bool clearTooltip = false,

  /// Clears the `iconUrl` overlay.
  final bool clearIconUrl = false,
}) {
  /// Creates a patch for action [id].
  this;
}
