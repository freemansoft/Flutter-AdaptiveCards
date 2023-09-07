import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards/src/utils.dart';
import 'package:provider/provider.dart';

import 'flutter_raw_adaptive_card.dart';

mixin AdaptiveElementWidgetMixin on StatefulWidget {
  Map<String, dynamic> get adaptiveMap;
}

mixin AdaptiveElementMixin<T extends AdaptiveElementWidgetMixin> on State<T> {
  late String id;

  late RawAdaptiveCardState widgetState;

  Map<String, dynamic> get adaptiveMap => widget.adaptiveMap;

  @override
  void initState() {
    super.initState();

    widgetState = context.read<RawAdaptiveCardState>();
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

  void appendInput(Map map);

  void initInput(Map map);

  void loadInput(Map map) {}

  bool checkRequired();
}

mixin AdaptiveTextualInputMixin<T extends AdaptiveElementWidgetMixin>
    on State<T> implements AdaptiveInputMixin<T> {
  @override
  void initState() {
    super.initState();
  }
}
