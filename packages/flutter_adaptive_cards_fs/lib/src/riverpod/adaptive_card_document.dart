import 'package:flutter/foundation.dart';
import 'package:flutter_adaptive_cards_fs/src/models/choice.dart';
import 'package:flutter_adaptive_cards_fs/src/models/fact.dart';

/// Immutable snapshot of a rendered Adaptive Card's document state.
///
/// Combines an unchanged **baseline** (deep copy of host JSON) with sparse
/// **overlays** for runtime patches. Widgets and actions should read merged
/// maps via resolved element/action providers, not mutate
/// [baseline] directly.
@immutable
class AdaptiveCardDocument {
  /// Creates a document snapshot.
  const AdaptiveCardDocument({
    required this.baseline,
    required this.nodesById,
    required this.overlaysById,
    required this.actionOverlaysById,
    required this.revision,
  });

  /// Deep-copied card JSON baseline (host input).
  final Map<String, dynamic> baseline;

  /// Index of baseline nodes by element id (natural ids only).
  final Map<String, Map<String, dynamic>> nodesById;

  /// Sparse runtime overlays keyed by element id.
  final Map<String, ElementOverlay> overlaysById;

  /// Sparse runtime overlays keyed by action id.
  final Map<String, ActionOverlay> actionOverlaysById;

  /// Monotonic revision to force provider updates when internals change.
  final int revision;

  /// Returns a copy with the given fields replaced.
  AdaptiveCardDocument copyWith({
    Map<String, dynamic>? baseline,
    Map<String, Map<String, dynamic>>? nodesById,
    Map<String, ElementOverlay>? overlaysById,
    Map<String, ActionOverlay>? actionOverlaysById,
    int? revision,
  }) {
    return AdaptiveCardDocument(
      baseline: baseline ?? this.baseline,
      nodesById: nodesById ?? this.nodesById,
      overlaysById: overlaysById ?? this.overlaysById,
      actionOverlaysById: actionOverlaysById ?? this.actionOverlaysById,
      revision: revision ?? this.revision,
    );
  }
}

/// Runtime overlay for a single element id.
///
/// Only non-null fields override the corresponding baseline JSON properties
/// when merged by `resolvedElementProvider`.
@immutable
class ElementOverlay {
  /// Creates an overlay patch for one element.
  const ElementOverlay({
    this.isVisible,
    this.inputValue,
    this.choices,
    this.queryCount,
    this.querySkip,
    this.querySearchText,
    this.errorMessage,
    this.isInvalid,
    this.text,
    this.isRequired,
    this.url,
    this.label,
    this.placeholder,
    this.facts,
    this.inlines,
    this.extensionPayloads,
    this.revealPasswordEnabled,
  });

  /// Overrides baseline `"isVisible"` when non-null.
  final bool? isVisible;

  /// Overrides baseline `"value"` on input elements when non-null.
  final Object? inputValue;

  /// Overrides baseline `"choices"` on `Input.ChoiceSet` when non-null.
  final List<Choice>? choices;

  /// Session override for `choices.data.count` (typeahead pagination).
  final int? queryCount;

  /// Session override for `choices.data.skip` (typeahead pagination).
  final int? querySkip;

  /// Current typeahead search text; not merged into resolved element JSON.
  final String? querySearchText;

  /// Overrides baseline `"errorMessage"` on input elements when non-null.
  final String? errorMessage;

  /// Host-driven validation flag merged into resolved `"isInvalid"`.
  final bool? isInvalid;

  /// Overrides baseline `"text"` on elements such as `TextBlock` when non-null.
  final String? text;

  /// Overrides baseline `"isRequired"` on input elements when non-null.
  final bool? isRequired;

  /// Overrides baseline `"url"` on `Image` / `Media` when non-null.
  final String? url;

  /// Overrides baseline `"label"` on inputs when non-null.
  final String? label;

  /// Overrides baseline `"placeholder"` on inputs when non-null.
  final String? placeholder;

  /// Overrides baseline `"facts"` on `FactSet` when non-null.
  final List<Fact>? facts;

  /// Replaces baseline `"inlines"` on `RichTextBlock` when non-null.
  final List<Map<String, dynamic>>? inlines;

