/// Render [Adaptive Cards](https://adaptivecards.io/) in Flutter host apps.
///
/// Use `AdaptiveCardsCanvas` to load card JSON, apply `HostConfigs`, and wire
/// host callbacks; use `RawAdaptiveCard` when you already have a parsed card
/// map.
///
library;

export 'package:flutter_adaptive_cards_fs/src/action/action_handler.dart';
export 'package:flutter_adaptive_cards_fs/src/adaptive_cards_canvas.dart';
export 'package:flutter_adaptive_cards_fs/src/flutter_raw_adaptive_card.dart'
    show RawAdaptiveCard, RawAdaptiveCardState;
export 'package:flutter_adaptive_cards_fs/src/hostconfig/host_config.dart';
export 'package:flutter_adaptive_cards_fs/src/models/action_invoke.dart';
export 'package:flutter_adaptive_cards_fs/src/models/adaptive_card_update.dart';
export 'package:flutter_adaptive_cards_fs/src/models/authentication_config.dart';
export 'package:flutter_adaptive_cards_fs/src/models/choice.dart';
export 'package:flutter_adaptive_cards_fs/src/models/data_query.dart';
export 'package:flutter_adaptive_cards_fs/src/models/fact.dart';
export 'package:flutter_adaptive_cards_fs/src/models/media_source.dart';
export 'package:flutter_adaptive_cards_fs/src/models/refresh_config.dart';
export 'package:flutter_adaptive_cards_fs/src/models/text_run.dart';

/// `CardTypeRegistry` and `ActionTypeRegistry` for customizing element and
/// action rendering; pass instances into `AdaptiveCardsCanvas` or
/// `RawAdaptiveCard`.
export 'package:flutter_adaptive_cards_fs/src/registry.dart';
export 'package:flutter_adaptive_cards_fs/src/riverpod/element_overlay_extension.dart';
export 'package:flutter_adaptive_cards_fs/src/riverpod/overlay_capability_registry.dart';

/// Security policies for card-controlled URLs and card-initiated fetches.
/// Wrap a card with `InheritedAdaptiveCardSecurityPolicy` (or pass policies to
/// `RawAdaptiveCard`) to customize scheme/host allowlists and fetch byte caps.
export 'package:flutter_adaptive_cards_fs/src/security/adaptive_fetch_policy.dart';
export 'package:flutter_adaptive_cards_fs/src/security/adaptive_uri_policy.dart';
export 'package:flutter_adaptive_cards_fs/src/security/adaptive_uri_validation.dart';
export 'package:flutter_adaptive_cards_fs/src/security/inherited_security_policy.dart';
