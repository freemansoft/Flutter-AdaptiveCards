import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/src/adaptive_mixins.dart';
import 'package:flutter_adaptive_cards_fs/src/additional.dart';
import 'package:flutter_adaptive_cards_fs/src/riverpod/providers.dart';
import 'package:flutter_adaptive_cards_fs/src/utils/utils.dart';
import 'package:flutter_adaptive_cards_fs/src/widgets/rating_stars.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Renders the Adaptive Cards **Rating** element as a row of stars.
///
/// See https://adaptivecards.io/explorer/Rating.html
class AdaptiveRating extends StatefulWidget with AdaptiveElementWidgetMixin {
  /// Creates a rating display from [adaptiveMap] JSON.
  AdaptiveRating({
    required this.adaptiveMap,
  }) : super(key: generateAdaptiveWidgetKey(adaptiveMap)) {
    id = loadId(adaptiveMap);
  }

  @override
  final Map<String, dynamic> adaptiveMap;

  @override
  late final String id;

  @override
  AdaptiveRatingState createState() => AdaptiveRatingState();
}

/// State for [AdaptiveRating]; renders filled and empty star icons.
class AdaptiveRatingState extends State<AdaptiveRating>
    with AdaptiveElementMixin, AdaptiveVisibilityMixin, ProviderScopeMixin {
  /// Current rating from `value`.
  late double value;

  /// Maximum star count from `max` (default 5).
  late double max;

  /// Color token from `color` (`neutral`, `marigold`, `light`).
  late String color;

  /// Icon size token from `size` (`medium` or `large`).
  late String size;

  ProviderSubscription<Map<String, dynamic>?>? _resolvedSubscription;

  @override
  void initState() {
    super.initState();
    value = (adaptiveMap['value'] as num? ?? 0).toDouble();
    max = (adaptiveMap['max'] as num? ?? 5).toDouble();
    color = adaptiveMap['color'] as String? ?? 'neutral';
    size = adaptiveMap['size'] as String? ?? 'medium';
  }

  void _syncFromResolved(Map<String, dynamic> resolved) {
    final nextValue = (resolved['value'] as num? ?? 0).toDouble();
    final nextMax = (resolved['max'] as num? ?? 5).toDouble();
    final nextColor = resolved['color'] as String? ?? 'neutral';
    final nextSize = resolved['size'] as String? ?? 'medium';
    if (nextValue == value &&
        nextMax == max &&
        nextColor == color &&
        nextSize == size) {
      return;
    }
    setState(() {
      value = nextValue;
      max = nextMax;
      color = nextColor;
      size = nextSize;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    _resolvedSubscription?.close();
    final container = ProviderScope.containerOf(context);
    _resolvedSubscription = container.listen<Map<String, dynamic>?>(
      resolvedElementProvider(id),
      (previous, next) {
        if (next == null) return;
        _syncFromResolved(next);
      },
      fireImmediately: true,
    );
  }

  @override
  void dispose() {
    _resolvedSubscription?.close();
    _resolvedSubscription = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final starColor = resolveRatingStarColor(styleResolver, color);
    final iconSize = resolveRatingIconSize(size);

    return Visibility(
      visible: isVisible,
      child: SeparatorElement(
        adaptiveMap: adaptiveMap,
        child: RatingStars(
          value: value,
          max: max,
          starColor: starColor,
          iconSize: iconSize,
        ),
      ),
    );
  }
}
