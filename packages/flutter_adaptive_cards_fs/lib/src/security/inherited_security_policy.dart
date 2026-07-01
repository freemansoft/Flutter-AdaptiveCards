import 'package:flutter/widgets.dart';
import 'package:flutter_adaptive_cards_fs/src/security/adaptive_fetch_policy.dart';
import 'package:flutter_adaptive_cards_fs/src/security/adaptive_uri_policy.dart';

/// Supplies the active [AdaptiveUriPolicy] and [AdaptiveFetchPolicy] to the
/// adaptive-card widget subtree.
///
/// The renderer installs this above each card so descendant widgets
/// (`Action.OpenUrl`, markdown links, media, images) can validate
/// card-controlled URLs without threading policy objects through every
/// constructor. Host apps may wrap a card with their own instance to override
/// the defaults. The `*Of` accessors fall back to the [AdaptiveUriPolicy.standard]
/// / [AdaptiveFetchPolicy.standard] defaults when no ancestor is present, so
/// validation is never silently skipped.
class InheritedAdaptiveCardSecurityPolicy extends InheritedWidget {
  /// Creates the inherited policy holder wrapping [child].
  const InheritedAdaptiveCardSecurityPolicy({
    required this.uriPolicy,
    required this.fetchPolicy,
    required super.child,
    super.key,
  });

  /// Policy governing which card-controlled URLs may be launched/fetched.
  final AdaptiveUriPolicy uriPolicy;

  /// Policy governing size/timeout of card-initiated fetches.
  final AdaptiveFetchPolicy fetchPolicy;

  /// Returns the nearest [uriPolicy], or [AdaptiveUriPolicy.standard] if none.
  static AdaptiveUriPolicy uriPolicyOf(BuildContext context) {
    return maybeOf(context)?.uriPolicy ?? AdaptiveUriPolicy.standard;
  }

  /// Returns the nearest [fetchPolicy], or [AdaptiveFetchPolicy.standard].
  static AdaptiveFetchPolicy fetchPolicyOf(BuildContext context) {
    return maybeOf(context)?.fetchPolicy ?? AdaptiveFetchPolicy.standard;
  }

  /// Returns the nearest ancestor instance, or null if none is present.
  static InheritedAdaptiveCardSecurityPolicy? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<
          InheritedAdaptiveCardSecurityPolicy
        >();
  }

  @override
  bool updateShouldNotify(InheritedAdaptiveCardSecurityPolicy oldWidget) {
    return uriPolicy != oldWidget.uriPolicy ||
        fetchPolicy != oldWidget.fetchPolicy;
  }
}
