import 'flutter_raw_adaptive_card.dart';

abstract class GenericAction {
  GenericAction(this.adaptiveMap, this.rawAdaptiveCardState);

  String? get title => adaptiveMap['title'];
  final Map<String, dynamic> adaptiveMap;
  final RawAdaptiveCardState rawAdaptiveCardState;

  void tap();
}

class GenericSubmitAction extends GenericAction {
  GenericSubmitAction(Map<String, dynamic> adaptiveMap,
      RawAdaptiveCardState rawAdaptiveCardState)
      : super(adaptiveMap, rawAdaptiveCardState) {
    data = adaptiveMap['data'] ?? {};
  }

  late Map<String, dynamic> data;

  @override
  void tap() {
    rawAdaptiveCardState.submit(data);
  }
}

class GenericActionOpenUrl extends GenericAction {
  GenericActionOpenUrl(Map<String, dynamic> adaptiveMap,
      RawAdaptiveCardState rawAdaptiveCardState)
      : super(adaptiveMap, rawAdaptiveCardState) {
    url = adaptiveMap['url'];
  }

  late String? url;

  @override
  void tap() {
    if (url != null) {
      rawAdaptiveCardState.openUrl(url!);
    }
  }
}
