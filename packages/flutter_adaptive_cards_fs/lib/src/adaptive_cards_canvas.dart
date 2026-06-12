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

/// Async source of root card JSON for [AdaptiveCardsCanvas].
///
/// Implement or use a built-in provider (memory, JSON string, asset, network).
abstract class AdaptiveCardContentProvider {
  /// Called by the canvas on first build; return the parsed root `AdaptiveCard` map.
  Future<Map<String, dynamic>> loadAdaptiveCardContent();
}

/// Synchronous in-memory card source when JSON is already parsed.
class MemoryAdaptiveCardContentProvider implements AdaptiveCardContentProvider {
  /// Supplies an already-parsed card map without I/O.
  MemoryAdaptiveCardContentProvider({required this.content}) : super();

  /// Parsed root card map supplied to [loadAdaptiveCardContent].
  Map<String, dynamic> content;

  @override
  Future<Map<String, dynamic>> loadAdaptiveCardContent() {
    return Future.value(content);
  }
}

/// Card source that decodes a JSON string at load time.
class JsonAdaptiveCardContentProvider implements AdaptiveCardContentProvider {
  /// Decodes [jsonString] when [loadAdaptiveCardContent] runs.
  JsonAdaptiveCardContentProvider({required this.jsonString}) : super();

  /// Root card JSON text decoded on load.
  String jsonString;

  @override
  Future<Map<String, dynamic>> loadAdaptiveCardContent() async {
    return json.decode(jsonString) as Map<String, dynamic>;
  }
}

/// Card source that reads JSON from the Flutter asset bundle.
class AssetAdaptiveCardContentProvider implements AdaptiveCardContentProvider {
  /// Loads card JSON from a Flutter asset via [path].
  AssetAdaptiveCardContentProvider({required this.path}) : super();

  /// Bundle path passed to `rootBundle.loadString`.
  String path;

  @override
  Future<Map<String, dynamic>> loadAdaptiveCardContent() async {
    return json.decode(await rootBundle.loadString(path))
        as Map<String, dynamic>;
  }
}

/// Card source that fetches JSON over HTTP(S).
class NetworkAdaptiveCardContentProvider
    implements AdaptiveCardContentProvider {
  /// Fetches card JSON from a remote [url] when content is requested.
  NetworkAdaptiveCardContentProvider({required this.url}) : super();

  /// Remote URL fetched when the canvas loads.
  String url;

  @override
  Future<Map<String, dynamic>> loadAdaptiveCardContent() async {
    final body = (await http.get(Uri.parse(url))).bodyBytes;

    return json.decode(utf8.decode(body)) as Map<String, dynamic>;
  }
}

/// Host entry widget: loads card JSON, applies [HostConfigs], and renders [RawAdaptiveCard].
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

  /// Convenience constructor for remote card JSON.
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

  /// Convenience constructor for asset-backed card JSON.
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

  /// Convenience constructor for inline JSON text.
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

  /// Async loader chosen by the named constructor; override for custom sources.
  final AdaptiveCardContentProvider adaptiveCardContentProvider;

  /// Widget shown until [AdaptiveCardContentProvider.loadAdaptiveCardContent]
  /// completes; defaults to a progress indicator.
  final Widget? placeholder;

  /// Element type registry; extend to add or override card elements.
  final CardTypeRegistry cardTypeRegistry;

  /// Action handler registry; extend to customize action behavior.
  final ActionTypeRegistry actionTypeRegistry;

  /// data that may be copied into `Input` cards to replace their templated state
  final Map? initData;

  /// Host callback for input edits; falls back to [InheritedAdaptiveCardHandlers.onChange].
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

  /// Light/dark HostConfig pair that drives theming for this card.
  final HostConfigs hostConfigs;

  @override
  AdaptiveCardsCanvasState createState() => AdaptiveCardsCanvasState();
}

/// Holds loaded card JSON and resolved [onChange] while [AdaptiveCardsCanvas] builds [RawAdaptiveCard].
class AdaptiveCardsCanvasState extends State<AdaptiveCardsCanvas> {
  /// Loaded root card JSON after the content provider completes.
  Map<String, dynamic>? map;

  /// data that may be copied into `Input` cards to replace their templated state
  Map? initData;

  /// Effective input-change handler after widget vs inherited resolution.
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
