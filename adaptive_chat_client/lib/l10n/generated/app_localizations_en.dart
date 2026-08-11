// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Adaptive Chat';

  @override
  String get newConversationTooltip => 'New conversation';

  @override
  String get startErrorMessage => 'Couldn\'t reach the chat server.';

  @override
  String get retryButton => 'Retry';

  @override
  String get composePlaceholder => 'Type a message';

  @override
  String get sendButton => 'Send';

  @override
  String get userRoleLabel => 'user';

  @override
  String get assistantRoleLabel => 'assistant';
}
