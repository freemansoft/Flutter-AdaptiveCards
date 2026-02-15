import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_plus/src/adaptive_mixins.dart';
import 'package:flutter_adaptive_cards_plus/src/additional.dart';
import 'package:flutter_adaptive_cards_plus/src/elements/image.dart';
import 'package:flutter_adaptive_cards_plus/src/riverpod_providers.dart';
import 'package:flutter_adaptive_cards_plus/src/utils/utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

///
/// https://adaptivecards.io/explorer/ImageSet.html
///
class AdaptiveImageSet extends StatefulWidget with AdaptiveElementWidgetMixin {
  AdaptiveImageSet({
    required this.adaptiveMap,
    required this.supportMarkdown,
  }) : super(key: generateAdaptiveWidgetKey(adaptiveMap)) {
    id = loadId(adaptiveMap);
  }

  @override
  final Map<String, dynamic> adaptiveMap;

  @override
  late final String id;

  final bool supportMarkdown;

  @override
  AdaptiveImageSetState createState() => AdaptiveImageSetState();
}

class AdaptiveImageSetState extends State<AdaptiveImageSet>
    with AdaptiveElementMixin, AdaptiveVisibilityMixin {
  late List<AdaptiveImage> images;

  late String imageSize;
  double? maybeSize;

  Color? backgroundColor;

  @override
  void initState() {
    super.initState();

    images = List<Map<String, dynamic>>.from(adaptiveMap['images'] ?? [])
        .map(
          (child) => AdaptiveImage(
            adaptiveMap: child,
            supportMarkdown: widget.supportMarkdown,
          ),
        )
        .toList();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    loadSize();
    backgroundColor = ProviderScope.containerOf(context)
        .read(styleReferenceResolverProvider)
        .resolveContainerBackgroundColor(
          style: style,
        );
  }

  @override
  Widget build(BuildContext context) {
    // developer.log(
    //   'Building ImageSet $id with ${images.length} images maybeSize: $maybeSize',
    //   name: runtimeType.toString(),
    // );
    return Visibility(
      visible: isVisible,
      child: SeparatorElement(
        adaptiveMap: adaptiveMap,
        child: Container(
          color: backgroundColor,
          child: Wrap(
            children: images.map((img) {
              if (maybeSize != null) {
                return SizedBox(width: maybeSize, child: img);
              }
              // Calculate factor
              double factor = 1;
              if (imageSize == 'stretch') {
                factor = 1;
              } else if (images.length >= 5) {
                factor = 1.0 / 5.0;
              } else if (images.isNotEmpty) {
                factor = 1.0 / images.length;
              }
              developer.log(
                'factor $factor for $id',
                name: runtimeType.toString(),
              );
              return FractionallySizedBox(widthFactor: factor, child: img);
            }).toList(),
          ),
        ),
      ),
    );
  }

  void loadSize() {
    String sizeDescription = adaptiveMap['imageSize']?.toString() ?? 'auto';
    sizeDescription = sizeDescription.toLowerCase();
    if (sizeDescription == 'auto' || sizeDescription == 'stretch') {
      imageSize = sizeDescription;
      maybeSize = null;
      return;
    }
    final int size =
        ProviderScope.containerOf(context)
            .read(styleReferenceResolverProvider)
            .getImageSetConfig()
            ?.imageSize(sizeDescription) ??
        20;
    maybeSize = size.toDouble();
  }
}
