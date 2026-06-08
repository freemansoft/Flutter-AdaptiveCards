import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/src/riverpod/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// Fades [child] in over [duration], then hides it when complete.
class FadeAnimation extends StatefulWidget {
  /// Creates a one-shot fade-in animation around [child].
  const FadeAnimation({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 500),
  });

  /// Widget shown while the fade animation runs.
  final Widget child;

  /// Length of the fade-in animation.
  final Duration duration;

  @override
  FadeAnimationState createState() => FadeAnimationState();
}

/// State for [FadeAnimation]; drives the opacity [AnimationController].
class FadeAnimationState extends State<FadeAnimation>
    with SingleTickerProviderStateMixin {
  /// Drives opacity from 1.0 down to 0.0 over [FadeAnimation.duration].
  late AnimationController animationController;

  @override
  void initState() {
    super.initState();
    animationController = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    animationController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
    unawaited(animationController.forward(from: 0));
  }

  @override
  void deactivate() {
    animationController.stop();
    super.deactivate();
  }

  @override
  void didUpdateWidget(FadeAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.child != widget.child) {
      unawaited(animationController.forward(from: 0));
    }
  }

  @override
  void dispose() {
    animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return animationController.isAnimating
        ? Opacity(opacity: 1.0 - animationController.value, child: widget.child)
        : Container();
  }
}

/// Lowercases only the first character of [s].
String firstCharacterToLowerCase(String s) =>
    s.isNotEmpty ? s[0].toLowerCase() + s.substring(1) : '';

/// Simple pair of two values.
class Tuple<A, B> {
  /// Creates a tuple holding [a] and [b].
  Tuple(this.a, this.b);

  /// First component.
  final A a;

  /// Second component.
  final B b;
}

/// Clips child content to a full rectangular bounds (used for person images).
class FullCircleClipper extends CustomClipper<Rect> {
  @override
  Rect getClip(Size size) {
    return Rect.fromLTWH(0, 0, size.width, size.height);
  }

  @override
  bool shouldReclip(CustomClipper<Rect> oldClipper) => false;
}

/// Parses `#RRGGBB` or `#AARRGGBB` hex strings into [Color].
Color? parseHexColor(String? colorValue) {
  if (colorValue == null) return null;
  // No alpha
  if (colorValue.length == 7) {
    return Color(int.parse(colorValue.substring(1, 7), radix: 16) + 0xFF000000);
  } else if (colorValue.length == 9) {
    return Color(int.parse(colorValue.substring(1, 9), radix: 16));
  } else if (colorValue.length == 8) {
    return Color(int.parse(colorValue.substring(0, 8), radix: 16));
  } else {
    throw StateError('$colorValue is not a valid color');
  }
}

/// Parses Adaptive Card `isVisible` values from JSON (bool, string, or absent).
bool parseIsVisible(Object? value) {
  if (value == null) return true;
  if (value is bool) return value;
  if (value is String) return value.toLowerCase() == 'true';
  return true;
}

/// Parses HostConfig hex colors (`#RRGGBB` or `#AARRGGBB`); returns null when invalid.
Color? parseHostConfigColor(dynamic value) {
  if (value is! String) return null;
  if (!value.startsWith('#')) return null;

  var hex = value.substring(1);
  if (hex.length == 6) {
    hex = 'FF$hex';
  }
  if (hex.length != 8) return null;

  return Color(int.parse(hex, radix: 16));
}

/// Returns the English ordinal suffix (`st`, `nd`, `rd`, `th`) for day [n].
String getDayOfMonthSuffix(int n) {
  assert(n >= 1 && n <= 31, 'illegal day of month: $n');
  if (n >= 11 && n <= 13) {
    return 'th';
  }
  switch (n % 10) {
    case 1:
      return 'st';
    case 2:
      return 'nd';
    case 3:
      return 'rd';
    default:
      return 'th';
  }
}

