import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards/src/adaptive_mixins.dart';
import 'package:flutter_adaptive_cards/src/additional.dart';
import 'package:flutter_adaptive_cards/src/hostconfig/image_sizes_config.dart';
import 'package:flutter_adaptive_cards/src/inherited_reference_resolver.dart';
import 'package:flutter_adaptive_cards/src/utils.dart';

///
/// https://adaptivecards.io/explorer/Image.html
///
class AdaptiveImage extends StatefulWidget with AdaptiveElementWidgetMixin {
  AdaptiveImage({
    super.key,
    required this.adaptiveMap,
    this.parentMode = 'stretch',
    required this.supportMarkdown,
  });

  @override
  final Map<String, dynamic> adaptiveMap;
  final String parentMode;
  final bool supportMarkdown;

  @override
  AdaptiveImageState createState() => AdaptiveImageState();
}

class AdaptiveImageState extends State<AdaptiveImage>
    with AdaptiveElementMixin {
  late bool isPerson;
  double? width;
  double? height;
  late Alignment horizontalAlignment;

  @override
  void initState() {
    super.initState();
    isPerson = loadIsPerson();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    loadSize();
    horizontalAlignment = InheritedReferenceResolver.of(context).resolver
        .resolveAlignment(
          adaptiveMap['horizontalAlignment'],
        );
  }

  @override
  Widget build(BuildContext context) {
    BoxFit fit = BoxFit.contain;
    if (height != null && width != null) {
      fit = BoxFit.fill;
    }

    Widget image = AdaptiveTappable(
      adaptiveMap: adaptiveMap,
      child: Image.network(
        url,
        semanticLabel: adaptiveMap['altText']?.toString(),
        fit: fit,
        height: height,
        width: width,
        // errorBuilder: (context, error, stacktrace) {
        //   return Text(
        //     'Failed to load image: $error.',
        //   );
        // },
      ),
    );

    if (isPerson) {
      image = ClipOval(clipper: FullCircleClipper(), child: image);
    }

    Widget child;

    if (widget.supportMarkdown) {
      child = Align(alignment: horizontalAlignment, child: image);
    } else {
      child = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.parentMode == 'auto')
            Flexible(child: image)
          else
            Expanded(
              child: Align(alignment: horizontalAlignment, child: image),
            ),
        ],
      );
    }

    return SeparatorElement(adaptiveMap: adaptiveMap, child: child);
  }

  bool loadIsPerson() {
    if (adaptiveMap['style'] == null || adaptiveMap['style'] == 'default') {
      return false;
    }
    return true;
  }

  String get url => adaptiveMap['url']?.toString() ?? '';

  void loadSize() {
    String sizeDescription = adaptiveMap['size']?.toString() ?? 'auto';
    sizeDescription = sizeDescription.toLowerCase();

    int? size;
    if (sizeDescription != 'auto' && sizeDescription != 'stretch') {
      size = ImageSizesConfig.resolveImageSizes(
        InheritedReferenceResolver.of(
          context,
        ).resolver.getImageSizesConfig(),
        sizeDescription,
      );
    }

    int? width = size;
    int? height = size;

    // Overwrite dynamic size if fixed size is given
    if (adaptiveMap['width'] != null) {
      var widthString = adaptiveMap['width'].toString();
      widthString = widthString.substring(
        0,
        widthString.length - 2,
      ); // remove px
      width = int.parse(widthString);
    }
    if (adaptiveMap['height'] != null) {
      var heightString = adaptiveMap['height'].toString();
      heightString = heightString.substring(
        0,
        heightString.length - 2,
      ); // remove px
      height = int.parse(heightString);
    }

    if (height == null && width == null) {
      return;
    }

    this.width = width?.toDouble();
    this.height = height?.toDouble();
  }
}
