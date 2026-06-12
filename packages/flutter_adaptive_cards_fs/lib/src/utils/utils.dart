import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/src/riverpod/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// One-shot fade-out wrapper that removes [child] when the animation completes.
class FadeAnimation extends StatefulWidget {
  /// Creates a one-shot fade-out animation around [child].
  const FadeAnimation({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 500),
  });

  /// Content shown during the one-shot fade-out effect.
  final Widget child;

  /// Fade duration before the widget is removed.
  final Duration duration;

  @override
  FadeAnimationState createState() => FadeAnimationState();
}

/// State object for [FadeAnimation]; not intended for direct host use.
class FadeAnimationState extends State<FadeAnimation>
    with SingleTickerProviderStateMixin {
  /// Opacity animation used by [FadeAnimation]; not for host use.
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

/// Lightweight two-value holder for internal/extension helpers.
class Tuple<A, B> {
  /// Creates a tuple holding [a] and [b].
  Tuple(this.a, this.b);

  /// First component.
  final A a;

  /// Second component.
  final B b;
}

/// Rectangular clipper used for person-style image masks in card elements.
class FullCircleClipper extends CustomClipper<Rect> {
  /// Returns full-bounds clip rect for the child.
  @override
  Rect getClip(Size size) {
    return Rect.fromLTWH(0, 0, size.width, size.height);
  }

  /// Always false; clip geometry does not depend on delegate state.
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

/// Expands Adaptive Cards `{{DATE(...)}}` and `{{TIME(...)}}` templates in display text.
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

/// True when `id` was author-supplied rather than auto-generated at card load.
bool idIsNatural(Map aMap) {
  final String? id = aMap['id']?.toString();
  final String? type = aMap['type']?.toString();
  return UUIDGenerator().isNaturalId(id, type);
}

/// Resolves element id from JSON; generates one if missing (normally pre-injected).
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

/// Deterministic [ValueKey] for the adaptive wrapper widget (`{id}_adaptive`).
ValueKey<String> generateAdaptiveWidgetKey(Map aMap) {
  return ValueKey('${loadId(aMap)}_adaptive');
}

/// Deterministic [ValueKey] for an input/control from element JSON.
ValueKey<String> generateWidgetKey(Map aMap, {String? suffix}) {
  final String id = loadId(aMap);
  return generateWidgetKeyFromId(id, suffix: suffix);
}

/// Deterministic [ValueKey] from a resolved element id.
ValueKey<String> generateWidgetKeyFromId(String id, {String? suffix}) {
  if (suffix != null) {
    return ValueKey('${id}_$suffix');
  }
  return ValueKey(id);
}

/// Shared id generation for elements missing author-supplied `id` values.
class UUIDGenerator {
  /// Access the shared [UUIDGenerator] instance used across the library.
  factory UUIDGenerator() {
    return _instance;
  }

  UUIDGenerator._internal();

  static final UUIDGenerator _instance = UUIDGenerator._internal();

  /// Produces a runtime-only element id when card JSON omits `id`.
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

/// Ensures every typed JSON node has an `id` before rendering; call on a copy,
/// not host-owned maps.
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
