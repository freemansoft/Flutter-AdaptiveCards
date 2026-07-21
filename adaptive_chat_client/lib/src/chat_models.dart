/// Data types for the Adaptive Chat wire contract.
library;

/// Result of starting a conversation.
class ChatStart {
  /// Creates a start result.
  const ChatStart({required this.conversationId, required this.postNext});

  /// Parses the `POST /conversations` response.
  factory ChatStart.fromJson(Map<String, dynamic> json) {
    final links = json['links'] as Map<String, dynamic>;
    return ChatStart(
      conversationId: json['conversationId'] as String,
      postNext: links['postNext'] as String,
    );
  }

  /// Server-minted conversation id.
  final String conversationId;

  /// URL the next interaction posts to.
  final String postNext;
}

/// One interaction's response: pre-styled cards plus follow-up links.
class ChatEnvelope {
  /// Creates an envelope.
  const ChatEnvelope({
    required this.conversationId,
    required this.interactionId,
    required this.messages,
    required this.self,
    required this.postNext,
  });

  /// Parses a send/replay response envelope.
  factory ChatEnvelope.fromJson(Map<String, dynamic> json) {
    final links = json['links'] as Map<String, dynamic>;
    final rawMessages = json['messages'] as List<dynamic>;
    return ChatEnvelope(
      conversationId: json['conversationId'] as String,
      interactionId: json['interactionId'] as String,
      messages: rawMessages
          .map((m) => Map<String, dynamic>.from(m as Map))
          .toList(),
      self: links['self'] as String,
      postNext: links['postNext'] as String,
    );
  }

  /// Conversation this interaction belongs to.
  final String conversationId;

  /// Client-supplied id echoed by the server.
  final String interactionId;

  /// Ordered, pre-styled Adaptive Card maps to render as bubbles.
  final List<Map<String, dynamic>> messages;

  /// Re-GET URL for this interaction (replay).
  final String self;

  /// URL the next interaction posts to.
  final String postNext;
}

/// Raised when the chat backend returns an error or unreachable response.
class ChatBackendException implements Exception {
  /// Creates the exception with a [message].
  ChatBackendException(this.message);

  /// Human-readable failure description.
  final String message;

  @override
  String toString() => 'ChatBackendException: $message';
}
