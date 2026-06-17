import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/src/adaptive_mixins.dart';
import 'package:flutter_adaptive_cards_fs/src/additional.dart';
import 'package:flutter_adaptive_cards_fs/src/hostconfig/image_sizes_config.dart';
import 'package:flutter_adaptive_cards_fs/src/riverpod/providers.dart';
import 'package:flutter_adaptive_cards_fs/src/utils/adaptive_image_utils.dart';
import 'package:flutter_adaptive_cards_fs/src/utils/utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

///
/// https://adaptivecards.io/explorer/Image.html
///
class AdaptiveImage extends ConsumerStatefulWidget with AdaptiveElementWidgetMixin {
  /// Creates an image element from [adaptiveMap] JSON.
  ///
  /// [parentMode] controls flex behavior when nested in column/row layouts.
  /// [supportMarkdown] enables markdown-friendly alignment when true.
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

  /// Parent container width mode (`auto`, `stretch`, etc.).
  final String parentMode;

  /// When true, uses [Align] instead of [Row] for horizontal placement.
  final bool supportMarkdown;

  @override
  AdaptiveImageState createState() => AdaptiveImageState();
}

/// State for [AdaptiveImage]; resolves size, style, and reactive URL updates.
class AdaptiveImageState extends ConsumerState<AdaptiveImage>
    with AdaptiveElementMixin, AdaptiveVisibilityMixin, ProviderScopeMixin {
  /// Whether to clip the image to a circle (`style: person`).
  late bool isPerson;

  /// Resolved width in logical pixels, when constrained.
  double? width;

  /// Resolved height in logical pixels, when constrained.
  double? height;

  /// Horizontal alignment within the parent from `horizontalAlignment`.
  late Alignment horizontalAlignment;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    isPerson = loadIsPerson();
    loadSize();
    horizontalAlignment = styleResolver.resolveAlignment(
      adaptiveMap['horizontalAlignment'],
    );
  }

  @override
  Widget build(BuildContext context) {
    final resolved = ref.watch(resolvedElementProvider(id));
    final url = resolved?['url']?.toString() ?? widget.adaptiveMap['url']?.toString() ?? '';

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

  /// Returns whether HostConfig marks this image as a person avatar.
  bool loadIsPerson() {
    return styleResolver.resolveImageIsPerson(
      adaptiveMap['style'] as String?,
    );
  }

  /// Parses `size`, `width`, and `height` into [width] and [height].
  void loadSize() {
    String sizeDescription = adaptiveMap['size']?.toString() ?? 'auto';
    sizeDescription = sizeDescription.toLowerCase();

    int? size;
    if (sizeDescription != 'auto' && sizeDescription != 'stretch') {
      size = ImageSizesConfig.resolveImageSizes(
        styleResolver.getImageSizesConfig(),
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
