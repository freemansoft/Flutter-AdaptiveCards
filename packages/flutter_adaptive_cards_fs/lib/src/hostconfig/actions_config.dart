/// HostConfig `actions.showCard` settings controlling ShowCard action
/// rendering.
class ShowCardConfig({
  /// How the revealed card is presented (`inline` or `popup`).
  required final String actionMode,

  /// Container style applied to the shown card (`default` or `emphasis`).
  required final String style,

  /// Top margin in pixels when [actionMode] is `inline`.
  required final int inlineTopMargin,
}) {
  /// Creates show-card layout settings from explicit values.
  this;

  /// Parses `actions.showCard` from HostConfig JSON.
  factory fromJson(Map<String, dynamic> json) {
    return ShowCardConfig(
      actionMode: json['actionMode']?.toString() ?? 'inline',
      style: json['style']?.toString() ?? 'emphasis',
      inlineTopMargin: json['inlineTopMargin'] as int? ?? 16,
    );
  }
}

/// HostConfig `actions` section controlling action set layout and button
/// chrome.
class ActionsConfig({
  /// Layout direction for action buttons (`horizontal` or `vertical`).
  required final String actionsOrientation,

  /// How buttons align within the action strip.
  required final String actionAlignment,

  /// Pixel gap between adjacent action buttons.
  required final int buttonSpacing,

  /// Maximum number of actions shown before overflow handling.
  required final int maxActions,

  /// Spacing token applied around the action set.
  required final String spacing,

  /// ShowCard-specific presentation settings.
  required final ShowCardConfig showCard,

  /// Where action icons render relative to button title text.
  required final String iconPlacement,

  /// Icon size in pixels for actions that include an icon.
  required final int iconSize,
}) {
  /// Creates action-set layout settings from explicit values.
  this;

  /// Parses `actions` from HostConfig JSON.
  factory fromJson(Map<String, dynamic> json) {
    return ActionsConfig(
      actionsOrientation:
          json['actionsOrientation']?.toString() ?? 'horizontal',
      actionAlignment: json['actionAlignment']?.toString() ?? 'stretch',
      buttonSpacing: json['buttonSpacing'] as int? ?? 10,
      maxActions: json['maxActions'] as int? ?? 5,
      spacing: json['spacing']?.toString() ?? 'default',
      showCard: ShowCardConfig.fromJson(json['showCard'] ?? {}),
      iconPlacement: json['iconPlacement']?.toString() ?? 'aboveTitle',
      iconSize: json['iconSize'] as int? ?? 30,
    );
  }
}
