/// Root-level `authentication` object on an Adaptive Card (v1.4+).
///
/// Drives the Bot Framework sign-in affordance. This library implements the
/// **sign-in button** path (`buttons[].type == "signin"`); the
/// [tokenExchangeResource] map is preserved for callers but SSO token exchange
/// is not performed by the renderer.
///
/// See [Authentication](https://learn.microsoft.com/en-us/adaptive-cards/schema-explorer/authentication).
class AuthenticationConfig {
  /// Creates authentication metadata from parsed JSON fields.
  const AuthenticationConfig({
    this.text,
    this.connectionName,
    this.tokenExchangeResource,
    this.buttons = const [],
  });

  /// Parses a card `authentication` object map, tolerating malformed fields.
  factory AuthenticationConfig.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic>? tokenExchangeResource;
    final ter = json['tokenExchangeResource'];
    if (ter is Map) {
      tokenExchangeResource = Map<String, dynamic>.from(ter);
    }

    final buttons = <AuthCardButton>[];
    final buttonsRaw = json['buttons'];
    if (buttonsRaw is List) {
      for (final entry in buttonsRaw) {
        if (entry is Map) {
          buttons.add(
            AuthCardButton.fromJson(Map<String, dynamic>.from(entry)),
          );
        }
      }
    }

    return AuthenticationConfig(
      text: json['text']?.toString(),
      connectionName: json['connectionName']?.toString(),
      tokenExchangeResource: tokenExchangeResource,
      buttons: buttons,
    );
  }

  /// Prompt shown above the sign-in buttons.
  final String? text;

  /// OAuth connection name the host uses to complete sign-in.
  final String? connectionName;

  /// Raw `tokenExchangeResource` object; preserved but not acted on (SSO is a
  /// future phase).
  final Map<String, dynamic>? tokenExchangeResource;

  /// Sign-in buttons rendered for the auth affordance.
  final List<AuthCardButton> buttons;
}

/// A single button inside an [AuthenticationConfig.buttons] list.
class AuthCardButton {
  /// Creates a sign-in button descriptor.
  const AuthCardButton({
    required this.type,
    this.title,
    this.image,
    this.value,
  });

  /// Parses one `authentication.buttons` entry.
  factory AuthCardButton.fromJson(Map<String, dynamic> json) {
    return AuthCardButton(
      type: json['type']?.toString() ?? '',
      title: json['title']?.toString(),
      image: json['image']?.toString(),
      value: json['value']?.toString(),
    );
  }

  /// Button type; the renderer only actions `"signin"`.
  final String type;

  /// Button label.
  final String? title;

  /// Optional leading image URL.
  final String? image;

  /// Sign-in URL / action value forwarded to the host on tap.
  final String? value;
}
