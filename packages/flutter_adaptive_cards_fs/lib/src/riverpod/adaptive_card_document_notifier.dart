// The patch tool sometimes drops the trailing newline; silence until stable.

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
  void setInputValue(String id, Object? value) {
    _updateOverlay(
      id,
      (current) => (current ?? const ElementOverlay()).copyWith(
        inputValue: value,
      ),
    );
  }

  /// Seeds input values from a host map (e.g. `RawAdaptiveCard.initData`).
  void seedInputValues(Map<String, Object?> values) {
    for (final entry in values.entries) {
      if (state.nodesById.containsKey(entry.key)) {
        setInputValue(entry.key, entry.value);
      }
    }
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

  /// Clears input value and dynamic choice overlays so resolved values fall
  /// back to baseline JSON. Visibility overlays are preserved.
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
        if (idIsNatural(map)) {
          final id = loadId(map);
          result[id] = map;
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
