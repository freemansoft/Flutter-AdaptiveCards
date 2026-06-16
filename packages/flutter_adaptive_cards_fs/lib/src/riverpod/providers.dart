// The patch tool sometimes drops the trailing newline; silence until stable.

import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/src/action/action_type_registry.dart';
import 'package:flutter_adaptive_cards_fs/src/cards/adaptive_card_element.dart';
import 'package:flutter_adaptive_cards_fs/src/flutter_raw_adaptive_card.dart';
import 'package:flutter_adaptive_cards_fs/src/models/choice.dart';
import 'package:flutter_adaptive_cards_fs/src/models/fact.dart';
import 'package:flutter_adaptive_cards_fs/src/models/text_run.dart';
import 'package:flutter_adaptive_cards_fs/src/reference_resolver.dart';
import 'package:flutter_adaptive_cards_fs/src/registry.dart';
import 'package:flutter_adaptive_cards_fs/src/riverpod/adaptive_card_document.dart';
import 'package:flutter_adaptive_cards_fs/src/riverpod/adaptive_card_document_notifier.dart';
import 'package:flutter_adaptive_cards_fs/src/riverpod/show_card_ui_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Host-supplied user id for root-card `refresh.userIds` auto-refresh gating.
final currentUserIdProvider = Provider<String?>(
  (ref) => null,
);

/// Card-scoped element type registry; overridden per [RawAdaptiveCard].
final cardTypeRegistryProvider = Provider<CardTypeRegistry>(
  (ref) => const CardTypeRegistry(),
);

/// Card-scoped action type registry; overridden per [RawAdaptiveCard].
final actionTypeRegistryProvider = Provider<ActionTypeRegistry>(
  (ref) => const DefaultActionTypeRegistry(),
);

/// The [RawAdaptiveCardState] for the current raw-card [ProviderScope].
final rawAdaptiveCardStateProvider = Provider<RawAdaptiveCardState>(
  (ref) =>
      throw UnimplementedError('rawAdaptiveCardStateProvider override missing'),
);

/// The [AdaptiveCardElementState] for the current card-element [ProviderScope].
final adaptiveCardElementStateProvider = Provider<AdaptiveCardElementState>(
  (ref) => throw UnimplementedError(
    'adaptiveCardElementStateProvider override missing',
  ),
);

/// HostConfig/theme resolver for the current raw-card scope (not registries).
final styleReferenceResolverProvider = Provider<ReferenceResolver>(
  (ref) => throw UnimplementedError(
    'styleReferenceResolverProvider override missing',
  ),
);

/// Deep-copied card JSON baseline for the current raw-card scope.
final baselineMapProvider = Provider<Map<String, dynamic>>(
  (ref) => throw UnimplementedError('baselineMapProvider override missing'),
);

/// Document notifier: baseline index + runtime overlays (inputs, visibility).
final adaptiveCardDocumentProvider =
    NotifierProvider<AdaptiveCardDocumentNotifier, AdaptiveCardDocument>(
      AdaptiveCardDocumentNotifier.new,
    );

/// Expanded ShowCard target id for the current [AdaptiveCardElement] scope.
final expandedShowCardIdProvider =
    NotifierProvider<ExpandedShowCardIdNotifier, String?>(
      ExpandedShowCardIdNotifier.new,
    );

