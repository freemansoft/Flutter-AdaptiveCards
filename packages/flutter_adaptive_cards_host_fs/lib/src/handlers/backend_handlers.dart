import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/flutter_adaptive_cards_fs.dart';
import 'package:flutter_adaptive_cards_host_fs/src/adapters/plain_json_invoke_adapter.dart';
import 'package:flutter_adaptive_cards_host_fs/src/adapters/plain_json_invoke_response_parser.dart';
import 'package:flutter_adaptive_cards_host_fs/src/client/backend_client.dart';
import 'package:flutter_adaptive_cards_host_fs/src/models/invoke_request.dart';
import 'package:flutter_adaptive_cards_host_fs/src/models/invoke_response.dart';

/// Wires [InheritedAdaptiveCardHandlers] to a backend invoke round-trip.
///
/// Assign [cardKey] to the same [RawAdaptiveCard] that renders the card.
/// [InputChangeInvoke] uses [InputChangeInvoke.cardState] directly; Submit and
/// Execute resolve state from [cardKey].
class AdaptiveCardBackendHandlers {
  /// Creates handlers that POST invoke payloads via [client].
  ///
  /// Defaults: `PlainJsonInvokeAdapter.toMap` and
  /// `PlainJsonInvokeResponseParser.parse`. Pass `TeamsInvokeAdapter` methods
  /// for Bot Framework–shaped JSON.
  AdaptiveCardBackendHandlers({
    required this.client,
    required this.cardKey,
    Map<String, dynamic> Function(AdaptiveCardInvokeRequest)? requestAdapter,
    AdaptiveCardInvokeResponse Function(Map<String, dynamic>)? responseParser,
    this.onError,
    this.onOpenUrl,
    this.onOpenUrlDialog,
  }) : requestAdapter = requestAdapter ?? PlainJsonInvokeAdapter.toMap,
       responseParser = responseParser ?? PlainJsonInvokeResponseParser.parse;

  /// Backend transport (HTTP, mock, or custom).
  final AdaptiveCardBackendClient client;

  /// Key shared with [RawAdaptiveCard] for Submit/Execute state lookup.
  final GlobalKey<RawAdaptiveCardState> cardKey;

  /// Serializes [AdaptiveCardInvokeRequest] before `client.post`.
  final Map<String, dynamic> Function(AdaptiveCardInvokeRequest) requestAdapter;

  /// Parses the JSON returned from `client.post`.
  final AdaptiveCardInvokeResponse Function(Map<String, dynamic>)
  responseParser;

  /// Called when POST or response parsing fails.
  final void Function(Object error)? onError;

  /// Optional override for `Action.OpenUrl` (defaults to no-op).
  final void Function(OpenUrlActionInvoke invoke)? onOpenUrl;

  /// Optional override for `Action.OpenUrlDialog` (defaults to no-op).
  final void Function(OpenUrlDialogActionInvoke invoke)? onOpenUrlDialog;

  /// Wraps [child] with backend-connected [InheritedAdaptiveCardHandlers].
  ///
  /// Provide [onCardReplaced] when the backend may return a full card JSON
  /// replacement.
  Widget wrap(
    Widget child, {
    void Function(Map<String, dynamic> card)? onCardReplaced,
  }) {
    return InheritedAdaptiveCardHandlers(
      onSubmit: (invoke) => unawaited(
        _handle(
          AdaptiveCardInvokeRequest.fromSubmit(invoke),
          onCardReplaced: onCardReplaced,
        ),
      ),
      onExecute: (invoke) => unawaited(
        _handle(
          AdaptiveCardInvokeRequest.fromExecute(invoke),
          onCardReplaced: onCardReplaced,
        ),
      ),
      onChange: (invoke) => unawaited(
        _handle(
          AdaptiveCardInvokeRequest.fromInputChange(invoke),
          cardState: invoke.cardState,
          onCardReplaced: onCardReplaced,
        ),
      ),
      onOpenUrl: onOpenUrl ?? (_) {},
      onOpenUrlDialog: onOpenUrlDialog ?? (_) {},
      child: child,
    );
  }

  Future<void> _handle(
    AdaptiveCardInvokeRequest request, {
    RawAdaptiveCardState? cardState,
    void Function(Map<String, dynamic> card)? onCardReplaced,
  }) async {
    final state = cardState ?? cardKey.currentState;
    if (state == null) {
      const message =
          'RawAdaptiveCardState not found — assign cardKey to RawAdaptiveCard';
      onError?.call(StateError(message));
      assert(() {
        developer.log('AdaptiveCardBackendHandlers: $message');
        return true;
      }());
      return;
    }

    try {
      final body = requestAdapter(request);
      final json = await client.post(body);
      responseParser(json).applyTo(state, onCardReplaced: onCardReplaced);
    } on Object catch (error, stackTrace) {
      onError?.call(error);
      assert(() {
        developer.log(
          'AdaptiveCardBackendHandlers invoke failed',
          error: error,
          stackTrace: stackTrace,
        );
        return true;
      }());
    }
  }
}
