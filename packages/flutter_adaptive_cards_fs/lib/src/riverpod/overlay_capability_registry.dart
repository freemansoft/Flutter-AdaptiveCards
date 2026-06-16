import 'package:flutter/foundation.dart';
import 'package:flutter_adaptive_cards_fs/src/models/adaptive_card_update.dart';
import 'package:flutter_adaptive_cards_fs/src/riverpod/element_overlay_extension.dart';

/// Runtime overlay patch field on an element (`AdaptiveElementUpdate` / host map).
enum ElementOverlayField {
  /// Overrides baseline `"isVisible"`.
  isVisible('isVisible'),

  /// Overrides baseline `"value"` (inputs and display `Rating`).
  value('value'),

  /// Overrides baseline `"label"` on inputs.
  label('label'),

  /// Overrides baseline `"placeholder"` on inputs.
  placeholder('placeholder'),

  /// Overrides baseline `"isRequired"` on inputs.
  isRequired('isRequired'),

  /// Overrides baseline `"errorMessage"` on inputs.
  errorMessage('errorMessage'),

  /// Merged into baseline `"isInvalid"` on inputs.
  isInvalid('isInvalid'),

  /// Replaces baseline `"choices"` on `Input.ChoiceSet`.
  choices('choices'),

  /// Typeahead session: merged into `choices.data.count`.
  queryCount('queryCount'),

  /// Typeahead session: merged into `choices.data.skip`.
  querySkip('querySkip'),

  /// Typeahead search text (overlay only).
  querySearchText('querySearchText'),

  /// Overrides baseline `"text"` (`TextBlock`, `Badge`, …).
  text('text'),

  /// Overrides baseline `"url"` (`Image`, `Media`).
  url('url'),

  /// Replaces baseline `"facts"` on `FactSet`.
  facts('facts'),

  /// Replaces baseline `"inlines"` on `RichTextBlock`.
  inlines('inlines'),

  /// Optional-package payload (`extensionPatches` / registered extensions).
  extensionPayload('extensionPayload');

  /// Creates a field identifier with host [patchKey] name where applicable.
  const ElementOverlayField(this.patchKey);

  /// Key used in `applyUpdatesFromMap` for this field (not used for extension payload).
  final String patchKey;
}

/// Runtime overlay patch field on an action (`AdaptiveActionUpdate` / host map).
enum ActionOverlayField {
  /// Overrides baseline `"isEnabled"`.
  isEnabled('isEnabled'),

  /// Overrides baseline `"title"`.
  title('title'),

  /// Overrides baseline `"tooltip"`.
  tooltip('tooltip');

  /// Creates a field identifier with host [patchKey] name.
  const ActionOverlayField(this.patchKey);

  /// Key used in `applyUpdatesFromMap` for this field.
  final String patchKey;
}

/// Maps JSON element/action `type` strings to supported overlay fields.
///
/// Hosts use this to discover valid patches (see `docs/overlay-properties-by-type.md`)
/// and the library uses it for debug validation in `applyUpdates`.
@immutable
class OverlayCapabilityRegistry {
  /// Creates a registry scoped to optional [overlayExtensions] on the card.
  const OverlayCapabilityRegistry({
    this.overlayExtensions = const CardOverlayExtensionRegistry(),
  });

  /// Registered overlay extensions (e.g. charts) that add [ElementOverlayField.extensionPayload].
  final CardOverlayExtensionRegistry overlayExtensions;

  static const Set<ElementOverlayField> _visibilityOnly = {
    ElementOverlayField.isVisible,
  };

  static const Set<ElementOverlayField> _standardInputFields = {
    ElementOverlayField.isVisible,
    ElementOverlayField.value,
    ElementOverlayField.label,
    ElementOverlayField.placeholder,
    ElementOverlayField.isRequired,
    ElementOverlayField.errorMessage,
    ElementOverlayField.isInvalid,
  };

  static const Set<ElementOverlayField> _choiceSetExtraFields = {
    ElementOverlayField.choices,
    ElementOverlayField.queryCount,
    ElementOverlayField.querySkip,
    ElementOverlayField.querySearchText,
  };

