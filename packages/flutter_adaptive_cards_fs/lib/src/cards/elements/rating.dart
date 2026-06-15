import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/src/adaptive_mixins.dart';
import 'package:flutter_adaptive_cards_fs/src/additional.dart';
import 'package:flutter_adaptive_cards_fs/src/utils/utils.dart';
import 'package:flutter_adaptive_cards_fs/src/widgets/rating_stars.dart';

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

  @override
  void initState() {
    super.initState();
    value = (adaptiveMap['value'] as num? ?? 0).toDouble();
    max = (adaptiveMap['max'] as num? ?? 5).toDouble();
    color = adaptiveMap['color'] as String? ?? 'neutral';
    size = adaptiveMap['size'] as String? ?? 'medium';
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
