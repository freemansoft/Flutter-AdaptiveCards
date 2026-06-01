import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/src/cards/adaptive_card_element.dart';
import 'package:flutter_adaptive_cards_fs/src/flutter_raw_adaptive_card.dart';
import 'package:flutter_adaptive_cards_fs/src/reference_resolver.dart';

/// Scoped adaptive-card state and [ReferenceResolver] for the widget tree.
///
/// Installed twice in nested cards: an outer node from [RawAdaptiveCardState]
/// (root state and resolver with registries) and inner nodes from each
/// [AdaptiveCardElementState] (form, widget registry, show-card targets).
/// Use [rawCardScopeOf] and [elementScopeOf] to read the correct ancestor.
class InheritedReferenceResolver extends InheritedWidget {
  const InheritedReferenceResolver({
    super.key,
    required this.resolver,
    this.rawAdaptiveCardState,
    this.adaptiveCardElementState,
    required super.child,
  });

  final ReferenceResolver resolver;
  final RawAdaptiveCardState? rawAdaptiveCardState;
  final AdaptiveCardElementState? adaptiveCardElementState;

  /// Nearest outer (raw-card) scope — root state and resolver (with registries).
  static InheritedReferenceResolver rawCardScopeOf(BuildContext context) {
    final InheritedReferenceResolver? result = _findAncestor(
      context,
      (scope) => scope.rawAdaptiveCardState != null,
    );
    assert(
      result != null,
      'No InheritedReferenceResolver raw-card scope found in context',
    );
    return result!;
  }

  /// Nearest inner (per-card element) scope.
  static InheritedReferenceResolver elementScopeOf(BuildContext context) {
    final InheritedReferenceResolver? result = _findAncestor(
      context,
      (scope) => scope.adaptiveCardElementState != null,
    );
    assert(
      result != null,
      'No InheritedReferenceResolver element scope found in context',
    );
    return result!;
  }

  static AdaptiveCardElementState? maybeElementStateOf(BuildContext context) {
    return _findAncestor(
      context,
      (scope) => scope.adaptiveCardElementState != null,
    )?.adaptiveCardElementState;
  }

  static InheritedReferenceResolver? _findAncestor(
    BuildContext context,
    bool Function(InheritedReferenceResolver scope) predicate,
  ) {
    InheritedReferenceResolver? found;
    context.visitAncestorElements((element) {
      final widget = element.widget;
      if (widget is InheritedReferenceResolver && predicate(widget)) {
        found = widget;
        return false;
      }
      return true;
    });
    return found;
  }

  @override
  bool updateShouldNotify(InheritedReferenceResolver oldWidget) =>
      resolver != oldWidget.resolver ||
      rawAdaptiveCardState != oldWidget.rawAdaptiveCardState ||
      adaptiveCardElementState != oldWidget.adaptiveCardElementState;
}
