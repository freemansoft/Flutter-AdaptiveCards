import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/src/action/action_type_registry.dart';
import 'package:flutter_adaptive_cards_fs/src/adaptive_cards_canvas.dart';
import 'package:flutter_adaptive_cards_fs/src/cards/inputs/choice_filter.dart';
import 'package:flutter_adaptive_cards_fs/src/hostconfig/host_config.dart';
import 'package:flutter_adaptive_cards_fs/src/hostconfig/theme_color_fallbacks.dart';
import 'package:flutter_adaptive_cards_fs/src/models/action_invoke.dart';
import 'package:flutter_adaptive_cards_fs/src/models/adaptive_card_update.dart';
import 'package:flutter_adaptive_cards_fs/src/models/choice.dart';
import 'package:flutter_adaptive_cards_fs/src/models/data_query.dart';
import 'package:flutter_adaptive_cards_fs/src/models/fact.dart';
import 'package:flutter_adaptive_cards_fs/src/reference_resolver.dart';
import 'package:flutter_adaptive_cards_fs/src/registry.dart';
import 'package:flutter_adaptive_cards_fs/src/riverpod/providers.dart';
import 'package:flutter_adaptive_cards_fs/src/utils/utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Low-level card renderer when you already have parsed JSON.
///
/// Prefer [AdaptiveCardsCanvas] for loading and host wiring.
class RawAdaptiveCard extends StatefulWidget {
  /// Renders [map] with [hostConfigs] and optional registries; ids are injected at runtime.
  const RawAdaptiveCard.fromMap({
    super.key,
    required this.map,
    this.cardTypeRegistry = const CardTypeRegistry(),
    this.actionTypeRegistry = const DefaultActionTypeRegistry(),
    this.initData,
    this.onChange,
    this.listView = false,
    this.showDebugJson = true,
    this.brightnessMode = AdaptiveCardBrightnessMode.auto,
    this.currentUserId,
    required this.hostConfigs,
  });

  /// Root Adaptive Card JSON for this subtree (ids injected at runtime).
  final Map<String, dynamic> map;

  /// Light/dark HostConfig palette used for styling resolution.
  final HostConfigs hostConfigs;

  /// Registry that maps element `type` strings to widgets.
  final CardTypeRegistry cardTypeRegistry;

  /// Registry that maps action `type` strings to tap handlers.
  final ActionTypeRegistry actionTypeRegistry;

  /// Optional seed values or patch maps applied to input overlays on load.
  final Map? initData;

  /// Host callback invoked when an input value changes.
  final void Function(InputChangeInvoke invoke)? onChange;

  /// When true (debug only), shows a button that displays [map] as JSON.
  final bool showDebugJson;

  /// When true, the root card body scrolls as a list.
  final bool listView;

  /// Selects light vs dark [HostConfigs] when not [AdaptiveCardBrightnessMode.auto].
  final AdaptiveCardBrightnessMode brightnessMode;

  /// Current user id for root `refresh.userIds` auto-refresh gating.
  final String? currentUserId;

  @override
  RawAdaptiveCardState createState() => RawAdaptiveCardState();
}

/// Host-facing card state: runtime overlays, validation, and imperative updates without mutating baseline JSON.
class RawAdaptiveCardState extends State<RawAdaptiveCard> {
  ///.  Wrapper around the host config
  late ReferenceResolver _resolver;

  // The root element that is loaded from the map
  late Widget _adaptiveElement;

  /// Deep-copied baseline for [baselineMapProvider]; stable across [build]
  /// so runtime overlays are not cleared when the host rebuilds this card.
  late Map<String, dynamic> _baselineMap;

  /// Riverpod container for this card scope; available after first frame for
  /// advanced host integrations outside widget [build].
  ProviderContainer? documentContainer;

  Brightness? _resolverBrightnessKey;

  /// creates a deep copy with ids injected
  static Map<String, dynamic> _deepCopyBaseline(Map<String, dynamic> map) {
    final copy = json.decode(json.encode(map)) as Map<String, dynamic>;
    injectIds(copy);
    return copy;
  }