  static const Set<ActionOverlayField> _standardActionFields = {
    ActionOverlayField.isEnabled,
    ActionOverlayField.title,
    ActionOverlayField.tooltip,
  };

  /// Supported element overlay fields for JSON [elementType].
  Set<ElementOverlayField> elementFieldsFor(String elementType) {
    if (elementType.startsWith('Input.')) {
      final fields = Set<ElementOverlayField>.from(_standardInputFields);
      if (elementType == 'Input.ChoiceSet') {
        fields.addAll(_choiceSetExtraFields);
      }
      return fields;
    }

    final fields = <ElementOverlayField>{..._visibilityOnly};
    if (elementType == 'TextBlock' || elementType == 'Badge') {
      fields.add(ElementOverlayField.text);
    }
    if (elementType == 'FactSet') {
      fields.add(ElementOverlayField.facts);
    }
    if (elementType == 'RichTextBlock') {
      fields.add(ElementOverlayField.inlines);
    }
    if (elementType == 'Image' || elementType == 'Media') {
      fields.add(ElementOverlayField.url);
    }
    if (elementType == 'Rating') {
      fields.add(ElementOverlayField.value);
    }

    if (_extensionAppliesTo(elementType)) {
      fields.add(ElementOverlayField.extensionPayload);
    }

    return fields;
  }

  /// Supported action overlay fields for JSON [actionType].
  Set<ActionOverlayField> actionFieldsFor(String actionType) {
    if (actionType.startsWith('Action.')) {
      return Set<ActionOverlayField>.from(_standardActionFields);
    }
    return const {};
  }

  /// Whether [field] affects UI for [elementType] in this registry scope.
  bool isElementFieldSupported(String elementType, ElementOverlayField field) {
    return elementFieldsFor(elementType).contains(field);
  }

  /// Whether [field] affects UI for [actionType] in this registry scope.
  bool isActionFieldSupported(String actionType, ActionOverlayField field) {
    return actionFieldsFor(actionType).contains(field);
  }

  /// Human-readable issues when [update] sets fields unsupported for [elementType].
  List<String> validateElementUpdate(
    String elementType,
    AdaptiveElementUpdate update,
  ) {
    final supported = elementFieldsFor(elementType);
    final issues = <String>[];

    for (final field in fieldsSetInElementUpdate(update)) {
      if (field == ElementOverlayField.extensionPayload) {
        issues.addAll(
          _validateExtensionPatches(elementType, update),
        );
        continue;
      }
      if (!supported.contains(field)) {
        issues.add(
          '${field.patchKey} is not supported for element type $elementType',
        );
      }
    }

    return issues;
  }

  /// Human-readable issues when [update] sets fields unsupported for [actionType].
  List<String> validateActionUpdate(
    String actionType,
    AdaptiveActionUpdate update,
  ) {
    final supported = actionFieldsFor(actionType);
    final issues = <String>[];

    for (final field in fieldsSetInActionUpdate(update)) {
      if (!supported.contains(field)) {
        issues.add(
          '${field.patchKey} is not supported for action type $actionType',
        );
      }
    }

    return issues;
  }

  bool _extensionAppliesTo(String elementType) {
    for (final extension in overlayExtensions.extensions) {
      if (extension.appliesTo(elementType)) {
        return true;
      }
    }
    return false;
  }

