import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/src/action/action_type_registry.dart';
import 'package:flutter_adaptive_cards_fs/src/action/reset_inputs_executor.dart';
import 'package:flutter_adaptive_cards_fs/src/cards/adaptive_card_element.dart';
import 'package:flutter_adaptive_cards_fs/src/flutter_raw_adaptive_card.dart';
import 'package:flutter_adaptive_cards_fs/src/reference_resolver.dart';
import 'package:flutter_adaptive_cards_fs/src/registry.dart';
import 'package:flutter_adaptive_cards_fs/src/resolved_input_state.dart';
import 'package:flutter_adaptive_cards_fs/src/responsive/width_bucket.dart';
import 'package:flutter_adaptive_cards_fs/src/riverpod/providers.dart';
import 'package:flutter_adaptive_cards_fs/src/utils/adaptive_image_utils.dart';
import 'package:flutter_adaptive_cards_fs/src/utils/utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Mixin for widgets that are adaptive elements- widget and not state

/// Contract for adaptive element widgets that expose JSON and a stable [id].
mixin AdaptiveElementWidgetMixin on StatefulWidget {
  // this is an abstract method that everyone needs to implmenet

  /// Baseline element JSON for this widget; required by element
  /// implementations.
  Map<String, dynamic> get adaptiveMap;

  /// Stable element id used for overlays, keys, and provider lookups.
  String get id;
}

/// Reads card-scoped Riverpod providers from the enclosing [ProviderScope].
mixin ProviderScopeMixin<T extends StatefulWidget> on State<T> {
  ProviderContainer get _container => ProviderScope.containerOf(context);

  /// Root [RawAdaptiveCardState] for this card subtree.
  RawAdaptiveCardState get rawRootCardWidgetState =>
      _container.read(rawAdaptiveCardStateProvider);

  /// Element factory registry for the current card scope.
  CardTypeRegistry get cardTypeRegistry =>
      _container.read(cardTypeRegistryProvider);

  /// Action handler registry for the current card scope.
  ActionTypeRegistry get actionTypeRegistry =>
      _container.read(actionTypeRegistryProvider);

  /// State of the root `AdaptiveCard` element widget.
  AdaptiveCardElementState get adaptiveCardElementState =>
      _container.read(adaptiveCardElementStateProvider);

  /// HostConfig-backed style resolver for the current card scope.
  ReferenceResolver get styleResolver =>
      _container.read(styleReferenceResolverProvider);
}

