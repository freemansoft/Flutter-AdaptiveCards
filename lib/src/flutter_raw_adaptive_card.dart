import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards/src/adaptive_mixins.dart';
import 'package:flutter_adaptive_cards/src/inherited_reference_resolver.dart';
import 'package:flutter_adaptive_cards/src/inputs/choice_filter.dart';
import 'package:flutter_adaptive_cards/src/inputs/choice_set.dart';
import 'package:flutter_adaptive_cards/src/reference_resolver.dart';
import 'package:flutter_adaptive_cards/src/registry.dart';
import 'package:format/format.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_adaptive_cards/src/riverpod_providers.dart';

/// Created by `AdaptiveCard` so there is usually only one of these per page.
///
class RawAdaptiveCard extends StatefulWidget {
  /// This widget takes a [map] (which usually is just a json decoded string) and
  /// displays in natively.
  ///
  /// Additionally a host config needs to be provided for styling.
  const RawAdaptiveCard.fromMap(
    this.map, {
    super.key,
    this.cardRegistry = const CardRegistry(),
    this.initData,
    this.onChange,
    this.onSubmit,
    this.onExecute,
    this.onOpenUrl,
    this.listView = false,
    this.showDebugJson = true,
  });

  final Map<String, dynamic> map;
  final CardRegistry cardRegistry;
  final Map? initData;

  final Function(String id, dynamic value, RawAdaptiveCardState cardState)?
  onChange;
  final Function(Map map)? onSubmit;
  final Function(Map map)? onExecute;
  final Function(String url)? onOpenUrl;

  final bool showDebugJson;
  final bool listView;

  @override
  RawAdaptiveCardState createState() => RawAdaptiveCardState();
}

class RawAdaptiveCardState extends State<RawAdaptiveCard> {
  // Wrapper around the host config
  late ReferenceResolver _resolver;
  late CardRegistry cardRegistry;

  // The root element that is loaded from the map
  late Widget _adaptiveElement;

