import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards/src/flutter_raw_adaptive_card.dart';
import 'package:flutter_adaptive_cards/src/reference_resolver.dart';
import 'package:flutter_adaptive_cards/src/utils.dart';

/// The visitor, the function is called once for every element in the tree
typedef AdaptiveElementVisitor = void Function(AdaptiveElement element);

/// The base class for every element (widget) drawn on the screen.
///
/// The lifecycle is as follows:
/// - [loadTree()] is called, all the initialization should be done here
/// - [generateWidget()] is called every time the elements needs to render
/// this method should be as lightweight as possible because it could possibly
/// be called many times (for example in an animation). The method should also be
/// idempotent meaning calling it multiple times without changing anything should
/// return the same result
///
/// This class also holds some references every element needs.
/// --------------------------------------------------------------------
/// The [adaptiveMap] is the map associated with that element
///
/// root
/// |
/// currentElement <-- ([adaptiveMap] contains the subtree from there)
/// |       |
/// child 1 child2
/// --------------------------------------------------------------------
///
/// The [ReferenceResolver] is a handy wrapper around the theming and styling, which makes accessing
/// it easier.
///
/// The [widgetState] provides access to flutter specific implementations.
///
/// If the element has children (you don't need to do this if the element is a
/// leaf):
/// implement the method [visitChildren] and call visitor(this) in addition call
/// [visitChildren] on each child with the passed visitor.
abstract class AdaptiveElement {
  AdaptiveElement({required this.adaptiveMap, required this.widgetState}) {
    loadTree();
  }

  final Map adaptiveMap;

  late String id;

  /// Because some widgets (looking at you ShowCardAction) need to set the state
  /// all elements get a way to set the state.
  final RawAdaptiveCardState widgetState;

  /// This method should be implemented by the actual elements to return
  /// their Flutter representation.
  Widget build();

  /// Use this method to obtain the widget tree of the adaptive card.
  ///
  /// Each mixin has the opportunity to add something to the widget hierarchy.
  ///
  /// An example:
  /// ```dart
  /// @override
  /// Widget generateWidget() {
  ///  assert(separator != null, 'Did you forget to call loadSeperator in this class?');
  ///  return Column(
  ///    children: <Widget>[
  ///      separator? Divider(height: topSpacing,): SizedBox(height: topSpacing,),
  ///      super.generateWidget(),
  ///    ],
  ///  );
  ///}
  ///```
  ///
  /// This works because each mixin calls [generateWidget] in its generateWidget
  /// and adds the returned value into the widget tree. Eventually the base
  /// implementation (this) will be called and the elements actual build method is
  /// included.
  @mustCallSuper
  Widget generateWidget() {
    return build();
  }

  void loadId() {
    if (adaptiveMap.containsKey('id')) {
      id = adaptiveMap['id'].toString();
    } else {
      id = UUIDGenerator().getId();
    }
  }

  @mustCallSuper
  void loadTree() {
    loadId();
  }

  /// Visits the children
  void visitChildren(AdaptiveElementVisitor visitor) {
    visitor(this);
  }

  @override
  // shouldn't override for unless marked @immutable but leaving for backward compatibility
  // ignore: avoid_equals_and_hash_code_on_mutable_classes
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdaptiveElement &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  // shouldn't override for unless marked @immutable but leaving for backward compatibility
  // ignore: avoid_equals_and_hash_code_on_mutable_classes
  int get hashCode => id.hashCode;
}
