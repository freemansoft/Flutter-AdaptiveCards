import 'package:adaptive_chat/src/chat_backend_client.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_adaptive_cards_fs/flutter_adaptive_cards_fs.dart';

/// Whether new interactions append to the log or replace it.
enum ChatMode {
  /// Keep the full history.
  append,

  /// Show only the latest interaction.
  replace,
}

/// Holds chat state and drives the [ChatBackendClient].
///
/// Ordinary Flutter state — Riverpod is reserved for the core library.
class ConversationController extends ChangeNotifier {
  /// Creates a controller backed by [client].
  ConversationController({required this.client});

  /// Backend transport.
  final ChatBackendClient client;

  /// Rendered bubble cards, oldest first.
  final List<Map<String, dynamic>> messages = [];

  /// True while a send is in flight (drives the pending indicator).
  bool pending = false;

  /// Append vs replace behavior.
  ChatMode mode = ChatMode.append;

  /// Bumped after each send so the compose card rebuilds empty.
  int composeEpoch = 0;

  String? _conversationId;
  String? _postNext;
  int _counter = 0;

  /// True once a conversation exists and sends are allowed.
  bool get ready => _postNext != null;

  /// Active conversation id, if any.
  String? get conversationId => _conversationId;

  /// Starts a new conversation and clears the log.
  Future<void> startConversation() async {
    final start = await client.startConversation();
    _conversationId = start.conversationId;
    _postNext = start.postNext;
    messages.clear();
    notifyListeners();
  }

  String _nextInteractionId() => 'i_${(++_counter).toString().padLeft(4, '0')}';

  /// Sends [text] and appends (or replaces with) the returned cards.
  Future<void> send(String text) async {
    final postNext = _postNext;
    if (postNext == null || text.trim().isEmpty || pending) {
      return;
    }
    pending = true;
    composeEpoch++;
    notifyListeners();
    try {
      final envelope = await client.sendInteraction(
        postNext: postNext,
        interactionId: _nextInteractionId(),
        invoke: SubmitActionInvoke(data: {'message': text}),
      );
      _postNext = envelope.postNext;
      if (mode == ChatMode.replace) {
        messages.clear();
      }
      messages.addAll(envelope.messages);
    } finally {
      pending = false;
      notifyListeners();
    }
  }

  /// Flips between append and replace.
  void toggleMode() {
    mode = mode == ChatMode.append ? ChatMode.replace : ChatMode.append;
    notifyListeners();
  }

  /// Clears the visible log (keeps the conversation).
  void clear() {
    messages.clear();
    notifyListeners();
  }
}
