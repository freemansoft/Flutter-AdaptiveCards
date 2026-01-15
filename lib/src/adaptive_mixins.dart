import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards/src/flutter_raw_adaptive_card.dart';
import 'package:flutter_adaptive_cards/src/riverpod_providers.dart';
import 'package:flutter_adaptive_cards/src/utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

mixin AdaptiveElementWidgetMixin on StatefulWidget {
  // this is an abstract method that everyone needs to implmenet
  Map<String, dynamic> get adaptiveMap;
}

mixin AdaptiveElementMixin<T extends AdaptiveElementWidgetMixin> on State<T> {
  late String id;

  late RawAdaptiveCardState widgetState;

  Map<String, dynamic> get adaptiveMap => widget.adaptiveMap;

  @override
  void initState() {
    super.initState();

    widgetState = ProviderScope.containerOf(
      context,
      listen: false,
    ).read(rawAdaptiveCardStateProvider);
    if (widget.adaptiveMap.containsKey('id')) {
      id = widget.adaptiveMap['id'];
    } else {
      id = UUIDGenerator().getId();
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdaptiveElementMixin &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

mixin AdaptiveActionMixin<T extends AdaptiveElementWidgetMixin> on State<T>
    implements AdaptiveElementMixin<T> {
  String get title => widget.adaptiveMap['title'] ?? '';

  void onTapped();
}

mixin AdaptiveInputMixin<T extends AdaptiveElementWidgetMixin> on State<T>
    implements AdaptiveElementMixin<T> {
  late String value;
  late String placeholder;

  @override
  void initState() {
    super.initState();
    value = adaptiveMap['value'].toString() == 'null'
        ? ''
        : adaptiveMap['value'].toString();

    placeholder = widget.adaptiveMap['placeholder'] ?? '';
  }

  /// Input cards implement this to copy their state **to** the map
  void appendInput(Map map);

  /// Input cards implement this as a way of loading state from a Map, `inputData`
  void initInput(Map map);

  /// Input card types implement this as a way of changing their state, currently only choice_set
  void loadInput(Map map) {}

  bool checkRequired();

  void resetInput() {
    // Default implementation: reset to initial value
    value = adaptiveMap['value'].toString() == 'null'
        ? ''
        : adaptiveMap['value'].toString();
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
