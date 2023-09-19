///
/// https://adaptivecards.io/explorer/ImageSet.html
///
import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards/src/inherited_reference_resolver.dart';

import '../adaptive_mixins.dart';
import '../additional.dart';
import '../elements/image.dart';

class AdaptiveImageSet extends StatefulWidget with AdaptiveElementWidgetMixin {
  AdaptiveImageSet(
      {super.key, required this.adaptiveMap, required this.supportMarkdown});

  final Map<String, dynamic> adaptiveMap;
  final bool supportMarkdown;

  @override
  _AdaptiveImageSetState createState() => _AdaptiveImageSetState();
}

class _AdaptiveImageSetState extends State<AdaptiveImageSet>
    with AdaptiveElementMixin {
  late List<AdaptiveImage> images;

  late String imageSize;
  double? maybeSize;

  @override
  void initState() {
    super.initState();

    images = List<Map<String, dynamic>>.from(adaptiveMap["images"])
        .map((child) => AdaptiveImage(
              adaptiveMap: child,
              supportMarkdown: widget.supportMarkdown,
            ))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    loadSize();
    var backgroundColor = InheritedReferenceResolver.of(context)
        .resolver
        .resolveBackgroundColorIfNoBackgroundImageAndNoDefaultStyle(
            context: context,
            style: adaptiveMap['style']?.toString(),
            backgroundImageUrl:
                adaptiveMap['backgroundImage']?['url']?.toString());

    return SeparatorElement(
      adaptiveMap: adaptiveMap,
      child: Container(
        color: backgroundColor,
        child: LayoutBuilder(builder: (context, constraints) {
          return Wrap(
            //maxCrossAxisExtent: 200.0,
            children: images
                .map((img) =>
                    SizedBox(width: calculateSize(constraints), child: img))
                .toList(),
            //shrinkWrap: true,
          );
        }),
      ),
    );
  }

  double calculateSize(BoxConstraints constraints) {
    if (maybeSize != null) return maybeSize!;
    if (imageSize == "stretch") return constraints.maxWidth;
    // Display a maximum of 5 children
    if (images.length >= 5) {
      return constraints.maxWidth / 5;
    } else if (images.length == 0) {
      return 0.0;
    } else {
      return constraints.maxWidth / images.length;
    }
  }

  void loadSize() {
    String sizeDescription = adaptiveMap["imageSize"] ?? "auto";
    if (sizeDescription == "auto") {
      imageSize = "auto";
      return;
    }
    if (sizeDescription == "stretch") {
      imageSize = "stretch";
      return;
    }
    int size = InheritedReferenceResolver.of(context)
        .resolver
        .resolveImageSizes(sizeDescription);
    maybeSize = size.toDouble();
  }
}