  @override
  void initState() {
    super.initState();
    // Resolver initialization moved to didChangeDependencies to access context Theme

    _baselineMap = _deepCopyBaseline(widget.map);
    _adaptiveElement = widget.cardTypeRegistry.getElement(
      map: _baselineMap,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateResolver();
  }

  @override
  void didUpdateWidget(RawAdaptiveCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.map != widget.map) {
      _baselineMap = _deepCopyBaseline(widget.map);
      _adaptiveElement = widget.cardTypeRegistry.getElement(
        map: _baselineMap,
      );
    } else if (oldWidget.cardTypeRegistry != widget.cardTypeRegistry) {
      _adaptiveElement = widget.cardTypeRegistry.getElement(
        map: _baselineMap,
      );
    }
    _updateResolver();
  }

  Brightness _themeBrightness() {
    switch (widget.brightnessMode) {
      case AdaptiveCardBrightnessMode.light:
        return Brightness.light;
      case AdaptiveCardBrightnessMode.dark:
        return Brightness.dark;
      case AdaptiveCardBrightnessMode.auto:
        return Theme.of(context).brightness;
    }
  }

  void _updateResolver() {
    final brightness = _themeBrightness();
    widget.hostConfigs.current = brightness == Brightness.dark
        ? widget.hostConfigs.dark
        : widget.hostConfigs.light;

    _resolver = ReferenceResolver(
      hostConfigs: widget.hostConfigs,
      colorFallbacks: ThemeColorFallbacks(Theme.of(context)),
    );
    _resolverBrightnessKey = brightness;
  }

  /// Forces a card subtree rebuild when host logic changes state outside overlay
  /// notifiers.
  void rebuild() {
    setState(() {});
  }

  /// Seeds input overlays from [map] (e.g. `RawAdaptiveCard.initData`).
  ///
  /// Flat maps `{id: value}` seed input values only. Maps whose values are
  /// patch objects `{id: {choices: …, value: …}}` delegate to [applyUpdatesFromMap].
  void initInput(Map map) {
    final container = documentContainer;
    if (container == null) return;
    final normalized = Map<String, Object?>.from(map);
    if (normalized.values.any((value) => value is Map)) {
      applyUpdatesFromMap(normalized);
      return;
    }
    container
        .read(adaptiveCardDocumentProvider.notifier)
        .seedInputValues(normalized);
  }

  /// Applies sparse overlay patches without mutating baseline JSON.
  void applyUpdates({
    Iterable<AdaptiveElementUpdate> elements = const [],
    Iterable<AdaptiveActionUpdate> actions = const [],
  }) {
    final container = documentContainer;
    if (container == null) return;
    container
        .read(adaptiveCardDocumentProvider.notifier)
        .applyUpdates(
          elements: elements,
          actions: actions,
        );
  }

  /// Parses [byId] patch maps (Adaptive Card property names) into overlay updates.
  void applyUpdatesFromMap(Map<String, Object?> byId) {
    final container = documentContainer;
    if (container == null) return;
    final parsed = container
        .read(adaptiveCardDocumentProvider.notifier)
        .updatesFromPatchMap(byId);
    container
        .read(adaptiveCardDocumentProvider.notifier)
        .applyUpdates(
          elements: parsed.elements,
          actions: parsed.actions,
        );
  }

  /// Sets host-driven validation overlays for input [id].
  void setInputError(
    String id, {
    String? message,
    bool isInvalid = true,
  }) {
    final container = documentContainer;
    if (container == null) return;
    container
        .read(adaptiveCardDocumentProvider.notifier)
        .setInputError(
          id,
          errorMessage: message,
          isInvalid: isInvalid,
        );
  }

  /// Clears validation overlays for input [id].
  void clearInputError(String id) {
    final container = documentContainer;
    if (container == null) return;
    container.read(adaptiveCardDocumentProvider.notifier).clearInputError(id);
  }

