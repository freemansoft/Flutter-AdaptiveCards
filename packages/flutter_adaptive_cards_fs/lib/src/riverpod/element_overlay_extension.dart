import 'package:flutter/foundation.dart';

/// Optional-package hook for merging extension-specific overlay fields.
///
/// Register instances on `CardTypeRegistry.overlayExtensions` (same opt-in
/// surface as `CardTypeRegistry.addedElements`).
@immutable
abstract class ElementOverlayExtension {
  /// Creates an overlay extension for `CardTypeRegistry.overlayExtensions`.
  const ElementOverlayExtension();

  /// Stable extension id used as the key in extension payload maps.
  String get id;

  /// Returns whether this extension merges overlays for [elementType].
  bool appliesTo(String elementType);

  /// Applies [payload] from the element's extension payload map onto [merged].
  void mergeResolved(
    Map<String, dynamic> merged,
    Map<String, dynamic> payload,
  );

  /// Merges [patch] into the stored payload for this extension.
  Map<String, dynamic> mergePayload({
    required Map<String, dynamic> current,
    required Map<String, dynamic> patch,
  });

  /// Extracts extension-relevant keys from a host patch map (`initData` / server).
  ///
  /// Return `null` when [hostPatch] contains no keys for this extension.
  Map<String, dynamic>? patchFromHostMap(Map<String, dynamic> hostPatch);

  /// Host / extension patch keys accepted for capability validation.
  ///
  /// When empty, extension payload keys are not validated beyond registration.
  Set<String> get overlayPatchKeys => const {};
}

/// Registry of [ElementOverlayExtension] instances for one card scope.
@immutable
class CardOverlayExtensionRegistry {
  /// Creates a registry with optional [extensions].
  const CardOverlayExtensionRegistry({this.extensions = const []});

  /// Registered overlay extensions for optional element packages.
  final List<ElementOverlayExtension> extensions;

  /// Returns the extension with [id], or `null` when not registered.
  ElementOverlayExtension? byId(String id) {
    for (final extension in extensions) {
      if (extension.id == id) {
        return extension;
      }
    }
    return null;
  }

  /// Combines this registry with [other]; [other] wins on id collision.
  CardOverlayExtensionRegistry merge(CardOverlayExtensionRegistry other) {
    final merged = <String, ElementOverlayExtension>{
      for (final extension in extensions) extension.id: extension,
      for (final extension in other.extensions) extension.id: extension,
    };
    return CardOverlayExtensionRegistry(extensions: merged.values.toList());
  }
}
