import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/src/adaptive_mixins.dart';
import 'package:flutter_adaptive_cards_fs/src/additional.dart';
import 'package:flutter_adaptive_cards_fs/src/cards/elements/image.dart';
import 'package:flutter_adaptive_cards_fs/src/utils/utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

///
/// https://adaptivecards.io/explorer/ImageSet.html
///
/// Renders an `ImageSet` as a wrapped row of [AdaptiveImage] children sized by
/// `imageSize`.
class AdaptiveImageSet extends ConsumerStatefulWidget with AdaptiveElementWidgetMixin {
  /// Creates an `ImageSet` from [adaptiveMap].
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

  /// Whether nested text elements may render markdown.
  final bool supportMarkdown;

  @override
  AdaptiveImageSetState createState() => AdaptiveImageSetState();
}

/// State for [AdaptiveImageSet].
class AdaptiveImageSetState extends ConsumerState<AdaptiveImageSet>
    with AdaptiveElementMixin, AdaptiveVisibilityMixin, ProviderScopeMixin {
  /// Child images from the `images` array.
  late List<AdaptiveImage> images;

  /// Parsed `imageSize` token (`auto`, `stretch`, or a HostConfig size name).
  late String imageSize;

  /// Fixed pixel width when [imageSize] maps to a HostConfig size.
  double? maybeSize;

  /// Background color resolved from HostConfig and image set style.
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
    backgroundColor = styleResolver.resolveContainerBackgroundColor(
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

  /// Resolves [imageSize] and [maybeSize] from `imageSize` and HostConfig.
  void loadSize() {
    String sizeDescription = adaptiveMap['imageSize']?.toString() ?? 'auto';
    sizeDescription = sizeDescription.toLowerCase();
    if (sizeDescription == 'auto' || sizeDescription == 'stretch') {
      imageSize = sizeDescription;
      maybeSize = null;
      return;
    }
    final int size =
        styleResolver.getImageSetConfig()?.imageSize(sizeDescription) ?? 20;
    maybeSize = size.toDouble();
  }
}
