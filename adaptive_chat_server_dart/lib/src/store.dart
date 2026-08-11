/// In-memory conversation state for the Adaptive Chat demo.
library;

import 'dart:math';

import 'package:adaptive_chat_server_dart/src/stats.dart';

/// Default user role label, used when a client does not supply its own
/// at `POST /conversations` time.
const defaultUserLabel = 'user';

/// Default assistant role label. See [defaultUserLabel].
const defaultAssistantLabel = 'assistant';

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
    this.ok = true,
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

  /// Whether [replyText] is a real answer rather than a failure diagnostic.
  ///
  /// Stored so history rebuilds can skip failed exchanges; the interaction is
  /// still kept and replayed to the client, because it did happen.
  final bool ok;
}

/// A session: ordered interactions keyed by client-supplied id.
class Conversation {
  /// Creates a conversation.
  Conversation({
    required this.conversationId,
    this.userLabel = defaultUserLabel,
    this.assistantLabel = defaultAssistantLabel,
    this.language,
  }) : interactions = {},
       order = [];

  /// The unique identifier for this conversation.
  final String conversationId;

  /// Role label shown above the user's bubbles, fixed for the conversation's
  /// lifetime (set once, at `POST /conversations`).
  final String userLabel;

  /// Role label shown above the assistant's bubbles. See [userLabel].
  final String assistantLabel;

  /// Client-supplied language tag (e.g. `es`), if any.
  ///
  /// Stored for future use (e.g. a localized system prompt or the
  /// "conversation expired" card); nothing reads it yet.
  final String? language;

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
  Conversation create({
    String userLabel = defaultUserLabel,
    String assistantLabel = defaultAssistantLabel,
    String? language,
  }) {
    final conv = Conversation(
      conversationId: _newConversationId(),
      userLabel: userLabel,
      assistantLabel: assistantLabel,
      language: language,
    );
    _conversations[conv.conversationId] = conv;
    return conv;
  }

  /// Gets a conversation by id, or null if not found.
  Conversation? get(String cid) => _conversations[cid];

  /// Adds an interaction to a conversation, ignoring a repeated id.
  ///
  /// The first write for an interaction id wins. Re-adding the same id is a
  /// no-op rather than a second entry, so a client retry can never duplicate
  /// a turn in [Conversation.order] — which would otherwise replay that turn
  /// twice in the model's history and double-count it in `GET /status`.
  void addInteraction(String cid, Interaction interaction) {
    final conv = _conversations[cid]!;
    if (conv.interactions.containsKey(interaction.interactionId)) return;
    conv.interactions[interaction.interactionId] = interaction;
    conv.order.add(interaction.interactionId);
  }

  /// Gets an interaction from a conversation, or null if not found.
  Interaction? getInteraction(String cid, String iid) =>
      _conversations[cid]?.interactions[iid];

  /// Every live conversation, in creation order.
  ///
  /// Insertion order is guaranteed by [Map] (a `LinkedHashMap` by default), so
  /// callers may rely on it without extra bookkeeping.
  List<Conversation> listConversations() => _conversations.values.toList();
}
