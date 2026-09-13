/// Data types for the Adaptive Chat wire contract.
library;

/// Result of starting a conversation.
class const ChatStart({
  /// Server-minted conversation id.
  required final String conversationId,

  /// URL the next interaction posts to.
  required final String postNext,
}) {
  /// Creates a start result.
  this;

  /// Parses the `POST /conversations` response.
  factory fromJson(Map<String, dynamic> json) {
    final links = json['links'] as Map<String, dynamic>;
    return ChatStart(
      conversationId: json['conversationId'] as String,
      postNext: links['postNext'] as String,
    );
  }
}

/// One interaction's response: pre-styled cards plus follow-up links.
class const ChatEnvelope({
  /// Conversation this interaction belongs to.
  required final String conversationId,

  /// Client-supplied id echoed by the server.
  required final String interactionId,

  /// Ordered, pre-styled Adaptive Card maps to render as bubbles.
  required final List<Map<String, dynamic>> messages,

  /// Re-GET URL for this interaction (replay).
  required final String self,

  /// URL the next interaction posts to.
  required final String postNext,
}) {
  /// Creates an envelope.
  this;

  /// Parses a send/replay response envelope.
  factory fromJson(Map<String, dynamic> json) {
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
}

/// Raised when the chat backend returns an error or unreachable response.
class ChatBackendException(
  /// Human-readable failure description.
  final String message,
) implements Exception {
  /// Creates the exception with a [message].
  this;

  @override
  String toString() => 'ChatBackendException: $message';
}
