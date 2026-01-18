import 'package:flutter/material.dart';

import 'package:flutter_adaptive_cards/src/reference_resolver.dart';

/// This class exists to provide a ReferenceResolver to the widget tree
/// We use this instead of riverpod because makes it easy to provide
/// scoped resolvers and to create overides to
/// do things like override a parent container configuration
class InheritedReferenceResolver extends InheritedWidget {
  const InheritedReferenceResolver({
    super.key,
    required this.resolver,
    required super.child,
  });

  /// The resolver to provide to the widget tree for resolving configuration
  final ReferenceResolver resolver;

  static InheritedReferenceResolver? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<InheritedReferenceResolver>();
  }

  static InheritedReferenceResolver of(BuildContext context) {
    final InheritedReferenceResolver? result = maybeOf(context);
    return result!;
  }

  @override
  bool updateShouldNotify(InheritedReferenceResolver oldWidget) =>
      resolver != oldWidget.resolver;
}
