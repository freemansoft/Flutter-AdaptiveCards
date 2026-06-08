import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/src/action/action_type_registry.dart';
import 'package:flutter_adaptive_cards_fs/src/action/reset_inputs_executor.dart';
import 'package:flutter_adaptive_cards_fs/src/cards/adaptive_card_element.dart';
import 'package:flutter_adaptive_cards_fs/src/flutter_raw_adaptive_card.dart';
import 'package:flutter_adaptive_cards_fs/src/reference_resolver.dart';
import 'package:flutter_adaptive_cards_fs/src/registry.dart';
import 'package:flutter_adaptive_cards_fs/src/resolved_input_state.dart';
import 'package:flutter_adaptive_cards_fs/src/riverpod/providers.dart';
import 'package:flutter_adaptive_cards_fs/src/utils/adaptive_image_utils.dart';
import 'package:flutter_adaptive_cards_fs/src/utils/utils.dart';
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

  CardTypeRegistry get cardTypeRegistry =>
      _container.read(cardTypeRegistryProvider);

  ActionTypeRegistry get actionTypeRegistry =>
      _container.read(actionTypeRegistryProvider);

  AdaptiveCardElementState get adaptiveCardElementState =>
      _container.read(adaptiveCardElementStateProvider);

  ReferenceResolver get styleResolver =>
      _container.read(styleReferenceResolverProvider);
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

/// Subscribes to [resolvedActionProvider] for `isEnabled`, `title`, and `tooltip`.
mixin AdaptiveActionStateMixin<T extends AdaptiveElementWidgetMixin> on State<T>
    implements AdaptiveElementMixin<T> {
  bool _actionEnabled = true;
  String _actionTitle = '';
  String? _actionTooltip;
  ProviderSubscription<Map<String, dynamic>?>? _actionStateSubscription;

  /// Whether the action accepts presses per merged baseline + overlay.
  bool get actionEnabled => _actionEnabled;

  String get title => _actionTitle;

  String? get tooltip => _actionTooltip;

  @override
  void initState() {
    super.initState();
    _actionTitle = adaptiveMap['title'] as String? ?? '';
    _actionTooltip = adaptiveMap['tooltip'] as String?;
    _actionEnabled = adaptiveMap['isEnabled'] != false;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _actionStateSubscription?.close();
    final container = ProviderScope.containerOf(context);
    _actionStateSubscription = container.listen<Map<String, dynamic>?>(
      resolvedActionProvider(id),
      (previous, next) {
        final enabled = next?['isEnabled'] != false;
        final nextTitle = next?['title'] as String? ?? '';
        final nextTooltip = next?['tooltip'] as String?;
        if (enabled == _actionEnabled &&
            nextTitle == _actionTitle &&
            nextTooltip == _actionTooltip) {
          return;
        }
        setState(() {
          _actionEnabled = enabled;
          _actionTitle = nextTitle;
          _actionTooltip = nextTooltip;
        });
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

mixin AdaptiveInputMixin<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  AdaptiveElementWidgetMixin get _inputElement =>
      widget as AdaptiveElementWidgetMixin;

  String get _inputId => _inputElement.id;

  Map<String, dynamic> get _inputAdaptiveMap => _inputElement.adaptiveMap;

  Object? _lastValueChangedActionTriggeredValue;

  bool get _inputRequiresCommittedValueChangedAction {
    final type = _inputAdaptiveMap['type'] as String?;
    return type == 'Input.Text' || type == 'Input.Number';
  }

  /// Runs embedded `valueChangedAction` when the user changes this input.
  ///
  /// Discrete inputs pass [committed] as `true` on each change. Text and
  /// number inputs pass `true` only on focus loss or editing complete.
  void notifyUserInputValueChanged(
    Object? value, {
    required bool committed,
  }) {
    if (_inputRequiresCommittedValueChangedAction && !committed) {
      return;
    }

    if (_lastValueChangedActionTriggeredValue == value) {
      return;
    }

    final actionRaw = _inputAdaptiveMap['valueChangedAction'];
    if (actionRaw is! Map) {
      return;
    }

    final actionMap = Map<String, dynamic>.from(actionRaw);
    if (actionMap['type'] != 'Action.ResetInputs') {
      return;
    }

    _lastValueChangedActionTriggeredValue = value;
    executeResetInputsAction(context, actionMap);
  }

  /// Marks this input invalid via the document notifier (Form validators,
  /// [checkRequired]). Omit [errorMessage] to use baseline JSON message.
  void setLocalValidationError({String? errorMessage}) {
    ref
        .read(adaptiveCardDocumentProvider.notifier)
        .setInputError(
          _inputId,
          errorMessage: errorMessage,
          isInvalid: true,
        );
  }

  /// Clears validation overlays for this input (e.g. when Form validation passes).
  void clearLocalValidationError() {
    ref.read(adaptiveCardDocumentProvider.notifier).clearInputError(_inputId);
  }

  /// Subscribes during [build]; returns merged baseline + overlay input state.
  ResolvedInputState watchResolvedInput() {
    final resolved = ref.watch(resolvedElementProvider(_inputId));
    return ResolvedInputState(resolved ?? _inputAdaptiveMap);
  }

  /// Imperative read for [checkRequired], [resetInput], and init seeding.
  ResolvedInputState readResolvedInput() {
    final resolved = ref.read(resolvedElementProvider(_inputId));
    return ResolvedInputState(resolved ?? _inputAdaptiveMap);
  }

  /// Call at the top of [build] to sync controllers when resolved value changes.
  void listenForResolvedValueChanges() {
    ref.listen(resolvedElementProvider(_inputId), (previous, next) {
      if (previous?['value'] == next?['value']) return;
      final value = next?['value'];
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        onDocumentValueChanged(value);
      });
    });
  }

  void setDocumentInputValue(Object? newValue) {
    ref
        .read(adaptiveCardDocumentProvider.notifier)
        .setInputValue(_inputId, newValue);
  }

  /// Clears the runtime value overlay so resolved `value` falls back to baseline.
  void clearDocumentInputValue() {
    ref.read(adaptiveCardDocumentProvider.notifier).clearInputValue(_inputId);
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

  /// Factory-resets this input via the document notifier, then syncs local UI
  /// from resolved state via [onDocumentValueChanged].
  ///
  /// Subclasses should override only to sync controllers or selection UI;
  /// do not clear overlays locally. See `docs/reactive-riverpod.md#reset-semantics`.
  void resetInput() {
    ref.read(adaptiveCardDocumentProvider.notifier).resetInput(_inputId);
    onDocumentValueChanged(readResolvedInput().valueRaw);
  }
}

mixin AdaptiveTextualInputMixin<T extends ConsumerStatefulWidget>
    on ConsumerState<T> {}

mixin AdaptiveVisibilityMixin<T extends AdaptiveElementWidgetMixin> on State<T>
    implements AdaptiveElementMixin<T> {
  late bool isVisible;
  ProviderSubscription<Map<String, dynamic>?>? _visibilitySubscription;

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
        final visible = parseIsVisible(next?['isVisible']);
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
