library flutter_adaptive_cards;

import 'dart:developer' as developer;
import 'package:format/format.dart';

import 'dart:async';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_adaptive_cards/src/action_handler.dart';
import 'package:flutter_adaptive_cards/src/inputs/choice_filter.dart';
import 'package:flutter_adaptive_cards/src/inputs/choice_set.dart';
import 'package:flutter_adaptive_cards/src/registry.dart';
import 'package:flutter_adaptive_cards/src/utils.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import 'base.dart';

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

/// Main entry point to adaptive cards.
///
/// This widget takes a [map] (which usually is just a json decoded string) and
/// displays in natively. Additionally a host config needs to be provided for
/// styling.
class RawAdaptiveCard extends StatefulWidget {
  RawAdaptiveCard.fromMap(
    this.map,
    this.hostConfig, {
    this.cardRegistry = const CardRegistry(),
    this.initData,
    this.onChange,
    required this.onSubmit,
    required this.onOpenUrl,
    this.listView = false,
    this.showDebugJson = true,
  }) : assert(onSubmit != null, onOpenUrl != null);

  final Map<String, dynamic> map;
  final Map<String, dynamic> hostConfig;
  final CardRegistry cardRegistry;
  final Map? initData;

  final Function(String id, dynamic value, RawAdaptiveCardState cardState)?
      onChange;
  final Function(Map map)? onSubmit;
  final Function(String url)? onOpenUrl;

  final bool showDebugJson;
  final bool listView;

  @override
  RawAdaptiveCardState createState() => RawAdaptiveCardState();
}

class RawAdaptiveCardState extends State<RawAdaptiveCard> {
  // Wrapper around the host config
  late ReferenceResolver _resolver;
  late UUIDGenerator idGenerator;
  late CardRegistry cardRegistry;

  // The root element
  late Widget _adaptiveElement;