  /// Factory-resets one input id (same rules as Action.ResetInputs per field).
  ///
  /// Clears overlay value, choices, validation, `isRequired`, `label`, and
  /// `placeholder` for [id]. See `docs/reactive-riverpod.md#reset-semantics`.
  void resetInput(String id) {
    final container = documentContainer;
    if (container == null) return;
    container.read(adaptiveCardDocumentProvider.notifier).resetInput(id);
  }

  /// Replaces effective `"text"` for element [id] (e.g. `TextBlock`).
  void setText(String id, String text) {
    final container = documentContainer;
    if (container == null) return;
    container.read(adaptiveCardDocumentProvider.notifier).setText(id, text);
  }

  /// Clears text overlay for element [id].
  void clearText(String id) {
    final container = documentContainer;
    if (container == null) return;
    container.read(adaptiveCardDocumentProvider.notifier).clearText(id);
  }

  /// Replaces effective `"facts"` for `FactSet` [id].
  void setFacts(String id, List<Fact> facts) {
    final container = documentContainer;
    if (container == null) return;
    container.read(adaptiveCardDocumentProvider.notifier).setFacts(id, facts);
  }

  /// Clears facts overlay for [id].
  void clearFacts(String id) {
    final container = documentContainer;
    if (container == null) return;
    container.read(adaptiveCardDocumentProvider.notifier).clearFacts(id);
  }

  /// Replaces effective `"inlines"` for `RichTextBlock` [id].
  void setInlines(String id, List<Map<String, dynamic>> inlines) {
    final container = documentContainer;
    if (container == null) return;
    container.read(adaptiveCardDocumentProvider.notifier).setInlines(id, inlines);
  }

  /// Clears inlines overlay for [id].
  void clearInlines(String id) {
    final container = documentContainer;
    if (container == null) return;
    container.read(adaptiveCardDocumentProvider.notifier).clearInlines(id);
  }

  /// Patches optional-package overlay payload for [id] and [extensionId].
  void patchExtensionOverlay(
    String id,
    String extensionId,
    Map<String, dynamic> patch, {
    bool clearPayload = false,
  }) {
    final container = documentContainer;
    if (container == null) return;
    container
        .read(adaptiveCardDocumentProvider.notifier)
        .patchExtensionOverlay(
          id,
          extensionId,
          patch,
          clearPayload: clearPayload,
        );
  }

  /// Sets whether action [id] is enabled (AC 1.5).
  void setActionEnabled(String id, {required bool enabled}) {
    final container = documentContainer;
    if (container == null) return;
    container
        .read(adaptiveCardDocumentProvider.notifier)
        .setActionEnabled(id, enabled: enabled);
  }

  /// Replaces `Input.ChoiceSet` choices for [id] via the document overlay.
  void loadInput(String id, Map map) {
    final container = documentContainer;
    if (container == null) return;
    final choices = map.entries
        .map(
          (entry) => Choice(
            title: entry.key.toString(),
            value: entry.value.toString(),
          ),
        )
        .toList();
    container
        .read(adaptiveCardDocumentProvider.notifier)
        .setChoices(
          id,
          choices,
        );
  }

  /// Notifies the host that input [id] changed, optionally with a [dataQuery].
  void changeValue(String id, dynamic value, {DataQuery? dataQuery}) {
    widget.onChange?.call(
      InputChangeInvoke(
        inputId: id,
        value: value,
        dataQuery: dataQuery,
        cardState: this,
      ),
    );
  }

