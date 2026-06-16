import 'package:flutter_adaptive_cards_fs/src/models/adaptive_card_update.dart';
import 'package:flutter_adaptive_cards_fs/src/models/choice.dart';
import 'package:flutter_adaptive_cards_fs/src/models/fact.dart';
import 'package:flutter_adaptive_cards_fs/src/models/text_run.dart';
import 'package:flutter_adaptive_cards_fs/src/riverpod/adaptive_card_document.dart';
import 'package:flutter_adaptive_cards_fs/src/riverpod/element_overlay_extension.dart';
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

    final baselineVisible = parseIsVisible(baselineNode['isVisible']);
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

  /// Replaces effective `"facts"` for `FactSet` [id].
  void setFacts(String id, List<Fact> facts) {
    _updateOverlay(
      id,
      (current) => (current ?? const ElementOverlay()).copyWith(facts: facts),
    );
  }

  /// Clears facts overlay for [id]; effective facts revert to baseline JSON.
  void clearFacts(String id) {
    _updateOverlay(
      id,
      (current) =>
          (current ?? const ElementOverlay()).copyWith(clearFacts: true),
    );
  }

  /// Replaces effective `"inlines"` for `RichTextBlock` [id].
  void setInlines(String id, List<Map<String, dynamic>> inlines) {
    _updateOverlay(
      id,
      (current) => (current ?? const ElementOverlay()).copyWith(
        inlines: inlines.map(Map<String, dynamic>.from).toList(),
      ),
    );
  }

  /// Clears inlines overlay for [id]; effective inlines revert to baseline JSON.
  void clearInlines(String id) {
    _updateOverlay(
      id,
      (current) =>
          (current ?? const ElementOverlay()).copyWith(clearInlines: true),
    );
  }

  /// Patches optional-package overlay payload for [id] and [extensionId].
  void patchExtensionOverlay(
    String id,
    String extensionId,
    Map<String, dynamic> patch, {
    bool clearPayload = false,
  }) {
    final extension = ref
        .read(cardTypeRegistryProvider)
        .overlayExtensions
        .byId(extensionId);
    if (extension == null) return;

    _updateOverlay(id, (current) {
      final allPayloads = Map<String, Map<String, dynamic>>.from(
        current?.extensionPayloads ?? const {},
      );
      if (clearPayload) {
        allPayloads.remove(extensionId);
      } else {
        final merged = extension.mergePayload(
          current: allPayloads[extensionId] ?? const {},
          patch: patch,
        );
        if (merged.isEmpty) {
          allPayloads.remove(extensionId);
        } else {
          allPayloads[extensionId] = merged;
        }
      }
      return (current ?? const ElementOverlay()).copyWith(
        extensionPayloads: allPayloads.isEmpty ? null : allPayloads,
        clearExtensionPayloads: allPayloads.isEmpty,
      );
    });
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

  /// Removes the runtime `inputValue` overlay for input [id].
  void clearInputValue(String id) {
    _updateOverlay(
      id,
      (current) => (current ?? const ElementOverlay()).copyWith(
        clearInputValue: true,
        clearIsInvalid: true,
        clearErrorMessage: true,
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
    final capabilities = ref.read(cardTypeRegistryProvider).overlayCapabilities;
    assert(() {
      for (final update in elements) {
        final node = state.nodesById[update.id];
        if (node == null) continue;
        final type = node['type'] as String?;
        if (type == null || type.startsWith('Action.')) continue;
        final issues = capabilities.validateElementUpdate(type, update);
        if (issues.isNotEmpty) {
          throw AssertionError(issues.join('; '));
        }
      }
      for (final update in actions) {
        final type = state.nodesById[update.id]?['type'] as String?;
        if (type == null) continue;
        final issues = capabilities.validateActionUpdate(type, update);
        if (issues.isNotEmpty) {
          throw AssertionError(issues.join('; '));
        }
      }
      return true;
    }());

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
      overlayExtensions: ref.read(cardTypeRegistryProvider).overlayExtensions,
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
    CardOverlayExtensionRegistry overlayExtensions =
        const CardOverlayExtensionRegistry(),
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
            iconUrl: patch['iconUrl'] as String?,
            clearTitle: patch['clearTitle'] == true,
            clearTooltip: patch['clearTooltip'] == true,
            clearIconUrl: patch['clearIconUrl'] == true,
          ),
        );
        continue;
      }

      final extensionPatches = <String, Map<String, dynamic>>{};
      final clearExtensions = <String>{};
      for (final extension in overlayExtensions.extensions) {
        final extracted = extension.patchFromHostMap(patch);
        if (extracted == null) continue;
        if (extracted['clearPayload'] == true) {
          clearExtensions.add(extension.id);
          continue;
        }
        extensionPatches[extension.id] = extracted;
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
          facts: _factsFromPatch(patch['facts']),
          clearFacts: patch['clearFacts'] == true,
          inlines: _inlinesFromPatch(patch['inlines']),
          clearInlines: patch['clearInlines'] == true,
          extensionPatches: extensionPatches.isEmpty ? null : extensionPatches,
          clearExtensions: clearExtensions,
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
    if (update.clearFacts) {
      overlay = overlay.copyWith(clearFacts: true);
    }
    if (update.clearInlines) {
      overlay = overlay.copyWith(clearInlines: true);
    }
    if (update.clearExtensions.isNotEmpty) {
      final payloads = Map<String, Map<String, dynamic>>.from(
        overlay.extensionPayloads ?? const {},
      );
      update.clearExtensions.forEach(payloads.remove);
      overlay = overlay.copyWith(
        extensionPayloads: payloads.isEmpty ? null : payloads,
        clearExtensionPayloads: payloads.isEmpty,
      );
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

    if (update.facts != null) {
      overlay = overlay.copyWith(facts: update.facts);
    }

    if (update.inlines != null) {
      overlay = overlay.copyWith(
        inlines: update.inlines!.map(Map<String, dynamic>.from).toList(),
      );
    }

    if (update.extensionPatches != null) {
      overlay = _mergeExtensionPatches(
        overlay,
        update.extensionPatches!,
      );
    }

    if (update.choices != null) {
      overlay = overlay.copyWith(
        choices: update.choices,
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
    if (update.clearIconUrl) {
      overlay = overlay.copyWith(clearIconUrl: true);
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
    if (update.iconUrl != null) {
      overlay = overlay.copyWith(iconUrl: update.iconUrl);
    }

    return overlay;
  }

  static List<Choice>? _choicesFromPatch(Object? raw) {
    if (raw is! List) return null;
    return choicesFromJsonList(raw);
  }

  static List<Fact>? _factsFromPatch(Object? raw) {
    if (raw is! List) return null;
    return factsFromJsonList(raw);
  }

  static List<Map<String, dynamic>>? _inlinesFromPatch(Object? raw) {
    if (raw is! List) return null;
    return inlinesFromJsonList(raw);
  }

  ElementOverlay _mergeExtensionPatches(
    ElementOverlay overlay,
    Map<String, Map<String, dynamic>> patches,
  ) {
    final registry = ref.read(cardTypeRegistryProvider).overlayExtensions;
    final payloads = Map<String, Map<String, dynamic>>.from(
      overlay.extensionPayloads ?? const {},
    );
    for (final entry in patches.entries) {
      final extension = registry.byId(entry.key);
      if (extension == null) continue;
      final merged = extension.mergePayload(
        current: payloads[entry.key] ?? const {},
        patch: entry.value,
      );
      if (merged.isEmpty) {
        payloads.remove(entry.key);
      } else {
        payloads[entry.key] = merged;
      }
    }
    return overlay.copyWith(
      extensionPayloads: payloads.isEmpty ? null : payloads,
      clearExtensionPayloads: payloads.isEmpty,
    );
  }

  /// Replaces effective `choices` for `Input.ChoiceSet` [id].
  ///
  /// Clears any `inputValue` overlay to match legacy `loadInput` behavior.
  void setChoices(String id, List<Choice> choices) {
    _updateOverlay(
      id,
      (current) => (current ?? const ElementOverlay()).copyWith(
        choices: choices,
        clearInputValue: true,
      ),
    );
  }

  /// Appends [choices] to baseline static + existing overlay (deduped by value).
  void appendChoices(String id, List<Choice> choices) {
    final byValue = <String, Choice>{};
    for (final choice in _effectiveChoices(id)) {
      byValue[choice.value] = choice;
    }
    for (final choice in choices) {
      byValue[choice.value] = choice;
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

  /// Factory-resets one input id: clears value, choices, validation,
  /// [ElementOverlay.isRequired], [ElementOverlay.label], and
  /// [ElementOverlay.placeholder] overlays so resolved fields match baseline
  /// JSON. Preserves input [ElementOverlay.isVisible] and typeahead session
  /// fields on that id.
  ///
  /// See [resetAllInputs] for batch reset and
  /// `docs/reactive-riverpod.md#reset-semantics`.
  void resetInput(String id) {
    resetInputs([id]);
  }

  /// Factory-resets the listed input ids in one revision using the same rules
  /// as [resetInput]. Unknown or non-input ids are skipped silently.
  void resetInputs(List<String> ids) {
    final overlays = Map<String, ElementOverlay>.from(state.overlaysById);
    var changed = false;

    for (final id in ids) {
      final node = state.nodesById[id];
      if (node == null) continue;
      final type = node['type'] as String?;
      if (type == null || !type.startsWith('Input.')) continue;

      final current = overlays[id];
      if (current == null) continue;

      _applyFactoryResetToOverlayMap(overlays, id, current);
      changed = true;
    }

    if (!changed) return;

    state = state.copyWith(
      overlaysById: overlays,
      revision: state.revision + 1,
    );
  }

  /// Factory-resets every `Input.*` id using the same rules as [resetInput].
  ///
  /// Clears overlay value, choices, validation, `isRequired`, `label`, and
  /// `placeholder` on inputs. Preserves input visibility and typeahead session
  /// overlays. Does not modify TextBlock text, Image url, or action overlays.
  void resetAllInputs() {
    final overlays = Map<String, ElementOverlay>.from(state.overlaysById);
    var changed = false;

    for (final entry in state.nodesById.entries) {
      final type = entry.value['type'] as String?;
      if (type == null || !type.startsWith('Input.')) continue;

      final current = overlays[entry.key];
      if (current == null) continue;

      _applyFactoryResetToOverlayMap(overlays, entry.key, current);
      changed = true;
    }

    if (!changed) return;

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

  /// Keeps visibility and typeahead session fields; strips factory-reset fields.
  void _applyFactoryResetToOverlayMap(
    Map<String, ElementOverlay> overlays,
    String id,
    ElementOverlay current,
  ) {
    final preserved = _factoryResetInputOverlay(current);
    if (preserved == null) {
      overlays.remove(id);
    } else {
      overlays[id] = preserved;
    }
  }

  ElementOverlay? _factoryResetInputOverlay(ElementOverlay current) {
    if (current.isVisible == null &&
        current.queryCount == null &&
        current.querySkip == null &&
        current.querySearchText == null) {
      return null;
    }
    return ElementOverlay(
      isVisible: current.isVisible,
      queryCount: current.queryCount,
      querySkip: current.querySkip,
      querySearchText: current.querySearchText,
    );
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

  List<Choice> _effectiveChoices(String id) {
    final baselineNode = state.nodesById[id];
    if (baselineNode == null) return const [];

    final overlay = state.overlaysById[id];
    if (overlay?.choices != null) {
      return overlay!.choices!;
    }

    return choicesFromJsonList(baselineNode['choices']);
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
}