  @override
  void initState() {
    super.initState();

    _resolver = ReferenceResolver(
      hostConfig: widget.hostConfig,
    );

    idGenerator = UUIDGenerator();
    cardRegistry = widget.cardRegistry;

    _adaptiveElement = widget.cardRegistry.getElement(widget.map);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.initData != null) {
        initInput(widget.initData!);
      }
    });
  }

  void didUpdateWidget(RawAdaptiveCard oldWidget) {
    _resolver = ReferenceResolver(
      hostConfig: widget.hostConfig,
    );
    _adaptiveElement = widget.cardRegistry.getElement(widget.map);
    super.didUpdateWidget(oldWidget);
  }

  /// Every widget can access method of this class, meaning setting the state
  /// is possible from every element
  void rebuild() {
    setState(() {});
  }

  /// Submits all the inputs of this adaptive card, does it by recursively
  /// visiting the elements in the tree
  void submit(Map map) {
    bool valid = true;

    var visitor;
    visitor = (element) {
      if (element is StatefulElement) {
        if (element.state is AdaptiveInputMixin) {
          if ((element.state as AdaptiveInputMixin).checkRequired()) {
            (element.state as AdaptiveInputMixin).appendInput(map);
          } else {
            valid = false;
          }
        }
      }
      element.visitChildren(visitor);
    };
    context.visitChildElements(visitor);

    if (widget.onSubmit != null && valid) {
      widget.onSubmit!(map);
    }
  }

  void initInput(Map map) {
    var visitor;
    visitor = (element) {
      if (element is StatefulElement) {
        if (element.state is AdaptiveInputMixin) {
          (element.state as AdaptiveInputMixin).initInput(map);
        }
      }
      element.visitChildren(visitor);
    };
    context.visitChildElements(visitor);
  }

  void loadInput(String id, Map map) {
    var visitor;
    visitor = (element) {
      if (element is StatefulElement) {
        if (element.state is AdaptiveInputMixin) {
          if ((element.state as AdaptiveInputMixin).id == id) {
            (element.state as AdaptiveInputMixin).loadInput(map);
          }
        }
      }
      element.visitChildren(visitor);
    };
    context.visitChildElements(visitor);
  }

  void openUrl(String url) {
    if (widget.onOpenUrl != null) {
      widget.onOpenUrl!(url);
    }
  }

  void changeValue(String id, dynamic value) {
    if (widget.onChange != null) {
      widget.onChange!(id, value, this);
    }
  }

  void showError(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> searchList(
      List<SearchModel>? data, Function(dynamic value) callback) async {
    await showModalBottomSheet(
        context: context,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(6.0)),
          side: BorderSide(),
        ),
        builder: (BuildContext builder) => SizedBox(
            height: MediaQuery.of(context).copyWith().size.height / 2,
            child: ChoiceFilter(data: data, callback: callback)));
  }

  Future<DateTime?> datePickerForPlatform(
      BuildContext context, DateTime? value, DateTime? min, DateTime? max) {
    if (Theme.of(context).platform == TargetPlatform.macOS ||
        Theme.of(context).platform == TargetPlatform.iOS) {
      return datePickerCupertino(context, value, min, max);
    } else {
      return datePickerMaterial(context, value, min, max);
    }
  }

  Future<DateTime?> datePickerCupertino(BuildContext context, DateTime? value,
      DateTime? min, DateTime? max) async {
    DateTime initialDate = value ?? DateTime.now();
    DateTime? pickedDate = initialDate;

    // showCupertinoModalPopup is a built-in function of the cupertino library
    await showCupertinoModalPopup<DateTime?>(
        context: context,
        builder: (_) => Container(
              height: 500,
              child: Column(
                children: [
                  SizedBox(
                    height: 400,
                    child: CupertinoDatePicker(
                        mode: CupertinoDatePickerMode.date,
                        initialDateTime: initialDate,
                        onDateTimeChanged: (val) {
                          pickedDate = val;
                        }),
                  ),

                  // Close the modal
                  CupertinoButton(
                    child: const Text('OK'),
                    onPressed: () => Navigator.of(context).pop(),
                  )
                ],
              ),
            ));
    return pickedDate;
  }

  /// min and max dates may be null, in this case no constraint is made in that direction
  Future<DateTime?> datePickerMaterial(
      BuildContext context, DateTime? value, DateTime? min, DateTime? max) {
    DateTime initialDate = value ?? DateTime.now();
    return showDatePicker(
        context: context,
        initialDate: initialDate,
        firstDate: min ?? DateTime.now().subtract(Duration(days: 10000)),
        lastDate: max ?? DateTime.now().add(Duration(days: 10000)));
  }

  Future<TimeOfDay?> timePickerForPlatform(BuildContext context,
      TimeOfDay? defaultTime, TimeOfDay? minTime, TimeOfDay? maxTime) {
    if (Theme.of(context).platform == TargetPlatform.macOS ||
        Theme.of(context).platform == TargetPlatform.iOS) {
      return timePickerCupertino(context, defaultTime, minTime, maxTime);
    } else {
      return timePickerMaterial(context, defaultTime, minTime, maxTime);
    }
  }

  Future<TimeOfDay?> timePickerCupertino(
      BuildContext context,
      TimeOfDay? defaultTime,
      TimeOfDay? minimumTime,
      TimeOfDay? maximumTime) async {
    TimeOfDay initialTimeOfDay = defaultTime ?? TimeOfDay.now();
    // the picker requires a DateTime but won't be carried forward in the results
    DateTime initialDateTime =
        DateTime(1, 1, 1, initialTimeOfDay.hour, initialTimeOfDay.minute);
    DateTime minDateTime =
        DateTime(1, 1, 1, minimumTime?.hour ?? 0, minimumTime?.minute ?? 0);
    DateTime maxDateTime =
        DateTime(1, 1, 1, maximumTime?.hour ?? 23, maximumTime?.minute ?? 59);
    assert(() {
      developer.log(
          format(
              "CupertinoPicker: initialtimeOfDay:{} initialDateTime:{} minDateTime:{} maxDateTime:{}",
              initialTimeOfDay,
              initialDateTime,
              minDateTime,
              maxDateTime),
          name: runtimeType.toString());
      return true;
    }());

    TimeOfDay? pickedTimeOfDay = initialTimeOfDay;

    // showCupertinoModalPopup is a built-in function of the cupertino library
    await showCupertinoModalPopup<TimeOfDay?>(
        context: context,
        builder: (_) => Container(
              height: 500,
              child: Column(
                children: [
                  SizedBox(
                    height: 400,
                    child: CupertinoDatePicker(
                        mode: CupertinoDatePickerMode.time,
                        use24hFormat: false,
                        initialDateTime: initialDateTime,
                        minimumDate: minDateTime,
                        maximumDate: maxDateTime,
                        onDateTimeChanged: (val) {
                          pickedTimeOfDay = TimeOfDay.fromDateTime(val);
                        }),
                  ),

                  // Close the modal
                  CupertinoButton(
                    child: const Text('OK'),
                    onPressed: () => Navigator.of(context).pop(),
                  )
                ],
              ),
            ));
    return pickedTimeOfDay;
  }

  ///
  /// TODO: Does not actually support min and max time
  ///
  Future<TimeOfDay?> timePickerMaterial(BuildContext context,
      TimeOfDay? defaultTime, TimeOfDay? minTime, TimeOfDay? maxTime) {
    TimeOfDay initialTimeOfDay = defaultTime ?? TimeOfDay.now();
    return showTimePicker(context: context, initialTime: initialTimeOfDay);
  }

  @override
  Widget build(BuildContext context) {
    Widget child = _adaptiveElement;

    assert(() {
      if (widget.showDebugJson) {
        child = Column(
          children: <Widget>[
            TextButton(
              onPressed: () {
                JsonEncoder encoder = new JsonEncoder.withIndent('  ');
                String prettyprint = encoder.convert(widget.map);
                showDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: Text(
                            'JSON (only added in debug mode, you can also turn '
                            'it off manually by passing showDebugJson = false)'),
                        content:
                            SingleChildScrollView(child: Text(prettyprint)),
                        actions: <Widget>[
                          Center(
                            child: TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: Text('Thanks'),
                            ),
                          )
                        ],
                        contentPadding: EdgeInsets.all(8.0),
                      );
                    });
              },
              child: Text('Debug show the JSON'),
            ),
            Divider(
              height: 0,
            ),
            child,
          ],
        );
      }
      return true;
    }());
    var backgroundColor = _resolver.resolveBackgroundColor(
      context: context,
      style: widget.map['style']?.toString().toLowerCase(),
    );

    return Provider<RawAdaptiveCardState>.value(
      value: this,
      child: InheritedReferenceResolver(
        resolver: _resolver,
        child: Card(
          color: backgroundColor,
          child: child,
        ),
      ),
    );
  }
}

