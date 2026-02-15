import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_adaptive_cards_plus/src/actions/action_handler.dart';
import 'package:flutter_adaptive_cards_plus/src/actions/action_type_registry.dart';
import 'package:flutter_adaptive_cards_plus/src/flutter_raw_adaptive_card.dart';
import 'package:flutter_adaptive_cards_plus/src/hostconfig/host_config.dart';
import 'package:flutter_adaptive_cards_plus/src/registry.dart';
import 'package:format/format.dart';
import 'package:http/http.dart' as http;

/// Core definition for AdaptiveCardContent providers.
/// The class that loads the json map for the card.
///
/// We use specialized versions for each way we get content
abstract class AdaptiveCardContentProvider {
  Future<Map<String, dynamic>> loadAdaptiveCardContent();
}

/// Content provider for getting card specifications from memory
class MemoryAdaptiveCardContentProvider implements AdaptiveCardContentProvider {
  MemoryAdaptiveCardContentProvider({required this.content}) : super();

  Map<String, dynamic> content;

  @override
  Future<Map<String, dynamic>> loadAdaptiveCardContent() {
    return Future.value(content);
  }
}

/// Content provider for getting card specifications from a JSON string
class JsonAdaptiveCardContentProvider implements AdaptiveCardContentProvider {
  JsonAdaptiveCardContentProvider({required this.jsonString}) : super();

  String jsonString;

  @override
  Future<Map<String, dynamic>> loadAdaptiveCardContent() async {
    return json.decode(jsonString) as Map<String, dynamic>;
  }
}

/// Content provider for getting card specifications from the Asset tree
class AssetAdaptiveCardContentProvider implements AdaptiveCardContentProvider {
  AssetAdaptiveCardContentProvider({required this.path}) : super();

  String path;

  @override
  Future<Map<String, dynamic>> loadAdaptiveCardContent() async {
    return json.decode(await rootBundle.loadString(path))
        as Map<String, dynamic>;
  }
}

/// Content provider for getting card specifications from a network resource
class NetworkAdaptiveCardContentProvider
    implements AdaptiveCardContentProvider {
  NetworkAdaptiveCardContentProvider({required this.url}) : super();

  String url;

  @override
  Future<Map<String, dynamic>> loadAdaptiveCardContent() async {
    final body = (await http.get(Uri.parse(url))).bodyBytes;

    return json.decode(utf8.decode(body)) as Map<String, dynamic>;
  }
}

/// The start of our AdaptiveCard widget tree but is not the actual `AdaptiveCard`
/// Wraps a `RawAdaptiveCard`
/// Pass in the Action handlers specific to the host program
class AdaptiveCard extends StatefulWidget {
  const AdaptiveCard({
    super.key,
    required this.adaptiveCardContentProvider,
    this.placeholder,
    this.cardRegistry = const CardTypeRegistry(),
    this.actionTypeRegistry = const DefaultActionTypeRegistry(),
    this.initData,
    this.onChange,
    this.listView = false,
    this.showDebugJson = true,
    this.supportMarkdown = true,
    required this.hostConfigs,
  });

  AdaptiveCard.network({
    super.key,
    this.placeholder,
    this.cardRegistry = const CardTypeRegistry(),
    this.actionTypeRegistry = const DefaultActionTypeRegistry(),
    required String url,
    this.initData,
    this.onChange,
    this.listView = false,
    this.showDebugJson = true,
    this.supportMarkdown = true,
    required this.hostConfigs,
  }) : adaptiveCardContentProvider = NetworkAdaptiveCardContentProvider(
         url: url,
       );

  AdaptiveCard.asset({
    super.key,
    this.placeholder,
    this.cardRegistry = const CardTypeRegistry(),
    this.actionTypeRegistry = const DefaultActionTypeRegistry(),
    required String assetPath,
    this.initData,
    this.onChange,
    this.listView = false,
    this.showDebugJson = true,
    this.supportMarkdown = true,
    required this.hostConfigs,
  }) : adaptiveCardContentProvider = AssetAdaptiveCardContentProvider(
         path: assetPath,
       );

