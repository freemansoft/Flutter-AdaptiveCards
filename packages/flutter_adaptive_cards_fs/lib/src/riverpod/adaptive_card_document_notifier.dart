import 'package:flutter_adaptive_cards_fs/src/models/adaptive_card_update.dart';
import 'package:flutter_adaptive_cards_fs/src/models/choice.dart';
import 'package:flutter_adaptive_cards_fs/src/riverpod/adaptive_card_document.dart';
import 'package:flutter_adaptive_cards_fs/src/riverpod/providers.dart';
import 'package:flutter_adaptive_cards_fs/src/utils/utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Riverpod notifier for card document state (baseline JSON + runtime overlays).
///
/// Seeded from [baselineMapProvider] on build. Public methods write sparse
/// [ElementOverlay] entries rather than mutating the host baseline map.
/// Scoped to one `RawAdaptiveCard` via `adaptiveCardDocumentProvider`.
class AdaptiveCardDocumentNotifier extends Notifier<AdaptiveCardDocument> {
  @override
  AdaptiveCardDocument build() {
    final baseline = ref.watch(baselineMapProvider);
    final nodesById = _indexNodesById(baseline);
    return AdaptiveCardDocument(
      baseline: baseline,
      nodesById: nodesById,
      overlaysById: const {},
      actionOverlaysById: const {},
      revision: 0,
    );
  }

  /// Sets [visible] for [id], preserving other overlay fields.
  void setVisibility(String id, {required bool visible}) {
    _updateOverlay(
      id,
      (current) => (current ?? const ElementOverlay()).copyWith(
        isVisible: visible,
      ),
    );
  }

  /// Flips effective visibility for [id] (overlay or baseline, then inverted).
  void toggleVisibility(String id) {
    final baselineNode = state.nodesById[id];
    if (baselineNode == null) return;

    final baselineVisible = _parseIsVisible(baselineNode['isVisible']);
    final overlay = state.overlaysById[id];
    final currentVisible = overlay?.isVisible ?? baselineVisible;
    setVisibility(id, visible: !currentVisible);
  }

  /// Records [value] for input [id], preserving other overlay fields.
  ///
  /// Clears host-driven validation overlays so editing clears error state.
  void setInputValue(String id, Object? value) {
    _updateOverlay(
      id,
      (current) => (current ?? const ElementOverlay()).copyWith(
        inputValue: value,
        clearIsInvalid: true,
        clearErrorMessage: true,
      ),
    );
  }

  /// Sets host-driven validation state for input [id].
  void setInputError(
    String id, {
    String? errorMessage,
    bool? isInvalid,
  }) {
    _updateOverlay(
      id,
      (current) => (current ?? const ElementOverlay()).copyWith(
        errorMessage: errorMessage,
        isInvalid: isInvalid,
      ),
    );
  }

  /// Replaces effective `"text"` for element [id] (e.g. `TextBlock`).
  void setText(String id, String text) {
    _updateOverlay(
      id,
      (current) => (current ?? const ElementOverlay()).copyWith(text: text),
    );
  }

  /// Clears text overlay for element [id].
  void clearText(String id) {
    _updateOverlay(
      id,
      (current) =>
          (current ?? const ElementOverlay()).copyWith(clearText: true),
    );
  }

  /// Clears validation overlays for input [id].
  void clearInputError(String id) {
    _updateOverlay(
      id,
      (current) => (current ?? const ElementOverlay()).copyWith(
        clearErrorMessage: true,
        clearIsInvalid: true,
      ),
    );
  }

  /// Sets whether action [id] is enabled (AC 1.5 `isEnabled`).
  void setActionEnabled(String id, {required bool enabled}) {
    _updateActionOverlay(
      id,
      (current) => (current ?? const ActionOverlay()).copyWith(
        isEnabled: enabled,
      ),
    );
  }

  /// Bulk-updates action enabled state by id.
  void setActionsEnabled(Map<String, bool> states) {
    final overlays = Map<String, ActionOverlay>.from(state.actionOverlaysById);
    for (final entry in states.entries) {
      if (!_isActionId(entry.key)) continue;
      overlays[entry.key] = (overlays[entry.key] ?? const ActionOverlay())
          .copyWith(isEnabled: entry.value);
    }
    state = state.copyWith(
      actionOverlaysById: overlays,
      revision: state.revision + 1,
    );
  }

  /// Seeds input values from a host map (e.g. `RawAdaptiveCard.initData`).
  void seedInputValues(Map<String, Object?> values) {
    applyUpdates(
      elements: values.entries
          .where((e) => state.nodesById.containsKey(e.key))
          .map((e) => AdaptiveElementUpdate(id: e.key, value: e.value)),
    );
  }

