import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards/src/adaptive_mixins.dart';
import 'package:flutter_adaptive_cards/src/additional.dart';
import 'package:flutter_adaptive_cards/src/utils/utils.dart';

class AdaptiveRating extends StatefulWidget with AdaptiveElementWidgetMixin {
  AdaptiveRating({
    required this.adaptiveMap,
  }) : super(key: generateWidgetKey(adaptiveMap)) {
    id = loadId(adaptiveMap);
  }

  @override
  final Map<String, dynamic> adaptiveMap;

  @override
  late final String id;

  @override
  AdaptiveRatingState createState() => AdaptiveRatingState();
}

class AdaptiveRatingState extends State<AdaptiveRating>
    with AdaptiveElementMixin, AdaptiveVisibilityMixin {
  late double value;
  late double max;
  late String color;
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
    Color starColor;
    if (color == 'marigold') {
      starColor = Colors.orange;
    } else if (color == 'light') {
      starColor = Colors.white70;
    } else {
      starColor = Colors.grey;
    }

    final double iconSize = size == 'large' ? 24 : 16;

    return Visibility(
      visible: isVisible,
      child: SeparatorElement(
        adaptiveMap: adaptiveMap,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(max.toInt(), (index) {
            IconData iconData;
            if (index < value) {
              iconData = Icons.star;
            } else {
              iconData = Icons.star_border;
            }

            return Icon(
              iconData,
              color: starColor,
              size: iconSize,
            );
          }),
        ),
      ),
    );
  }
}
