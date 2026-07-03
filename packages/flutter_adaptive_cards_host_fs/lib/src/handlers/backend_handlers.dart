import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/flutter_adaptive_cards_fs.dart';
import 'package:flutter_adaptive_cards_host_fs/src/adapters/plain_json_invoke_adapter.dart';
import 'package:flutter_adaptive_cards_host_fs/src/adapters/plain_json_invoke_response_parser.dart';
import 'package:flutter_adaptive_cards_host_fs/src/client/backend_client.dart';
import 'package:flutter_adaptive_cards_host_fs/src/client/http_action_executor.dart';
import 'package:flutter_adaptive_cards_host_fs/src/models/invoke_request.dart';
import 'package:flutter_adaptive_cards_host_fs/src/models/invoke_response.dart';
import 'package:flutter_adaptive_cards_host_fs/src/security/bounded_json.dart';

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
    this.httpExecutor,
    this.urlOpener,
    this.onSignin,
  }) : requestAdapter = requestAdapter ?? PlainJsonInvokeAdapter.toMap,
       responseParser = responseParser ?? PlainJsonInvokeResponseParser.parse;

  /// Backend transport (HTTP, mock, or custom).
  final AdaptiveCardBackendClient client;

  /// Executor for card-authored `Action.Http` requests.
  ///
  /// **Deprecated/legacy:** `Action.Http` was the original Adaptive Cards HTTP
  /// action model (schema v1.0), superseded by `Action.Execute` (Universal
  /// Action Model, schema v1.4); still used by Outlook Actionable Messages.
  /// When null, `Action.Http` taps are ignored. Provide
  /// [HttpAdaptiveHttpExecutor] (or a custom [AdaptiveHttpExecutor]) to perform
  /// the GET/POST and honor `CARD-UPDATE-IN-BODY` / `CARD-ACTION-STATUS`.
  final AdaptiveHttpExecutor? httpExecutor;

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

  /// Opens the sign-in URL from a card `authentication` button.
  ///
  /// The app owns the browser/redirect; when null, sign-in taps are ignored.
  final Future<void> Function(String url)? urlOpener;

  /// Optional override for the sign-in handoff (defaults to [urlOpener]).
  final void Function(SigninActionInvoke invoke)? onSignin;

  SigninActionInvoke? _pendingSignin;
  void Function(Map<String, dynamic> card)? _onCardReplaced;
  AdaptiveCardValidator? _cardValidator;

  /// Wraps [child] with backend-connected [InheritedAdaptiveCardHandlers].
  ///
  /// Provide [onCardReplaced] when the backend may return a full card JSON
  /// replacement. Pass [cardValidator] to reject untrusted replacement cards
  /// that fail a host-defined check before they render.
  Widget wrap(
    Widget child, {
    void Function(Map<String, dynamic> card)? onCardReplaced,
    AdaptiveCardValidator? cardValidator,
  }) {
    _onCardReplaced = onCardReplaced;
    _cardValidator = cardValidator;
    return InheritedAdaptiveCardHandlers(
      onSubmit: (invoke) => unawaited(
        _handle(
          AdaptiveCardInvokeRequest.fromSubmit(invoke),
          onCardReplaced: onCardReplaced,
          cardValidator: cardValidator,
        ),
      ),
      onExecute: (invoke) => unawaited(
        _handle(
          AdaptiveCardInvokeRequest.fromExecute(invoke),
          onCardReplaced: onCardReplaced,
          cardValidator: cardValidator,
        ),
      ),
      onRefresh: (invoke) => unawaited(
        _handle(
          AdaptiveCardInvokeRequest.fromExecute(
            ExecuteActionInvoke(
              data: invoke.data,
              verb: invoke.verb,
              actionId: invoke.actionId,
            ),
          ),
          onCardReplaced: onCardReplaced,
          cardValidator: cardValidator,
        ),
      ),
      onChange: (invoke) => unawaited(
        _handle(
          AdaptiveCardInvokeRequest.fromInputChange(invoke),
          cardState: invoke.cardState,
          onCardReplaced: onCardReplaced,
          cardValidator: cardValidator,
        ),
      ),
      onOpenUrl: onOpenUrl ?? (_) {},
      onOpenUrlDialog: onOpenUrlDialog ?? (_) {},
      onSignin: (invoke) {
        _pendingSignin = invoke;
        final override = onSignin;
        if (override != null) {
          override(invoke);
          return;
        }
        final opener = urlOpener;
        if (opener != null && invoke.value.isNotEmpty) {
          unawaited(opener(invoke.value));
        }
      },
      onHttp: httpExecutor == null
          ? null
          : (invoke) => unawaited(
              _handleHttp(
                invoke,
                onCardReplaced: onCardReplaced,
                cardValidator: cardValidator,
              ),
            ),
      child: child,
    );
  }

  /// Completes a card sign-in after the app captures the OAuth redirect.
  ///
  /// POSTs a sign-in invoke (built from the last `onSignin` payload plus
  /// [state]) and applies the response — a `replaceCard` effect swaps in the
  /// real card. Call after [urlOpener]'s flow returns.
  Future<void> completeSignin({
    required String state,
    void Function(Map<String, dynamic> card)? onCardReplaced,
    AdaptiveCardValidator? cardValidator,
  }) async {
    final pending = _pendingSignin;
    if (pending == null) {
      onError?.call(
        StateError('completeSignin called with no pending sign-in'),
      );
      return;
    }
    await _handle(
      AdaptiveCardInvokeRequest.fromSignin(pending, state: state),
      onCardReplaced: onCardReplaced ?? _onCardReplaced,
      cardValidator: cardValidator ?? _cardValidator,
    );
    _pendingSignin = null;
  }

  Future<void> _handleHttp(
    HttpActionInvoke invoke, {
    void Function(Map<String, dynamic> card)? onCardReplaced,
    AdaptiveCardValidator? cardValidator,
  }) async {
    final executor = httpExecutor;
    if (executor == null) return;

    try {
      final result = await executor.execute(invoke);

      if (!result.isSuccess) {
        // Outlook convention: failures carry a human-readable message in the
        // CARD-ACTION-STATUS header.
        final status = result.headers['card-action-status'];
        throw AdaptiveCardBackendException(
          status ?? 'Action.Http failed with HTTP ${result.statusCode}',
          body: result.body,
        );
      }

      // Outlook refresh-card convention: a CARD-UPDATE-IN-BODY: true response
      // replaces the rendered card with the JSON in the body.
      final updateInBody = result.headers['card-update-in-body'];
      if (updateInBody?.toLowerCase() == 'true' && result.body.isNotEmpty) {
        final state = cardKey.currentState;
        if (state == null) {
          throw StateError(
            'RawAdaptiveCardState not found '
            '— assign cardKey to RawAdaptiveCard',
          );
        }
        if (onCardReplaced == null) {
          throw StateError(
            'onCardReplaced is required to apply a CARD-UPDATE-IN-BODY refresh',
          );
        }
        final card = decodeJsonMapWithLimit(result.body);
        if (cardValidator != null && !cardValidator(card)) {
          throw AdaptiveCardInvokeResponseParseException(
            'Action.Http replacement card rejected by cardValidator',
          );
        }
        onCardReplaced(card);
      }
    } on Object catch (error, stackTrace) {
      onError?.call(error);
      assert(() {
        developer.log(
          'AdaptiveCardBackendHandlers Action.Http failed',
          error: error,
          stackTrace: stackTrace,
        );
        return true;
      }());
    }
  }

  Future<void> _handle(
    AdaptiveCardInvokeRequest request, {
    RawAdaptiveCardState? cardState,
    void Function(Map<String, dynamic> card)? onCardReplaced,
    AdaptiveCardValidator? cardValidator,
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
      responseParser(json).applyTo(
        state,
        onCardReplaced: onCardReplaced,
        cardValidator: cardValidator,
      );
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