  /// Applies sparse overlay patches in one revision bump.
  void applyUpdates({
    Iterable<AdaptiveElementUpdate> elements = const [],
    Iterable<AdaptiveActionUpdate> actions = const [],
  }) {
    final elementOverlays = Map<String, ElementOverlay>.from(
      state.overlaysById,
    );
    final actionOverlays = Map<String, ActionOverlay>.from(
      state.actionOverlaysById,
    );
    var changed = false;

    for (final update in elements) {
      if (!state.nodesById.containsKey(update.id)) continue;
      if (_isActionId(update.id)) continue;

      elementOverlays[update.id] = _mergeElementUpdate(
        elementOverlays[update.id],
        update,
      );
      changed = true;
    }

    for (final update in actions) {
      if (!_isActionId(update.id)) continue;
      actionOverlays[update.id] = _mergeActionUpdate(
        actionOverlays[update.id],
        update,
      );
      changed = true;
    }

    if (!changed) return;

    state = state.copyWith(
      overlaysById: elementOverlays,
      actionOverlaysById: actionOverlays,
      revision: state.revision + 1,
    );
  }

  /// Sets whether input [id] is required at runtime.
  void setIsRequired(String id, {required bool required}) {
    _updateOverlay(
      id,
      (current) => (current ?? const ElementOverlay()).copyWith(
        isRequired: required,
      ),
    );
  }

  /// Clears `isRequired` overlay for [id].
  void clearIsRequired(String id) {
    _updateOverlay(
      id,
      (current) => (current ?? const ElementOverlay()).copyWith(
        clearIsRequired: true,
      ),
    );
  }

  /// Replaces effective `"url"` for element [id] (e.g. `Image`).
  void setUrl(String id, String url) {
    _updateOverlay(
      id,
      (current) => (current ?? const ElementOverlay()).copyWith(url: url),
    );
  }

  /// Clears `url` overlay for [id].
  void clearUrl(String id) {
    _updateOverlay(
      id,
      (current) => (current ?? const ElementOverlay()).copyWith(clearUrl: true),
    );
  }

  /// Parses initData / server patch maps into element and action updates.
  ({
    List<AdaptiveElementUpdate> elements,
    List<AdaptiveActionUpdate> actions,
  })
  updatesFromPatchMap(Map<String, Object?> byId) {
    return AdaptiveCardDocumentNotifier.updatesFromPatchMapWithNodes(
      byId,
      nodesById: state.nodesById,
    );
  }

  /// Parses patch maps using [nodesById] to route `Action.*` ids correctly.
  static ({
    List<AdaptiveElementUpdate> elements,
    List<AdaptiveActionUpdate> actions,
  })
  updatesFromPatchMapWithNodes(
    Map<String, Object?> byId, {
    required Map<String, Map<String, dynamic>> nodesById,
  }) {
    final elements = <AdaptiveElementUpdate>[];
    final actions = <AdaptiveActionUpdate>[];

    for (final entry in byId.entries) {
      final id = entry.key;
      final raw = entry.value;
      final isAction = _isActionIdStatic(id, nodesById);

      if (raw is! Map) {
        if (isAction) continue;
        elements.add(AdaptiveElementUpdate(id: id, value: raw));
        continue;
      }

      final patch = Map<String, dynamic>.from(raw);
      if (isAction) {
        actions.add(
          AdaptiveActionUpdate(
            id: id,
            isEnabled: patch['isEnabled'] as bool?,
            title: patch['title'] as String?,
            tooltip: patch['tooltip'] as String?,
            clearTitle: patch['clearTitle'] == true,
            clearTooltip: patch['clearTooltip'] == true,
          ),
        );
        continue;
      }

      elements.add(
        AdaptiveElementUpdate(
          id: id,
          isVisible: patch['isVisible'] as bool?,
          value: patch.containsKey('value') && patch['value'] != null
              ? patch['value']
              : null,
          errorMessage: patch['errorMessage'] as String?,
          isInvalid: patch['isInvalid'] as bool?,
          isRequired: patch['isRequired'] as bool?,
          url: patch['url'] as String?,
          text: patch['text'] as String?,
          label: patch['label'] as String?,
          placeholder: patch['placeholder'] as String?,
          choices: _choicesFromPatch(patch['choices']),
          queryCount: patch['queryCount'] as int?,
          querySkip: patch['querySkip'] as int?,
          querySearchText: patch['querySearchText'] as String?,
          clearValue:
              patch['clearValue'] == true ||
              (patch.containsKey('value') && patch['value'] == null),
          clearError: patch['clearError'] == true,
          clearChoices: patch['clearChoices'] == true,
          clearText: patch['clearText'] == true,
          clearIsRequired: patch['clearIsRequired'] == true,
          clearUrl: patch['clearUrl'] == true,
          clearLabel: patch['clearLabel'] == true,
          clearPlaceholder: patch['clearPlaceholder'] == true,
        ),
      );
    }

    return (elements: elements, actions: actions);
  }