  AdaptiveCard.memory({
    super.key,
    this.placeholder,
    this.cardRegistry = const CardTypeRegistry(),
    this.actionTypeRegistry = const DefaultActionTypeRegistry(),
    required Map<String, dynamic> content,
    this.initData,
    this.onChange,
    this.listView = false,
    this.showDebugJson = true,
    this.supportMarkdown = true,
    required this.hostConfigs,
  }) : adaptiveCardContentProvider = MemoryAdaptiveCardContentProvider(
         content: content,
       );

  AdaptiveCard.json({
    super.key,
    this.placeholder,
    this.cardRegistry = const CardTypeRegistry(),
    this.actionTypeRegistry = const DefaultActionTypeRegistry(),
    required String jsonString,
    this.initData,
    this.onChange,
    this.listView = false,
    this.showDebugJson = true,
    this.supportMarkdown = true,
    required this.hostConfigs,
  }) : adaptiveCardContentProvider = JsonAdaptiveCardContentProvider(
         jsonString: jsonString,
       );

  /// Content provider usually specific to a named constructor
  final AdaptiveCardContentProvider adaptiveCardContentProvider;

  /// Shown while asynchronous loading is happening
  final Widget? placeholder;

  /// Used to convert card type strings into Card instances
  final CardTypeRegistry cardRegistry;

  /// Used to convert card type strings into Card instances
  final ActionTypeRegistry actionTypeRegistry;

  /// data that may be copied into `Input` cards to replace their templated state
  final Map? initData;

  /// Environment specific function that knows how to handle state change
  final Function(String id, dynamic value, RawAdaptiveCardState cardState)?
  onChange;

  final bool showDebugJson;
  final bool supportMarkdown;
  final bool listView;

  /// HostConfig for this card stack - describes string to color, etc. mappings
  final HostConfigs hostConfigs;

  @override
  AdaptiveCardState createState() => AdaptiveCardState();
}

/// State for **The** AdaptiveCard card
class AdaptiveCardState extends State<AdaptiveCard> {
  /// The loaded json map for this `AdaptiveCard` and its descendants
  Map<String, dynamic>? map;

  /// data that may be copied into `Input` cards to replace their templated state
  Map? initData;

  /// Environment specific function that knows how to handle state change
  Function(String id, dynamic value, RawAdaptiveCardState cardState)? onChange;

  /// Environment specific function that knows how to handle submission to remote APIs
  Function(Map map)? onSubmit;

  /// Environment specific function that knows how to handle execution to remote APIs
  Function(Map map)? onExecute;

  /// Environment specific function that knows how to open a URL on this platform
  Function(String url)? onOpenUrl;

  @override
  void initState() {
    super.initState();
    widget.adaptiveCardContentProvider.loadAdaptiveCardContent().then((
      adaptiveMap,
    ) {
      if (mounted) {
        setState(() {
          map = adaptiveMap;
        });
      }
    });

    initData = widget.initData;
  }

  @override
  void didUpdateWidget(AdaptiveCard oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Update the onChange if one is provided
    if (widget.onChange != null) {
      onChange = widget.onChange;
    }

    // Update the onChange if one is provided or there is one in the DefaultAdapterCardHandlers
    if (widget.onChange != null) {
      onChange = widget.onChange;
    } else {
      final foundOnChange = InheritedAdaptiveCardHandlers.of(context)?.onChange;
      if (foundOnChange != null) {
        onChange = foundOnChange;
      } else {
        onChange = (it, value, cardState) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                format('No custom handler found for onchange: \n {}', it),
              ),
            ),
          );
        };
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (map == null) {
      return widget.placeholder ??
          const Center(child: CircularProgressIndicator());
    }

    return RawAdaptiveCard.fromMap(
      map: map!,
      cardTypeRegistry: widget.cardRegistry,
      actionTypeRegistry: widget.actionTypeRegistry,
      initData: initData,
      onChange: onChange,
      listView: widget.listView,
      showDebugJson: widget.showDebugJson,
      hostConfigs: widget.hostConfigs,
    );
  }
}
