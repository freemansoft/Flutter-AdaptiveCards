import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/src/action/action_type_registry.dart';
import 'package:flutter_adaptive_cards_fs/src/cards/adaptive_card_element.dart';
import 'package:flutter_adaptive_cards_fs/src/flutter_raw_adaptive_card.dart';
import 'package:flutter_adaptive_cards_fs/src/reference_resolver.dart';
import 'package:flutter_adaptive_cards_fs/src/registry.dart';
import 'package:flutter_adaptive_cards_fs/src/riverpod/providers.dart';
import 'package:flutter_adaptive_cards_fs/src/utils/adaptive_image_utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Mixin for widgets that are adaptive elements- widget and not state

mixin AdaptiveElementWidgetMixin on StatefulWidget {
  // this is an abstract method that everyone needs to implmenet

  /// implementers will need to provide the adaptive map
  Map<String, dynamic> get adaptiveMap;

  /// implementers will need to provide the id
  String get id;
}

mixin ProviderScopeMixin<T extends StatefulWidget> on State<T> {
  ProviderContainer get _container => ProviderScope.containerOf(context);

  RawAdaptiveCardState get rawRootCardWidgetState =>
      _container.read(rawAdaptiveCardStateProvider);

  CardTypeRegistry get cardTypeRegistry => _container.read(cardTypeRegistryProvider);

  ActionTypeRegistry get actionTypeRegistry =>
      _container.read(actionTypeRegistryProvider);

  AdaptiveCardElementState get adaptiveCardElementState =>
      _container.read(adaptiveCardElementStateProvider);

  ReferenceResolver get styleResolver => _container.read(styleReferenceResolverProvider);
}

mixin AdaptiveElementMixin<T extends AdaptiveElementWidgetMixin> on State<T> {
  String get id => widget.id;

  String? get style => (adaptiveMap['style'] as String?)?.toLowerCase();

  Map<String, dynamic> get adaptiveMap => widget.adaptiveMap;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdaptiveElementMixin &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  void dispose() {
    super.dispose();
  }

  BoxFit calculateBackgroundImageFit(String? fillMode) {
    final myFillMode = fillMode?.toLowerCase();
    switch (myFillMode) {
      case 'repeatvertically':
      case 'repeathorizontally':
      case 'repeat':
        return BoxFit.none;
      default:
        return BoxFit.cover;
    }
  }

  ImageRepeat calculateBackgroundImageRepeat(String? fillMode) {
    final myFillMode = fillMode?.toLowerCase();
    switch (myFillMode) {
      case 'repeatvertically':
        return ImageRepeat.repeatY;
      case 'repeathorizontally':
        return ImageRepeat.repeatX;
      case 'repeat':
        return ImageRepeat.repeat;
      default:
        return ImageRepeat.noRepeat;
    }
  }

  /// Reliable image loader that handles when image not found
  /// Cards that support background images include
  /// AdaptiveCard, Column, Container, TableCell, Authentication
  Widget getBackgroundImage(
    String url, {
    ImageRepeat repeat = ImageRepeat.noRepeat,
    BoxFit fit = BoxFit.cover,
  }) {
    return AdaptiveImageUtils.getImage(url, fit: fit, semanticsLabel: null);
  }

  /// Reliable image provider loader that handles base64 and network images
  ImageProvider getBackgroundImageProvider(String url) {
    return AdaptiveImageUtils.getImageProvider(url);
  }

  /// internal helper to resolve the background image properties from either a string or a map
  ({String url, BoxFit fit, ImageRepeat repeat})? resolveBackgroundImage(
    dynamic backgroundImage,
  ) {
    if (backgroundImage == null) return null;

    if (backgroundImage is String) {
      return (
        url: backgroundImage,
        fit: BoxFit.cover,
        repeat: ImageRepeat.noRepeat,
      );
    }

    if (backgroundImage is Map && backgroundImage['url'] != null) {
      final url = backgroundImage['url'];
      final fillMode = backgroundImage['fillMode']?.toString().toLowerCase();

      return (
        url: url,
        fit: calculateBackgroundImageFit(fillMode),
        repeat: calculateBackgroundImageRepeat(fillMode),
      );
    }

    return null;
  }

  /// JSON schema aware version of getBackgroundImage
  Widget? getBackgroundImageFromMap(Map element) {
    final props = resolveBackgroundImage(element['backgroundImage']);
    if (props == null) return null;

    return getBackgroundImage(props.url, repeat: props.repeat, fit: props.fit);
  }

  /// JSON schema aware BoxDecoration wrapper of getDecorationImageFromMap
  BoxDecoration getDecorationFromMap(Map element, {Color? backgroundColor}) {
    final decorationImage = getDecorationImageFromMap(element);
    return BoxDecoration(image: decorationImage, color: backgroundColor);
  }

  /// JSON schema aware DecorationImage wrapper of DecorationImage
  /// Cards that support background images include
  /// AdaptiveCard, Column, Container, TableCell, Authentication
  DecorationImage? getDecorationImageFromMap(Map element) {
    final props = resolveBackgroundImage(element['backgroundImage']);
    if (props == null) return null;

    return DecorationImage(
      image: getBackgroundImageProvider(props.url),
      repeat: props.repeat,
      fit: props.fit,
    );
  }
}

