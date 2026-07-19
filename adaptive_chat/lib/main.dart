import 'dart:async';

import 'package:adaptive_chat/src/chat_backend_client.dart';
import 'package:adaptive_chat/src/chat_page.dart';
import 'package:adaptive_chat/src/conversation_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/flutter_adaptive_cards_fs.dart';

void main() => runApp(const AdaptiveChatApp());

/// Root of the Adaptive Chat SDUI demo.
class AdaptiveChatApp extends StatefulWidget {
  /// Creates the app.
  const AdaptiveChatApp({super.key});

  @override
  State<AdaptiveChatApp> createState() => _AdaptiveChatAppState();
}

class _AdaptiveChatAppState extends State<AdaptiveChatApp> {
  late final ConversationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ConversationController(
      client: ChatBackendClient(baseUrl: Uri.parse('http://localhost:8000')),
    );
    // Fire-and-forget from initState: startConversation() never throws (a
    // failed start is recorded on the controller as `startError`), so no
    // try/catch is needed here.
    unawaited(_controller.startConversation());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Adaptive Chat',
      theme: ThemeData(useMaterial3: true),
      home: ChatPage(controller: _controller, hostConfigs: HostConfigs()),
    );
  }
}
