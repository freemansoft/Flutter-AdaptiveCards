/// Flutter Adaptive Cards
///
/// This package provides a way to display Adaptive Cards in a Flutter application.
///
library;

export 'package:flutter_adaptive_cards_fs/src/action/action_handler.dart';
export 'package:flutter_adaptive_cards_fs/src/adaptive_cards_canvas.dart';
export 'package:flutter_adaptive_cards_fs/src/flutter_raw_adaptive_card.dart'
    show RawAdaptiveCard, RawAdaptiveCardState;
export 'package:flutter_adaptive_cards_fs/src/hostconfig/host_config.dart';
export 'package:flutter_adaptive_cards_fs/src/models/action_invoke.dart';
export 'package:flutter_adaptive_cards_fs/src/models/adaptive_card_update.dart';
export 'package:flutter_adaptive_cards_fs/src/models/choice.dart';
export 'package:flutter_adaptive_cards_fs/src/models/data_query.dart';
export 'package:flutter_adaptive_cards_fs/src/models/fact.dart';
export 'package:flutter_adaptive_cards_fs/src/models/media_source.dart';
export 'package:flutter_adaptive_cards_fs/src/models/refresh_config.dart';
export 'package:flutter_adaptive_cards_fs/src/models/text_run.dart';

/// needed so we can create the registry to pass into the AdaptiveCard constructor
export 'package:flutter_adaptive_cards_fs/src/registry.dart';
