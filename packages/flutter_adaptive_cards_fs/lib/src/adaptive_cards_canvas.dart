import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_adaptive_cards_fs/src/action/action_handler.dart';
import 'package:flutter_adaptive_cards_fs/src/action/action_type_registry.dart';
import 'package:flutter_adaptive_cards_fs/src/flutter_raw_adaptive_card.dart';
import 'package:flutter_adaptive_cards_fs/src/hostconfig/host_config.dart';
import 'package:flutter_adaptive_cards_fs/src/models/action_invoke.dart';
import 'package:flutter_adaptive_cards_fs/src/registry.dart';
import 'package:http/http.dart' as http;

/// Core definition for AdaptiveCardContent providers.
/// The class that loads the json map for the card.
///
/// We use specialized versions for each way we get content
abstract class AdaptiveCardContentProvider {
  /// Loads the root Adaptive Card JSON map for [AdaptiveCardsCanvas].
  Future<Map<String, dynamic>> loadAdaptiveCardContent();
}

/// Content provider for getting card specifications from memory
class MemoryAdaptiveCardContentProvider implements AdaptiveCardContentProvider {
  /// Supplies an already-parsed card map without I/O.
  MemoryAdaptiveCardContentProvider({required this.content}) : super();

  /// Root Adaptive Card JSON held in memory.
  Map<String, dynamic> content;

  @override
  Future<Map<String, dynamic>> loadAdaptiveCardContent() {
    return Future.value(content);
  }
}

/// Content provider for getting card specifications from a JSON string
class JsonAdaptiveCardContentProvider implements AdaptiveCardContentProvider {
  /// Decodes [jsonString] when [loadAdaptiveCardContent] runs.
  JsonAdaptiveCardContentProvider({required this.jsonString}) : super();

  /// Raw JSON text for the root Adaptive Card.
  String jsonString;

  @override
  Future<Map<String, dynamic>> loadAdaptiveCardContent() async {
    return json.decode(jsonString) as Map<String, dynamic>;
  }
}

/// Content provider for getting card specifications from the Asset tree
class AssetAdaptiveCardContentProvider implements AdaptiveCardContentProvider {
  /// Loads card JSON from a Flutter asset via [path].
  AssetAdaptiveCardContentProvider({required this.path}) : super();

  /// Asset bundle path to the card JSON file.
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
  /// Fetches card JSON from a remote [url] when content is requested.
  NetworkAdaptiveCardContentProvider({required this.url}) : super();

  /// HTTP(S) location of the root Adaptive Card JSON.
  String url;

  @override
  Future<Map<String, dynamic>> loadAdaptiveCardContent() async {
    final body = (await http.get(Uri.parse(url))).bodyBytes;

    return json.decode(utf8.decode(body)) as Map<String, dynamic>;
  }
}

/// The canvas for AdaptiveCard widget trees
/// but is not the actual card of type `AdaptiveCard`
/// Wraps a [RawAdaptiveCard] that is the actual adaptive card element
/// Pass in the Action handlers specific to the host program
class AdaptiveCardsCanvas extends StatefulWidget {
  /// Creates a canvas that loads content from [adaptiveCardContentProvider].
  const AdaptiveCardsCanvas({
    super.key,
    required this.adaptiveCardContentProvider,
    this.placeholder,
    this.cardTypeRegistry = const CardTypeRegistry(),
    this.actionTypeRegistry = const DefaultActionTypeRegistry(),
    this.initData,
    this.onChange,
    this.listView = false,
    this.showDebugJson = true,
    this.supportMarkdown = true,
    this.brightnessMode = AdaptiveCardBrightnessMode.auto,
    this.currentUserId,
    required this.hostConfigs,
  });

  /// Loads card JSON from a network [url].
  AdaptiveCardsCanvas.network({
    super.key,
    this.placeholder,
    this.cardTypeRegistry = const CardTypeRegistry(),
    this.actionTypeRegistry = const DefaultActionTypeRegistry(),
    required String url,
    this.initData,
    this.onChange,
    this.listView = false,
    this.showDebugJson = true,
    this.supportMarkdown = true,
    this.brightnessMode = AdaptiveCardBrightnessMode.auto,
    this.currentUserId,
    required this.hostConfigs,
  }) : adaptiveCardContentProvider = NetworkAdaptiveCardContentProvider(
         url: url,
       );

  /// Loads card JSON from a bundled [assetPath].
  AdaptiveCardsCanvas.asset({
    super.key,
    this.placeholder,
    this.cardTypeRegistry = const CardTypeRegistry(),
    this.actionTypeRegistry = const DefaultActionTypeRegistry(),
    required String assetPath,
    this.initData,
    this.onChange,
    this.listView = false,
    this.showDebugJson = true,
    this.supportMarkdown = true,
    this.brightnessMode = AdaptiveCardBrightnessMode.auto,
    this.currentUserId,
    required this.hostConfigs,
  }) : adaptiveCardContentProvider = AssetAdaptiveCardContentProvider(
         path: assetPath,
       );

