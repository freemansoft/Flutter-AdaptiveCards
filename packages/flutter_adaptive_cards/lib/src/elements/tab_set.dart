import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards/src/adaptive_mixins.dart';
import 'package:flutter_adaptive_cards/src/additional.dart';

// Assuming there is a container (TabSet?) that holds TabPages.
// If "TabPage" is the valid element mentioned by user, then likely there is a parent "TabSet".
// Or maybe "TabPage" behaves like a container that renders as a page in a tab view?
// AC usually has a "TabSet" container.
// I will implement "AdaptiveTabSet" which looks for "TabPage" items.

class AdaptiveTabSet extends StatefulWidget with AdaptiveElementWidgetMixin {
  AdaptiveTabSet({super.key, required this.adaptiveMap});

  @override
  final Map<String, dynamic> adaptiveMap;

  @override
  AdaptiveTabSetState createState() => AdaptiveTabSetState();
}

class AdaptiveTabSetState extends State<AdaptiveTabSet>
    with AdaptiveElementMixin, TickerProviderStateMixin {
  late List<Map<String, dynamic>> tabs;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    // Assuming 'tabs' property holds list of TabPage
    final tabList =
        widget.adaptiveMap['tabs'] ?? widget.adaptiveMap['items']; // Fallback
    tabs = [];
    if (tabList is List) {
      tabs = List<Map<String, dynamic>>.from(tabList);
    }
    _tabController = TabController(length: tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (tabs.isEmpty) return const SizedBox.shrink();

    return SeparatorElement(
      adaptiveMap: widget.adaptiveMap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TabBar(
            controller: _tabController,
            labelColor: Colors.black, // TODO(username): context theme
            tabs: tabs.map((t) => Tab(text: t['title'] ?? 'Tab')).toList(),
          ),
          SizedBox(
            // TabBarView needs constrained height or expanded.
            // Adaptive Cards usually flow.
            // We can measure content or use a fixed height // layout builder?
            // "Expandable" tab view is tricky.
            // For MVP: Fixed height or resizing wrapper.
            // I'll use a constrained height for now (same as Carousel MVP issue)
            height: 400,
            child: TabBarView(
              controller: _tabController,
              children: tabs.map((t) {
                // Parse body of the tab
                final List<Widget> children = [];
                final contentItems = t['items'] ?? t['body'];
                if (contentItems is List) {
                  for (final c in contentItems) {
                    final el = widgetState.cardRegistry.getElement(map: c);
                    children.add(el);
                  }
                }
                return SingleChildScrollView(child: Column(children: children));
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