  static bool _isActionIdStatic(
    String id,
    Map<String, Map<String, dynamic>> nodesById,
  ) {
    final type = nodesById[id]?['type'] as String?;
    return type != null && type.startsWith('Action.');
  }

  ElementOverlay _mergeElementUpdate(
    ElementOverlay? current,
    AdaptiveElementUpdate update,
  ) {
    var overlay = current ?? const ElementOverlay();

    if (update.clearError) {
      overlay = overlay.copyWith(clearErrorMessage: true, clearIsInvalid: true);
    }
    if (update.clearValue) {
      overlay = overlay.copyWith(clearInputValue: true);
    }
    if (update.clearChoices) {
      overlay = overlay.copyWith(clearChoices: true);
    }
    if (update.clearText) {
      overlay = overlay.copyWith(clearText: true);
    }
    if (update.clearIsRequired) {
      overlay = overlay.copyWith(clearIsRequired: true);
    }
    if (update.clearUrl) {
      overlay = overlay.copyWith(clearUrl: true);
    }
    if (update.clearLabel) {
      overlay = overlay.copyWith(clearLabel: true);
    }
    if (update.clearPlaceholder) {
      overlay = overlay.copyWith(clearPlaceholder: true);
    }

    if (update.isVisible != null) {
      overlay = overlay.copyWith(isVisible: update.isVisible);
    }
    if (update.errorMessage != null || update.isInvalid != null) {
      overlay = overlay.copyWith(
        errorMessage: update.errorMessage,
        isInvalid: update.isInvalid,
      );
    }
    if (update.text != null) {
      overlay = overlay.copyWith(text: update.text);
    }
    if (update.isRequired != null) {
      overlay = overlay.copyWith(isRequired: update.isRequired);
    }
    if (update.url != null) {
      overlay = overlay.copyWith(url: update.url);
    }
    if (update.label != null) {
      overlay = overlay.copyWith(label: update.label);
    }
    if (update.placeholder != null) {
      overlay = overlay.copyWith(placeholder: update.placeholder);
    }
    if (update.queryCount != null ||
        update.querySkip != null ||
        update.querySearchText != null) {
      overlay = overlay.copyWith(
        queryCount: update.queryCount,
        querySkip: update.querySkip,
        querySearchText: update.querySearchText,
      );
    }

    if (update.choices != null) {
      overlay = overlay.copyWith(
        choices: update.choices!.map((c) => c.toJson()).toList(),
        clearInputValue: update.value == null && !update.clearValue,
      );
    }

    if (update.value != null) {
      overlay = overlay.copyWith(
        inputValue: update.value,
        clearIsInvalid: true,
        clearErrorMessage: true,
      );
    }

    return overlay;
  }

  ActionOverlay _mergeActionUpdate(
    ActionOverlay? current,
    AdaptiveActionUpdate update,
  ) {
    var overlay = current ?? const ActionOverlay();

    if (update.clearTitle) {
      overlay = overlay.copyWith(clearTitle: true);
    }
    if (update.clearTooltip) {
      overlay = overlay.copyWith(clearTooltip: true);
    }
    if (update.isEnabled != null) {
      overlay = overlay.copyWith(isEnabled: update.isEnabled);
    }
    if (update.title != null) {
      overlay = overlay.copyWith(title: update.title);
    }
    if (update.tooltip != null) {
      overlay = overlay.copyWith(tooltip: update.tooltip);
    }

    return overlay;
  }

  static List<Choice>? _choicesFromPatch(Object? raw) {
    if (raw is! List) return null;
    return raw
        .map(
          (e) => Choice.fromJson(Map<String, dynamic>.from(e as Map)),
        )
        .toList();
  }

  /// Replaces effective `choices` for `Input.ChoiceSet` [id].
  ///
  /// Clears any `inputValue` overlay to match legacy `loadInput` behavior.
  void setChoices(String id, List<Choice> choices) {
    _updateOverlay(
      id,
      (current) => (current ?? const ElementOverlay()).copyWith(
        choices: choices.map((c) => c.toJson()).toList(),
        clearInputValue: true,
      ),
    );
  }

