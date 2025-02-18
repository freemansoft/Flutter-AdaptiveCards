import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards/src/flutter_raw_adaptive_card.dart';

/// Widget tree wrapper for the ReferenceResolver
/// So folks can do .of(context) to get the resolver
class InheritedRawAdaptiveCardStateResolver extends InheritedWidget {
  final RawAdaptiveCardState state;

  const InheritedRawAdaptiveCardStateResolver({
    super.key,
    required this.state,
    required super.child,
  });

  static InheritedRawAdaptiveCardStateResolver? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<
          InheritedRawAdaptiveCardStateResolver
        >();
  }

  static InheritedRawAdaptiveCardStateResolver of(BuildContext context) {
    final InheritedRawAdaptiveCardStateResolver? result = maybeOf(context);
    return result!;
  }

  @override
  bool updateShouldNotify(InheritedRawAdaptiveCardStateResolver oldWidget) =>
      state != oldWidget.state;
}