/// Parses a given text string to property handle DATE() and TIME()
String parseTextString(String text, {String? locale}) {
  return text.replaceAllMapped(RegExp('{{.*}}'), (match) {
    final String? res = match.group(0);
    String? input = res?.substring(2, res.length - 2);
    input = input?.replaceAll(' ', '');

    final String? type = input?.substring(0, 4);
    if (type == 'DATE') {
      final String? dateFunction = input?.substring(5, input.length - 1);
      final List<String> items = dateFunction?.split(',') ?? [];
      if (items.length == 1) {
        items.add('COMPACT');
      }
      //if(items.length != 2) throw StateError('$dateFunction is not valid');
      // Wrong format
      if (items.length != 2) return res ?? '';

      final DateTime? dateTime = DateTime.tryParse(items[0]);

      DateFormat dateFormat;

      if (dateTime == null) return res ?? '';
      if (items[1] == 'COMPACT') {
        dateFormat = DateFormat.yMd(locale);
        return dateFormat.format(dateTime);
      } else if (items[1] == 'SHORT') {
        dateFormat = DateFormat('E, MMM d{n}, y', locale);
        return dateFormat
            .format(dateTime)
            .replaceFirst('{n}', getDayOfMonthSuffix(dateTime.day));
      } else if (items[1] == 'LONG') {
        dateFormat = DateFormat('EEEE, MMMM d{n}, y', locale);
        return dateFormat
            .format(dateTime)
            .replaceFirst('{n}', getDayOfMonthSuffix(dateTime.day));
      } else {
        // Wrong format
        return res ?? '';
      }
    } else if (type == 'TIME') {
      final String? time = input?.substring(5, input.length - 1);
      final DateTime? dateTime = DateTime.tryParse(time ?? '');
      if (dateTime == null) return res ?? '';

      final DateFormat dateFormat = DateFormat('jm', locale);

      return dateFormat.format(dateTime);
    } else {
      // Wrong format
      return res ?? '';
      //throw StateError('Function $type not found');
    }
  });
}

