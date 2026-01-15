import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards/src/adaptive_mixins.dart';
import 'package:flutter_adaptive_cards/src/additional.dart';

class AdaptiveCarousel extends StatefulWidget with AdaptiveElementWidgetMixin {
  AdaptiveCarousel({super.key, required this.adaptiveMap});

  @override
  final Map<String, dynamic> adaptiveMap;

  @override
  AdaptiveCarouselState createState() => AdaptiveCarouselState();
}

class AdaptiveCarouselState extends State<AdaptiveCarousel>
    with AdaptiveElementMixin {
  late List<Map<String, dynamic>> pages;
  late int initialPage;
  late int? timer;
  late PageController pageController;
  Timer? autoPlayTimer;

  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    var pagesList = widget.adaptiveMap['pages'];
    if (pagesList is List) {
      pages = List<Map<String, dynamic>>.from(pagesList);
    } else {
      pages = [];
    }
    initialPage = widget.adaptiveMap['initialPage'] ?? 0;
    if (initialPage < 0 || initialPage >= pages.length) initialPage = 0;
    _currentIndex = initialPage;

    timer = widget.adaptiveMap['timer']; // in milliseconds

    pageController = PageController(initialPage: initialPage);

    if (timer != null && timer! > 0) {
      autoPlayTimer = Timer.periodic(Duration(milliseconds: timer!), (timer) {
        if (pageController.hasClients) {
          // If user is interacting, maybe pause? For MVP we just scroll.
          int nextPage = (pageController.page!.round() + 1) % pages.length;
          pageController.animateToPage(
            nextPage,
            duration: Duration(milliseconds: 300),
            curve: Curves.easeIn,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    autoPlayTimer?.cancel();
    pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _goToPage(int index) {
    pageController.animateToPage(
      index,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (pages.isEmpty) return SizedBox.shrink();

    // The implementation needs to render the pages AND the controls.
    // The previous implementation used a SeparatorElement. We should probably keep that.

    return SeparatorElement(
      adaptiveMap: widget.adaptiveMap,
      child: Column(
        mainAxisSize: MainAxisSize.min, // Wrap content
        children: [
          // Carousel Content
          SizedBox(
            height:
                400, // Still fixed height for now as pages might be flexible
            child: PageView.builder(
              controller: pageController,
              onPageChanged: _onPageChanged,
              itemCount: pages.length,
              itemBuilder: (context, index) {
                var pageContent = pages[index];
                // We expect pageContent to likely be type: CarouselPage
                // But it could be any element if the JSON is weak.
                // If it is CarouselPage, the Registry will pick it up (if we register it).

                return widgetState.cardRegistry.getElement(pageContent);
              },
            ),
          ),
          SizedBox(height: 8),
          // Carousel Controls
          _buildControls(),
        ],
      ),
    );
  }

  Widget _buildControls() {
    // "The control has a smal circular button for each each CarouselPage...
    // The current page will be bar the same width as 3 of the non selected page dots."
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(pages.length, (index) {
        bool isSelected = index == _currentIndex;
        return GestureDetector(
          onTap: () => _goToPage(index),
          child: AnimatedContainer(
            duration: Duration(milliseconds: 300),
            margin: EdgeInsets.symmetric(horizontal: 4),
            width: isSelected ? 24.0 : 8.0, // Bar width vs Dot width
            height: 8.0,
            decoration: BoxDecoration(
              color: isSelected
                  ? Theme.of(context).primaryColor
                  : Colors.grey.withAlpha(128),
              borderRadius: BorderRadius.circular(4), // Fully rounded
            ),
          ),
        );
      }),
    );
  }
}

class AdaptiveCarouselPage extends StatefulWidget
    with AdaptiveElementWidgetMixin {
  AdaptiveCarouselPage({super.key, required this.adaptiveMap});

  @override
  final Map<String, dynamic> adaptiveMap;

  @override
  AdaptiveCarouselPageState createState() => AdaptiveCarouselPageState();
}

class AdaptiveCarouselPageState extends State<AdaptiveCarouselPage>
    with AdaptiveElementMixin {
  late List<Widget> children;

  @override
  void initState() {
    super.initState();
    children = [];
    var items = widget.adaptiveMap['items']; // Content is in "items"
    if (items is List) {
      for (var item in items) {
        children.add(widgetState.cardRegistry.getElement(item));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    bool showBorder = widget.adaptiveMap['showBorder'] == true;
    bool roundedCorners = widget.adaptiveMap['roundedCorners'] == true;
    String? style = widget.adaptiveMap['style'];

    // Resolve background color based on style
    // We can use ReferenceResolver logic or simple map for now.
    // inherited_reference_resolver logic is usually handled by the registry wrapping this? No.
    // We can assume InheritedReferenceResolver is present.
    // But specific container logic might be needed.

    Color? backgroundColor;
    if (style != null) {
      // Basic mapping
      if (style == 'emphasis') backgroundColor = Colors.grey.shade100;
      if (style == 'good') backgroundColor = Colors.green.shade50;
      if (style == 'attention') backgroundColor = Colors.red.shade50;
      if (style == 'warning') backgroundColor = Colors.amber.shade50;
      if (style == 'accent') backgroundColor = Colors.blue.shade50;
    }

    BoxDecoration? decoration;
    if (showBorder || backgroundColor != null) {
      decoration = BoxDecoration(
        color: backgroundColor,
        border: showBorder ? Border.all(color: Colors.grey.shade300) : null,
        borderRadius: roundedCorners ? BorderRadius.circular(8.0) : null,
      );
    }

    return Container(
      decoration: decoration,
      padding: EdgeInsets.all(12), // Some padding for the page content
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}