  /// Displays [message] in a [SnackBar] for quick host feedback.
  void showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  /// Presents a modal [ChoiceFilter] sheet and returns the selection via [callback].
  Future<void> searchList(
    List<Choice>? data,
    void Function(Choice? value) callback, {
    String? inputId,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(6)),
        side: BorderSide(),
      ),
      builder: (BuildContext builder) => SizedBox(
        height: MediaQuery.of(context).copyWith().size.height / 2,
        child: ChoiceFilter(
          key: inputId != null ? ValueKey(inputId) : null,
          data: data,
          callback: callback,
        ),
      ),
    );
  }

  /// Shows a platform-appropriate date picker constrained by [min] and [max].
  Future<DateTime?> datePickerForPlatform(
    BuildContext context,
    DateTime? value,
    DateTime? min,
    DateTime? max,
  ) {
    if (Theme.of(context).platform == TargetPlatform.macOS ||
        Theme.of(context).platform == TargetPlatform.iOS) {
      return datePickerCupertino(context, value, min, max);
    } else {
      return datePickerMaterial(context, value, min, max);
    }
  }

  /// Cupertino-style date picker used on iOS and macOS.
  Future<DateTime?> datePickerCupertino(
    BuildContext context,
    DateTime? value,
    DateTime? min,
    DateTime? max,
  ) async {
    final DateTime initialDate = value ?? DateTime.now();
    DateTime? pickedDate = initialDate;

    // showCupertinoModalPopup is a built-in function of the cupertino library
    await showCupertinoModalPopup<DateTime?>(
      context: context,
      useRootNavigator: false, // see if this fixes the pop
      //barrierColor: Theme.of(context).colorScheme.surfaceContainer,
      builder: (_) => SizedBox(
        height: 500,
        child: Column(
          children: [
            SizedBox(
              height: 400,
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                initialDateTime: initialDate,
                onDateTimeChanged: (val) {
                  pickedDate = val;
                },
              ),
            ),

            // Close the modal
            CupertinoButton(
              child: const Text('OK'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
    return pickedDate;
  }

  /// Material date picker for non-Apple platforms; null [min]/[max] means no bound in that direction.
  Future<DateTime?> datePickerMaterial(
    BuildContext context,
    DateTime? value,
    DateTime? min,
    DateTime? max,
  ) {
    final DateTime initialDate = value ?? DateTime.now();
    return showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: min ?? DateTime.now().subtract(const Duration(days: 10000)),
      lastDate: max ?? DateTime.now().add(const Duration(days: 10000)),
    );
  }

  /// Shows a platform-appropriate time picker within optional bounds.
  Future<TimeOfDay?> timePickerForPlatform(
    BuildContext context,
    TimeOfDay? defaultTime,
    TimeOfDay? minTime,
    TimeOfDay? maxTime,
  ) {
    if (Theme.of(context).platform == TargetPlatform.macOS ||
        Theme.of(context).platform == TargetPlatform.iOS) {
      return timePickerCupertino(context, defaultTime, minTime, maxTime);
    } else {
      return timePickerMaterial(context, defaultTime, minTime, maxTime);
    }
  }

  /// Cupertino-style time picker used on iOS and macOS.
  Future<TimeOfDay?> timePickerCupertino(
    BuildContext context,
    TimeOfDay? defaultTime,
    TimeOfDay? minimumTime,
    TimeOfDay? maximumTime,
  ) async {
    final TimeOfDay initialTimeOfDay = defaultTime ?? TimeOfDay.now();
    // the picker requires a DateTime but won't be carried forward in the results
    final DateTime initialDateTime = DateTime(
      1,
      1,
      1,
      initialTimeOfDay.hour,
      initialTimeOfDay.minute,
    );
    final DateTime minDateTime = DateTime(
      1,
      1,
      1,
      minimumTime?.hour ?? 0,
      minimumTime?.minute ?? 0,
    );
    final DateTime maxDateTime = DateTime(
      1,
      1,
      1,
      maximumTime?.hour ?? 23,
      maximumTime?.minute ?? 59,
    );
    assert(() {
      developer.log(
        'CupertinoPicker: initialtimeOfDay:$initialTimeOfDay initialDateTime:$initialDateTime minDateTime:$minDateTime maxDateTime:$maxDateTime',
        name: runtimeType.toString(),
      );

      return true;
    }());

    TimeOfDay? pickedTimeOfDay = initialTimeOfDay;

    // showCupertinoModalPopup is a built-in function of the cupertino library
    await showCupertinoModalPopup<TimeOfDay?>(
      context: context,
      useRootNavigator: false,
      builder: (_) => SizedBox(
        height: 500,
        child: Column(
          children: [
            SizedBox(
              height: 400,
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.time,
                use24hFormat: false,
                initialDateTime: initialDateTime,
                minimumDate: minDateTime,
                maximumDate: maxDateTime,
                onDateTimeChanged: (val) {
                  pickedTimeOfDay = TimeOfDay.fromDateTime(val);
                },
              ),
            ),

            // Close the modal
            CupertinoButton(
              child: const Text('OK'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
    return pickedTimeOfDay;
  }

  /// Material time picker; [minTime]/[maxTime] are ignored on this platform.
  Future<TimeOfDay?> timePickerMaterial(
    BuildContext context,
    TimeOfDay? defaultTime,
    TimeOfDay? minTime,
    TimeOfDay? maxTime,
  ) {
    final TimeOfDay initialTimeOfDay = defaultTime ?? TimeOfDay.now();
    return showTimePicker(context: context, initialTime: initialTimeOfDay);
  }

  @override
  Widget build(BuildContext context) {
    Widget child = _adaptiveElement;

    assert(() {
      if (widget.showDebugJson) {
        child = Column(
          children: <Widget>[
            TextButton(
              onPressed: () {
                const JsonEncoder encoder = JsonEncoder.withIndent('  ');
                final String prettyprint = encoder.convert(widget.map);
                unawaited(
                  showDialog<void>(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: const Text(
                          'JSON (only added in debug mode, you can also turn '
                          'it off manually by passing showDebugJson = false)',
                        ),
                        content: SingleChildScrollView(
                          child: SelectableText(prettyprint),
                        ),
                        contentPadding: const EdgeInsets.all(8),
                      );
                    },
                  ),
                );
              },
              child: const Text('Debug show the JSON'),
            ),
            const Divider(height: 0),
            child,
          ],
        );
      }
      return true;
    }());
    final backgroundColor = _resolver.resolveContainerBackgroundColor(
      style: widget.map['style']?.toString().toLowerCase(),
    );

    return ProviderScope(
      key: ValueKey<Brightness?>(_resolverBrightnessKey),
      overrides: [
        cardTypeRegistryProvider.overrideWithValue(widget.cardTypeRegistry),
        actionTypeRegistryProvider.overrideWithValue(widget.actionTypeRegistry),
        rawAdaptiveCardStateProvider.overrideWithValue(this),
        styleReferenceResolverProvider.overrideWithValue(_resolver),
        baselineMapProvider.overrideWithValue(_baselineMap),
        currentUserIdProvider.overrideWithValue(widget.currentUserId),
      ],
      child: _AdaptiveCardDocumentLifecycle(
        cardState: this,
        initData: widget.initData,
        child: Card(color: backgroundColor, child: child),
      ),
    );
  }
}

/// Registers the card-scoped [ProviderContainer] and seeds [initData] overlays.
class _AdaptiveCardDocumentLifecycle extends StatefulWidget {
  const _AdaptiveCardDocumentLifecycle({
    required this.cardState,
    required this.initData,
    required this.child,
  });

  final RawAdaptiveCardState cardState;
  final Map? initData;
  final Widget child;

  @override
  State<_AdaptiveCardDocumentLifecycle> createState() =>
      _AdaptiveCardDocumentLifecycleState();
}

class _AdaptiveCardDocumentLifecycleState
    extends State<_AdaptiveCardDocumentLifecycle> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  @override
  void didUpdateWidget(covariant _AdaptiveCardDocumentLifecycle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initData != widget.initData) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _seedInitData());
    }
  }

  void _bootstrap() {
    if (!mounted) return;
    widget.cardState.documentContainer = ProviderScope.containerOf(context);
    _seedInitData();
  }

  void _seedInitData() {
    final initData = widget.initData;
    if (initData == null || initData.isEmpty) return;
    final normalized = <String, Object?>{};
    for (final entry in initData.entries) {
      if (entry.value is Map) {
        normalized[entry.key.toString()] = entry.value;
      } else {
        normalized[entry.key.toString()] = {'value': entry.value};
      }
    }
    widget.cardState.applyUpdatesFromMap(normalized);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