/// Builds the label row above an input using HostConfig label styles.
Widget loadLabel({
  required BuildContext context,
  String? label,
  bool isRequired = false,
}) {
  if (label == null) {
    return const SizedBox();
  }

  final resolver = ProviderScope.containerOf(
    context,
  ).read(styleReferenceResolverProvider);
  final inputsConfig = resolver.getInputsConfig();
  final labelConfig = isRequired
      ? inputsConfig?.label.requiredInputs
      : inputsConfig?.label.optionalInputs;

  final color = resolver.resolveContainerForegroundColor(
    style: labelConfig?.color ?? 'default',
    isSubtle: labelConfig?.isSubtle ?? false,
  );
  final double fontSize = resolver.resolveFontSize(
    context: context,
    sizeString: labelConfig?.size ?? 'default',
  );
  final FontWeight fontWeight = resolver.resolveFontWeight(
    labelConfig?.weight ?? 'default',
  );

  final double bottomPadding = resolver.resolveSpacing(
    inputsConfig?.label.inputSpacing,
  );

  return Align(
    alignment: Alignment.centerLeft,
    child: Padding(
      padding: EdgeInsets.only(bottom: bottomPadding, top: 0),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: label,
              style: TextStyle(
                color: color,
                fontSize: fontSize,
                fontWeight: fontWeight,
              ),
            ),
            if (labelConfig?.suffix.isNotEmpty ?? false)
              TextSpan(
                text: labelConfig?.suffix,
                style: TextStyle(
                  color: color,
                  fontSize: fontSize,
                  fontWeight: fontWeight,
                ),
              ),
            if (isRequired)
              TextSpan(
                text: ' *',
                style: TextStyle(
                  color:
                      resolver.resolveContainerForegroundColor(
                        style: 'attention',
                        isSubtle: false,
                      ) ??
                      Theme.of(context).colorScheme.error,
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

/// Builds the validation error text below an input when [showError] is true.
Widget loadErrorMessage({
  required BuildContext context,
  String? errorMessage,
  bool showError = false,
}) {
  if (errorMessage == null || !showError) {
    return const SizedBox();
  }

  final resolver = ProviderScope.containerOf(
    context,
  ).read(styleReferenceResolverProvider);
  final inputsConfig = resolver.getInputsConfig();
  final errorMessageConfig = inputsConfig?.errorMessage;

  final color = resolver.resolveContainerForegroundColor(
    style: 'attention', // Error messages usually use attention colo
    isSubtle: false,
  );
  final double fontSize = resolver.resolveFontSize(
    context: context,
    sizeString: errorMessageConfig?.size,
  );
  final FontWeight fontWeight = resolver.resolveFontWeight(
    errorMessageConfig?.weight ?? 'default',
  );
  final double topPadding = resolver.resolveSpacing(
    errorMessageConfig?.spacing,
  );

  return Align(
    alignment: Alignment.centerLeft,
    child: Padding(
      padding: EdgeInsets.only(top: topPadding, bottom: 0),
      child: Text(
        errorMessage,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: fontWeight,
        ),
      ),
    ),
  );
}

/// ids are generated if they aren't specified in the 'id' property
bool idIsNatural(Map aMap) {
  final String? id = aMap['id']?.toString();
  final String? type = aMap['type']?.toString();
  return UUIDGenerator().isNaturalId(id, type);
}

/// Can override this if need to special process the id
String loadId(Map aMap) {
  if (aMap.containsKey('id')) {
    return aMap['id'].toString();
  } else {
    // this should never happen because we inject missing ids on load
    assert(() {
      return true;
    }());
    return UUIDGenerator().generateUniqueId(type: aMap['type']);
  }
}

/// generate the widget key for the adaptive widget that wraps any field widget
/// based on the 'id' property in the passed in map plus the suffix '_adaptive'
ValueKey<String> generateAdaptiveWidgetKey(Map aMap) {
  return ValueKey('${loadId(aMap)}_adaptive');
}

/// generate the widget key for the actual input element
/// based on the 'id' property in the passed in map
ValueKey<String> generateWidgetKey(Map aMap, {String? suffix}) {
  final String id = loadId(aMap);
  return generateWidgetKeyFromId(id, suffix: suffix);
}

/// generate the widget key for the actual input element
/// where the id property has already been resolved
ValueKey<String> generateWidgetKeyFromId(String id, {String? suffix}) {
  if (suffix != null) {
    return ValueKey('${id}_$suffix');
  }
  return ValueKey(id);
}

/// Everyone uses the same scheme for UUID Generation
class UUIDGenerator {
  /// We use a factory which returns the singleton
  factory UUIDGenerator() {
    return _instance;
  }

  /// The named constructor is the "real" constructor
  UUIDGenerator._internal();

  static final UUIDGenerator _instance = UUIDGenerator._internal();

  /// generates the next UUID based on provided type and/or map
  ///
  /// If both are provided, the UUID will be of the form 'type_hashCode'
  /// If only type is provided, the UUID will be of the form 'type_UniqueKey'
  /// If neither is provided, the UUID will be a random string
  String generateUniqueId({required String? type}) {
    final newId = (type == null)
        ? UniqueKey().toString()
        : '$type-${UniqueKey()}';
    assert(() {
      developer.log(
        'Generating Unique ID: $newId for type $type',
        //stackTrace: StackTrace.current,
      );
      return true;
    }());
    return newId;
  }

  /// Returns true when [id] was author-supplied (not auto-generated from [type]).
  bool isNaturalId(String? id, String? type) {
    if (id == null) return false;
    if (type == null) return true;
    return !id.contains(type);
  }
}

/// Recursively traverses the map and injects an 'id' property into any map
/// that has a 'type' property but lacks an 'id'.
void injectIds(
  dynamic data,
) {
  if (data is Map) {
    if (data.containsKey('type') &&
        !data.containsKey('id') &&
        data['type'] is String) {
      data['id'] = UUIDGenerator().generateUniqueId(
        type: data['type'].toString(),
      );
    }
    // Create a copy of values to avoid ConcurrentModificationError when injecting 'id'
    final values = data.values.toList();
    for (int i = 0; i < values.length; i++) {
      final value = values[i];
      injectIds(value);
    }
  } else if (data is List) {
    // Create a copy of list to be safe, although less likely to be modified here
    final items = data.toList();
    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      injectIds(item);
    }
  }
}

/// Parses the `minHeight` property from the Adaptive Cards JSON,
/// supporting both pixel values (e.g. `"240px"`) and raw integer/double values.
double? parseMinHeight(dynamic rawMinHeight) {
  if (rawMinHeight == null) return null;
  final String minHeightStr = rawMinHeight.toString().trim().toLowerCase();
  if (minHeightStr.endsWith('px')) {
    return double.tryParse(
      minHeightStr.substring(0, minHeightStr.length - 2),
    );
  }
  return double.tryParse(minHeightStr);
}