/// Merged baseline + overlay map for the given element id; `null` if unknown.
final Provider<Map<String, dynamic>?> Function(String id)
resolvedElementProvider = Provider.family<Map<String, dynamic>?, String>(
  (ref, id) {
    final doc = ref.watch(adaptiveCardDocumentProvider);
    final registry = ref.watch(cardTypeRegistryProvider);
    final baselineNode = doc.nodesById[id];
    if (baselineNode == null) return null;
    final overlay = doc.overlaysById[id];
    final merged = Map<String, dynamic>.from(baselineNode);
    if (overlay?.isVisible != null) {
      merged['isVisible'] = overlay!.isVisible;
    }
    if (overlay?.inputValue != null) {
      merged['value'] = overlay!.inputValue;
    }
    if (overlay?.choices != null) {
      merged['choices'] = choicesToJsonList(overlay!.choices!);
    }
    if (overlay?.facts != null) {
      merged['facts'] = factsToJsonList(overlay!.facts!);
    }
    if (overlay?.inlines != null) {
      merged['inlines'] = inlinesToJsonList(overlay!.inlines!);
    }
    if (overlay?.errorMessage != null) {
      merged['errorMessage'] = overlay!.errorMessage;
    }
    if (overlay?.isInvalid != null) {
      merged['isInvalid'] = overlay!.isInvalid;
    }
    if (overlay?.text != null) {
      merged['text'] = overlay!.text;
    }
    if (overlay?.isRequired != null) {
      merged['isRequired'] = overlay!.isRequired;
    }
    if (overlay?.url != null) {
      final type = merged['type'] as String?;
      if (type == 'Media') {
        final rawSources = merged['sources'];
        final List<Map<String, dynamic>> sources;
        if (rawSources is List && rawSources.isNotEmpty) {
          sources = rawSources
              .map((entry) => Map<String, dynamic>.from(entry as Map))
              .toList();
          sources[0] = Map<String, dynamic>.from(sources[0])
            ..['url'] = overlay!.url;
        } else {
          sources = [
            {'url': overlay!.url},
          ];
        }
        merged['sources'] = sources;
      } else {
        merged['url'] = overlay!.url;
      }
    }
    if (overlay?.label != null) {
      merged['label'] = overlay!.label;
    }
    if (overlay?.placeholder != null) {
      merged['placeholder'] = overlay!.placeholder;
    }
    if (overlay?.queryCount != null || overlay?.querySkip != null) {
      final choicesData = Map<String, dynamic>.from(
        (merged['choices.data'] as Map<dynamic, dynamic>?)?.map(
              (key, value) => MapEntry(key.toString(), value),
            ) ??
            const {},
      );
      if (overlay!.queryCount != null) {
        choicesData['count'] = overlay.queryCount;
      }
      if (overlay.querySkip != null) {
        choicesData['skip'] = overlay.querySkip;
      }
      merged['choices.data'] = choicesData;
    }
    final elementType = merged['type']?.toString() ?? '';
    final extensionPayloads = overlay?.extensionPayloads;
    if (extensionPayloads != null) {
      for (final extension in registry.overlayExtensions.extensions) {
        if (!extension.appliesTo(elementType)) continue;
        final payload = extensionPayloads[extension.id];
        if (payload == null || payload.isEmpty) continue;
        extension.mergeResolved(merged, payload);
      }
    }
    return merged;
  },
).call;

/// Merged baseline + overlay map for the given action id; `null` if unknown.
final Provider<Map<String, dynamic>?> Function(String id)
resolvedActionProvider = Provider.family<Map<String, dynamic>?, String>(
  (ref, id) {
    final doc = ref.watch(adaptiveCardDocumentProvider);
    final baselineNode = doc.nodesById[id];
    if (baselineNode == null) return null;
    final type = baselineNode['type'] as String?;
    if (type == null || !type.startsWith('Action.')) return null;

    final overlay = doc.actionOverlaysById[id];
    final merged = Map<String, dynamic>.from(baselineNode);
    if (overlay?.isEnabled != null) {
      merged['isEnabled'] = overlay!.isEnabled;
    }
    if (overlay?.title != null) {
      merged['title'] = overlay!.title;
    }
    if (overlay?.tooltip != null) {
      merged['tooltip'] = overlay!.tooltip;
    }
    if (overlay?.iconUrl != null) {
      merged['iconUrl'] = overlay!.iconUrl;
    }
    return merged;
  },
).call;

/// Returns the current theme brightness from [context] (for HostConfig selection).
Brightness adaptiveCardBrightnessOf(BuildContext context) =>
    Theme.of(context).brightness;
