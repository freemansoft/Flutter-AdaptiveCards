library;

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_adaptive_cards/src/action_handler.dart';
import 'package:flutter_adaptive_cards/src/flutter_raw_adaptive_card.dart';
import 'package:flutter_adaptive_cards/src/registry.dart';
import 'package:format/format.dart';
import 'package:http/http.dart' as http;

/// Core definition for AdaptiveCardContent providers.
/// The class that loads the json map for the card.
///
/// We use specialized versions for each way we get content
abstract class AdaptiveCardContentProvider {
  AdaptiveCardContentProvider();

  Future<Map<String, dynamic>> loadAdaptiveCardContent();
}

/// Content provider for getting card specifications from memory
class MemoryAdaptiveCardContentProvider extends AdaptiveCardContentProvider {
  MemoryAdaptiveCardContentProvider({required this.content}) : super();

  Map<String, dynamic> content;

  @override
  Future<Map<String, dynamic>> loadAdaptiveCardContent() {
    return Future.value(content);
  }
}

/// Content provider for getting card specifications from the Asset tree
class AssetAdaptiveCardContentProvider extends AdaptiveCardContentProvider {
  AssetAdaptiveCardContentProvider({required this.path}) : super();

  String path;

  @override
  Future<Map<String, dynamic>> loadAdaptiveCardContent() async {
    return json.decode(await rootBundle.loadString(path));
  }
}

/// Content provider for getting card specifications from a network resource
class NetworkAdaptiveCardContentProvider extends AdaptiveCardContentProvider {
  NetworkAdaptiveCardContentProvider({required this.url}) : super();

  String url;

  @override
  Future<Map<String, dynamic>> loadAdaptiveCardContent() async {
    var body = (await http.get(Uri.parse(url))).bodyBytes;

    return json.decode(utf8.decode(body));
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
    this.cardRegistry = const CardRegistry(),
    this.initData,
    this.onChange,
    this.onSubmit,
    this.onExecute,
    this.onOpenUrl,
    this.listView = false,
    this.showDebugJson = true,
    this.supportMarkdown = true,
  });

  AdaptiveCard.network({
    super.key,
    this.placeholder,
    this.cardRegistry,
    required String url,
    this.initData,
    this.onChange,
    this.onSubmit,
    this.onExecute,
    this.onOpenUrl,
    this.listView = false,
    this.showDebugJson = true,
    this.supportMarkdown = true,
  }) : adaptiveCardContentProvider = NetworkAdaptiveCardContentProvider(
         url: url,
       );

  AdaptiveCard.asset({
    super.key,
    this.placeholder,
    this.cardRegistry,
    required String assetPath,
    this.initData,
    this.onChange,
    this.onSubmit,
    this.onExecute,
    this.onOpenUrl,
    this.listView = false,
    this.showDebugJson = true,
    this.supportMarkdown = true,
  }) : adaptiveCardContentProvider = AssetAdaptiveCardContentProvider(
         path: assetPath,
       );

  AdaptiveCard.memory({
    super.key,
    this.placeholder,
    this.cardRegistry,
    required Map<String, dynamic> content,
    this.initData,
    this.onChange,
    this.onSubmit,
    this.onExecute,
    this.onOpenUrl,
    this.listView = false,
    this.showDebugJson = true,
    this.supportMarkdown = true,
  }) : adaptiveCardContentProvider = MemoryAdaptiveCardContentProvider(
         content: content,
       );

  /// Content provider usually specific to a named constructor
  final AdaptiveCardContentProvider adaptiveCardContentProvider;

  /// Shown while asynch oloading is happening
  final Widget? placeholder;

  /// Used to convert card type strings into Card instances
  final CardRegistry? cardRegistry;

  /// data that may be copied into `Input` cards to replace their templated state
  final Map? initData;

  /// Environment specific function that knows how to handle state change
  final Function(String id, dynamic value, RawAdaptiveCardState cardState)?
  onChange;

  /// Environment specific function that knows how to handle submission to remote APIs
  final Function(Map map)? onSubmit;

  /// Environment specific function that knows how to handle execution to remote APIs
  final Function(Map map)? onExecute;

  /// Environment specific function that knows how to open a URL on this platform
  final Function(String url)? onOpenUrl;

  final bool showDebugJson;
  final bool supportMarkdown;
  final bool listView;

  @override
  AdaptiveCardState createState() => AdaptiveCardState();
}

/// State for **The** AdaptiveCard card
class AdaptiveCardState extends State<AdaptiveCard> {
  /// The loaded json map for this `AdaptiveCard` and its descendants
  Map<String, dynamic>? map;

  /// data that may be copied into `Input` cards to replace their templated state
  Map? initData;

  late CardRegistry cardRegistry;

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
    if (widget.cardRegistry != null) {
      cardRegistry = widget.cardRegistry!;
    } else {
      CardRegistry? cardRegistry = DefaultCardRegistry.of(context);
      if (cardRegistry != null) {
        this.cardRegistry = cardRegistry;
      } else {
        this.cardRegistry = CardRegistry(
          supportMarkdown: widget.supportMarkdown,
          listView: widget.listView,
        );
      }
    }

    // Update the onChange if one is provided
    if (widget.onChange != null) {
      onChange = widget.onChange;
    }

    // Update the onChange if one is provided or there is one in the DefaultAdapterCardHandlers
    if (widget.onSubmit != null) {
      onSubmit = widget.onSubmit;
    } else {
      var foundOnSubmit = DefaultAdaptiveCardHandlers.of(context)?.onSubmit;
      if (foundOnSubmit != null) {
        onSubmit = foundOnSubmit;
      } else {
        onSubmit = (it) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                format('No handler found for: \n {}', it.toString()),
              ),
            ),
          );
        };
      }
    }

    // Update the onExecute if one is provided or there is one in the DefaultAdapterCardHandlers
    if (widget.onExecute != null) {
      onExecute = widget.onExecute;
    } else {
      var foundOnExecute = DefaultAdaptiveCardHandlers.of(context)?.onExecute;
      if (foundOnExecute != null) {
        onExecute = foundOnExecute;
      } else {
        onExecute = (it) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                format('No handler found for: \n {}', it.toString()),
              ),
            ),
          );
        };
      }
    }

    // Update the onOpenUrl if one is provided or there is one in the DefaultAdapterCardHandlers
    if (widget.onOpenUrl != null) {
      onOpenUrl = widget.onOpenUrl;
    } else {
      var foundOpenUrl = DefaultAdaptiveCardHandlers.of(context)?.onOpenUrl;
      if (foundOpenUrl != null) {
        onOpenUrl = foundOpenUrl;
      } else {
        onOpenUrl = (it) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(format('und for: \n {}', it.toString()))),
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
      map!,
      cardRegistry: cardRegistry,
      initData: initData,
      onChange: onChange,
      onOpenUrl: onOpenUrl,
      onSubmit: onSubmit,
      onExecute: onExecute,
      listView: widget.listView,
      showDebugJson: widget.showDebugJson,
    );
  }
}
