// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Chat Adaptativo';

  @override
  String get newConversationTooltip => 'Nueva conversación';

  @override
  String get startErrorMessage =>
      'No se pudo conectar con el servidor de chat.';

  @override
  String get retryButton => 'Reintentar';

  @override
  String get composePlaceholder => 'Escribe un mensaje';

  @override
  String get sendButton => 'Enviar';

  @override
  String get userRoleLabel => 'usuario';

  @override
  String get assistantRoleLabel => 'asistente';
}
