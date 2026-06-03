import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/src/action/action_type_registry.dart';
import 'package:flutter_adaptive_cards_fs/src/adaptive_cards_canvas.dart';
import 'package:flutter_adaptive_cards_fs/src/cards/inputs/choice_filter.dart';
import 'package:flutter_adaptive_cards_fs/src/cards/inputs/choice_set.dart';
import 'package:flutter_adaptive_cards_fs/src/hostconfig/host_config.dart';
import 'package:flutter_adaptive_cards_fs/src/models/choice.dart';
import 'package:flutter_adaptive_cards_fs/src/models/data_query.dart';
import 'package:flutter_adaptive_cards_fs/src/reference_resolver.dart';
import 'package:flutter_adaptive_cards_fs/src/registry.dart';
import 'package:flutter_adaptive_cards_fs/src/riverpod/providers.dart';
import 'package:flutter_adaptive_cards_fs/src/utils/utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The working root of an adaptive card tree when operating against the map
///
/// The this root of the loaded tree is a child of [AdaptiveCardsCanvas]
/// There is usually only one of these per page. (One per AdaptiveCard tree)
/// except when there is an Action.ShowCard which results in another sub-tree
///
class RawAdaptiveCard extends StatefulWidget {
  /// This widget takes a [map] (which usually is just a json decoded string)
  /// and displays in natively.
  ///
  /// Additionally a host config needs to be provided for styling.
  const RawAdaptiveCard.fromMap({
    super.key,
    required this.map,
    this.cardTypeRegistry = const CardTypeRegistry(),
    this.actionTypeRegistry = const DefaultActionTypeRegistry(),
    this.initData,
    this.onChange,
    this.listView = false,
    this.showDebugJson = true,
    required this.hostConfigs,
  });

  final Map<String, dynamic> map;
  final HostConfigs hostConfigs;
  final CardTypeRegistry cardTypeRegistry;
  final ActionTypeRegistry actionTypeRegistry;
  final Map? initData;

  final Function(
    String id,
    dynamic value,
    DataQuery? dataQuery,
    RawAdaptiveCardState cardState,
  )?
  onChange;

  final bool showDebugJson;
  final bool listView;

  @override
  RawAdaptiveCardState createState() => RawAdaptiveCardState();
}

/// The working root of adaptive card state tree when operating against the map
///
class RawAdaptiveCardState extends State<RawAdaptiveCard> {
  ///.  Wrapper around the host config
  late ReferenceResolver _resolver;

  // The root element that is loaded from the map
  late Widget _adaptiveElement;

  /// Deep-copied baseline for [baselineMapProvider]; stable across [build]
  /// so runtime overlays are not cleared when the host rebuilds this card.
  late Map<String, dynamic> _baselineMap;

  /// Set by [_AdaptiveCardDocumentLifecycle] for host APIs outside the scope.
  ProviderContainer? documentContainer;

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

  void _updateResolver() {
    // Dynamically toggle HostConfig light/dark mode based on the current theme brightness
    final Brightness brightness = Theme.of(context).brightness;
    widget.hostConfigs.current = brightness == Brightness.dark
        ? widget.hostConfigs.dark
        : widget.hostConfigs.light;

    _resolver = ReferenceResolver(
      hostConfigs: widget.hostConfigs,
    );
  }

  /// Every widget can access method of this class, meaning setting the state
  /// is possible from every element
  void rebuild() {
    setState(() {});
  }

  /// Seeds input overlays from [map] (e.g. `RawAdaptiveCard.initData`).
  void initInput(Map map) {
    final container = documentContainer;
    if (container == null) return;
    container
        .read(adaptiveCardDocumentProvider.notifier)
        .seedInputValues(Map<String, Object?>.from(map));
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

  void changeValue(String id, dynamic value, {DataQuery? dataQuery}) {
    if (widget.onChange != null) {
      widget.onChange?.call(id, value, dataQuery, this);
    }
  }

  void showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> searchList(
    List<SearchModel>? data,
    Function(dynamic value) callback, {
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

  /// min and max dates may be null, in this case no constraint is made in that direction
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

  ///
  ///
  /// Material doesn't actually support min and max time
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
      overrides: [
        cardTypeRegistryProvider.overrideWithValue(widget.cardTypeRegistry),
        actionTypeRegistryProvider.overrideWithValue(widget.actionTypeRegistry),
        rawAdaptiveCardStateProvider.overrideWithValue(this),
        styleReferenceResolverProvider.overrideWithValue(_resolver),
        baselineMapProvider.overrideWithValue(_baselineMap),
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
    widget.cardState.initInput(initData);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