  List<String> _validateExtensionPatches(
    String elementType,
    AdaptiveElementUpdate update,
  ) {
    if (!_extensionAppliesTo(elementType)) {
      if (update.extensionPatches != null &&
          update.extensionPatches!.isNotEmpty) {
        return [
          'extensionPayload is not supported for element type $elementType (no overlay extension registered)',
        ];
      }
      if (update.clearExtensions.isNotEmpty) {
        return [
          'clearExtensions is not supported for element type $elementType (no overlay extension registered)',
        ];
      }
      return const [];
    }

    final issues = <String>[];
    final patches = update.extensionPatches;
    if (patches != null) {
      for (final entry in patches.entries) {
        final extension = overlayExtensions.byId(entry.key);
        if (extension == null) {
          issues.add(
            'Unknown overlay extension "${entry.key}" for element type '
            '$elementType',
          );
          continue;
        }
        if (!extension.appliesTo(elementType)) {
          issues.add(
            'Overlay extension "${entry.key}" does not apply to element type '
            '$elementType',
          );
          continue;
        }
        issues.addAll(
          _validateExtensionPatchKeys(extension, entry.value, elementType),
        );
      }
    }

    for (final extensionId in update.clearExtensions) {
      final extension = overlayExtensions.byId(extensionId);
      if (extension == null) {
        issues.add(
          'Unknown overlay extension "$extensionId" in clearExtensions for '
          'element type $elementType',
        );
      } else if (!extension.appliesTo(elementType)) {
        issues.add(
          'Overlay extension "$extensionId" does not apply to element type '
          '$elementType',
        );
      }
    }

    return issues;
  }

  List<String> _validateExtensionPatchKeys(
    ElementOverlayExtension extension,
    Map<String, dynamic> patch,
    String elementType,
  ) {
    if (patch.isEmpty) return const [];

    final allowed = extension.overlayPatchKeys;
    if (allowed.isEmpty) return const [];

    final issues = <String>[];
    for (final key in patch.keys) {
      if (!allowed.contains(key)) {
        issues.add(
          'Extension "${extension.id}" patch key "$key" is not supported for '
          'element type $elementType',
        );
      }
    }
    return issues;
  }
}

/// Returns overlay fields explicitly set on [update].
Set<ElementOverlayField> fieldsSetInElementUpdate(
  AdaptiveElementUpdate update,
) {
  final fields = <ElementOverlayField>{};
  if (update.isVisible != null) {
    fields.add(ElementOverlayField.isVisible);
  }
  if (update.value != null || update.clearValue) {
    fields.add(ElementOverlayField.value);
  }
  if (update.label != null || update.clearLabel) {
    fields.add(ElementOverlayField.label);
  }
  if (update.placeholder != null || update.clearPlaceholder) {
    fields.add(ElementOverlayField.placeholder);
  }
  if (update.isRequired != null || update.clearIsRequired) {
    fields.add(ElementOverlayField.isRequired);
  }
  if (update.errorMessage != null || update.clearError) {
    fields.add(ElementOverlayField.errorMessage);
  }
  if (update.isInvalid != null) {
    fields.add(ElementOverlayField.isInvalid);
  }
  if (update.choices != null || update.clearChoices) {
    fields.add(ElementOverlayField.choices);
  }
  if (update.queryCount != null) {
    fields.add(ElementOverlayField.queryCount);
  }
  if (update.querySkip != null) {
    fields.add(ElementOverlayField.querySkip);
  }
  if (update.querySearchText != null) {
    fields.add(ElementOverlayField.querySearchText);
  }
  if (update.text != null || update.clearText) {
    fields.add(ElementOverlayField.text);
  }
  if (update.url != null || update.clearUrl) {
    fields.add(ElementOverlayField.url);
  }
  if (update.facts != null || update.clearFacts) {
    fields.add(ElementOverlayField.facts);
  }
  if (update.inlines != null || update.clearInlines) {
    fields.add(ElementOverlayField.inlines);
  }
  if (update.extensionPatches != null && update.extensionPatches!.isNotEmpty) {
    fields.add(ElementOverlayField.extensionPayload);
  }
  if (update.clearExtensions.isNotEmpty) {
    fields.add(ElementOverlayField.extensionPayload);
  }
  return fields;
}

/// Returns overlay fields explicitly set on [update].
Set<ActionOverlayField> fieldsSetInActionUpdate(AdaptiveActionUpdate update) {
  final fields = <ActionOverlayField>{};
  if (update.isEnabled != null) {
    fields.add(ActionOverlayField.isEnabled);
  }
  if (update.title != null || update.clearTitle) {
    fields.add(ActionOverlayField.title);
  }
  if (update.tooltip != null || update.clearTooltip) {
    fields.add(ActionOverlayField.tooltip);
  }
  return fields;
}
