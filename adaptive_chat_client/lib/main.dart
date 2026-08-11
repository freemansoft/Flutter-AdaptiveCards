import 'dart:async';

import 'package:adaptive_chat_client/l10n/generated/app_localizations.dart';
import 'package:adaptive_chat_client/src/chat_backend_client.dart';
import 'package:adaptive_chat_client/src/chat_host_config.dart';
import 'package:adaptive_chat_client/src/chat_page.dart';
import 'package:adaptive_chat_client/src/conversation_controller.dart';
import 'package:flutter/material.dart';

void main() => runApp(const AdaptiveChatApp());

/// Root of the Adaptive Chat SDUI demo.
class AdaptiveChatApp extends StatelessWidget {
  /// Creates the app.
  ///
  /// [locale] overrides the device locale; tests pass it to force a
  /// deterministic language instead of relying on the test runner's locale.
  const AdaptiveChatApp({this.locale, super.key});

  /// Locale override, if any.
  final Locale? locale;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
      theme: ThemeData(useMaterial3: true),
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const _ChatHome(),
    );
  }
}

/// Builds the [ConversationController] once [AppLocalizations] and the
/// resolved [Locale] are reachable — i.e. below [MaterialApp] — so the
/// bubble role labels sent to the backend, and the `language` tag, follow
/// the app's locale from the very first `startConversation()` call.
class _ChatHome extends StatefulWidget {
  const _ChatHome();

  @override
  State<_ChatHome> createState() => _ChatHomeState();
}

class _ChatHomeState extends State<_ChatHome> {
  ConversationController? _controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller != null) return;
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context);
    final controller = ConversationController(
      client: ChatBackendClient(baseUrl: Uri.parse('http://localhost:8000')),
      userLabel: l10n.userRoleLabel,
      assistantLabel: l10n.assistantRoleLabel,
      language: locale.languageCode,
    );
    _controller = controller;
    // Fire-and-forget from didChangeDependencies: startConversation() never
    // throws (a failed start is recorded on the controller as `startError`),
    // so no try/catch is needed here.
    unawaited(controller.startConversation());
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChatPage(controller: _controller!, hostConfigs: chatHostConfigs());
  }
}