  /// Renders an in-memory [content] map without asynchronous loading.
  AdaptiveCardsCanvas.map({
    super.key,
    this.placeholder,
    this.cardTypeRegistry = const CardTypeRegistry(),
    this.actionTypeRegistry = const DefaultActionTypeRegistry(),
    required Map<String, dynamic> content,
    this.initData,
    this.onChange,
    this.listView = false,
    this.showDebugJson = true,
    this.supportMarkdown = true,
    this.brightnessMode = AdaptiveCardBrightnessMode.auto,
    this.currentUserId,
    required this.hostConfigs,
  }) : adaptiveCardContentProvider = MemoryAdaptiveCardContentProvider(
         content: content,
       );

  /// Decodes [jsonString] into the root card map.
  AdaptiveCardsCanvas.json({
    super.key,
    this.placeholder,
    this.cardTypeRegistry = const CardTypeRegistry(),
    this.actionTypeRegistry = const DefaultActionTypeRegistry(),
    required String jsonString,
    this.initData,
    this.onChange,
    this.listView = false,
    this.showDebugJson = true,
    this.supportMarkdown = true,
    this.brightnessMode = AdaptiveCardBrightnessMode.auto,
    this.currentUserId,
    required this.hostConfigs,
  }) : adaptiveCardContentProvider = JsonAdaptiveCardContentProvider(
         jsonString: jsonString,
       );

  /// Content provider usually specific to a named constructor
  final AdaptiveCardContentProvider adaptiveCardContentProvider;

  /// Shown while asynchronous loading is happening
  final Widget? placeholder;

  /// Used to convert card type strings into Card instances
  final CardTypeRegistry cardTypeRegistry;

  /// Used to convert card type strings into Card instances
  final ActionTypeRegistry actionTypeRegistry;

  /// data that may be copied into `Input` cards to replace their templated state
  final Map? initData;

  /// Environment specific function that knows how to handle input value changes.
  final void Function(InputChangeInvoke invoke)? onChange;

  /// When true (debug only), shows a button that displays the source JSON.
  final bool showDebugJson;

  /// When false, [CardTypeRegistry] disables Markdown rendering in text elements.
  final bool supportMarkdown;

  /// When true, the root adaptive card body scrolls as a list.
  final bool listView;

  /// How light vs dark [HostConfigs] are selected for this card.
  final AdaptiveCardBrightnessMode brightnessMode;

  /// Current user id for root `refresh.userIds` auto-refresh gating.
  final String? currentUserId;

  /// HostConfig for this card stack - describes string to color, etc. mappings
  final HostConfigs hostConfigs;

  @override
  AdaptiveCardsCanvasState createState() => AdaptiveCardsCanvasState();
}

/// State for **The** AdaptiveCard card
class AdaptiveCardsCanvasState extends State<AdaptiveCardsCanvas> {
  /// The loaded json map for this `AdaptiveCard` and its descendants
  Map<String, dynamic>? map;

  /// data that may be copied into `Input` cards to replace their templated state
  Map? initData;

  /// Environment specific function that knows how to handle input value changes.
  void Function(InputChangeInvoke invoke)? onChange;

  @override
  void initState() {
    super.initState();
    // async because we don't know if provider is synchronous or asynchronous
    unawaited(
      widget.adaptiveCardContentProvider.loadAdaptiveCardContent().then((
        loadedMap,
      ) {
        if (mounted) {
          // this class does not use the map so id injection is out of scope
          // also we should only mutate a copy of the map
          //injectIds(adaptiveMap);
          setState(() {
            map = loadedMap;
          });
        }
      }),
    );

    initData = widget.initData;
  }

  @override
  void didUpdateWidget(AdaptiveCardsCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Update the onChange if one is provided or there is one in the DefaultAdapterCardHandlers
    if (widget.onChange != null) {
      onChange = widget.onChange;
    } else {
      final foundOnChange = InheritedAdaptiveCardHandlers.of(context)?.onChange;
      if (foundOnChange != null) {
        onChange = foundOnChange;
      } else {
        onChange = (invoke) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'No custom handler found for onChange: \n ${invoke.inputId}',
              ),
            ),
          );
        };
      }
    }
  }

  CardTypeRegistry _registryWithCanvasFlags() {
    final base = widget.cardTypeRegistry;
    if (base.supportMarkdown == widget.supportMarkdown &&
        base.listView == widget.listView) {
      return base;
    }
    return CardTypeRegistry(
      removedElements: base.removedElements,
      addedElements: base.addedElements,
      addedActions: base.addedActions,
      listView: widget.listView,
      supportMarkdown: widget.supportMarkdown,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (map == null) {
      return widget.placeholder ??
          const Center(child: CircularProgressIndicator());
    }

    return RawAdaptiveCard.fromMap(
      map: map!,
      cardTypeRegistry: _registryWithCanvasFlags(),
      actionTypeRegistry: widget.actionTypeRegistry,
      initData: initData,
      onChange: onChange,
      listView: widget.listView,
      showDebugJson: widget.showDebugJson,
      brightnessMode: widget.brightnessMode,
      currentUserId: widget.currentUserId,
      hostConfigs: widget.hostConfigs,
    );
  }
}
