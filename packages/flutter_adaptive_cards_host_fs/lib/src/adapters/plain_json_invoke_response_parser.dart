import 'package:flutter_adaptive_cards_fs/flutter_adaptive_cards_fs.dart';
import 'package:flutter_adaptive_cards_host_fs/src/adapters/element_update_json.dart';
import 'package:flutter_adaptive_cards_host_fs/src/models/invoke_effect.dart';
import 'package:flutter_adaptive_cards_host_fs/src/models/invoke_response.dart';

/// Parses the default PlainJson invoke response contract.
class PlainJsonInvokeResponseParser {
  const PlainJsonInvokeResponseParser._();

  static const _responseType = 'adaptiveCard.invokeResponse';

  /// Parses [map] into [AdaptiveCardInvokeResponse].
  static AdaptiveCardInvokeResponse parse(Map<String, dynamic> map) {
    final type = map['type'] as String?;
    if (type != null && type != _responseType) {
      throw AdaptiveCardInvokeResponseParseException(
        'Unsupported response type: $type',
      );
    }

    final effects = <AdaptiveCardInvokeEffect>[];

    final card = map['card'];
    if (card is Map<String, dynamic>) {
      effects.add(ReplaceCardEffect(card));
    }

    final rawEffects = map['effects'];
    if (rawEffects is List) {
      for (final raw in rawEffects) {
        if (raw is! Map<String, dynamic>) continue;
        effects.add(_effectFromMap(raw));
      }
    }

    if (effects.isEmpty) {
      effects.add(const NoOpEffect());
    }

    return AdaptiveCardInvokeResponse(_orderEffects(effects));
  }

  static List<AdaptiveCardInvokeEffect> _orderEffects(
    List<AdaptiveCardInvokeEffect> effects,
  ) {
    final patches = <ApplyPatchesEffect>[];
    final errors = <SetInputErrorsEffect>[];
    final replacements = <ReplaceCardEffect>[];
    final noOps = <NoOpEffect>[];

    for (final effect in effects) {
      switch (effect) {
        case ApplyPatchesEffect():
          patches.add(effect);
        case SetInputErrorsEffect():
          errors.add(effect);
        case ReplaceCardEffect():
          replacements.add(effect);
        case NoOpEffect():
          noOps.add(effect);
      }
    }

    return [
      ...patches,
      ...errors,
      ...replacements,
      ...noOps,
    ];
  }

  static AdaptiveCardInvokeEffect _effectFromMap(Map<String, dynamic> map) {
    final type = map['type'] as String?;
    switch (type) {
      case 'applyPatches':
        final elements = <AdaptiveElementUpdate>[];
        final rawElements = map['elements'];
        if (rawElements is List) {
          for (final raw in rawElements) {
            if (raw is Map<String, dynamic>) {
              elements.add(elementUpdateFromJson(raw));
            }
          }
        }
        return ApplyPatchesEffect(elements);
      case 'setInputErrors':
        final rawErrors = map['errors'];
        final errors = <String, String>{};
        if (rawErrors is Map) {
          rawErrors.forEach((key, value) {
            errors[key.toString()] = value.toString();
          });
        }
        return SetInputErrorsEffect(errors);
      case 'replaceCard':
        final card = map['card'];
        if (card is Map<String, dynamic>) {
          return ReplaceCardEffect(card);
        }
        throw AdaptiveCardInvokeResponseParseException(
          'replaceCard effect missing card map',
        );
      case 'noOp':
        return const NoOpEffect();
      default:
        return const NoOpEffect();
    }
  }
}