/// The visitor, the function is called once for every element in the tree
typedef AdaptiveElementVisitor = void Function(AdaptiveElement element);

/// The base class for every element (widget) drawn on the screen.
///
/// The lifecycle is as follows:
/// - [loadTree()] is called, all the initialization should be done here
/// - [generateWidget()] is called every time the elements needs to render
/// this method should be as lightweight as possible because it could possibly
/// be called many times (for example in an animation). The method should also be
/// idempotent meaning calling it multiple times without changing anything should
/// return the same result
///
/// This class also holds some references every element needs.
/// --------------------------------------------------------------------
/// The [adaptiveMap] is the map associated with that element
///
/// root
/// |
/// currentElement <-- ([adaptiveMap] contains the subtree from there)
/// |       |
/// child 1 child2
/// --------------------------------------------------------------------
///
/// The [resolver] is a handy wrapper around the hostConfig, which makes accessing
/// it easier.
///
/// The [widgetState] provides access to flutter specific implementations.
///
/// If the element has children (you don't need to do this if the element is a
/// leaf):
/// implement the method [visitChildren] and call visitor(this) in addition call
/// [visitChildren] on each child with the passed visitor.
abstract class AdaptiveElement {
  AdaptiveElement({required this.adaptiveMap, required this.widgetState}) {
    loadTree();
  }

  final Map adaptiveMap;

  late String id;

  /// Because some widgets (looking at you ShowCardAction) need to set the state
  /// all elements get a way to set the state.
  final RawAdaptiveCardState widgetState;

  /// This method should be implemented by the actual elements to return
  /// their Flutter representation.
  Widget build();

  /// Use this method to obtain the widget tree of the adaptive card.
  ///
  /// Each mixin has the opportunity to add something to the widget hierarchy.
  ///
  /// An example:
  /// ```
  /// @override
  /// Widget generateWidget() {
  ///  assert(separator != null, 'Did you forget to call loadSeperator in this class?');
  ///  return Column(
  ///    children: <Widget>[
  ///      separator? Divider(height: topSpacing,): SizedBox(height: topSpacing,),
  ///      super.generateWidget(),
  ///    ],
  ///  );
  ///}
  ///```
  ///
  /// This works because each mixin calls [generateWidget] in its generateWidget
  /// and adds the returned value into the widget tree. Eventually the base
  /// implementation (this) will be called and the elements actual build method is
  /// included.
  @mustCallSuper
  Widget generateWidget() {
    return build();
  }

  void loadId() {
    if (adaptiveMap.containsKey('id')) {
      id = adaptiveMap['id'];
    } else {
      id = widgetState.idGenerator.getId();
    }
  }

  @mustCallSuper
  void loadTree() {
    loadId();
  }

