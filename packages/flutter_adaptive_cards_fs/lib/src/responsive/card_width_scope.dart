import 'package:flutter/widgets.dart';
import 'package:flutter_adaptive_cards_fs/src/responsive/width_bucket.dart';

/// Publishes the current card render-width [WidthBucket] to descendant elements.
///
/// Installed once near the card root inside a `LayoutBuilder`, so the bucket is
/// derived from the card's measured width. Elements read it via [of] to gate
/// `targetWidth` visibility and select `layouts` (`Layout.Flow`). Reading
/// through [of] registers an inherited dependency, so descendants rebuild when
/// the card crosses a width boundary.
class CardWidthScope extends InheritedWidget {
  /// Creates a scope publishing [bucket] to [child].
  const CardWidthScope({
    required this.bucket,
    required super.child,
    super.key,
  });

  /// The width bucket for the card subtree below this scope.
  final WidthBucket bucket;

  /// The current [WidthBucket], or [WidthBucket.wide] when no scope is present.
  ///
  /// Defaults to `wide` (fail-open: show everything / widest layout) so an
  /// element built without a surrounding [CardWidthScope] still renders.
  /// Registers [context] as a dependent so it rebuilds when the bucket changes.
  static WidthBucket of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<CardWidthScope>();
    return scope?.bucket ?? WidthBucket.wide;
  }

  @override
  bool updateShouldNotify(CardWidthScope oldWidget) => bucket != oldWidget.bucket;
}