bool backgroundImageSpecified(Map element) {
  final backgroundImage = element['backgroundImage'];
  if (backgroundImage == null) return false;

  if (backgroundImage is String) {
    return true;
  }

  if (backgroundImage is Map && backgroundImage['url'] != null) {
    return true;
  }

  return false;
}

mixin AdaptiveActionMixin<T extends AdaptiveElementWidgetMixin> on State<T>
    implements AdaptiveElementMixin<T> {
  String get title => adaptiveMap['title'] as String? ?? '';
  String? get tooltip => adaptiveMap['tooltip'] as String?;
}

/// Subscribes to [resolvedActionProvider] for AC 1.5 `isEnabled` (default true).
mixin AdaptiveActionStateMixin<T extends AdaptiveElementWidgetMixin> on State<T>
    implements AdaptiveElementMixin<T> {
  bool _actionEnabled = true;
  ProviderSubscription<Map<String, dynamic>?>? _actionStateSubscription;

  /// Whether the action accepts presses per merged baseline + overlay.
  bool get actionEnabled => _actionEnabled;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _actionStateSubscription?.close();
    final container = ProviderScope.containerOf(context);
    _actionStateSubscription = container.listen<Map<String, dynamic>?>(
      resolvedActionProvider(id),
      (previous, next) {
        final enabled = next?['isEnabled'] != false;
        if (enabled == _actionEnabled) return;
        setState(() => _actionEnabled = enabled);
      },
      fireImmediately: true,
    );
  }

  @override
  void dispose() {
    _actionStateSubscription?.close();
    _actionStateSubscription = null;
    super.dispose();
  }
}

