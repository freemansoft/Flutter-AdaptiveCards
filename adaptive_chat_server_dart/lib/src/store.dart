/// In-memory conversation state for the Adaptive Chat demo.
library;

import 'dart:math';

import 'package:adaptive_chat_server_dart/src/stats.dart';

/// One rendered bubble: an author role plus its Adaptive Card map.
class Message {
  /// Creates a message.
  const Message({required this.role, required this.card});

  /// The author role of the message.
  final String role;

  /// The Adaptive Card map for this message.
  final Map<String, dynamic> card;
}

/// One send/response cycle within a conversation.
class Interaction {
  /// Creates an interaction.
  const Interaction({
    required this.interactionId,
    required this.text,
    required this.messages,
    this.replyText = '',
    this.stats,
  });

  /// The unique identifier for this interaction.
  final String interactionId;

  /// The user input text.
  final String text;

  /// The rendered messages in this interaction.
  final List<Message> messages;

  /// The reply text from the model.
  final String replyText;

  /// `null` whenever the reply cost no measurable tokens: echo mode, or any
  /// Ollama failure. The interaction still counts — it happened.
  final InteractionStats? stats;
}

/// A session: ordered interactions keyed by client-supplied id.
class Conversation {
  /// Creates a conversation.
  Conversation({required this.conversationId}) : interactions = {}, order = [];

  /// The unique identifier for this conversation.
  final String conversationId;

  /// Map of interaction ids to interactions.
  final Map<String, Interaction> interactions;

  /// List of interaction ids in creation order.
  final List<String> order;
}

final _idRandom = Random.secure();

String _newConversationId() {
  final bytes = List<int>.generate(6, (_) => _idRandom.nextInt(256));
  final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  return 'c_$hex';
}

/// Process-lifetime store of conversations (lost on restart).
class ConversationStore {
  final Map<String, Conversation> _conversations = {};

  /// Creates a new conversation and returns it.
  Conversation create() {
    final conv = Conversation(conversationId: _newConversationId());
    _conversations[conv.conversationId] = conv;
    return conv;
  }

  /// Gets a conversation by id, or null if not found.
  Conversation? get(String cid) => _conversations[cid];

  /// Checks if an interaction exists in a conversation.
  bool hasInteraction(String cid, String iid) {
    final conv = _conversations[cid];
    return conv != null && conv.interactions.containsKey(iid);
  }

  /// Adds an interaction to a conversation.
  void addInteraction(String cid, Interaction interaction) {
    final conv = _conversations[cid]!;
    conv.interactions[interaction.interactionId] = interaction;
    conv.order.add(interaction.interactionId);
  }

  /// Gets an interaction from a conversation, or null if not found.
  Interaction? getInteraction(String cid, String iid) =>
      _conversations[cid]?.interactions[iid];

  /// Every live conversation, in creation order.
  ///
  /// Insertion order is guaranteed by [Map] (a `LinkedHashMap` by default),
  /// the same guarantee the Python store relies on for `dict`.
  List<Conversation> listConversations() => _conversations.values.toList();
}
