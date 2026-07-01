import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/src/adaptive_mixins.dart';
import 'package:flutter_adaptive_cards_fs/src/additional.dart';
import 'package:flutter_adaptive_cards_fs/src/resolved_input_state.dart';
import 'package:flutter_adaptive_cards_fs/src/utils/utils.dart';
import 'package:flutter_adaptive_cards_fs/src/widgets/rating_stars.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Interactive Adaptive Cards **Input.Rating** element.
///
/// See https://learn.microsoft.com/en-us/microsoftteams/platform/task-modules-and-cards/cards/cards-format#inputrating
class AdaptiveRatingInput extends ConsumerStatefulWidget
    with AdaptiveElementWidgetMixin {
  /// Creates a rating input from [adaptiveMap] JSON.
  AdaptiveRatingInput({
    required this.adaptiveMap,
  }) : super(key: generateAdaptiveWidgetKey(adaptiveMap)) {
    id = loadId(adaptiveMap);
  }

  @override
  final Map<String, dynamic> adaptiveMap;

  @override
  late final String id;

  @override
  AdaptiveRatingInputState createState() => AdaptiveRatingInputState();
}

/// State for [AdaptiveRatingInput]; syncs star selection with document
/// overlays.
class AdaptiveRatingInputState extends ConsumerState<AdaptiveRatingInput>
    with
        AdaptiveInputMixin,
        AdaptiveElementMixin,
        AdaptiveVisibilityMixin,
        ProviderScopeMixin {
  /// Maximum star count from `max` (default 5).
  late double max;

  /// Color token from `color` (`neutral`, `marigold`, `light`).
  late String color;

  /// Icon size token from `size` (`small`, `medium`, `large`).
  late String size;

  /// Whether half-star increments are allowed (`allowHalfSteps`).
  late bool allowHalfSteps;

  @override
  void initState() {
    super.initState();
    max = (adaptiveMap['max'] as num? ?? 5).toDouble();
    color = adaptiveMap['color'] as String? ?? 'neutral';
    size = adaptiveMap['size'] as String? ?? 'medium';
    allowHalfSteps = adaptiveMap['allowHalfSteps'] as bool? ?? false;
  }

  double _parseRatingValue(Object? raw) {
    if (raw == null) {
      return 0;
    }
    if (raw is num) {
      return raw.toDouble();
    }
    return double.tryParse(raw.toString()) ?? 0;
  }

  double _resolvedValue(ResolvedInputState input) =>
      _parseRatingValue(input.valueRaw);

  void _onRatingChanged(double newValue) {
    setDocumentInputValue(newValue);
    rawRootCardWidgetState.changeValue(id, newValue);
    notifyUserInputValueChanged(newValue, committed: true);
  }

  @override
  Widget build(BuildContext context) {
    listenForResolvedValueChanges();
    final input = watchResolvedInput();
    final displayValue = _resolvedValue(input);
    final starColor = resolveRatingStarColor(styleResolver, color);
    final iconSize = resolveRatingIconSize(size);

    return Visibility(
      visible: isVisible,
      child: SeparatorElement(
        adaptiveMap: adaptiveMap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            loadLabel(
              context: context,
              label: input.label,
              isRequired: input.isRequired,
            ),
            RatingStars(
              key: generateWidgetKey(adaptiveMap),
              value: displayValue,
              max: max,
              starColor: starColor,
              iconSize: iconSize,
              readOnly: false,
              allowHalfSteps: allowHalfSteps,
              onRatingChanged: _onRatingChanged,
            ),
            loadErrorMessage(
              context: context,
              errorMessage: input.errorMessage,
              showError: input.isInvalid,
            ),
          ],
        ),
      ),
    );
  }

  @override
  void appendInput(Map map) {
    map[id] = _resolvedValue(readResolvedInput());
  }

  @override
  void initInput(Map map) {
    if (map[id] != null) {
      setDocumentInputValue(map[id]);
    }
  }

  @override
  void onDocumentValueChanged(Object? valueFromDocument) {
    // Rebuild via ref.watch; keeps controller-less inputs in sync after reset/init.
    setState(() {});
  }

  @override
  bool checkRequired() {
    if (!readResolvedInput().isRequired) {
      return true;
    }
    if (_resolvedValue(readResolvedInput()) <= 0) {
      setLocalValidationError();
      return false;
    }
    clearLocalValidationError();
    return true;
  }
}
