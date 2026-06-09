/// Root-level `refresh` object on an Adaptive Card (v1.4+).
///
/// See [Refresh](https://adaptivecards.io/explorer/Refresh.html).
class RefreshConfig {
  /// Creates refresh metadata from parsed JSON fields.
  const RefreshConfig({
    this.action,
    this.userIds,
    this.expires,
  });

  /// Parses a card `refresh` object map.
  factory RefreshConfig.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic>? action;
    final actionRaw = json['action'];
    if (actionRaw is Map) {
      action = Map<String, dynamic>.from(actionRaw);
    }

    List<String>? userIds;
    final userIdsRaw = json['userIds'];
    if (userIdsRaw is List) {
      userIds = userIdsRaw.map((id) => id.toString()).toList();
    }

    DateTime? expires;
    final expiresRaw = json['expires'];
    if (expiresRaw != null) {
      expires = DateTime.tryParse(expiresRaw.toString());
    }

    return RefreshConfig(
      action: action,
      userIds: userIds,
      expires: expires,
    );
  }

  /// Nested `Action.Execute` (or compatible) map fired on refresh.
  final Map<String, dynamic>? action;

  /// When non-empty, auto-refresh only runs for these user ids.
  final List<String>? userIds;

  /// When in the past, auto-refresh fires once after the first frame.
  final DateTime? expires;
}
