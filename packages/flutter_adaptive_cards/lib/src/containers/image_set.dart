import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards/src/adaptive_mixins.dart';
import 'package:flutter_adaptive_cards/src/additional.dart';
import 'package:flutter_adaptive_cards/src/elements/image.dart';
import 'package:flutter_adaptive_cards/src/riverpod_providers.dart';
import 'package:flutter_adaptive_cards/src/utils/utils.dart';
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
    return Visibility(
      visible: isVisible,
      child: SeparatorElement(
        adaptiveMap: adaptiveMap,
        child: Container(
          color: backgroundColor,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Wrap(
                //maxCrossAxisExtent: 200.0,
                children: images
                    .map(
                      (img) => SizedBox(
                        width: calculateSize(constraints),
                        child: img,
                      ),
                    )
                    .toList(),
                //shrinkWrap: true,
              );
            },
          ),
        ),
      ),
    );
  }

  double calculateSize(BoxConstraints constraints) {
    if (maybeSize != null) return maybeSize!;
    if (imageSize == 'stretch') return constraints.maxWidth;
    // Display a maximum of 5 children
    if (images.length >= 5) {
      return constraints.maxWidth / 5;
    } else if (images.isEmpty) {
      return 0;
    } else {
      return constraints.maxWidth / images.length;
    }
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
