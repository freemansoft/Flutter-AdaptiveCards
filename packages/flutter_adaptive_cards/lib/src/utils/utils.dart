import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards/src/hostconfig/miscellaneous_configs.dart';
import 'package:flutter_adaptive_cards/src/inherited_reference_resolver.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

class FadeAnimation extends StatefulWidget {
  const FadeAnimation({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 500),
  });

  final Widget child;
  final Duration duration;

  @override
  FadeAnimationState createState() => FadeAnimationState();
}

class FadeAnimationState extends State<FadeAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController animationController;

  @override
  void initState() {
    super.initState();
    animationController = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    animationController
      ..addListener(() {
        if (mounted) {
          setState(() {});
        }
      })
      ..forward(from: 0);
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
      animationController.forward(from: 0);
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

String firstCharacterToLowerCase(String s) =>
    s.isNotEmpty ? s[0].toLowerCase() + s.substring(1) : '';

class Tuple<A, B> {
  Tuple(this.a, this.b);
  final A a;
  final B b;
}

class FullCircleClipper extends CustomClipper<Rect> {
  @override
  Rect getClip(Size size) {
    return Rect.fromLTWH(0, 0, size.width, size.height);
  }

  @override
  bool shouldReclip(CustomClipper<Rect> oldClipper) => false;
}

Color? parseHexColor(String? colorValue) {
  if (colorValue == null) return null;
  // No alpha
  if (colorValue.length == 7) {
    return Color(int.parse(colorValue.substring(1, 7), radix: 16) + 0xFF000000);
  } else if (colorValue.length == 9) {
    return Color(int.parse(colorValue.substring(1, 9), radix: 16));
  } else {
    throw StateError('$colorValue is not a valid color');
  }
}

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
// TODO(username): this needs a bunch of tests
String parseTextString(String text) {
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

      // TODO(username): use locale
      DateFormat dateFormat;

      if (dateTime == null) return res ?? '';
      if (items[1] == 'COMPACT') {
        dateFormat = DateFormat.yMd();
        return dateFormat.format(dateTime);
      } else if (items[1] == 'SHORT') {
        dateFormat = DateFormat('E, MMM d{n}, y');
        return dateFormat
            .format(dateTime)
            .replaceFirst('{n}', getDayOfMonthSuffix(dateTime.day));
      } else if (items[1] == 'LONG') {
        dateFormat = DateFormat('EEEE, MMMM d{n}, y');
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

      final DateFormat dateFormat = DateFormat('jm');

      return dateFormat.format(dateTime);
    } else {
      // Wrong format
      return res ?? '';
      //throw StateError('Function $type not found');
    }
  });
}

Widget loadLabel({
  required BuildContext context,
  String? label,
  bool isRequired = false,
}) {
  if (label == null) {
    return const SizedBox();
  }

  final resolver = InheritedReferenceResolver.of(context).resolver;
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

  final double bottomPadding = SpacingsConfig.resolveSpacing(
    resolver.getSpacingsConfig(),
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
              const TextSpan(
                text: ' *',
                // TODO(username): fix this color to be looked up from ReferenceResolver
                style: TextStyle(color: Colors.red),
              ),
          ],
        ),
      ),
    ),
  );
}

Widget loadErrorMessage({
  required BuildContext context,
  String? errorMessage,
  bool stateHasError = false,
}) {
  if (errorMessage == null || !stateHasError) {
    return const SizedBox();
  }

  final resolver = InheritedReferenceResolver.of(context).resolver;
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
  final double topPadding = SpacingsConfig.resolveSpacing(
    resolver.getSpacingsConfig(),
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
  return aMap.containsKey('id');
}

/// Can override this if need to special process the id
String loadId(Map aMap) {
  if (aMap.containsKey('id')) {
    return aMap['id'].toString();
  } else {
    // if no id is specified, use the hashcode of the map
    // only thing we can do for cards that don't have id properties or provided ids
    return '${aMap['type']}-${aMap.hashCode}';
  }
}

/// generate the widget key for the adaptive widget
ValueKey<String> generateAdaptiveWidgetKey(Map aMap) {
  return ValueKey('${loadId(aMap)}_adaptive');
}

/// generate the widget key for the actual input element
ValueKey<String> generateWidgetKey(Map aMap, {String? suffix}) {
  final String id = loadId(aMap);
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
  UUIDGenerator._internal() {
    uuid = const Uuid();
  }
  static final UUIDGenerator _instance = UUIDGenerator._internal();

  late final Uuid uuid;

  String getId() {
    return uuid.v1();
  }
}
