import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_adaptive_cards_fs/src/adaptive_mixins.dart';
import 'package:flutter_adaptive_cards_fs/src/additional.dart';
import 'package:flutter_adaptive_cards_fs/src/reference_resolver.dart';
import 'package:flutter_adaptive_cards_fs/src/utils/utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Renders the Adaptive Cards **Carousel** element with page dots.
///
/// See https://adaptivecards.io/explorer/Carousel.html
class AdaptiveCarousel extends ConsumerStatefulWidget
    with AdaptiveElementWidgetMixin {
  /// Creates a carousel from [adaptiveMap] JSON.
  AdaptiveCarousel({
    required this.adaptiveMap,
  }) : super(key: generateAdaptiveWidgetKey(adaptiveMap)) {
    id = loadId(adaptiveMap);
  }

  @override
  final Map<String, dynamic> adaptiveMap;

  @override
  late final String id;

  @override
  AdaptiveCarouselState createState() => AdaptiveCarouselState();
}

/// State for [AdaptiveCarousel]; drives [PageView] and dot controls.
class AdaptiveCarouselState extends ConsumerState<AdaptiveCarousel>
    with AdaptiveElementMixin, AdaptiveVisibilityMixin, ProviderScopeMixin {
  /// Carousel page maps from `pages`.
  late List<Map<String, dynamic>> pages;

  /// Zero-based index of the page shown on first build.
  late int initialPage;

  /// Controller for horizontal page swipes and dot navigation.
  late PageController pageController;

  /// Auto-advance interval in milliseconds from `timer`; null disables it.
  int? autoAdvanceMs;

  /// Scroll axis from `orientation` (`vertical` -> [Axis.vertical]).
  Axis scrollAxis = Axis.horizontal;

  /// Whether to wrap past the last page from `loop`.
  bool loop = false;

  /// Fixed pixel height from `heightInPixels` (e.g. `"100px"`); null when
  /// unset.
  double? heightInPixels;

  /// Whether `height` is `stretch` (fill parent) rather than the default auto.
  bool isStretchHeight = false;

  /// Fallback height used before the pages have been measured.
  static const double _fallbackHeight = 400;

  /// Measured natural height of each page, keyed by page index.
  final Map<int, double> _pageHeights = <int, double>{};

  Timer? _autoAdvanceTimer;

  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    final pagesList = adaptiveMap['pages'];
    if (pagesList is List) {
      pages = List<Map<String, dynamic>>.from(pagesList);
    } else {
      pages = [];
    }
    initialPage = adaptiveMap['initialPage'] as int? ?? 0;
    if (initialPage < 0 || initialPage >= pages.length) initialPage = 0;
    _currentIndex = initialPage;

    pageController = PageController(initialPage: initialPage);
    autoAdvanceMs = adaptiveMap['timer'] as int?;
    scrollAxis =
        adaptiveMap['orientation']?.toString().toLowerCase() == 'vertical'
        ? Axis.vertical
        : Axis.horizontal;
    loop = adaptiveMap['loop'] == true;
    heightInPixels = _parsePixelHeight(adaptiveMap['heightInPixels']);
    isStretchHeight =
        adaptiveMap['height']?.toString().toLowerCase() == 'stretch';
    _startAutoAdvance();
  }

  double? _parsePixelHeight(Object? raw) {
    if (raw == null) return null;
    final String cleaned = raw
        .toString()
        .toLowerCase()
        .replaceAll('px', '')
        .trim();
    final double? value = double.tryParse(cleaned);
    return (value != null && value > 0) ? value : null;
  }

  double? _measuredMaxHeight() {
    if (_pageHeights.length < pages.length) return null;
    return _pageHeights.values.fold<double>(
      0,
      (double m, double h) => h > m ? h : m,
    );
  }

  void _recordPageHeight(int index, double height) {
    if (!mounted) return;
    if (_pageHeights[index] == height) return;
    setState(() => _pageHeights[index] = height);
  }

  void _startAutoAdvance() {
    final ms = autoAdvanceMs;
    if (ms == null || ms <= 0 || pages.length < 2) return;
    _autoAdvanceTimer = Timer.periodic(Duration(milliseconds: ms), (_) {
      if (!mounted) return;
      var next = _currentIndex + 1;
      if (next >= pages.length) {
        if (!loop) {
          _autoAdvanceTimer?.cancel();
          return;
        }
        next = 0;
      }
      _goToPage(next);
    });
  }

  @override
  void dispose() {
    _autoAdvanceTimer?.cancel();
    pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _goToPage(int index) {
    unawaited(
      pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (pages.isEmpty) return const SizedBox.shrink();

    return Visibility(
      visible: isVisible,
      child: SeparatorElement(
        adaptiveMap: adaptiveMap,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double? measuredMax = _measuredMaxHeight();
            final double height = resolveCarouselHeight(
              heightInPixels: heightInPixels,
              isStretch: isStretchHeight,
              maxAvailableHeight: constraints.maxHeight,
              measuredMaxHeight: measuredMax,
              fallback: _fallbackHeight,
            );
            final bool needsMeasure =
                heightInPixels == null &&
                !(isStretchHeight && constraints.maxHeight.isFinite) &&
                measuredMax == null;

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (needsMeasure) _buildMeasurementLayer(constraints.maxWidth),
                SizedBox(
                  height: height,
                  child: PageView.builder(
                    controller: pageController,
                    scrollDirection: scrollAxis,
                    onPageChanged: _onPageChanged,
                    itemCount: pages.length,
                    itemBuilder: (context, index) {
                      return cardTypeRegistry.getElement(map: pages[index]);
                    },
                  ),
                ),
                const SizedBox(height: 8),
                _buildControls(styleResolver),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Off-stage layer that lays out every page at the carousel width so each
  /// page's natural height can be measured; dropped once all pages are known.
  // Building each page here in addition to the PageView is safe: the spec
  // forbids Input.* and Media inside CarouselPages, so there's no
  // input/document state to double-register.
  Widget _buildMeasurementLayer(double width) {
    return Offstage(
      child: Column(
        children: [
          for (int i = 0; i < pages.length; i++)
            _MeasureSize(
              onChange: (Size size) => _recordPageHeight(i, size.height),
              child: SizedBox(
                width: width.isFinite ? width : null,
                child: cardTypeRegistry.getElement(map: pages[i]),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildControls(ReferenceResolver resolver) {
    // "The control has a smal circular button for each each CarouselPage... The
    // current page will be bar the same width as 3 of the non selected page
    // dots."
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(pages.length, (index) {
        final bool isSelected = index == _currentIndex;
        return Semantics(
          button: true,
          selected: isSelected,
          label: 'Go to slide ${index + 1}',
          child: GestureDetector(
            onTap: () => _goToPage(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: isSelected ? 24.0 : 8.0, // Bar width vs Dot width
              height: 8,
              decoration: BoxDecoration(
                color: _currentIndex == index
                    ? resolver.resolveContainerForegroundColor(
                            style: 'default',
                          ) ??
                          Colors.black
                    : resolver.resolveContainerForegroundColor(
                            style: 'default',
                            isSubtle: true,
                          ) ??
                          Colors.grey.withAlpha(128),
                borderRadius: BorderRadius.circular(4), // Fully rounded
              ),
            ),
          ),
        );
      }),
    );
  }
}

/// Renders a single **CarouselPage** inside a [AdaptiveCarousel].
///
/// See https://adaptivecards.io/explorer/CarouselPage.html
class AdaptiveCarouselPage extends StatefulWidget
    with AdaptiveElementWidgetMixin {
  /// Creates a carousel page from [adaptiveMap] JSON.
  AdaptiveCarouselPage({
    super.key,
    required this.adaptiveMap,
  }) {
    id = loadId(adaptiveMap);
  }

  @override
  final Map<String, dynamic> adaptiveMap;

  @override
  late final String id;

  @override
  AdaptiveCarouselPageState createState() => AdaptiveCarouselPageState();
}

/// State for [AdaptiveCarouselPage]; builds child elements from `items`.
class AdaptiveCarouselPageState extends State<AdaptiveCarouselPage>
    with AdaptiveElementMixin, ProviderScopeMixin {
  /// Child element widgets resolved from the page `items` array.
  late List<Widget> children;

  @override
  void didChangeDependencies() {
    children = [];
    final items = adaptiveMap['items']; // Content is in "items"
    if (items is List) {
      for (final item in items) {
        children.add(
          cardTypeRegistry.getElement(
            map: item,
          ),
        );
      }
    }
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    final bool showBorder = adaptiveMap['showBorder'] == true;
    final bool roundedCorners = adaptiveMap['roundedCorners'] == true;

    // Resolve background color based on style
    // We can use ReferenceResolver logic or simple map for now.
    // But specific container logic might be needed.

    final Color? backgroundColor = styleResolver
        .resolveContainerBackgroundColor(
          style: style,
        );

    BoxDecoration? decoration;
    if (showBorder || backgroundColor != null) {
      decoration = BoxDecoration(
        color: backgroundColor,
        border: showBorder
            ? Border.all(
                color: styleResolver.resolveSeparatorColor(),
              )
            : null,
        borderRadius: roundedCorners ? BorderRadius.circular(8) : null,
      );
    }

    return AdaptiveTappable(
      adaptiveMap: adaptiveMap,
      child: Container(
        decoration: decoration,
        padding: const EdgeInsets.all(12), // Some padding for the page content
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );
  }
}

/// Resolves the pixel height for the carousel's page container.
///
/// Precedence: an explicit `heightInPixels` wins; otherwise a `stretch` height
/// fills the parent when it supplies a finite height; otherwise the measured
/// tallest page is used; before any measurement the [fallback] applies.
double resolveCarouselHeight({
  required double? heightInPixels,
  required bool isStretch,
  required double maxAvailableHeight,
  required double? measuredMaxHeight,
  required double fallback,
}) {
  if (heightInPixels != null) return heightInPixels;
  if (isStretch && maxAvailableHeight.isFinite) return maxAvailableHeight;
  return measuredMaxHeight ?? fallback;
}

typedef _SizeCallback = void Function(Size size);

/// Reports its child's laid-out [Size] after each layout, off the paint path.
///
/// Used by [AdaptiveCarousel] to measure each page's natural height so the
/// carousel can size itself to the tallest page.
class _MeasureSize extends SingleChildRenderObjectWidget {
  const _MeasureSize({required this.onChange, required Widget super.child});

  final _SizeCallback onChange;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _MeasureSizeRenderObject(onChange);

  @override
  void updateRenderObject(
    BuildContext context,
    _MeasureSizeRenderObject renderObject,
  ) {
    renderObject.onChange = onChange;
  }
}

class _MeasureSizeRenderObject extends RenderProxyBox {
  _MeasureSizeRenderObject(this.onChange);

  _SizeCallback onChange;
  Size? _oldSize;

  @override
  void performLayout() {
    super.performLayout();
    final Size newSize = child?.size ?? Size.zero;
    if (_oldSize == newSize) return;
    _oldSize = newSize;
    WidgetsBinding.instance.addPostFrameCallback((_) => onChange(newSize));
  }
}
