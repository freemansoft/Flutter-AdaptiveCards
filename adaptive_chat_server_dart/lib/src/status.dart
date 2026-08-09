/// Assembles the `GET /status` payload from the store and the live
/// responder.
///
/// Deliberately carries no message text: the endpoint is unauthenticated
/// and CORS is wide open, so conversation content must not be reachable
/// through it.
library;

import 'dart:convert';

import 'package:adaptive_chat_server_dart/src/responder.dart';
import 'package:adaptive_chat_server_dart/src/stats.dart';
import 'package:adaptive_chat_server_dart/src/store.dart';
import 'package:crypto/crypto.dart';

/// Stable, non-reversible label for correlating a conversation across polls.
///
/// The raw `conversationId` is the bearer credential for
/// `GET/POST /conversations/{cid}/interactions`, which return message text.
/// Since this endpoint is unauthenticated and CORS is wide open, leaking the
/// id here would hand any web page the developer visits a way to read the
/// transcript. Truncating the hash keeps it short while leaving it useless
/// for guessing the original id.
String conversationRef(String conversationId) {
  final digest = sha256.convert(utf8.encode(conversationId));
  return digest.toString().substring(0, 12);
}

/// Effective responder config, or a placeholder when it cannot report one.
///
/// A test double's `describe()` must not be able to turn `/status` into a
/// 500, so a throwing `describe()` degrades to `{'kind': 'unknown'}` instead
/// of propagating.
Map<String, dynamic> _describeResponder(Responder responder) {
  try {
    return responder.describe();
  } on Object {
    return {'kind': 'unknown'};
  }
}

Map<String, dynamic> _conversationRow(Conversation conversation) {
  var promptTokens = 0;
  var replyTokens = 0;
  for (final iid in conversation.order) {
    final stats = conversation.interactions[iid]!.stats;
    if (stats != null) {
      promptTokens += stats.promptTokens;
      replyTokens += stats.replyTokens;
    }
  }

  Map<String, dynamic>? last;
  if (conversation.order.isNotEmpty) {
    final lastIid = conversation.order.last;
    final lastStats = conversation.interactions[lastIid]!.stats;
    last = {'stats': lastStats != null ? statsToJson(lastStats) : null};
  }

  return {
    'conversationRef': conversationRef(conversation.conversationId),
    'interactionCount': conversation.order.length,
    'totals': {
      'promptTokens': promptTokens,
      'replyTokens': replyTokens,
      'totalTokens': promptTokens + replyTokens,
    },
    'lastInteraction': last,
  };
}

/// Operator snapshot of the running server.
Map<String, dynamic> buildStatus(
  ConversationStore store,
  Responder responder,
) {
  final conversations = store.listConversations();
  return {
    'responder': _describeResponder(responder),
    'conversationCount': conversations.length,
    'conversations': conversations.map(_conversationRow).toList(),
  };
}