  /// Optional-package overlay payloads keyed by extension id.
  final Map<String, Map<String, dynamic>>? extensionPayloads;

  /// Overrides the host `inputs.text.revealPasswordEnabled` default for one
  /// `Input.Text` password field when non-null.
  final bool? revealPasswordEnabled;

  /// Returns a copy with the given fields replaced.
  ElementOverlay copyWith({
    bool? isVisible,
    Object? inputValue,
    List<Choice>? choices,
    int? queryCount,
    int? querySkip,
    String? querySearchText,
    String? errorMessage,
    bool? isInvalid,
    String? text,
    bool? isRequired,
    String? url,
    String? label,
    String? placeholder,
    List<Fact>? facts,
    List<Map<String, dynamic>>? inlines,
    Map<String, Map<String, dynamic>>? extensionPayloads,
    bool? revealPasswordEnabled,
    bool clearInputValue = false,
    bool clearChoices = false,
    bool clearQueryCount = false,
    bool clearQuerySkip = false,
    bool clearQuerySearchText = false,
    bool clearErrorMessage = false,
    bool clearIsInvalid = false,
    bool clearText = false,
    bool clearIsRequired = false,
    bool clearUrl = false,
    bool clearLabel = false,
    bool clearPlaceholder = false,
    bool clearFacts = false,
    bool clearInlines = false,
    bool clearExtensionPayloads = false,
    bool clearRevealPasswordEnabled = false,
  }) {
    return ElementOverlay(
      isVisible: isVisible ?? this.isVisible,
      inputValue: clearInputValue ? null : (inputValue ?? this.inputValue),
      choices: clearChoices ? null : (choices ?? this.choices),
      queryCount: clearQueryCount ? null : (queryCount ?? this.queryCount),
      querySkip: clearQuerySkip ? null : (querySkip ?? this.querySkip),
      querySearchText: clearQuerySearchText
          ? null
          : (querySearchText ?? this.querySearchText),
      errorMessage: clearErrorMessage
          ? null
          : (errorMessage ?? this.errorMessage),
      isInvalid: clearIsInvalid ? null : (isInvalid ?? this.isInvalid),
      text: clearText ? null : (text ?? this.text),
      isRequired: clearIsRequired ? null : (isRequired ?? this.isRequired),
      url: clearUrl ? null : (url ?? this.url),
      label: clearLabel ? null : (label ?? this.label),
      placeholder: clearPlaceholder ? null : (placeholder ?? this.placeholder),
      facts: clearFacts ? null : (facts ?? this.facts),
      inlines: clearInlines ? null : (inlines ?? this.inlines),
      extensionPayloads: clearExtensionPayloads
          ? null
          : (extensionPayloads ?? this.extensionPayloads),
      revealPasswordEnabled: clearRevealPasswordEnabled
          ? null
          : (revealPasswordEnabled ?? this.revealPasswordEnabled),
    );
  }
}

/// Runtime overlay for a single action id.
///
/// Only non-null fields override the corresponding baseline JSON properties
/// when merged by the resolved action provider.
@immutable
class ActionOverlay {
  /// Creates an overlay patch for one action.
  const ActionOverlay({
    this.isEnabled,
    this.title,
    this.tooltip,
    this.iconUrl,
  });

  /// Overrides baseline `"isEnabled"` when non-null (AC 1.5, default true).
  final bool? isEnabled;

  /// Overrides baseline `"title"` when non-null.
  final String? title;

  /// Overrides baseline `"tooltip"` when non-null.
  final String? tooltip;

  /// Overrides baseline `"iconUrl"` when non-null.
  final String? iconUrl;

  /// Returns a copy with the given fields replaced.
  ActionOverlay copyWith({
    bool? isEnabled,
    String? title,
    String? tooltip,
    String? iconUrl,
    bool clearTitle = false,
    bool clearTooltip = false,
    bool clearIconUrl = false,
  }) {
    return ActionOverlay(
      isEnabled: isEnabled ?? this.isEnabled,
      title: clearTitle ? null : (title ?? this.title),
      tooltip: clearTooltip ? null : (tooltip ?? this.tooltip),
      iconUrl: clearIconUrl ? null : (iconUrl ?? this.iconUrl),
    );
  }
}
