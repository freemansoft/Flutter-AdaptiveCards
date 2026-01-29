import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards/src/adaptive_mixins.dart';
import 'package:flutter_adaptive_cards/src/additional.dart';
import 'package:flutter_adaptive_cards/src/hostconfig/fact_set_config.dart';
import 'package:flutter_adaptive_cards/src/inherited_reference_resolver.dart';
import 'package:flutter_adaptive_cards/src/reference_resolver.dart';
import 'package:flutter_adaptive_cards/src/utils/utils.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

/// Implements
/// https://adaptivecards.io/explorer/FactSet.html
/// https://adaptivecards.io/explorer/Fact.html
///
class AdaptiveFactSet extends StatefulWidget with AdaptiveElementWidgetMixin {
  AdaptiveFactSet({
    required this.adaptiveMap,
  }) : super(key: generateWidgetKey(adaptiveMap)) {
    id = loadId(adaptiveMap);
  }

  @override
  final Map<String, dynamic> adaptiveMap;

  @override
  late final String id;

  @override
  AdaptiveFactSetState createState() => AdaptiveFactSetState();
}

class AdaptiveFactSetState extends State<AdaptiveFactSet>
    with AdaptiveElementMixin, AdaptiveVisibilityMixin {
  late List<Map> facts;
  Color? backgroundColor;

  @override
  void initState() {
    super.initState();

    /// https://adaptivecards.io/explorer/Fact.html
    facts = List<Map>.from(adaptiveMap['facts']).toList();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    backgroundColor =
        InheritedReferenceResolver.of(
          context,
        ).resolver.resolveContainerBackgroundColor(
          style: adaptiveMap['style']?.toString(),
        );
  }

  @override
  Widget build(BuildContext context) {
    final ReferenceResolver resolver = InheritedReferenceResolver.of(
      context,
    ).resolver;
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
                          fact['title'],
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
                            data: fact['value'],
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
