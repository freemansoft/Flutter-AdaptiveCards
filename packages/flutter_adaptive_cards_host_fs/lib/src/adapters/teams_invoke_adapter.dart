import 'package:flutter_adaptive_cards_host_fs/src/adapters/plain_json_invoke_response_parser.dart';
import 'package:flutter_adaptive_cards_host_fs/src/models/invoke_effect.dart';
import 'package:flutter_adaptive_cards_host_fs/src/models/invoke_kind.dart';
import 'package:flutter_adaptive_cards_host_fs/src/models/invoke_request.dart';
import 'package:flutter_adaptive_cards_host_fs/src/models/invoke_response.dart';

/// Maps invoke requests/responses to Bot Framework–shaped JSON.
///
/// Use with `AdaptiveCardBackendHandlers` when POSTing to a Teams bot endpoint:
/// set `TeamsInvokeAdapter.toMap` as `requestAdapter` and
/// `TeamsInvokeAdapter.responseFromMap` as `responseParser`.
class TeamsInvokeAdapter {
  const TeamsInvokeAdapter._();

  static const _adaptiveCardContentType =
      'application/vnd.microsoft.card.adaptive';

  /// Bot Framework invoke activity value for POST to a Teams bot endpoint.
  static Map<String, dynamic> toMap(AdaptiveCardInvokeRequest request) {
    switch (request.kind) {
      case AdaptiveCardInvokeKind.execute:
      case AdaptiveCardInvokeKind.submit:
        return {
          'type': 'invoke',
          'name': 'adaptiveCard/action',
          'value': {
            'action': {
              'type': request.kind == AdaptiveCardInvokeKind.execute
                  ? 'Action.Execute'
                  : 'Action.Submit',
              if (request.verb != null) 'verb': request.verb,
              if (request.actionId != null) 'id': request.actionId,
              'data': request.data,
            },
          },
        };
      case AdaptiveCardInvokeKind.inputChange:
        return {
          'type': 'invoke',
          'name': 'application/search',
          'value': {
            if (request.dataQuery?.dataset != null)
              'dataset': request.dataQuery!.dataset,
            if (request.dataQuery?.count != null)
              'count': request.dataQuery!.count,
            if (request.dataQuery?.skip != null)
              'skip': request.dataQuery!.skip,
            'data': request.dataQuery?.parameters ?? request.data,
            if (request.value != null) 'queryText': request.value.toString(),
          },
        };
      case AdaptiveCardInvokeKind.openUrl:
      case AdaptiveCardInvokeKind.openUrlDialog:
        return {
          'type': 'invoke',
          'name': 'adaptiveCard/action',
          'value': {
            'action': {
              'type': request.kind == AdaptiveCardInvokeKind.openUrl
                  ? 'Action.OpenUrl'
                  : 'Action.OpenUrlDialog',
              if (request.actionId != null) 'id': request.actionId,
              'url': request.url,
            },
          },
        };
      case AdaptiveCardInvokeKind.signin:
        return {
          'type': 'invoke',
          'name': 'signin/verifyState',
          'value': {
            'state': request.value?.toString(),
          },
        };
    }
  }

  /// Parses Teams invoke responses (attachments, task/continue payloads), then
  /// falls back to PlainJson when no card attachment is present.
  static AdaptiveCardInvokeResponse responseFromMap(Map<String, dynamic> map) {
    final attachmentCard = _cardFromAttachments(map);
    if (attachmentCard != null) {
      return AdaptiveCardInvokeResponse([ReplaceCardEffect(attachmentCard)]);
    }

    final taskCard = _cardFromTaskContinue(map);
    if (taskCard != null) {
      return AdaptiveCardInvokeResponse([ReplaceCardEffect(taskCard)]);
    }

    return PlainJsonInvokeResponseParser.parse(map);
  }

  static Map<String, dynamic>? _cardFromAttachments(Map<String, dynamic> map) {
    final attachments = map['attachments'];
    if (attachments is! List) return null;

    for (final raw in attachments) {
      if (raw is! Map<String, dynamic>) continue;
      if (raw['contentType'] != _adaptiveCardContentType) continue;
      final content = raw['content'];
      if (content is Map<String, dynamic>) {
        return content;
      }
    }
    return null;
  }

  static Map<String, dynamic>? _cardFromTaskContinue(Map<String, dynamic> map) {
    final value = map['value'];
    if (value is! Map<String, dynamic>) return null;
    if (value['type'] != 'continue') return null;

    final card = value['card'];
    if (card is Map<String, dynamic>) {
      return card;
    }

    final cardContent = value['cardContent'];
    if (cardContent is Map<String, dynamic>) {
      return cardContent;
    }
    return null;
  }
}