  /// Appends [choices] to baseline static + existing overlay (deduped by value).
  void appendChoices(String id, List<Choice> choices) {
    final byValue = <String, Map<String, dynamic>>{};
    for (final json in _effectiveChoiceJson(id)) {
      final value = json['value']?.toString() ?? '';
      byValue[value] = json;
    }
    for (final choice in choices) {
      byValue[choice.value] = choice.toJson();
    }
    _updateOverlay(
      id,
      (current) => (current ?? const ElementOverlay()).copyWith(
        choices: byValue.values.toList(),
      ),
    );
  }

  /// Updates typeahead session fields for `Input.ChoiceSet` [id].
  void setDataQuerySession(
    String id, {
    int? count,
    int? skip,
    String? searchText,
  }) {
    _updateOverlay(
      id,
      (current) => (current ?? const ElementOverlay()).copyWith(
        queryCount: count,
        querySkip: skip,
        querySearchText: searchText,
      ),
    );
  }

  /// Clears input value, choices, and validation overlays so resolved values
  /// fall back to baseline JSON. Visibility and action overlays are preserved.
  void resetAllInputs() {
    final overlays = Map<String, ElementOverlay>.from(state.overlaysById);
    final inputIds = state.nodesById.entries
        .where(
          (e) => (e.value['type'] as String?)?.startsWith('Input.') ?? false,
        )
        .map((e) => e.key);

    for (final id in inputIds) {
      final current = overlays[id];
      if (current == null) continue;
      overlays[id] = ElementOverlay(
        isVisible: current.isVisible,
        queryCount: current.queryCount,
        querySkip: current.querySkip,
        querySearchText: current.querySearchText,
        label: current.label,
        placeholder: current.placeholder,
        isRequired: current.isRequired,
      );
    }

    state = state.copyWith(
      overlaysById: overlays,
      revision: state.revision + 1,
    );
  }

  /// Returns submit data: overlay input value if set, else baseline `"value"`.
  Map<String, Object?> collectInputValues() {
    final result = <String, Object?>{};
    for (final entry in state.nodesById.entries) {
      final node = entry.value;
      final type = node['type'] as String?;
      if (type == null || !type.startsWith('Input.')) continue;

      final overlay = state.overlaysById[entry.key];
      result[entry.key] = overlay?.inputValue ?? node['value'];
    }
    return result;
  }

  void _updateOverlay(
    String id,
    ElementOverlay Function(ElementOverlay? current) merge,
  ) {
    final overlays = Map<String, ElementOverlay>.from(state.overlaysById);
    overlays[id] = merge(overlays[id]);
    state = state.copyWith(
      overlaysById: overlays,
      revision: state.revision + 1,
    );
  }

  void _updateActionOverlay(
    String id,
    ActionOverlay Function(ActionOverlay? current) merge,
  ) {
    final overlays = Map<String, ActionOverlay>.from(state.actionOverlaysById);
    overlays[id] = merge(overlays[id]);
    state = state.copyWith(
      actionOverlaysById: overlays,
      revision: state.revision + 1,
    );
  }

  bool _isActionId(String id) {
    final type = state.nodesById[id]?['type'] as String?;
    return type != null && type.startsWith('Action.');
  }

  List<Map<String, dynamic>> _effectiveChoiceJson(String id) {
    final baselineNode = state.nodesById[id];
    if (baselineNode == null) return const [];

    final overlay = state.overlaysById[id];
    if (overlay?.choices != null) {
      return overlay!.choices!;
    }

    final raw = baselineNode['choices'];
    if (raw is! List) return const [];
    return raw
        .map((e) => Map<String, dynamic>.from(e as Map<dynamic, dynamic>))
        .toList();
  }

  Map<String, Map<String, dynamic>> _indexNodesById(
    Map<String, dynamic> baseline,
  ) {
    final result = <String, Map<String, dynamic>>{};

    void visitNode(Object? node) {
      if (node is Map) {
        final map = Map<String, dynamic>.from(node);
        if (map.containsKey('type') && map.containsKey('id')) {
          result[loadId(map)] = map;
        }

        map.values.forEach(visitNode);
      } else if (node is List) {
        node.forEach(visitNode);
      }
    }

    visitNode(baseline);
    return result;
  }

  bool _parseIsVisible(Object? value) {
    if (value == null) return true;
    if (value is bool) return value;
    if (value is String) return value.toLowerCase() == 'true';
    return true;
  }
}
