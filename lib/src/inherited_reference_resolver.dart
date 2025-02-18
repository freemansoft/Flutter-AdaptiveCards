import 'package:flutter/material.dart';

import 'reference_resolver.dart';

class InheritedReferenceResolver extends InheritedWidget {
  final ReferenceResolver resolver;

  const InheritedReferenceResolver({
    super.key,
    required this.resolver,
    required super.child,
  });

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
