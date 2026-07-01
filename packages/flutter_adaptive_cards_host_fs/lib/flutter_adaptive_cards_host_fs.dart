/// Backend invoke bridge for Flutter Adaptive Cards.
///
/// Serialize host callbacks, POST to a flow-service, parse responses, and
/// apply overlay patches or full card replacement
/// via `AdaptiveCardBackendHandlers`.
library;

export 'package:flutter_adaptive_cards_host_fs/src/adapters/plain_json_invoke_adapter.dart';
export 'package:flutter_adaptive_cards_host_fs/src/adapters/plain_json_invoke_response_parser.dart';
export 'package:flutter_adaptive_cards_host_fs/src/adapters/teams_invoke_adapter.dart';
export 'package:flutter_adaptive_cards_host_fs/src/client/backend_client.dart';
export 'package:flutter_adaptive_cards_host_fs/src/client/http_action_executor.dart';
export 'package:flutter_adaptive_cards_host_fs/src/client/http_backend_client.dart';
export 'package:flutter_adaptive_cards_host_fs/src/handlers/backend_handlers.dart';
export 'package:flutter_adaptive_cards_host_fs/src/models/invoke_effect.dart';
export 'package:flutter_adaptive_cards_host_fs/src/models/invoke_kind.dart';
export 'package:flutter_adaptive_cards_host_fs/src/models/invoke_request.dart';
export 'package:flutter_adaptive_cards_host_fs/src/models/invoke_response.dart';
export 'package:flutter_adaptive_cards_host_fs/src/security/bounded_json.dart';
