import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/src/adaptive_mixins.dart';
import 'package:flutter_adaptive_cards_fs/src/additional.dart';
import 'package:flutter_adaptive_cards_fs/src/hostconfig/fact_set_config.dart';
import 'package:flutter_adaptive_cards_fs/src/models/fact.dart';
import 'package:flutter_adaptive_cards_fs/src/reference_resolver.dart';
import 'package:flutter_adaptive_cards_fs/src/riverpod/providers.dart';
import 'package:flutter_adaptive_cards_fs/src/utils/utils.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Implements
/// https://adaptivecards.io/explorer/FactSet.html
/// https://learn.microsoft.com/en-us/adaptive-cards/schema-explorer/fact-set
/// https://adaptivecards.io/explorer/Fact.html
/// https://learn.microsoft.com/en-us/adaptive-cards/schema-explorer/fact
///
/// Renders a `FactSet` as title/value pairs in two columns, with reactive
/// updates when overlay `facts` change.
class AdaptiveFactSet extends ConsumerStatefulWidget
    with AdaptiveElementWidgetMixin {
  /// Creates a `FactSet` from [adaptiveMap].
  AdaptiveFactSet({
    required this.adaptiveMap,
  }) : super(key: generateAdaptiveWidgetKey(adaptiveMap)) {
    id = loadId(adaptiveMap);
  }

  @override
  final Map<String, dynamic> adaptiveMap;

  @override
  late final String id;

  @override
  AdaptiveFactSetState createState() => AdaptiveFactSetState();
}

/// State for [AdaptiveFactSet].
class AdaptiveFactSetState extends ConsumerState<AdaptiveFactSet>
    with AdaptiveElementMixin, AdaptiveVisibilityMixin, ProviderScopeMixin {
  /// Background color resolved from HostConfig and fact set style.
  Color? backgroundColor;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    backgroundColor = styleResolver.resolveContainerBackgroundColor(
      style: style,
    );
  }

  @override
  Widget build(BuildContext context) {
    final resolved = ref.watch(resolvedElementProvider(id));
    final facts = resolved != null
        ? factsFromJsonList(resolved['facts'])
        : factsFromJsonList(adaptiveMap['facts']);

    final ReferenceResolver resolver = styleResolver;
    final FactSetConfig? factSetConfig = resolver.getFactSetConfig();

    return Visibility(
      visible: isVisible,
      child: SeparatorElement(
        adaptiveMap: adaptiveMap,
        child: Container(
          color: backgroundColor,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: facts
                    .map(
                      (fact) => ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth:
                              factSetConfig?.title.maxWidth != null &&
                                  factSetConfig!.title.maxWidth > 0
                              ? factSetConfig.title.maxWidth.toDouble()
                              : double.infinity,
                        ),
                        child: Text(
                          fact.title,
                          softWrap: factSetConfig?.title.wrap ?? true,
                          style: TextStyle(
                            fontWeight: resolver.resolveFontWeight(
                              factSetConfig?.title.weight ?? 'default',
                            ),
                            fontSize: resolver.resolveFontSize(
                              context: context,
                              sizeString: factSetConfig?.title.size ?? 'normal',
                            ),
                            color: resolver.resolveContainerForegroundColor(
                              style: factSetConfig?.title.color,
                              isSubtle: factSetConfig?.title.isSubtle,
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
              SizedBox(width: factSetConfig?.spacing.toDouble() ?? 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: facts
                      .map(
                        (fact) => ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth:
                                factSetConfig?.value.maxWidth != null &&
                                    factSetConfig!.value.maxWidth > 0
                                ? factSetConfig.value.maxWidth.toDouble()
                                : double.infinity,
                          ),
                          child: MarkdownBody(
                            data: fact.value,
                            styleSheet: loadMarkdownStyleSheet(
                              resolver: resolver,
                              context: context,
                              factSetTextConfig: factSetConfig?.value,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds markdown styling for fact values from HostConfig
  /// [factSetTextConfig].
  MarkdownStyleSheet loadMarkdownStyleSheet({
    required ReferenceResolver resolver,
    required BuildContext context,
    required FactSetTextConfig? factSetTextConfig,
  }) {
    final Color? color = resolver.resolveContainerForegroundColor(
      style: factSetTextConfig?.color,
      isSubtle: factSetTextConfig?.isSubtle,
    );
    final FontWeight weight = resolver.resolveFontWeight(
      factSetTextConfig?.weight,
    );
    final double fontSize = resolver.resolveFontSize(
      context: context,
      sizeString: factSetTextConfig?.size,
    );

    final TextStyle style = TextStyle(
      color: color,
      fontWeight: weight,
      fontSize: fontSize,
    );

    return MarkdownStyleSheet(
      a: style,
      blockquote: style,
      code: style,
      em: style,
      strong: style.copyWith(fontWeight: FontWeight.bold),
      p: style,
    );
  }
}