  /// Visits the children
  void visitChildren(AdaptiveElementVisitor visitor) {
    visitor(this);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdaptiveElement &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Resolves values based on the host config.
///
/// All values can also be null, in that case the default is used
class ReferenceResolver {
  ReferenceResolver({
    required this.hostConfig,
    this.currentStyle,
  });

  final Map<String, dynamic> hostConfig;

  final String? currentStyle;

  /// return the value hostConfig[key][value]
  dynamic resolve(String key, String value) {
    dynamic res = hostConfig[key]?[firstCharacterToLowerCase(value)];
    assert(res != null,
        'Could not find hostConfig[$key][${firstCharacterToLowerCase(value)}]');
    return res;
  }

  /// return the value for hostConfig[key]
  dynamic get(String key) {
    dynamic res = hostConfig[key];
    assert(res != null, 'Could not find hostConfig[$key]');
    return res;
  }

  /// Resolves a color type from the Theme palette if colorType is null or 'default'
  /// Resovles a color to the host config if colorType is not null and not 'default'
  ///
  /// Typically one of the following colors:
  /// - default
  /// - dark
  /// - light
  /// - accent
  /// - good
  /// - warning
  /// - attention
  ///
  /// If the color type is 'default' then it picks the standard color for the current style.
  Color? resolveForegroundColor(
      {required BuildContext context, String? colorType, bool? isSubtle}) {
    final String subtleOrDefault = isSubtle ?? false ? 'subtle' : 'default';
    // default or emphasis, I think
    final String myStyle = currentStyle ?? 'default';

    Color? foregroundColor;
    switch (colorType) {
      // "default" means default for the current style
      case "default":
        {
          // derive our foreground color from the theme if the color is set to default

          switch (myStyle) {
            case "default":
              foregroundColor =
                  Theme.of(context).colorScheme.onPrimaryContainer;
            case "emphasis":
              foregroundColor =
                  Theme.of(context).colorScheme.onSecondaryContainer;
            case "good":
              foregroundColor =
                  Theme.of(context).colorScheme.onTertiaryContainer;
            case "attention":
            case "warning:":
              foregroundColor = Theme.of(context).colorScheme.onErrorContainer;
            default:
              foregroundColor =
                  Theme.of(context).colorScheme.onPrimaryContainer;
          }
        }
      // we can override the default foreground for the current background
      case "emphasis":
        foregroundColor = Theme.of(context).colorScheme.onSecondaryContainer;
      case "good":
        foregroundColor = Theme.of(context).colorScheme.onTertiaryContainer;
      case "attention":
      case "warning:":
        foregroundColor = Theme.of(context).colorScheme.onErrorContainer;
      default:
        foregroundColor = null;
    }
    if (foregroundColor != null && subtleOrDefault == "subtle")
      foregroundColor = Color.fromARGB(foregroundColor.alpha ~/ 2,
          foregroundColor.red, foregroundColor.green, foregroundColor.blue);
    assert(() {
      developer.log(
          format("resolved foreground style:{} color:{} subtle:{} to color:{}",
              myStyle, colorType, subtleOrDefault, foregroundColor),
          name: runtimeType.toString());
      return true;
    }());
    return foregroundColor;
  }

  /// Resolves a background color from the host config
  /// Assumes you always want a color call
  ///
  /// Typically one of the following ContainerStyles styles - v 1.0
  ///
  /// - default
  /// - emphasis
  ///
  /// - good added v1.2
  /// - attention added v1.2
  /// - warning added v1.2
  /// - accent added v1.2
  ///
  /// Maps to surface and primaryContainer or SecondaryContainer
  ///
  /// Use resolveBackgroundColorIfNoBackgroundImageAndNoDefaultStyle() if you want no color if nothing specified

  Color? resolveBackgroundColor({
    required BuildContext context,
    required String? style,
  }) {
    String myStyle = style ?? 'default';

    Color? backgroundColor;

    switch (myStyle) {
      case "default":
        backgroundColor = Theme.of(context).colorScheme.primaryContainer;
      case "emphasis":
        backgroundColor = Theme.of(context).colorScheme.secondaryContainer;
      case "good":
        backgroundColor = Theme.of(context).colorScheme.tertiaryContainer;
      case "attention":
      case "warning:":
        backgroundColor = Theme.of(context).colorScheme.errorContainer;
      default:
        backgroundColor = Theme.of(context).colorScheme.primaryContainer;
    }

    assert(() {
      developer.log(
          format("resolved background style:{} to color:{}", myStyle,
              backgroundColor),
          name: runtimeType.toString());
      return true;
    }());

    return backgroundColor;
  }

  ///
  /// This returns no color if a background image url is provided or if there is no style
  ///
  /// Style is typically one of the ContainerStyles
  /// - default
  /// - emphasis
  ///
  ///
  Color? resolveBackgroundColorIfNoBackgroundImageAndNoDefaultStyle({
    required BuildContext context,
    required String? style,
    required String? backgroundImageUrl,
  }) {
    if (backgroundImageUrl != null) {
      return null;
    }

    if (style == null) return null;

    return resolveBackgroundColor(context: context, style: style.toLowerCase());
  }

  ReferenceResolver copyWith({String? style}) {
    String myStyle = style ?? 'default';
    return ReferenceResolver(
      hostConfig: this.hostConfig,
      currentStyle: myStyle,
    );
  }

  double? resolveSpacing(String? spacing) {
    String mySpacing = spacing ?? 'default';
    if (mySpacing == 'none') return 0.0;
    int? intSpacing = resolve('spacing', mySpacing) as int?;
    assert(intSpacing != null, 'resolve(\'spacing\',\'$mySpacing\') was null');

    return intSpacing?.toDouble();
  }
}
