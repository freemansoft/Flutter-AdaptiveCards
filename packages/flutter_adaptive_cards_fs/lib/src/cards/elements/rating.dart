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
class AdaptiveRating extends ConsumerStatefulWidget
    with AdaptiveElementWidgetMixin {
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
class AdaptiveRatingState extends ConsumerState<AdaptiveRating>
    with AdaptiveElementMixin, AdaptiveVisibilityMixin, ProviderScopeMixin {
  @override
  Widget build(BuildContext context) {
    final resolved = ref.watch(resolvedElementProvider(id));
    final value = ((resolved?['value'] ?? adaptiveMap['value']) as num? ?? 0)
        .toDouble();
    final max = ((resolved?['max'] ?? adaptiveMap['max']) as num? ?? 5)
        .toDouble();
    final color =
        (resolved?['color'] as String?) ??
        (adaptiveMap['color'] as String?) ??
        'neutral';
    final size =
        (resolved?['size'] as String?) ??
        (adaptiveMap['size'] as String?) ??
        'medium';

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
