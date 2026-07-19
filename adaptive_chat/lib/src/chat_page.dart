import 'dart:async';

import 'package:adaptive_chat/src/compose_card.dart';
import 'package:adaptive_chat/src/conversation_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/flutter_adaptive_cards_fs.dart';

/// The chat screen: a scrolling log of server bubbles plus a compose card.
class ChatPage extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Adaptive Chat'),
            actions: [
              IconButton(
                key: const ValueKey('new-conversation'),
                tooltip: 'New conversation',
                icon: const Icon(Icons.add_comment_outlined),
                onPressed: controller.startConversation,
              ),
              Row(
                children: [
                  const Text('Replace'),
                  Switch(
                    key: const ValueKey('mode-toggle'),
                    value: controller.mode == ChatMode.replace,
                    onChanged: (_) => controller.toggleMode(),
                  ),
                ],
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
      !controller.ready &&
      !controller.starting &&
      controller.startError != null;

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
              onPressed: controller.startConversation,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLog(BuildContext context) {
    final itemCount = controller.messages.length + (controller.pending ? 1 : 0);
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        if (index >= controller.messages.length) {
          return const _PendingBubble(key: ValueKey('pending-bubble'));
        }
        final card = controller.messages[index];
        return Padding(
          // Keyed by the card's own identity (not index): in replace mode a
          // new message can land at the same list index as the old one, and
          // AdaptiveCardsCanvas only loads its content in initState, so an
          // unkeyed rebuild would keep showing the stale card.
          key: ObjectKey(card),
          padding: const EdgeInsets.only(bottom: 8),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 220),
            builder: (context, t, child) => Opacity(opacity: t, child: child),
            child: AdaptiveCardsCanvas.map(
              content: card,
              hostConfigs: hostConfigs,
              showDebugJson: false,
            ),
          ),
        );
      },
    );
  }

  Widget _buildCompose(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: InheritedAdaptiveCardHandlers(
        onSubmit: (invoke) {
          final text = invoke.data['message'] as String? ?? '';
          unawaited(controller.send(text));
        },
        onExecute: (_) {},
        onOpenUrl: (_) {},
        onOpenUrlDialog: (_) {},
        onChange: (_) {},
        child: AdaptiveCardsCanvas.map(
          // Rebuild empty after each send.
          key: ValueKey('compose-${controller.composeEpoch}'),
          content: composeCard(),
          hostConfigs: hostConfigs,
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