  @override
  void initState() {
    super.initState();

    _resolver = ReferenceResolver();

    cardRegistry = widget.cardRegistry;

    _adaptiveElement = widget.cardRegistry.getElement(widget.map);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.initData != null) {
        initInput(widget.initData!);
      }
    });
  }

  @override
  void didUpdateWidget(RawAdaptiveCard oldWidget) {
    _resolver = ReferenceResolver();
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

    void visitor(Element element) {
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
    }

    context.visitChildElements(visitor);

    if (widget.onSubmit != null && valid) {
      widget.onSubmit!(map);
    }
  }

  /// Executes all the inputs of this adaptive card, does it by recursively
  /// visiting the elements in the tree
  void execute(Map map) {
    bool valid = true;

    void visitor(Element element) {
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
    }

    context.visitChildElements(visitor);

    if (widget.onExecute != null && valid) {
      widget.onExecute!(map);
    }
  }

  void initInput(Map map) {
    // this code exists in several places
    // but looks like it uses the visitor prior to assignment
    void visitor(Element element) {
      if (element is StatefulElement) {
        if (element.state is AdaptiveInputMixin) {
          (element.state as AdaptiveInputMixin).initInput(map);
        }
      }
      element.visitChildren(visitor);
    }

    context.visitChildElements(visitor);
  }

  void loadInput(String id, Map map) {
    // this code exists in several places
    // but looks like it uses the visitor prior to assignment
    void visitor(Element element) {
      if (element is StatefulElement) {
        if (element.state is AdaptiveInputMixin) {
          if ((element.state as AdaptiveInputMixin).id == id) {
            (element.state as AdaptiveInputMixin).loadInput(map);
          }
        }
      }
      element.visitChildren(visitor);
    }

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
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> searchList(
    List<SearchModel>? data,
    Function(dynamic value) callback,
  ) async {
    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(6.0)),
        side: BorderSide(),
      ),
      builder: (BuildContext builder) => SizedBox(
        height: MediaQuery.of(context).copyWith().size.height / 2,
        child: ChoiceFilter(data: data, callback: callback),
      ),
    );
  }

  Future<DateTime?> datePickerForPlatform(
    BuildContext context,
    DateTime? value,
    DateTime? min,
    DateTime? max,
  ) {
    if (Theme.of(context).platform == TargetPlatform.macOS ||
        Theme.of(context).platform == TargetPlatform.iOS) {
      return datePickerCupertino(context, value, min, max);
    } else {
      return datePickerMaterial(context, value, min, max);
    }
  }

  Future<DateTime?> datePickerCupertino(
    BuildContext context,
    DateTime? value,
    DateTime? min,
    DateTime? max,
  ) async {
    DateTime initialDate = value ?? DateTime.now();
    DateTime? pickedDate = initialDate;

    // showCupertinoModalPopup is a built-in function of the cupertino library
    await showCupertinoModalPopup<DateTime?>(
      context: context,
      builder: (_) => SizedBox(
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
                },
              ),
            ),

            // Close the modal
            CupertinoButton(
              child: const Text('OK'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
    return pickedDate;
  }

  /// min and max dates may be null, in this case no constraint is made in that direction
  Future<DateTime?> datePickerMaterial(
    BuildContext context,
    DateTime? value,
    DateTime? min,
    DateTime? max,
  ) {
    DateTime initialDate = value ?? DateTime.now();
    return showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: min ?? DateTime.now().subtract(const Duration(days: 10000)),
      lastDate: max ?? DateTime.now().add(const Duration(days: 10000)),
    );
  }

  Future<TimeOfDay?> timePickerForPlatform(
    BuildContext context,
    TimeOfDay? defaultTime,
    TimeOfDay? minTime,
    TimeOfDay? maxTime,
  ) {
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
    TimeOfDay? maximumTime,
  ) async {
    TimeOfDay initialTimeOfDay = defaultTime ?? TimeOfDay.now();
    // the picker requires a DateTime but won't be carried forward in the results
    DateTime initialDateTime = DateTime(
      1,
      1,
      1,
      initialTimeOfDay.hour,
      initialTimeOfDay.minute,
    );
    DateTime minDateTime = DateTime(
      1,
      1,
      1,
      minimumTime?.hour ?? 0,
      minimumTime?.minute ?? 0,
    );
    DateTime maxDateTime = DateTime(
      1,
      1,
      1,
      maximumTime?.hour ?? 23,
      maximumTime?.minute ?? 59,
    );
    assert(() {
      developer.log(
        format(
          'CupertinoPicker: initialtimeOfDay:{} initialDateTime:{} minDateTime:{} maxDateTime:{}',
          initialTimeOfDay,
          initialDateTime,
          minDateTime,
          maxDateTime,
        ),
        name: runtimeType.toString(),
      );
      return true;
    }());

    TimeOfDay? pickedTimeOfDay = initialTimeOfDay;

    // showCupertinoModalPopup is a built-in function of the cupertino library
    await showCupertinoModalPopup<TimeOfDay?>(
      context: context,
      builder: (_) => SizedBox(
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
                },
              ),
            ),

            // Close the modal
            CupertinoButton(
              child: const Text('OK'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
    return pickedTimeOfDay;
  }

  ///
  /// TODO: Does not actually support min and max time
  ///
  Future<TimeOfDay?> timePickerMaterial(
    BuildContext context,
    TimeOfDay? defaultTime,
    TimeOfDay? minTime,
    TimeOfDay? maxTime,
  ) {
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
                JsonEncoder encoder = const JsonEncoder.withIndent('  ');
                String prettyprint = encoder.convert(widget.map);
                showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: const Text(
                        'JSON (only added in debug mode, you can also turn '
                        'it off manually by passing showDebugJson = false)',
                      ),
                      content: SingleChildScrollView(child: Text(prettyprint)),
                      actions: <Widget>[
                        Center(
                          child: TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Thanks'),
                          ),
                        ),
                      ],
                      contentPadding: const EdgeInsets.all(8.0),
                    );
                  },
                );
              },
              child: const Text('Debug show the JSON'),
            ),
            const Divider(height: 0),
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

    return ProviderScope(
      overrides: [
        rawAdaptiveCardStateProvider.overrideWithValue(this),
      ],
      child: InheritedReferenceResolver(
        resolver: _resolver,
        child: Card(color: backgroundColor, child: child),
      ),
    );
  }
}
