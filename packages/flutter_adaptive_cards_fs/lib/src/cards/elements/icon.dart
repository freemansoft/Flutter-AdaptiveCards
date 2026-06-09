import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/src/adaptive_mixins.dart';
import 'package:flutter_adaptive_cards_fs/src/additional.dart';
import 'package:flutter_adaptive_cards_fs/src/reference_resolver.dart';
import 'package:flutter_adaptive_cards_fs/src/utils/fluent_icon_map.dart';
import 'package:flutter_adaptive_cards_fs/src/utils/utils.dart';

/// Renders the Adaptive Cards hub **Icon** element (Fluent icon catalog).
///
/// See https://learn.microsoft.com/en-us/microsoftteams/platform/task-modules-and-cards/cards/cards-format
class AdaptiveIcon extends StatefulWidget with AdaptiveElementWidgetMixin {
  /// Creates an icon element from [adaptiveMap] JSON.
  AdaptiveIcon({
    required this.adaptiveMap,
  }) : super(key: generateAdaptiveWidgetKey(adaptiveMap)) {
    id = loadId(adaptiveMap);
  }

  @override
  final Map<String, dynamic> adaptiveMap;

  @override
  late final String id;

  @override
  AdaptiveIconState createState() => AdaptiveIconState();
}

/// State for [AdaptiveIcon]; resolves Fluent name, size, color, and style.
class AdaptiveIconState extends State<AdaptiveIcon>
    with AdaptiveElementMixin, AdaptiveVisibilityMixin, ProviderScopeMixin {
  /// Fluent icon name from `name`.
  late String? name;

  /// Size token from `size` (default `Standard`).
  late String sizeToken;

  /// Semantic color token from `color` (default `Default`).
  late String colorToken;

  /// Icon style from `style`: `Filled` or `Regular`.
  late String iconStyle;

  @override
  void initState() {
    super.initState();
    name = adaptiveMap['name'] as String?;
    sizeToken = adaptiveMap['size']?.toString() ?? 'Standard';
    colorToken = adaptiveMap['color']?.toString() ?? 'Default';
    iconStyle = adaptiveMap['style']?.toString() ?? 'Filled';
  }

  Color _resolveIconColor(ReferenceResolver resolver, BuildContext context) {
    final token = colorToken.toLowerCase();
    final style = switch (token) {
      'dark' => 'dark',
      'light' => 'light',
      'accent' => 'accent',
      'good' => 'good',
      'warning' => 'warning',
      'attention' => 'attention',
      _ => 'default',
    };

    return resolver.resolveContainerForegroundColor(style: style) ??
        Theme.of(context).iconTheme.color ??
        Colors.black;
  }

  @override
  Widget build(BuildContext context) {
    final resolver = styleResolver;
    final filled = iconStyle.toLowerCase() != 'regular';
    final iconData =
        (name != null && name!.isNotEmpty
            ? resolveFluentIcon(name!, filled: filled)
            : null) ??
        Icons.help_outline;

    Widget icon = Icon(
      iconData,
      size: resolveIconSize(sizeToken),
      color: _resolveIconColor(resolver, context),
      semanticLabel: name,
    );

    icon = AdaptiveTappable(
      adaptiveMap: adaptiveMap,
      child: icon,
    );

    return Visibility(
      visible: isVisible,
      child: SeparatorElement(
        adaptiveMap: adaptiveMap,
        child: icon,
      ),
    );
  }
}
