import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_plus/src/adaptive_mixins.dart';
import 'package:flutter_adaptive_cards_plus/src/additional.dart';
import 'package:flutter_adaptive_cards_plus/src/hostconfig/image_sizes_config.dart';
import 'package:flutter_adaptive_cards_plus/src/riverpod_providers.dart';
import 'package:flutter_adaptive_cards_plus/src/utils/adaptive_image_utils.dart';
import 'package:flutter_adaptive_cards_plus/src/utils/utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

///
/// https://adaptivecards.io/explorer/Image.html
///
class AdaptiveImage extends StatefulWidget with AdaptiveElementWidgetMixin {
  AdaptiveImage({
    required this.adaptiveMap,
    this.parentMode = 'stretch',
    required this.supportMarkdown,
  }) : super(key: generateAdaptiveWidgetKey(adaptiveMap)) {
    id = loadId(adaptiveMap);
  }

  @override
  final Map<String, dynamic> adaptiveMap;

  @override
  late final String id;

  final String parentMode;
  final bool supportMarkdown;

  @override
  AdaptiveImageState createState() => AdaptiveImageState();
}

class AdaptiveImageState extends State<AdaptiveImage>
    with AdaptiveElementMixin, AdaptiveVisibilityMixin {
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
    horizontalAlignment = ProviderScope.containerOf(context)
        .read(styleReferenceResolverProvider)
        .resolveAlignment(
          adaptiveMap['horizontalAlignment'],
        );
  }

  @override
  Widget build(BuildContext context) {
    BoxFit fit = BoxFit.contain;
    if (height != null && width != null && height != width) {
      fit = BoxFit.fill;
    }

    Widget image = AdaptiveTappable(
      adaptiveMap: adaptiveMap,
      child: AdaptiveImageUtils.getImage(
        url,
        fit: fit,
        height: height,
        width: width,
        semanticsLabel: adaptiveMap['altText']?.toString(),
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

    return Visibility(
      visible: isVisible,
      child: SeparatorElement(
        adaptiveMap: adaptiveMap,
        child: child,
      ),
    );
  }

  bool loadIsPerson() {
    if (style == null || style == 'default') {
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
        ProviderScope.containerOf(
          context,
        ).read(styleReferenceResolverProvider).getImageSizesConfig(),
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