/// Shared element identity and background-image helpers for adaptive widgets.
mixin AdaptiveElementMixin<T extends AdaptiveElementWidgetMixin> on State<T> {
  /// Same as [AdaptiveElementWidgetMixin.id].
  String get id => widget.id;

  /// Lowercased `style` token from [adaptiveMap], if present.
  String? get style => (adaptiveMap['style'] as String?)?.toLowerCase();

  /// Baseline JSON for this element.
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

  /// Maps Adaptive Card `fillMode` to a [BoxFit] for background images.
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

  /// Maps Adaptive Card `fillMode` to [ImageRepeat] tiling behavior.
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

  /// Background [Widget] for container-style elements; supports network and
  /// data URLs.
  Widget getBackgroundImage(
    String url, {
    ImageRepeat repeat = ImageRepeat.noRepeat,
    BoxFit fit = BoxFit.cover,
  }) {
    return AdaptiveImageUtils.getImage(url, fit: fit, semanticsLabel: null);
  }

  /// [ImageProvider] for [DecorationImage] backgrounds on container-style
  /// elements.
  ImageProvider getBackgroundImageProvider(String url) {
    return AdaptiveImageUtils.getImageProvider(url);
  }

  /// Normalizes `backgroundImage` string or object to url/fit/repeat for
  /// container elements.
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

  /// Builds a background image widget from an element map's `backgroundImage`.
  Widget? getBackgroundImageFromMap(Map element) {
    final props = resolveBackgroundImage(element['backgroundImage']);
    if (props == null) return null;

    return getBackgroundImage(props.url, repeat: props.repeat, fit: props.fit);
  }

  /// [BoxDecoration] with optional background color and image from element
  /// JSON; corner radius is caller-supplied.
  ///
  /// [borderRadius] is caller-supplied (not read from [element] here) so
  /// each element decides whether it honors a `roundedCorners` flag —
  /// container-family elements (`AdaptiveContainer`, `AdaptiveColumnSet`,
  /// `AdaptiveColumn`) opt in by passing one.
  BoxDecoration getDecorationFromMap(
    Map element, {
    Color? backgroundColor,
    BorderRadius? borderRadius,
  }) {
    final decorationImage = getDecorationImageFromMap(element);
    return BoxDecoration(
      image: decorationImage,
      color: backgroundColor,
      borderRadius: borderRadius,
    );
  }

  /// [DecorationImage] from element JSON `backgroundImage`.
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

/// Returns whether [element] defines a usable `backgroundImage` value.
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

/// Static action label/tooltip from baseline JSON for simple action widgets.
mixin AdaptiveActionMixin<T extends AdaptiveElementWidgetMixin> on State<T>
    implements AdaptiveElementMixin<T> {
  /// Action label from baseline JSON.
  String get title => adaptiveMap['title'] as String? ?? '';

  /// Optional hover or accessibility hint from baseline JSON.
  String? get tooltip => adaptiveMap['tooltip'] as String?;
}

/// Reactive action label, tooltip, iconUrl, and enabled state from merged
/// baseline + overlays.
mixin AdaptiveActionStateMixin<T extends ConsumerStatefulWidget>
    on ConsumerState<T> {
  /// Stable element id; provided by [AdaptiveElementMixin] when mixed in.
  String get id;

  /// Baseline element JSON; provided by [AdaptiveElementMixin] when mixed in.
  Map<String, dynamic> get adaptiveMap;

  /// Whether the action accepts presses per merged baseline + overlay.
  bool get actionEnabled =>
      ref.watch(resolvedActionProvider(id))?['isEnabled'] != false;

  /// Merged action label from baseline JSON and runtime overlays.
  String get title =>
      (ref.watch(resolvedActionProvider(id))?['title'] as String?) ??
      (adaptiveMap['title'] as String?) ??
      '';

  /// Merged tooltip from baseline JSON and runtime overlays.
  String? get tooltip =>
      (ref.watch(resolvedActionProvider(id))?['tooltip'] as String?) ??
      (adaptiveMap['tooltip'] as String?);

  /// Merged `iconUrl` from baseline JSON and runtime overlays.
  String? get iconUrl =>
      (ref.watch(resolvedActionProvider(id))?['iconUrl'] as String?) ??
      (adaptiveMap['iconUrl'] as String?);
}

/// Shared input overlay, validation, and value-changed-action behavior for
/// input widgets.
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

  /// Clears validation overlays for this input (e.g. when Form validation
  /// passes).
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

  /// Call at the top of [build] to sync controllers when resolved value
  /// changes.
  ///
  /// Registers a `ref.listen` subscription (auto-removed on the next rebuild)
  /// that schedules a post-frame callback whenever the resolved `'value'` key
  /// changes. The callback reads the **latest** resolved value at execution
  /// time rather than capturing it at listener-fire time. This prevents a
  /// stale-echo: if two keystrokes arrive in the same frame, the intermediate
  /// captured value would be outdated by the time the callback runs. Reading
  /// the latest ensures the echo is a no-op when the controller already
  /// reflects the current document state, preserving the IME cursor position.
  void listenForResolvedValueChanges() {
    ref.listen(resolvedElementProvider(_inputId), (previous, next) {
      if (previous?['value'] == next?['value']) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        onDocumentValueChanged(readResolvedInput().valueRaw);
      });
    });
  }

  /// Writes a runtime value overlay for this input id.
  void setDocumentInputValue(Object? newValue) {
    ref
        .read(adaptiveCardDocumentProvider.notifier)
        .setInputValue(_inputId, newValue);
  }

  /// Clears the runtime value overlay so resolved `value` falls back to
  /// baseline.
  void clearDocumentInputValue() {
    ref.read(adaptiveCardDocumentProvider.notifier).clearInputValue(_inputId);
  }

  /// Subclasses can override to sync controllers from document changes.
  void onDocumentValueChanged(Object? valueFromDocument) {}

  /// Collect this input's submit value into a host payload map.
  void appendInput(Map map);

  /// Seed local UI from host `initData` for this input type.
  void initInput(Map map);

  /// Host hook to replace ChoiceSet options at runtime.
  void loadInput(Map map) {}

  /// Returns whether required validation passes for this input before submit.
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

/// Marker mixin for text-like inputs that share [AdaptiveInputMixin] behavior.
mixin AdaptiveTextualInputMixin<T extends ConsumerStatefulWidget>
    on ConsumerState<T> {}

/// Reactive `isVisible` from merged baseline + overlays.
mixin AdaptiveVisibilityMixin<T extends ConsumerStatefulWidget>
    on ConsumerState<T> {
  /// Stable element id; provided by [AdaptiveElementMixin] when mixed in.
  String get id;

  /// Effective visibility: baseline JSON + runtime overlays, ANDed with the
  /// element's `targetWidth` match against the current card width bucket.
  ///
  /// `isVisible` and `targetWidth` are independent gates — a runtime
  /// `setIsVisible(visible: true)` overlay cannot override a `targetWidth`
  /// miss.
  bool get isVisible {
    final resolved = ref.watch(resolvedElementProvider(id));
    final baselineVisible = parseIsVisible(resolved?['isVisible']);
    final bucket = ref.watch(cardWidthBucketProvider);
    final matchesWidth = targetWidthMatches(
      resolved?['targetWidth'] as String?,
      bucket,
    );
    return baselineVisible && matchesWidth;
  }

  /// Sets runtime visibility overlay for this element id (host or
  /// Action.ToggleVisibility).
  void setIsVisible({required bool visible}) {
    ref
        .read(adaptiveCardDocumentProvider.notifier)
        .setVisibility(id, visible: visible);
  }
}
