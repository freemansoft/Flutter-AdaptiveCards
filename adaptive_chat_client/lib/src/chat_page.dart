import 'dart:async';

import 'package:adaptive_chat_client/src/compose_card.dart';
import 'package:adaptive_chat_client/src/conversation_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/flutter_adaptive_cards_fs.dart';

/// The chat screen: a scrolling log of server bubbles plus a compose card.
class ChatPage extends StatefulWidget {
  /// Creates the page bound to [controller].
  const ChatPage({
    required this.controller,
    required this.hostConfigs,
    super.key,
  });

  /// Chat state and transport.
  final ConversationController controller;

  /// Light/dark HostConfig used to render every card.
  final HostConfigs hostConfigs;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final ScrollController _scrollController = ScrollController();
  int _lastItemCount = 0;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    _scrollController.dispose();
    super.dispose();
  }

  int get _itemCount =>
      widget.controller.messages.length + (widget.controller.pending ? 1 : 0);

  /// Keep the latest server response in view: whenever a new item (a message
  /// or the pending bubble) is added, scroll to the very bottom.
  void _onControllerChanged() {
    final count = _itemCount;
    if (count > _lastItemCount) {
      // Scroll after this frame lays out the new item...
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
      // ...and once more after the card's content settles (AdaptiveCardsCanvas
      // loads its content asynchronously, so its full height arrives a frame
      // or two later), snapping to the true bottom.
      unawaited(
        Future<void>.delayed(const Duration(milliseconds: 320), _snapToBottom),
      );
    }
    _lastItemCount = count;
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    unawaited(
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      ),
    );
  }

  void _snapToBottom() {
    if (!mounted || !_scrollController.hasClients) return;
    _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Adaptive Chat'),
            actions: [
              IconButton(
                key: const ValueKey('new-conversation'),
                tooltip: 'New conversation',
                icon: const Icon(Icons.add_comment_outlined),
                onPressed: widget.controller.startConversation,
              ),
            ],
          ),
          body: Column(
            children: [
              if (_showStartError) _buildStartError(context),
              Expanded(child: _buildLog(context)),
              const Divider(height: 1),
              _buildCompose(context),
            ],
          ),
        );
      },
    );
  }

  bool get _showStartError =>
      !widget.controller.ready &&
      !widget.controller.starting &&
      widget.controller.startError != null;

  Widget _buildStartError(BuildContext context) {
    return Material(
      key: const ValueKey('start-error'),
      color: Theme.of(context).colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Text(
                "Couldn't reach the chat server.",
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onErrorContainer,
                ),
              ),
            ),
            TextButton(
              key: const ValueKey('start-error-retry'),
              onPressed: widget.controller.startConversation,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLog(BuildContext context) {
    final messages = widget.controller.messages;
    final itemCount = messages.length + (widget.controller.pending ? 1 : 0);
    return SelectionArea(
      child: ListView.builder(
        key: const ValueKey('chat-log'),
        controller: _scrollController,
        padding: const EdgeInsets.all(12),
        itemCount: itemCount,
        itemBuilder: (context, index) {
          if (index >= messages.length) {
            return const _PendingBubble(key: ValueKey('pending-bubble'));
          }
          final card = messages[index];
          return Padding(
            // Keyed by the card's own identity (not index): after New
            // conversation / clear() a new message can land at the same list
            // index as a previous (different) card, and AdaptiveCardsCanvas
            // only loads its content in initState, so an unkeyed rebuild
            // would keep showing the stale card.
            key: ObjectKey(card),
            padding: const EdgeInsets.only(bottom: 8),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 220),
              builder: (context, t, child) => Opacity(opacity: t, child: child),
              child: AdaptiveCardsCanvas.map(
                content: card,
                hostConfigs: widget.hostConfigs,
                showDebugJson: false,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCompose(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: InheritedAdaptiveCardHandlers(
        onSubmit: (invoke) {
          final text = invoke.data['message'] as String? ?? '';
          unawaited(widget.controller.send(text));
        },
        onExecute: (_) {},
        onOpenUrl: (_) {},
        onOpenUrlDialog: (_) {},
        onChange: (_) {},
        child: AdaptiveCardsCanvas.map(
          // Rebuild empty after each send.
          key: ValueKey('compose-${widget.controller.composeEpoch}'),
          content: composeCard(),
          hostConfigs: widget.hostConfigs,
          showDebugJson: false,
        ),
      ),
    );
  }
}

/// Three-dot "typing" indicator shown while a send is in flight.
class _PendingBubble extends StatelessWidget {
  const _PendingBubble({super.key});

  @override
  Widget build(BuildContext context) {
    return const Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}
