library flutter_adaptive_cards;

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:format/format.dart';
import 'package:http/http.dart' as http;

import 'action_handler.dart';
import 'flutter_raw_adaptive_card.dart';
import 'registry.dart';

abstract class AdaptiveCardContentProvider {
  AdaptiveCardContentProvider({required this.hostConfigPath, this.hostConfig});

  final String hostConfigPath;
  final String? hostConfig;

  Future<Map<String, dynamic>> loadHostConfig() async {
    if (hostConfig != null) {
      var cleanedHostConfig = hostConfig!.replaceAll(new RegExp(r'\n'), '');
      return json.decode(cleanedHostConfig);
    }

    String hostConfigString = await rootBundle.loadString(hostConfigPath);
    return json.decode(hostConfigString);
  }

  Future<Map<String, dynamic>> loadAdaptiveCardContent();
}

class MemoryAdaptiveCardContentProvider extends AdaptiveCardContentProvider {
  MemoryAdaptiveCardContentProvider(
      {required this.content,
      required String hostConfigPath,
      String? hostConfig})
      : super(hostConfigPath: hostConfigPath, hostConfig: hostConfig);

  Map<String, dynamic> content;

  @override
  Future<Map<String, dynamic>> loadAdaptiveCardContent() {
    return Future.value(content);
  }
}

class AssetAdaptiveCardContentProvider extends AdaptiveCardContentProvider {
  AssetAdaptiveCardContentProvider(
      {required this.path, required String hostConfigPath, String? hostConfig})
      : super(hostConfigPath: hostConfigPath, hostConfig: hostConfig);

  String path;

  @override
  Future<Map<String, dynamic>> loadAdaptiveCardContent() async {
    return json.decode(await rootBundle.loadString(path));
  }
}

class NetworkAdaptiveCardContentProvider extends AdaptiveCardContentProvider {
  NetworkAdaptiveCardContentProvider(
      {required this.url, required String hostConfigPath, String? hostConfig})
      : super(hostConfigPath: hostConfigPath, hostConfig: hostConfig);

  String url;

  @override
  Future<Map<String, dynamic>> loadAdaptiveCardContent() async {
    var body = (await http.get(Uri.parse(url))).bodyBytes;

    return json.decode(utf8.decode(body));
  }
}

class AdaptiveCard extends StatefulWidget {
  AdaptiveCard({
    super.key,
    required this.adaptiveCardContentProvider,
    this.placeholder,
    this.cardRegistry = const CardRegistry(),
    this.initData,
    this.onChange,
    this.onSubmit,
    this.onOpenUrl,
    this.hostConfig,
    this.listView = false,
    this.showDebugJson = true,
    this.supportMarkdown = true,
  });

  AdaptiveCard.network({
    super.key,
    this.placeholder,
    this.cardRegistry,
    required String url,
    required String hostConfigPath,
    this.hostConfig,
    this.initData,
    this.onChange,
    this.onSubmit,
    this.onOpenUrl,
    this.listView = false,
    this.showDebugJson = true,
    this.supportMarkdown = true,
  }) : adaptiveCardContentProvider = NetworkAdaptiveCardContentProvider(
            url: url, hostConfigPath: hostConfigPath, hostConfig: hostConfig);

  AdaptiveCard.asset({
    super.key,
    this.placeholder,
    this.cardRegistry,
    required String assetPath,
    required String hostConfigPath,
    this.hostConfig,
    this.initData,
    this.onChange,
    this.onSubmit,
    this.onOpenUrl,
    this.listView = false,
    this.showDebugJson = true,
    this.supportMarkdown = true,
  }) : adaptiveCardContentProvider = AssetAdaptiveCardContentProvider(
            path: assetPath,
            hostConfigPath: hostConfigPath,
            hostConfig: hostConfig);

  AdaptiveCard.memory({
    super.key,
    this.placeholder,
    this.cardRegistry,
    required Map<String, dynamic> content,
    required String hostConfigPath,
    this.hostConfig,
    this.initData,
    this.onChange,
    this.onSubmit,
    this.onOpenUrl,
    this.listView = false,
    this.showDebugJson = true,
    this.supportMarkdown = true,
  }) : adaptiveCardContentProvider = MemoryAdaptiveCardContentProvider(
            content: content,
            hostConfigPath: hostConfigPath,
            hostConfig: hostConfig);

  final AdaptiveCardContentProvider adaptiveCardContentProvider;

  final Widget? placeholder;

  final CardRegistry? cardRegistry;

  final String? hostConfig;

  final Map? initData;

  final Function(String id, dynamic value, RawAdaptiveCardState state)?
      onChange;
  final Function(Map map)? onSubmit;
  final Function(String url)? onOpenUrl;

  final bool showDebugJson;
  final bool supportMarkdown;
  final bool listView;

  @override
  _AdaptiveCardState createState() => new _AdaptiveCardState();
}

class _AdaptiveCardState extends State<AdaptiveCard> {
  Map<String, dynamic>? map;
  Map<String, dynamic>? hostConfig;
  Map? initData;

  late CardRegistry cardRegistry;

  Function(String id, dynamic value, RawAdaptiveCardState cardState)? onChange;
  Function(Map map)? onSubmit;
  Function(String url)? onOpenUrl;

  @override
  void initState() {
    super.initState();
    widget.adaptiveCardContentProvider.loadHostConfig().then((hostConfigMap) {
      if (mounted) {
        setState(() {
          hostConfig = hostConfigMap;
        });
      }
    });
    widget.adaptiveCardContentProvider
        .loadAdaptiveCardContent()
        .then((adaptiveMap) {
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
    widget.adaptiveCardContentProvider.loadHostConfig().then((hostConfigMap) {
      if (mounted) {
        setState(() {
          hostConfig = hostConfigMap;
        });
      }
    });

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
            supportMarkdown: widget.supportMarkdown, listView: widget.listView);
      }
    }

    if (widget.onChange != null) {
      onChange = widget.onChange;
    }

    if (widget.onSubmit != null) {
      onSubmit = widget.onSubmit;
    } else {
      var foundOnSubmit = DefaultAdaptiveCardHandlers.of(context)?.onSubmit;
      if (foundOnSubmit != null) {
        onSubmit = foundOnSubmit;
      } else {
        onSubmit = (it) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content:
                  Text(format('No handler found for: \n {}', it.toString()))));
        };
      }
    }

    if (widget.onOpenUrl != null) {
      onOpenUrl = widget.onOpenUrl;
    } else {
      var foundOpenUrl = DefaultAdaptiveCardHandlers.of(context)?.onOpenUrl;
      if (foundOpenUrl != null) {
        onOpenUrl = foundOpenUrl;
      } else {
        onOpenUrl = (it) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(format('und for: \n {}', it.toString()))));
        };
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (map == null || hostConfig == null) {
      return widget.placeholder ??
          Container(child: Center(child: CircularProgressIndicator()));
    }

    return RawAdaptiveCard.fromMap(
      map!,
      hostConfig!,
      cardRegistry: cardRegistry,
      initData: initData,
      onChange: onChange,
      onOpenUrl: onOpenUrl,
      onSubmit: onSubmit,
      listView: widget.listView,
      showDebugJson: widget.showDebugJson,
    );
  }
}