mixin AdaptiveInputMixin<T extends AdaptiveElementWidgetMixin> on State<T>
    implements AdaptiveElementMixin<T> {
  late String value;
  late String placeholder;
  late String? errorMessage;
  bool overlayValidationError = false;
  ProviderSubscription<Map<String, dynamic>?>? _inputValueSubscription;

  /// Local required-field / validator error OR host overlay `isInvalid`.
  bool get showValidationError => stateHasError || overlayValidationError;

  /// Widget-local validation flag (required checks, Form validators).
  bool stateHasError = false;

  @override
  void initState() {
    super.initState();
    value = adaptiveMap['value'].toString() == 'null'
        ? ''
        : adaptiveMap['value'].toString();

    placeholder =
        adaptiveMap['placeholder'] as String? ??
        adaptiveMap['label'] as String? ??
        '';

    errorMessage = adaptiveMap['errorMessage'] as String?;
    overlayValidationError = adaptiveMap['isInvalid'] == true;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _inputValueSubscription?.close();
    final container = ProviderScope.containerOf(context);
    _inputValueSubscription = container.listen<Map<String, dynamic>?>(
      resolvedElementProvider(id),
      (previous, next) {
        final nextValue = next?['value'];
        final nextString = nextValue?.toString() ?? '';
        final nextError = next?['errorMessage'] as String?;
        final nextInvalid = next?['isInvalid'] == true;
        final valueChanged = nextString != value;
        final errorChanged =
            nextError != errorMessage || nextInvalid != overlayValidationError;
        if (!valueChanged && !errorChanged) return;
        setState(() {
          if (valueChanged) {
            value = nextString;
            onDocumentValueChanged(nextValue);
          }
          if (errorChanged) {
            errorMessage = nextError;
            overlayValidationError = nextInvalid;
          }
        });
      },
      fireImmediately: true,
    );
  }

  @override
  void dispose() {
    _inputValueSubscription?.close();
    _inputValueSubscription = null;
    super.dispose();
  }

  void setDocumentInputValue(Object? newValue) {
    final container = ProviderScope.containerOf(context);
    container.read(adaptiveCardDocumentProvider.notifier).setInputValue(id, newValue);
  }

  /// Subclasses can override to sync controllers from document changes.
  void onDocumentValueChanged(Object? valueFromDocument) {}

  /// Input cards implement this to copy their state **to** the map
  void appendInput(Map map);

  /// Input cards implement this as a way of loading state from a Map, `inputData`
  void initInput(Map map);

  /// Input card types implement this as a way of changing their state, currently only choice_set
  void loadInput(Map map) {}

  /// this is a prototype that is overridden by the input fields
  /// to check if they are required and there is a value
  bool checkRequired();

  void resetInput() {
    // Default implementation: reset to initial value to the map value
    if (adaptiveMap.containsKey('value')) {
      assert(() {
        developer.log(
          'resetting value to ${adaptiveMap['value']} string for $id',
          name: runtimeType.toString(),
        );
        return true;
      }());
      value = adaptiveMap['value'].toString();
    } else {
      assert(() {
        developer.log(
          'resetting value to empty string for $id',
          name: runtimeType.toString(),
        );
        return true;
      }());
      value = ''; // default value for inputs that don't have one
    }
    // Subclasses should override update their text controllers etc.
  }
}

mixin AdaptiveTextualInputMixin<T extends AdaptiveElementWidgetMixin>
    on State<T>
    implements AdaptiveInputMixin<T> {
  @override
  void initState() {
    super.initState();
  }
}

mixin AdaptiveVisibilityMixin<T extends AdaptiveElementWidgetMixin> on State<T>
    implements AdaptiveElementMixin<T> {
  late bool isVisible;
  ProviderSubscription<Map<String, dynamic>?>? _visibilitySubscription;

  bool _parseIsVisible(Object? value) {
    if (value == null) return true;
    if (value is bool) return value;
    if (value is String) return value.toLowerCase() == 'true';
    return true;
  }

  @override
  void initState() {
    super.initState();
    isVisible = true;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _visibilitySubscription?.close();

    final container = ProviderScope.containerOf(context);
    _visibilitySubscription = container.listen<Map<String, dynamic>?>(
      resolvedElementProvider(id),
      (previous, next) {
        final visible = _parseIsVisible(next?['isVisible']);
        if (visible == isVisible) return;
        setState(() => isVisible = visible);
      },
      fireImmediately: true,
    );
  }

  @override
  void dispose() {
    _visibilitySubscription?.close();
    _visibilitySubscription = null;
    super.dispose();
  }

  /// Update visibility and trigger rebuild
  void setIsVisible({required bool visible}) {
    final container = ProviderScope.containerOf(context);
    container
        .read(adaptiveCardDocumentProvider.notifier)
        .setVisibility(id, visible: visible);
  }
}
